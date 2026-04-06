## Main scene — root of the game. Manages scene transitions, UI layers, and game flow.
extends Node

const _UITheme = preload("res://scenes/ui/ui_theme.gd")

@onready var world_container: Node2D = $WorldContainer
@onready var ui_layer: CanvasLayer = $UILayer
@onready var dialogue_ui: CanvasLayer = $DialogueUI
@onready var fade_rect: ColorRect = $FadeLayer/FadeRect
@onready var hud: Control = $UILayer/HUD
@onready var time_label: Label = $UILayer/HUD/TimeLabel
@onready var health_bar: ProgressBar = $UILayer/HUD/HealthBar
@onready var region_label: Label = $UILayer/HUD/RegionLabel
@onready var quest_label: Label = $UILayer/HUD/QuestLabel
@onready var notification_label: Label = $UILayer/NotificationLabel
@onready var splash_layer: CanvasLayer = $SplashLayer
@onready var splash_rect: TextureRect = $SplashLayer/Background
@onready var help_overlay: PanelContainer = $UILayer/HelpOverlay
@onready var btn_inventory: Button = $UILayer/HUD/ButtonBar/BtnInventory
@onready var btn_journal: Button = $UILayer/HUD/ButtonBar/BtnJournal
@onready var btn_quests: Button = $UILayer/HUD/ButtonBar/BtnQuests
@onready var btn_lore: Button = $UILayer/HUD/ButtonBar/BtnLore
@onready var btn_help: Button = $UILayer/HUD/ButtonBar/BtnHelp
@onready var inventory_ui: CanvasLayer = $InventoryUI

var _current_region: Node2D = null
var _player_instance: CharacterBody2D = null
var _is_transitioning: bool = false
var _intro_instance: CanvasLayer = null

# Notification queue
var _notification_queue: Array[Dictionary] = []
var _notification_timer: float = 0.0
const NOTIFICATION_DURATION: float = 3.0

# Region label fade
var _region_label_timer: float = 0.0
const REGION_LABEL_SHOW_DURATION: float = 3.0
const REGION_LABEL_FADE_DURATION: float = 1.0


func _ready() -> void:
	# Connect signals
	EventBus.scene_transition_requested.connect(_on_scene_transition_requested)
	EventBus.scene_transition_completed.connect(_on_scene_transition_completed)
	EventBus.notification_requested.connect(_on_notification_requested)
	EventBus.player_died.connect(_on_player_died)
	EventBus.quest_state_changed.connect(_on_quest_state_changed)
	EventBus.quest_discovered.connect(_on_quest_discovered)
	EventBus.quest_completed.connect(_on_quest_completed)
	EventBus.quest_failed.connect(_on_quest_failed)

	# Wire HUD buttons
	if btn_inventory:
		btn_inventory.pressed.connect(func(): Input.action_press("inventory"); Input.action_release("inventory"))
	if btn_journal:
		btn_journal.pressed.connect(func(): Input.action_press("journal"); Input.action_release("journal"))
	if btn_quests:
		btn_quests.pressed.connect(func(): Input.action_press("quest_log"); Input.action_release("quest_log"))
	if btn_lore:
		btn_lore.pressed.connect(func(): Input.action_press("codex"); Input.action_release("codex"))
	if btn_help:
		btn_help.pressed.connect(_toggle_help)

	# Apply dark fantasy UI theme
	var game_theme: Theme = _UITheme.create_theme()
	if ui_layer and ui_layer.get_child_count() > 0:
		for child in get_children():
			if child is CanvasLayer:
				for ui_child in child.get_children():
					if ui_child is Control:
						ui_child.theme = game_theme

	# Initial fade
	fade_rect.color = Color(0, 0, 0, 1)
	splash_layer.visible = true
	splash_rect.modulate.a = 1.0

	# Initial quest label update
	_update_quest_label()

	# Start new game or load
	_start_new_game()


func _process(delta: float) -> void:
	# Update HUD health bar
	if health_bar:
		health_bar.value = GameState.get_state("player.health", 100.0)

	# Update HUD time label
	if time_label:
		time_label.text = "Day %d - %02d:%02d" % [TimeManager.day, TimeManager.hour, TimeManager.minute]

	# Region label fade-out
	if _region_label_timer > 0.0:
		_region_label_timer -= delta
		if _region_label_timer <= 0.0:
			# Start fade out
			if region_label:
				var tween := create_tween()
				tween.tween_property(region_label, "modulate:a", 0.0, REGION_LABEL_FADE_DURATION)
				tween.tween_callback(func(): region_label.visible = false)

	# Process notification display
	if _notification_timer > 0:
		_notification_timer -= delta
		if _notification_timer <= 0:
			notification_label.visible = false
			# Show next in queue
			if not _notification_queue.is_empty():
				var next: Dictionary = _notification_queue.pop_front()
				_show_notification(next.text, next.type)


## Load a region scene and place the player.
func load_region(region_scene_path: String, spawn_point: String = "default") -> void:
	if _is_transitioning:
		return
	_is_transitioning = true

	EventBus.scene_transition_started.emit()

	# Fade out
	var tween := create_tween()
	tween.tween_property(fade_rect, "color:a", 1.0, 0.3)
	await tween.finished

	# Remove old region
	if _current_region:
		_current_region.queue_free()
		_current_region = null

	# Remove player from old parent
	if _player_instance and _player_instance.get_parent():
		_player_instance.get_parent().remove_child(_player_instance)

	# Load new region
	var scene: PackedScene = load(region_scene_path)
	if scene == null:
		push_error("Main: Cannot load region: %s" % region_scene_path)
		_is_transitioning = false
		return

	_current_region = scene.instantiate()
	world_container.add_child(_current_region)

	# Add player to region
	if _player_instance:
		_current_region.add_child(_player_instance)

	# Position player at spawn point
	if _current_region.has_method("spawn_player_at"):
		_current_region.spawn_player_at(spawn_point)
	elif spawn_point == "save_position":
		var px: float = GameState.get_state("player.position_x", 0.0)
		var py: float = GameState.get_state("player.position_y", 0.0)
		if _player_instance:
			_player_instance.global_position = Vector2(px, py)

	# Fade in
	var fade_in := create_tween()
	fade_in.tween_property(fade_rect, "color:a", 0.0, 0.5)
	await fade_in.finished

	_is_transitioning = false
	EventBus.scene_transition_completed.emit()


func _start_new_game() -> void:
	SaveManager.new_game()

	# Create player instance
	var player_scene: PackedScene = load("res://scenes/player/player.tscn")
	if player_scene:
		_player_instance = player_scene.instantiate()
		# Attach floating interact prompt to player
		var prompt_script: Script = load("res://scenes/ui/interact_prompt.gd")
		if prompt_script:
			var prompt := Node2D.new()
			prompt.set_script(prompt_script)
			prompt.name = "InteractPrompt"
			_player_instance.add_child(prompt)

	# Load initial data
	_load_game_data()

	# Fade out splash screen first
	var s_tween := create_tween()
	s_tween.tween_property(splash_rect, "modulate:a", 0.0, 1.0)
	await s_tween.finished
	splash_layer.visible = false

	# Play intro sequence if not already seen
	if not GameState.get_state("flag.intro_completed", false):
		await _play_intro_sequence()

	# Load starting region (Ashvale village) — spawn at south gate after intro
	var spawn_point: String = "SouthGateSpawn" if GameState.get_state("flag.intro_completed", false) else "default"
	await load_region("res://scenes/world/ashvale_village.tscn", spawn_point)


func _play_intro_sequence() -> void:
	var intro_scene: PackedScene = load("res://scenes/intro/intro_sequence.tscn")
	if intro_scene == null:
		push_error("Main: Cannot load intro sequence")
		GameState.set_state("flag.intro_completed", true)
		return

	_intro_instance = intro_scene.instantiate()
	add_child(_intro_instance)

	# Start playback and wait for completion
	_intro_instance.play()
	await _intro_instance.intro_completed

	# Mark intro as done
	GameState.set_state("flag.intro_completed", true)

	# Clean up
	_intro_instance.queue_free()
	_intro_instance = null


func _load_game_data() -> void:
	# Load faction data
	var factions_file := FileAccess.open("res://data/factions/factions.json", FileAccess.READ)
	if factions_file:
		var json := JSON.new()
		if json.parse(factions_file.get_as_text()) == OK:
			FactionManager.load_factions(json.data)

	# Load dialogue files
	NarrativeEngine.load_dialogues_from_dir("res://data/dialogues/")

	# Load narrative atoms
	NarrativeEngine.load_narrative_atoms("res://data/narrative/atoms/")

	# Load quest definitions
	var quests_to_load: Array = []
	var quest_dir := DirAccess.open("res://data/quests/")
	if quest_dir:
		quest_dir.list_dir_begin()
		var fname: String = quest_dir.get_next()
		while fname != "":
			if fname.ends_with(".json"):
				var qfile := FileAccess.open("res://data/quests/" + fname, FileAccess.READ)
				if qfile:
					var qjson := JSON.new()
					if qjson.parse(qfile.get_as_text()) == OK:
						quests_to_load.append(qjson.data)
			fname = quest_dir.get_next()
		quest_dir.list_dir_end()
	QuestManager.load_quests(quests_to_load)

	# Load consequence chains
	var chains: Array = []
	var chain_dir := DirAccess.open("res://data/narrative/consequences/")
	if chain_dir:
		chain_dir.list_dir_begin()
		var fname2: String = chain_dir.get_next()
		while fname2 != "":
			if fname2.ends_with(".json"):
				var cfile := FileAccess.open("res://data/narrative/consequences/" + fname2, FileAccess.READ)
				if cfile:
					var cjson := JSON.new()
					if cjson.parse(cfile.get_as_text()) == OK:
						chains.append(cjson.data)
			fname2 = chain_dir.get_next()
		chain_dir.list_dir_end()
	WorldSimulation.load_consequence_chains(chains)


func _show_notification(text: String, type: String = "info") -> void:
	notification_label.text = text
	notification_label.visible = true
	_notification_timer = NOTIFICATION_DURATION

	# Color by type
	match type:
		"item":
			notification_label.modulate = Color(0.2, 0.8, 0.2)
		"gold":
			notification_label.modulate = Color(1.0, 0.85, 0.0)
		"world_event":
			notification_label.modulate = Color(0.9, 0.3, 0.3)
		"quest":
			notification_label.modulate = Color(0.3, 0.6, 0.9)
		_:
			notification_label.modulate = Color.WHITE


func _on_scene_transition_completed() -> void:
	# Show region name on the HUD for a few seconds then fade out
	if region_label and _current_region and _current_region.has_method("get") == false:
		var rname: String = _current_region.get("region_name") if "region_name" in _current_region else ""
		if rname != "":
			region_label.text = rname
			region_label.modulate.a = 1.0
			region_label.visible = true
			_region_label_timer = REGION_LABEL_SHOW_DURATION


func _on_scene_transition_requested(target_scene: String, spawn_point: String) -> void:
	load_region(target_scene, spawn_point)


func _on_notification_requested(text: String, type: String) -> void:
	if _notification_timer > 0:
		_notification_queue.append({"text": text, "type": type})
	else:
		_show_notification(text, type)


func _on_player_died() -> void:
	# Show death screen, option to reload
	_show_notification("You have died...", "world_event")
	# In full implementation: death screen UI, load last save


func _update_quest_label() -> void:
	if not quest_label:
		return
	var active_quests: Array[String] = QuestManager.get_active_quests()
	if active_quests.size() == 0:
		quest_label.visible = false
		return
	# Show first active quest's current objective text
	var qid: String = active_quests[0]
	var state_data: Dictionary = QuestManager.get_quest_state_data(qid)
	var objectives: Array = state_data.get("objectives", [])
	var objective_text: String = ""
	for obj in objectives:
		if obj is Dictionary and not obj.get("completed", false):
			objective_text = obj.get("text", "")
			break
	if objective_text == "":
		# Fallback to journal entry
		objective_text = state_data.get("journal_entry", "")
	if objective_text != "":
		quest_label.text = "~ %s ~" % objective_text
		quest_label.visible = true
	else:
		quest_label.visible = false


func _on_quest_state_changed(_quest_id: String, _old_state: String, _new_state: String) -> void:
	_update_quest_label()


func _on_quest_discovered(_quest_id: String) -> void:
	_update_quest_label()


func _on_quest_completed(_quest_id: String, _ending: String) -> void:
	_update_quest_label()


func _on_quest_failed(_quest_id: String, _reason: String) -> void:
	_update_quest_label()


func _toggle_help() -> void:
	if help_overlay:
		help_overlay.visible = not help_overlay.visible


func _unhandled_input(event: InputEvent) -> void:
	# H key toggles help
	if event is InputEventKey and event.pressed and event.keycode == KEY_H:
		_toggle_help()
		get_viewport().set_input_as_handled()
	# Show help on first game start (after intro)
	if event is InputEventKey and event.pressed and not GameState.get_state("flag.help_shown_once", false):
		GameState.set_state("flag.help_shown_once", true)
		# Show a brief hint
		_show_notification("Press H for controls help. Talk to the guard ahead.", "quest")
