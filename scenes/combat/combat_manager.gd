## CombatManager — instantiated per-region to track active combat encounters.
## Handles combat start/end flow, enemy AI targeting, spare/kill decisions,
## and writes all outcomes to GameState.
## Design principle: combat is DANGEROUS and a CONSEQUENCE, not a gameplay loop.
extends Node

signal combat_state_changed(in_combat: bool)

# Active combat tracking
var in_combat: bool = false
var active_enemies: Array[Node] = []
var _combat_region_id: String = ""

# Targeting
var _player_ref: WeakRef = WeakRef.new()
var _current_target: Node = null


func _ready() -> void:
	EventBus.enemy_defeated.connect(_on_enemy_defeated)
	EventBus.enemy_surrendered.connect(_on_enemy_surrendered)
	EventBus.npc_died.connect(_on_npc_died)
	EventBus.player_died.connect(_on_player_died)

	# Cache the region we belong to
	var region: Node = _find_parent_region()
	if region and region.has_method("get") and region.get("region_id"):
		_combat_region_id = region.region_id
	elif region:
		_combat_region_id = region.name


func _process(_delta: float) -> void:
	if not in_combat:
		return
	# Clean dead/freed references from the list
	_prune_enemy_list()
	if active_enemies.is_empty():
		end_combat("victory")


## Start combat with a set of enemy nodes.
func start_combat(enemies: Array[Node], player: Node2D = null) -> void:
	if in_combat:
		# Reinforce — add new enemies to existing encounter
		for enemy in enemies:
			if enemy not in active_enemies:
				active_enemies.append(enemy)
		return

	in_combat = true
	active_enemies = enemies.duplicate()

	if player:
		_player_ref = weakref(player)
	else:
		var tree_player: Node = Engine.get_main_loop().root.get_tree().get_first_node_in_group("player") if Engine.get_main_loop() else null
		if tree_player == null:
			tree_player = get_tree().get_first_node_in_group("player")
		if tree_player:
			_player_ref = weakref(tree_player)

	# Alert all enemies
	for enemy in active_enemies:
		if enemy.has_method("enter_combat"):
			enemy.enter_combat(_player_ref.get_ref())

	# Record combat start in GameState
	GameState.delta_state("player.stats.combats_entered", 1.0)

	var enemy_ids: Array = []
	for enemy in active_enemies:
		if "npc_id" in enemy:
			enemy_ids.append(enemy.npc_id)
	EventBus.combat_started.emit(active_enemies)
	combat_state_changed.emit(true)


## End the current combat encounter.
func end_combat(result: String = "victory") -> void:
	if not in_combat:
		return

	in_combat = false

	# Tell remaining enemies combat is over
	for enemy in active_enemies:
		if is_instance_valid(enemy) and enemy.has_method("exit_combat"):
			enemy.exit_combat()

	active_enemies.clear()
	_current_target = null

	EventBus.combat_ended.emit(result)
	combat_state_changed.emit(false)


## Get the highest-priority target for an enemy to attack.
## Returns the player node or null.
func get_player_target() -> Node2D:
	var player: Node2D = _player_ref.get_ref() as Node2D
	if player and is_instance_valid(player):
		return player
	return null


## Process the player's decision to spare a surrendered enemy.
func spare_enemy(enemy_node: Node) -> void:
	if not is_instance_valid(enemy_node):
		return

	var eid: String = enemy_node.npc_id if "npc_id" in enemy_node else ""
	if eid == "":
		return

	GameState.begin_batch()

	# Mark as spared
	GameState.set_state("npc.%s.spared" % eid, true)
	GameState.set_state("npc.%s.spared_by" % eid, "player")

	# Positive disposition shift — they owe you their life
	GameState.delta_state("npc.%s.disposition" % eid, 40.0)

	# Faction reputation boost for mercy
	var faction_id: String = _get_enemy_faction(enemy_node)
	if faction_id != "":
		FactionManager.modify_player_rep(faction_id, 5)

	# Notify witnesses of mercy
	_notify_witnesses_of_mercy(enemy_node, eid)

	GameState.end_batch()

	# Remove from active enemies
	active_enemies.erase(enemy_node)
	EventBus.enemy_defeated.emit(eid, true)

	# Check if combat should end
	if _all_enemies_resolved():
		end_combat("victory")


## Process the player's decision to kill a surrendered enemy.
func kill_surrendered_enemy(enemy_node: Node) -> void:
	if not is_instance_valid(enemy_node):
		return

	var eid: String = enemy_node.npc_id if "npc_id" in enemy_node else ""
	if eid == "":
		return

	GameState.begin_batch()

	# Mark as executed (killed after surrender — worse than combat death)
	GameState.set_state("npc.%s.executed" % eid, true)
	GameState.set_state("npc.%s.alive" % eid, false)
	GameState.set_state("npc.%s.killed_by" % eid, "player")
	GameState.delta_state("player.stats.executions", 1.0)

	# Heavy faction penalty — executing prisoners is dishonorable
	var faction_id: String = _get_enemy_faction(enemy_node)
	if faction_id != "":
		FactionManager.modify_player_rep(faction_id, -20)

	# Witnesses are horrified
	_notify_witnesses_of_execution(enemy_node, eid)

	GameState.end_batch()

	# Kill the NPC
	if enemy_node.has_method("_die"):
		enemy_node._die("player")

	active_enemies.erase(enemy_node)
	EventBus.enemy_defeated.emit(eid, false)

	if _all_enemies_resolved():
		end_combat("victory")


## Get the damage modifier for an enemy based on world state.
## Starving soldiers fight at 50%, well-paid mercs at 120%.
func get_enemy_damage_modifier(enemy_node: Node) -> float:
	var faction_id: String = _get_enemy_faction(enemy_node)
	if faction_id == "":
		return 1.0

	var modifier: float = 1.0

	# Check for famine in the faction's region
	var famine_key: String = "faction.%s.status.famine" % faction_id
	if GameState.get_state(famine_key, false):
		modifier *= 0.5

	# Check for well-funded status
	var power: float = GameState.get_state("faction.%s.power" % faction_id, 50.0)
	if power >= 80.0:
		modifier *= 1.2

	return modifier


# --- Private ---

func _prune_enemy_list() -> void:
	var i: int = active_enemies.size() - 1
	while i >= 0:
		var enemy: Node = active_enemies[i]
		if not is_instance_valid(enemy):
			active_enemies.remove_at(i)
		elif "current_state" in enemy:
			# Remove dead or surrendered enemies from active threat list
			var state = enemy.current_state
			# Check by value comparison since enum types may differ
			if enemy.has_method("is_out_of_combat") and enemy.is_out_of_combat():
				active_enemies.remove_at(i)
		i -= 1


func _all_enemies_resolved() -> bool:
	for enemy in active_enemies:
		if not is_instance_valid(enemy):
			continue
		if enemy.has_method("is_out_of_combat") and enemy.is_out_of_combat():
			continue
		# Still a live threat
		return false
	return true


func _get_enemy_faction(enemy_node: Node) -> String:
	if "npc_data" in enemy_node and enemy_node.npc_data:
		return enemy_node.npc_data.faction_id
	var eid: String = enemy_node.npc_id if "npc_id" in enemy_node else ""
	if eid != "":
		return GameState.get_state("npc.%s.faction" % eid, "")
	return ""


func _notify_witnesses_of_mercy(enemy_node: Node, enemy_id: String) -> void:
	for npc in get_tree().get_nodes_in_group("npcs"):
		if npc == enemy_node:
			continue
		if not is_instance_valid(npc) or not "npc_id" in npc:
			continue
		if enemy_node.global_position.distance_to(npc.global_position) < 120.0:
			GameState.set_state("npc.%s.memory.witnessed_mercy_%s" % [npc.npc_id, enemy_id], true)
			GameState.delta_state("npc.%s.disposition" % npc.npc_id, 10.0)


func _notify_witnesses_of_execution(enemy_node: Node, enemy_id: String) -> void:
	for npc in get_tree().get_nodes_in_group("npcs"):
		if npc == enemy_node:
			continue
		if not is_instance_valid(npc) or not "npc_id" in npc:
			continue
		if enemy_node.global_position.distance_to(npc.global_position) < 120.0:
			var witness_id: String = npc.npc_id
			GameState.set_state("npc.%s.memory.witnessed_execution_%s" % [witness_id, enemy_id], true)
			GameState.set_state("npc.%s.memory.witnessed_violence" % witness_id, true)
			GameState.delta_state("npc.%s.disposition" % witness_id, -50.0)


func _find_parent_region() -> Node:
	var node: Node = get_parent()
	while node:
		if node.is_in_group("regions"):
			return node
		node = node.get_parent()
	return null


func _on_enemy_defeated(enemy_id: String, was_spared: bool) -> void:
	if was_spared:
		GameState.delta_state("player.stats.enemies_spared", 1.0)
	else:
		GameState.delta_state("player.stats.enemies_killed", 1.0)


func _on_enemy_surrendered(_enemy_id: String) -> void:
	# A surrendered enemy is no longer an active threat but stays in the list
	# until the player decides to spare or kill
	pass


func _on_npc_died(npc_id: String, killer: String) -> void:
	# Remove from active enemies if present
	for i in range(active_enemies.size() - 1, -1, -1):
		if is_instance_valid(active_enemies[i]) and "npc_id" in active_enemies[i]:
			if active_enemies[i].npc_id == npc_id:
				active_enemies.remove_at(i)

	if _all_enemies_resolved() and in_combat:
		end_combat("victory")


func _on_player_died() -> void:
	if in_combat:
		end_combat("defeat")
