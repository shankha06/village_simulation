## NPC Base — AI controller with schedule following, dialogue, memory, and combat.
extends CharacterBody2D

@export var npc_id: String = ""
@export var npc_data: NPCData

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var dialogue_zone: Area2D = $DialogueZone
@onready var label: Label = $NameLabel

# Behavior FSM
enum NPCState { IDLE, WALKING, AT_ACTIVITY, REACTING, FLEEING, SURRENDERED, DEAD }
var current_state: NPCState = NPCState.IDLE

# Movement
const WALK_SPEED: float = 40.0
var _target_position: Vector2 = Vector2.ZERO
var _has_target: bool = false
var _facing_direction: Vector2 = Vector2.DOWN

# Schedule
var _current_schedule_entry: Dictionary = {}

# Navigation
var _nav_path: PackedVector2Array = []
var _path_index: int = 0

# NPC sprite reference (for facing direction updates)
var _npc_sprite: Sprite2D = null
var _npc_outline_sprites: Array[Sprite2D] = []

# Interaction
var _player_in_range: bool = false

# Bark system
var _bark_label: Label = null
var _bark_timer: float = 0.0
var _bark_visible_timer: float = 0.0
var _last_bark_index: int = -1
const BARK_DELAY: float = 3.0
const BARK_DISPLAY_TIME: float = 3.5
const BARK_FADE_TIME: float = 0.5

# Dialogue tracking
var _awaiting_dialogue_end: bool = false


## NPC JSON data loaded at runtime (dialogue pools, personality, etc.)
var _json_data: Dictionary = {}


func _ready() -> void:
	add_to_group("npcs")
	add_to_group("interactable")

	if npc_id == "" and npc_data:
		npc_id = npc_data.npc_id

	# Load NPC data from JSON file
	_load_json_data()

	# Initialize NPC state in GameState
	if npc_id != "":
		if not GameState.has_state("npc.%s.alive" % npc_id):
			GameState.set_state("npc.%s.alive" % npc_id, true)
		if not GameState.has_state("npc.%s.disposition" % npc_id):
			GameState.set_state("npc.%s.disposition" % npc_id, 0)

	# Set display name
	var display_name: String = _json_data.get("name", "")
	if display_name == "" and npc_data:
		display_name = npc_data.display_name
	if display_name == "":
		display_name = npc_id.capitalize()
	if label:
		label.text = display_name

	# Load NPC sprite if available
	_setup_visual()

	# Initialize dialogue stage if not set
	if npc_id != "":
		if not GameState.has_state("npc.%s.dialogue_stage" % npc_id):
			GameState.set_state("npc.%s.dialogue_stage" % npc_id, "intro")

	# Create bark label
	_setup_bark_label()

	# Connect signals
	TimeManager.hour_tick.connect(_on_hour_tick)
	EventBus.player_interacted.connect(_on_player_interacted)
	EventBus.dialogue_ended.connect(_on_dialogue_ended_tracking)
	GameState.state_changed.connect(_on_state_changed)


func _load_json_data() -> void:
	if npc_id == "":
		return
	var json_path: String = "res://data/npcs/%s.json" % npc_id
	if not FileAccess.file_exists(json_path):
		print("NPC %s: No JSON data at %s" % [npc_id, json_path])
		return
	var file := FileAccess.open(json_path, FileAccess.READ)
	if file == null:
		return
	var json := JSON.new()
	if json.parse(file.get_as_text()) == OK and json.data is Dictionary:
		_json_data = json.data
		print("NPC %s: Loaded JSON data (%s)" % [npc_id, _json_data.get("name", "?")])
	file.close()


func _setup_visual() -> void:
	# Try to load the NPC's sprite from assets
	var sprite_path: String = "res://assets/sprites/npcs/%s.png" % npc_id
	if ResourceLoader.exists(sprite_path):
		var tex: Texture2D = load(sprite_path)
		if tex and animated_sprite:
			animated_sprite.visible = false
			var sprite := Sprite2D.new()
			sprite.name = "NPCSprite"
			sprite.texture = tex
			sprite.hframes = 4
			sprite.frame = 0
			sprite.position = Vector2(0, -8)
			# Texture filter Nearest for sharp pixels
			sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

			# Store reference for facing direction updates
			_npc_sprite = sprite
			_npc_outline_sprites.clear()

			# Add a simple 1px dark outline by duplicating and shifting
			# This makes the 16x16 characters pop against dark backgrounds
			for dir in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]:
				var outline := Sprite2D.new()
				outline.texture = tex
				outline.hframes = 4
				outline.frame = 0
				outline.position = Vector2(0, -8) + dir
				outline.modulate = Color(0, 0, 0, 0.7) # Dark semi-transparent outline
				outline.z_index = -1
				sprite.add_child(outline)
				_npc_outline_sprites.append(outline)

			add_child(sprite)
			return
	# No sprite found — create a minimal styled placeholder
	if animated_sprite:
		animated_sprite.visible = false
	
	# Small shadow for better grounding
	var shadow := ColorRect.new()
	shadow.color = Color(0, 0, 0, 0.4)
	shadow.size = Vector2(8, 3)
	shadow.position = Vector2(-4, -1)
	add_child(shadow)
	
	# Only add a colored block if npc_id is set to something meaningful
	if npc_id != "":
		var block := ColorRect.new()
		var hue = fposmod(npc_id.hash() / 1000000.0, 1.0)
		block.color = Color.from_hsv(hue, 0.3, 0.5, 0.8)
		block.size = Vector2(8, 10)
		block.position = Vector2(-4, -10)
		add_child(block)


func _physics_process(delta: float) -> void:
	match current_state:
		NPCState.IDLE:
			_idle_behavior(delta)
		NPCState.WALKING:
			_walk_behavior(delta)
		NPCState.AT_ACTIVITY:
			pass  # Standing at schedule location
		NPCState.REACTING:
			pass  # Temporary reaction to event
		NPCState.FLEEING:
			_flee_behavior(delta)
		NPCState.SURRENDERED:
			pass
		NPCState.DEAD:
			return


## Get the current mood based on disposition and world state.
func get_mood() -> String:
	var disposition: int = GameState.get_state("npc.%s.disposition" % npc_id, 0)
	if disposition > 50:
		return "happy"
	elif disposition < -50:
		return "angry"
	elif disposition < -20:
		return "sad"
	# Check world state for fear
	var region_status: String = GameState.get_state("world.region.ashvale.status", "normal")
	if region_status in ["war", "plague"]:
		return "fearful"
	return "neutral"


## Get the best dialogue ID for current context.
## Uses dialogue_stage tracking to avoid repeating the same intro.
func get_dialogue_id() -> String:
	# Get dialogue pools from JSON data or NPCData resource
	var pools: Dictionary = {}
	var default: String = ""

	if not _json_data.is_empty():
		pools = _json_data.get("dialogue_pools", {})
		default = _json_data.get("default_greeting", "")
	elif npc_data != null:
		pools = npc_data.dialogue_pools
		default = npc_data.default_greeting

	if pools.is_empty() and default == "":
		# Last resort — try convention: "{npc_id}_intro"
		var fallback: String = "%s_intro" % npc_id
		if NarrativeEngine.get_dialogue(fallback).size() > 0:
			return fallback
		return ""

	var disposition: int = GameState.get_state("npc.%s.disposition" % npc_id, 0)

	# Check for context-specific dialogue pools (memory-triggered)
	for pool_key in pools:
		var condition_key: String = "npc.%s.memory.%s" % [npc_id, pool_key]
		if GameState.get_state(condition_key, false):
			return pools[pool_key]

	# Check disposition-based pools
	if disposition < -50 and pools.has("hostile"):
		return pools["hostile"]
	elif disposition > 50 and pools.has("friendly"):
		return pools["friendly"]

	# --- Dialogue stage tracking ---
	var stage: String = GameState.get_state("npc.%s.dialogue_stage" % npc_id, "intro")

	match stage:
		"follow_up":
			# Try follow_up dialogue; fall back to greeting if it doesn't exist
			var follow_up_id: String = "%s_follow_up" % npc_id
			if NarrativeEngine.get_dialogue(follow_up_id).size() > 0:
				return follow_up_id
			# Also check pools for a follow_up key
			if pools.has("follow_up"):
				return pools["follow_up"]
		"quest_active":
			var quest_id: String = "%s_quest_active" % npc_id
			if NarrativeEngine.get_dialogue(quest_id).size() > 0:
				return quest_id
			if pools.has("quest_active"):
				return pools["quest_active"]
			# Fall through to follow_up if quest dialogue doesn't exist
			var follow_up_id: String = "%s_follow_up" % npc_id
			if NarrativeEngine.get_dialogue(follow_up_id).size() > 0:
				return follow_up_id
		"quest_complete":
			var complete_id: String = "%s_quest_complete" % npc_id
			if NarrativeEngine.get_dialogue(complete_id).size() > 0:
				return complete_id
			if pools.has("quest_complete"):
				return pools["quest_complete"]

	# Default: intro / greeting
	if pools.has("greeting"):
		return pools["greeting"]

	return default


## Take damage (combat integration).
func take_damage(amount: float, attacker: String = "player") -> void:
	var health: float = GameState.get_state("npc.%s.health" % npc_id, npc_data.max_health if npc_data else 50.0)
	health -= amount
	GameState.set_state("npc.%s.health" % npc_id, maxf(health, 0.0))

	if health <= 0.0:
		_die(attacker)
	elif npc_data and npc_data.can_surrender and health < (npc_data.max_health * 0.2):
		_surrender()
	else:
		# NPC remembers being attacked
		GameState.set_state("npc.%s.memory.attacked_by_%s" % [npc_id, attacker], true)
		GameState.delta_state("npc.%s.disposition" % npc_id, -30.0)


## Make this NPC move to a world position.
func move_to(target: Vector2) -> void:
	_target_position = target
	_has_target = true
	current_state = NPCState.WALKING


func _idle_behavior(delta: float) -> void:
	# Bark system: when player is nearby but not interacting
	_update_bark(delta)


func _update_bark(delta: float) -> void:
	if not _player_in_range:
		return
	if NarrativeEngine.is_in_dialogue():
		return
	if _get_barks().is_empty():
		return

	# If bark is visible, count down display timer
	if _bark_visible_timer > 0.0:
		_bark_visible_timer -= delta
		if _bark_visible_timer <= 0.0:
			_hide_bark()
		return

	# Count up to bark delay
	_bark_timer += delta
	if _bark_timer >= BARK_DELAY:
		_bark_timer = 0.0
		_show_bark()


func _walk_behavior(_delta: float) -> void:
	if not _has_target:
		current_state = NPCState.IDLE
		return

	var direction: Vector2 = (_target_position - global_position).normalized()
	var distance: float = global_position.distance_to(_target_position)

	if distance < 4.0:
		# Arrived
		velocity = Vector2.ZERO
		_has_target = false
		current_state = NPCState.AT_ACTIVITY
		return

	_facing_direction = direction
	velocity = direction * WALK_SPEED
	move_and_slide()
	_update_facing_frame()


func _flee_behavior(_delta: float) -> void:
	# Flee away from player
	var player: Node2D = get_tree().get_first_node_in_group("player")
	if player == null:
		current_state = NPCState.IDLE
		return

	var flee_dir: Vector2 = (global_position - player.global_position).normalized()
	_facing_direction = flee_dir
	velocity = flee_dir * WALK_SPEED * 1.5
	move_and_slide()
	_update_facing_frame()


## Update sprite frame based on facing direction.
## frame 0 = down, 1 = left, 2 = right, 3 = up
func _update_facing_frame() -> void:
	if _npc_sprite == null:
		return

	var frame: int = 0
	if absf(_facing_direction.x) > absf(_facing_direction.y):
		# Horizontal dominant
		frame = 1 if _facing_direction.x < 0 else 2
	else:
		# Vertical dominant
		frame = 3 if _facing_direction.y < 0 else 0

	_npc_sprite.frame = frame
	# Update outline sprites to match
	for outline in _npc_outline_sprites:
		if is_instance_valid(outline):
			outline.frame = frame


func _surrender() -> void:
	current_state = NPCState.SURRENDERED
	velocity = Vector2.ZERO
	GameState.set_state("npc.%s.surrendered" % npc_id, true)
	EventBus.enemy_surrendered.emit(npc_id)


func _die(killer: String) -> void:
	current_state = NPCState.DEAD
	velocity = Vector2.ZERO
	GameState.set_state("npc.%s.alive" % npc_id, false)
	GameState.set_state("npc.%s.killed_by" % npc_id, killer)
	EventBus.npc_died.emit(npc_id, killer)

	# Affect nearby NPC dispositions
	if killer == "player":
		_notify_witnesses()

	# Visual: play death anim and disable collision
	if animated_sprite:
		animated_sprite.modulate = Color(0.5, 0.5, 0.5, 0.7)
	collision_layer = 0
	collision_mask = 0


func _notify_witnesses() -> void:
	# Find nearby NPCs who witnessed the kill
	for npc in get_tree().get_nodes_in_group("npcs"):
		if npc == self:
			continue
		if global_position.distance_to(npc.global_position) < 120.0:
			var witness_id: String = npc.npc_id
			GameState.set_state("npc.%s.memory.witnessed_kill_%s" % [witness_id, npc_id], true)
			GameState.delta_state("npc.%s.disposition" % witness_id, -40.0)


func _on_hour_tick(current_hour: int, _current_day: int) -> void:
	if current_state == NPCState.DEAD:
		return
	if npc_data == null:
		return

	# Follow schedule
	var entry: Dictionary = npc_data.get_schedule_for_hour(current_hour)
	if entry != _current_schedule_entry and entry.has("location"):
		_current_schedule_entry = entry
		EventBus.npc_schedule_arrived.emit(npc_id, entry.location)
		# In a full implementation, resolve location_id to world position
		# For now, mark schedule activity in state
		GameState.set_state("npc.%s.activity" % npc_id, entry.get("activity", "idle"))


func _on_player_interacted(target: Node) -> void:
	if target != self and target != dialogue_zone:
		return
	if current_state == NPCState.DEAD:
		return

	# Mark that player met this NPC
	GameState.set_state("npc.%s.met" % npc_id, true)

	# Hide any active bark
	_hide_bark()

	var dialogue_id: String = get_dialogue_id()
	if dialogue_id == "":
		print("NPC %s: No dialogue available" % npc_id)
		# Release the player — no dialogue to show
		var player: Node = get_tree().get_first_node_in_group("player")
		if player and player.has_method("end_interaction"):
			player.end_interaction()
		return

	print("NPC %s: Starting dialogue '%s'" % [npc_id, dialogue_id])
	_awaiting_dialogue_end = true
	EventBus.npc_started_dialogue.emit(npc_id)
	NarrativeEngine.start_dialogue(dialogue_id)


func _on_state_changed(key: String, _old: Variant, _new: Variant) -> void:
	# React to relevant state changes
	if key == "npc.%s.disposition" % npc_id:
		EventBus.npc_mood_changed.emit(npc_id, get_mood())


## Called when any dialogue ends. Advance dialogue stage if this NPC was talking.
func _on_dialogue_ended_tracking(_dialogue_id: String) -> void:
	if not _awaiting_dialogue_end:
		return
	_awaiting_dialogue_end = false

	var current_stage: String = GameState.get_state("npc.%s.dialogue_stage" % npc_id, "intro")

	# Advance stage progression: intro -> follow_up -> quest_active (set externally) -> quest_complete
	match current_stage:
		"intro":
			GameState.set_state("npc.%s.dialogue_stage" % npc_id, "follow_up")
			print("NPC %s: Dialogue stage advanced to 'follow_up'" % npc_id)
		# follow_up stays as follow_up until a quest system advances it
		# quest_active -> quest_complete is handled by quest completion logic

	EventBus.npc_ended_dialogue.emit(npc_id)


# ==================== Bark System ====================

func _setup_bark_label() -> void:
	_bark_label = Label.new()
	_bark_label.name = "BarkLabel"
	_bark_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_bark_label.position = Vector2(-60, -32)
	_bark_label.custom_minimum_size = Vector2(120, 0)
	_bark_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_bark_label.add_theme_font_size_override("font_size", 9)
	_bark_label.add_theme_color_override("font_color", Color(0.91, 0.88, 0.82, 1.0))
	_bark_label.visible = false

	# Add a background panel behind the label
	var bg := PanelContainer.new()
	bg.name = "BarkBG"
	bg.position = Vector2(-62, -34)
	bg.custom_minimum_size = Vector2(124, 0)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.04, 0.03, 0.8)
	style.border_color = Color(0.855, 0.69, 0.28, 0.5)
	style.border_width_bottom = 1
	style.border_width_top = 1
	style.border_width_left = 1
	style.border_width_right = 1
	style.corner_radius_top_left = 3
	style.corner_radius_top_right = 3
	style.corner_radius_bottom_left = 3
	style.corner_radius_bottom_right = 3
	style.content_margin_left = 6
	style.content_margin_right = 6
	style.content_margin_top = 3
	style.content_margin_bottom = 3
	bg.add_theme_stylebox_override("panel", style)
	bg.visible = false
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE

	add_child(bg)
	add_child(_bark_label)


func _get_barks() -> Array:
	var barks: Array = _json_data.get("barks", []).duplicate()

	# Prepend a relationship-colored bark based on RelationshipManager dimensions.
	# This implements Technique 3: Relationship-Gated Dialogue Variants (RDR2 Honor + BG3 Approval).
	var rel_bark: String = _get_relationship_bark()
	if rel_bark != "":
		barks.insert(0, rel_bark)

	return barks


## Generate a context-sensitive bark based on the NPC's relationship dimensions toward the player.
## Checks trust, fear, respect, affection, and debt in priority order.
func _get_relationship_bark() -> String:
	if npc_id == "":
		return ""

	var rel: Dictionary = RelationshipManager.get_relationship(npc_id, "player")

	# Check JSON-defined relationship barks first (allows per-NPC overrides)
	var rel_bark_data: Dictionary = _json_data.get("relationship_barks", {})

	# Priority order: hostility > fear > warm trust > respect > debt
	# Affection < -0.5: hostile
	if rel.affection < -0.5:
		if rel_bark_data.has("hostile"):
			return rel_bark_data["hostile"][randi() % rel_bark_data["hostile"].size()]
		var hostile_barks: Array = [
			"Haven't you done enough?",
			"Walk away.",
			"I have nothing to say to you.",
			"You're not welcome here.",
		]
		return hostile_barks[randi() % hostile_barks.size()]

	# Fear > 0.5: nervous
	if rel.fear > 0.5:
		if rel_bark_data.has("fearful"):
			return rel_bark_data["fearful"][randi() % rel_bark_data["fearful"].size()]
		var fearful_barks: Array = [
			"O-oh, it's you again.",
			"Please don't be angry...",
			"I-I'll do whatever you say.",
			"Don't hurt me. Please.",
		]
		return fearful_barks[randi() % fearful_barks.size()]

	# Trust > 0.7: warm familiar
	if rel.trust > 0.7:
		if rel_bark_data.has("trusting"):
			return rel_bark_data["trusting"][randi() % rel_bark_data["trusting"].size()]
		var trusting_barks: Array = [
			"Glad you're here.",
			"I've been thinking about what you said.",
			"Good to see a friendly face.",
			"I knew you'd come back.",
		]
		return trusting_barks[randi() % trusting_barks.size()]

	# Respect > 0.7: deferential
	if rel.respect > 0.7:
		if rel_bark_data.has("respectful"):
			return rel_bark_data["respectful"][randi() % rel_bark_data["respectful"].size()]
		var respectful_barks: Array = [
			"What do you need?",
			"I trust your judgment.",
			"Say the word.",
			"You've earned that much, at least.",
		]
		return respectful_barks[randi() % respectful_barks.size()]

	# Debt > 0.5: obligation
	if rel.debt > 0.5:
		if rel_bark_data.has("indebted"):
			return rel_bark_data["indebted"][randi() % rel_bark_data["indebted"].size()]
		var indebted_barks: Array = [
			"I haven't forgotten what you did for me.",
			"I owe you. I know that.",
			"If there's anything I can do...",
			"You helped me when no one else would.",
		]
		return indebted_barks[randi() % indebted_barks.size()]

	# No strong relationship dimension — return empty (use normal barks only)
	return ""


func _show_bark() -> void:
	var barks: Array = _get_barks()
	if barks.is_empty():
		return

	# Pick a bark that isn't the same as last time
	var index: int = randi() % barks.size()
	if barks.size() > 1:
		while index == _last_bark_index:
			index = randi() % barks.size()
	_last_bark_index = index

	var bark_text: String = barks[index]

	if _bark_label:
		_bark_label.text = bark_text
		_bark_label.visible = true
		_bark_label.modulate.a = 0.0

		# Show background too
		var bg: PanelContainer = get_node_or_null("BarkBG")
		if bg:
			bg.visible = true
			bg.modulate.a = 0.0
			var bg_tween := create_tween()
			bg_tween.tween_property(bg, "modulate:a", 1.0, BARK_FADE_TIME)

		# Fade in
		var tween := create_tween()
		tween.tween_property(_bark_label, "modulate:a", 1.0, BARK_FADE_TIME)

	_bark_visible_timer = BARK_DISPLAY_TIME


func _hide_bark() -> void:
	if _bark_label and _bark_label.visible:
		var tween := create_tween()
		tween.tween_property(_bark_label, "modulate:a", 0.0, BARK_FADE_TIME)
		tween.tween_callback(func(): _bark_label.visible = false)

		var bg: PanelContainer = get_node_or_null("BarkBG")
		if bg:
			var bg_tween := create_tween()
			bg_tween.tween_property(bg, "modulate:a", 0.0, BARK_FADE_TIME)
			bg_tween.tween_callback(func(): bg.visible = false)

	_bark_visible_timer = 0.0
	_bark_timer = 0.0


func _on_dialogue_zone_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_in_range = true
		_bark_timer = 0.0


func _on_dialogue_zone_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_in_range = false
		_hide_bark()
