## EnemyAI — combat behavior component for hostile NPCs.
## Attach as a child of an NPC node (CharacterBody2D with npc_data).
## States: PATROL, ALERT, CHASE, ATTACK, STUNNED, FLEEING, SURRENDERED, DEAD.
## Reads faction state for damage modifiers; supports surrender for non-lethal resolution.
extends Node2D

signal state_changed(old_state: int, new_state: int)
signal surrendered(npc_id: String)
signal died(npc_id: String)

enum AIState { PATROL, ALERT, CHASE, ATTACK, STUNNED, FLEEING, SURRENDERED, DEAD }
var current_state: AIState = AIState.PATROL

# Movement
const PATROL_SPEED: float = 25.0
const CHASE_SPEED: float = 55.0
const FLEE_SPEED: float = 50.0

# Detection
const DETECTION_RANGE: float = 80.0
const LOSE_INTEREST_RANGE: float = 150.0
const ATTACK_RANGE: float = 18.0
const ALERT_DURATION: float = 1.0

# Attack
const ATTACK_COOLDOWN: float = 1.2
const ATTACK_HITBOX_SIZE: Vector2 = Vector2(16.0, 12.0)
const ATTACK_HITBOX_OFFSET: float = 14.0
const ATTACK_DURATION: float = 0.3

# Stun
const STUN_DURATION: float = 0.5

# Surrender
const SURRENDER_HP_RATIO: float = 0.2  # 20% HP threshold

# Internal
var _npc: CharacterBody2D = null
var _target: Node2D = null
var _combat_manager: Node = null

# Timers
var _alert_timer: float = 0.0
var _attack_cooldown_timer: float = 0.0
var _attack_timer: float = 0.0
var _stun_timer: float = 0.0

# Patrol
var _patrol_origin: Vector2 = Vector2.ZERO
var _patrol_target: Vector2 = Vector2.ZERO
var _patrol_wait_timer: float = 0.0
const PATROL_RADIUS: float = 40.0
const PATROL_WAIT_MIN: float = 2.0
const PATROL_WAIT_MAX: float = 5.0

# Active hitbox during attack
var _active_hitbox: Area2D = null


func _ready() -> void:
	_npc = get_parent() as CharacterBody2D
	if _npc == null:
		push_warning("EnemyAI: must be a child of a CharacterBody2D (an NPC).")
		return

	_patrol_origin = _npc.global_position
	_pick_patrol_target()


func _physics_process(delta: float) -> void:
	if _npc == null:
		return

	# Always tick the attack cooldown
	if _attack_cooldown_timer > 0.0:
		_attack_cooldown_timer -= delta

	match current_state:
		AIState.PATROL:
			_process_patrol(delta)
		AIState.ALERT:
			_process_alert(delta)
		AIState.CHASE:
			_process_chase(delta)
		AIState.ATTACK:
			_process_attack(delta)
		AIState.STUNNED:
			_process_stunned(delta)
		AIState.FLEEING:
			_process_flee(delta)
		AIState.SURRENDERED, AIState.DEAD:
			_npc.velocity = Vector2.ZERO


## Called by CombatManager when combat starts.
func enter_combat(player: Node2D) -> void:
	_target = player
	_transition_to(AIState.CHASE)


## Called by CombatManager when combat ends.
func exit_combat() -> void:
	_target = null
	if current_state != AIState.DEAD and current_state != AIState.SURRENDERED:
		_transition_to(AIState.PATROL)


## Whether this enemy is no longer an active threat.
func is_out_of_combat() -> bool:
	return current_state in [AIState.DEAD, AIState.SURRENDERED, AIState.FLEEING]


## Apply damage to this enemy.
func take_damage(amount: float, _source: String = "player") -> void:
	if current_state == AIState.DEAD or current_state == AIState.SURRENDERED:
		return

	var npc_id: String = _get_npc_id()
	var npc_data: Resource = _npc.npc_data if "npc_data" in _npc else null
	var max_hp: float = npc_data.max_health if npc_data else 50.0
	var health: float = GameState.get_state("npc.%s.health" % npc_id, max_hp)

	health -= amount
	GameState.set_state("npc.%s.health" % npc_id, maxf(health, 0.0))

	# Spawn damage number
	_spawn_damage_number(amount)

	if health <= 0.0:
		_die()
		return

	# Check surrender threshold
	var can_surrender: bool = npc_data.can_surrender if npc_data else false
	if can_surrender and health < (max_hp * SURRENDER_HP_RATIO):
		_surrender()
		return

	# Check flee threshold — cowardly NPCs flee at 40% HP
	var courage: float = npc_data.courage if npc_data else 0.5
	if courage < 0.3 and health < (max_hp * 0.4):
		_transition_to(AIState.FLEEING)
		return

	# Brief stun from being hit
	_stun_timer = STUN_DURATION
	_transition_to(AIState.STUNNED)

	# Remember being attacked
	GameState.set_state("npc.%s.memory.attacked_by_player" % npc_id, true)
	GameState.delta_state("npc.%s.disposition" % npc_id, -30.0)

	# If we weren't chasing, now we are
	if _target == null:
		var player: Node2D = get_tree().get_first_node_in_group("player")
		if player:
			_target = player


## Melee attack with cooldown.
func attack() -> void:
	if _attack_cooldown_timer > 0.0:
		return
	if current_state == AIState.DEAD or current_state == AIState.SURRENDERED:
		return

	_transition_to(AIState.ATTACK)
	_attack_timer = ATTACK_DURATION
	_attack_cooldown_timer = ATTACK_COOLDOWN

	_create_attack_hitbox()


## Chase the current target.
func chase_target(player: Node2D) -> void:
	_target = player
	if current_state != AIState.DEAD and current_state != AIState.SURRENDERED:
		_transition_to(AIState.CHASE)


## Start fleeing from the player.
func flee() -> void:
	_transition_to(AIState.FLEEING)


## Stop fighting and become interactable for spare/kill.
func surrender() -> void:
	_surrender()


## Get the damage this enemy deals, modified by world state.
func get_attack_damage() -> float:
	var npc_data: Resource = _npc.npc_data if "npc_data" in _npc else null
	var base_damage: float = npc_data.attack_damage if npc_data else 5.0

	# Apply world-state modifier
	var modifier: float = _get_damage_modifier()
	return base_damage * modifier


# --- State Processors ---

func _process_patrol(delta: float) -> void:
	# Check for player detection
	var player: Node2D = get_tree().get_first_node_in_group("player")
	if player and _can_detect(player):
		_target = player
		_transition_to(AIState.ALERT)
		return

	# Wander around patrol origin
	if _patrol_wait_timer > 0.0:
		_patrol_wait_timer -= delta
		_npc.velocity = Vector2.ZERO
		_npc.move_and_slide()
		return

	var dist: float = _npc.global_position.distance_to(_patrol_target)
	if dist < 4.0:
		_patrol_wait_timer = randf_range(PATROL_WAIT_MIN, PATROL_WAIT_MAX)
		_pick_patrol_target()
		return

	var dir: Vector2 = (_patrol_target - _npc.global_position).normalized()
	_npc.velocity = dir * PATROL_SPEED
	_npc.move_and_slide()


func _process_alert(delta: float) -> void:
	_alert_timer -= delta
	_npc.velocity = Vector2.ZERO
	_npc.move_and_slide()

	if _alert_timer <= 0.0:
		if _target and is_instance_valid(_target):
			_transition_to(AIState.CHASE)
		else:
			_transition_to(AIState.PATROL)


func _process_chase(_delta: float) -> void:
	if _target == null or not is_instance_valid(_target):
		_transition_to(AIState.PATROL)
		return

	var dist: float = _npc.global_position.distance_to(_target.global_position)

	# Lost interest
	if dist > LOSE_INTEREST_RANGE:
		_target = null
		_transition_to(AIState.PATROL)
		return

	# Close enough to attack
	if dist <= ATTACK_RANGE and _attack_cooldown_timer <= 0.0:
		attack()
		return

	# Move toward target
	var dir: Vector2 = (_target.global_position - _npc.global_position).normalized()
	_npc.velocity = dir * CHASE_SPEED
	if "facing_direction" in _npc or "_facing_direction" in _npc:
		_npc._facing_direction = dir
	_npc.move_and_slide()


func _process_attack(delta: float) -> void:
	_npc.velocity = Vector2.ZERO
	_npc.move_and_slide()

	_attack_timer -= delta
	if _attack_timer <= 0.0:
		_end_attack()
		# Return to chasing
		if _target and is_instance_valid(_target):
			_transition_to(AIState.CHASE)
		else:
			_transition_to(AIState.PATROL)


func _process_stunned(delta: float) -> void:
	_npc.velocity = Vector2.ZERO
	_npc.move_and_slide()

	_stun_timer -= delta
	if _stun_timer <= 0.0:
		if _target and is_instance_valid(_target):
			_transition_to(AIState.CHASE)
		else:
			_transition_to(AIState.PATROL)


func _process_flee(_delta: float) -> void:
	var player: Node2D = get_tree().get_first_node_in_group("player")
	if player == null:
		_transition_to(AIState.PATROL)
		return

	var flee_dir: Vector2 = (_npc.global_position - player.global_position).normalized()
	_npc.velocity = flee_dir * FLEE_SPEED
	_npc.move_and_slide()

	# Stop fleeing if far enough away
	if _npc.global_position.distance_to(player.global_position) > LOSE_INTEREST_RANGE:
		_transition_to(AIState.PATROL)


# --- Combat Actions ---

func _create_attack_hitbox() -> void:
	var facing: Vector2 = Vector2.DOWN
	if "_facing_direction" in _npc:
		facing = _npc._facing_direction
	elif _target and is_instance_valid(_target):
		facing = (_target.global_position - _npc.global_position).normalized()

	var hitbox := Area2D.new()
	hitbox.name = "EnemyAttackHitbox"
	hitbox.collision_layer = 0
	hitbox.collision_mask = 2  # Layer 2: player
	hitbox.monitoring = true
	hitbox.monitorable = false

	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = ATTACK_HITBOX_SIZE
	shape.shape = rect
	hitbox.add_child(shape)

	hitbox.position = facing.normalized() * ATTACK_HITBOX_OFFSET
	_npc.add_child(hitbox)
	_active_hitbox = hitbox

	hitbox.area_entered.connect(_on_attack_hit_area)
	hitbox.body_entered.connect(_on_attack_hit_body)


func _end_attack() -> void:
	if _active_hitbox and is_instance_valid(_active_hitbox):
		_active_hitbox.queue_free()
		_active_hitbox = null


func _on_attack_hit_area(area: Area2D) -> void:
	_try_damage_player(area.get_parent())


func _on_attack_hit_body(body: Node2D) -> void:
	_try_damage_player(body)


func _try_damage_player(target: Node) -> void:
	if target == null or target == _npc:
		return
	if not target.is_in_group("player"):
		return

	# Check if player is dodging (i-frames)
	var player_combat: Node = _find_player_combat(target)
	if player_combat and player_combat.is_invincible:
		return

	var damage: float = get_attack_damage()

	if player_combat and player_combat.has_method("take_damage"):
		player_combat.take_damage(damage, _get_npc_id())
	elif target.has_method("take_damage"):
		target.take_damage(damage, _get_npc_id())


# --- Surrender / Death ---

func _surrender() -> void:
	_transition_to(AIState.SURRENDERED)
	_npc.velocity = Vector2.ZERO

	var npc_id: String = _get_npc_id()
	GameState.set_state("npc.%s.surrendered" % npc_id, true)

	# Make interactable for spare/kill dialogue
	if _npc.is_in_group("interactable") == false:
		_npc.add_to_group("interactable")

	EventBus.enemy_surrendered.emit(npc_id)
	surrendered.emit(npc_id)


func _die() -> void:
	_transition_to(AIState.DEAD)
	_npc.velocity = Vector2.ZERO
	_end_attack()

	var npc_id: String = _get_npc_id()
	GameState.set_state("npc.%s.alive" % npc_id, false)
	GameState.set_state("npc.%s.killed_by" % npc_id, "player")
	EventBus.npc_died.emit(npc_id, "player")

	died.emit(npc_id)

	# Disable collision so the corpse doesn't block
	_npc.collision_layer = 0
	_npc.collision_mask = 0

	# Dim the sprite to indicate death
	if "animated_sprite" in _npc and _npc.animated_sprite:
		_npc.animated_sprite.modulate = Color(0.5, 0.5, 0.5, 0.7)


# --- Helpers ---

func _transition_to(new_state: AIState) -> void:
	if current_state == new_state:
		return
	var old: AIState = current_state
	current_state = new_state

	# State entry logic
	match new_state:
		AIState.ALERT:
			_alert_timer = ALERT_DURATION
		AIState.STUNNED:
			_stun_timer = STUN_DURATION

	state_changed.emit(old, new_state)


func _can_detect(player: Node2D) -> bool:
	var dist: float = _npc.global_position.distance_to(player.global_position)
	return dist <= DETECTION_RANGE


func _get_npc_id() -> String:
	if "npc_id" in _npc:
		return _npc.npc_id
	return _npc.name


func _get_damage_modifier() -> float:
	# World-state driven damage modifier
	var npc_data: Resource = _npc.npc_data if "npc_data" in _npc else null
	var faction_id: String = npc_data.faction_id if npc_data else ""
	if faction_id == "":
		return 1.0

	var modifier: float = 1.0

	# Starving soldiers fight at 50% damage
	var famine_key: String = "faction.%s.status.famine" % faction_id
	if GameState.get_state(famine_key, false):
		modifier *= 0.5

	# Well-funded factions (high power) fight at 120%
	var power: float = GameState.get_state("faction.%s.power" % faction_id, 50.0)
	if power >= 80.0:
		modifier *= 1.2

	return modifier


func _pick_patrol_target() -> void:
	var angle: float = randf() * TAU
	var dist: float = randf_range(10.0, PATROL_RADIUS)
	_patrol_target = _patrol_origin + Vector2(cos(angle), sin(angle)) * dist


func _find_player_combat(player_node: Node) -> Node:
	# Look for a PlayerCombat child on the player node
	for child in player_node.get_children():
		if child is Node2D and child.has_method("take_damage") and "is_invincible" in child:
			return child
	return null


func _spawn_damage_number(amount: float) -> void:
	var DamageNumber = preload("res://scenes/combat/damage_number.gd")
	var label: Node = DamageNumber.new()
	label.setup(amount, _npc.global_position + Vector2(0, -8), false)
	var tree: SceneTree = get_tree()
	if tree and tree.current_scene:
		tree.current_scene.add_child(label)
