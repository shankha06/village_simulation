## EndingScreen — final screen shown after Act 4 concludes.
## Reads GameState flags to determine ending, shows ending dialogue,
## NPC epilogue slides, play statistics, and post-game options.
extends CanvasLayer

# --- Child nodes ---
@onready var background: ColorRect = $Background
@onready var content_panel: PanelContainer = $ContentPanel
@onready var title_label: Label = $ContentPanel/VBox/TitleLabel
@onready var body_text: RichTextLabel = $ContentPanel/VBox/BodyText
@onready var portrait_rect: TextureRect = $ContentPanel/VBox/Portrait
@onready var continue_button: Button = $ContentPanel/VBox/ContinueButton
@onready var stats_panel: VBoxContainer = $ContentPanel/VBox/StatsPanel
@onready var button_container: HBoxContainer = $ContentPanel/VBox/ButtonContainer
@onready var main_menu_button: Button = $ContentPanel/VBox/ButtonContainer/MainMenuButton
@onready var new_game_plus_button: Button = $ContentPanel/VBox/ButtonContainer/NewGamePlusButton

# --- Ending data ---
var _ending_id: String = ""
var _ending_dialogue_id: String = ""
var _epilogue_data: Dictionary = {}
var _slide_order: Array = []
var _current_slide_index: int = -1
var _phase: int = 0  # 0 = ending dialogue, 1 = epilogue slides, 2 = stats, 3 = the end

# --- Consequence evaluation data ---
var _endings_data: Dictionary = {}

# Style
const COLOR_TITLE: Color = Color(0.9, 0.75, 0.4, 1.0)
const COLOR_BODY: Color = Color(0.8, 0.78, 0.7, 1.0)
const COLOR_STAT_LABEL: Color = Color(0.6, 0.58, 0.52, 1.0)
const COLOR_STAT_VALUE: Color = Color(0.9, 0.85, 0.65, 1.0)
const COLOR_ENDING_TITLE: Color = Color(1.0, 0.9, 0.6, 1.0)
const FADE_DURATION: float = 1.5
const SLIDE_FADE_DURATION: float = 0.8


func _ready() -> void:
	visible = false
	if background:
		background.color = Color(0.0, 0.0, 0.0, 0.0)

	if continue_button:
		continue_button.pressed.connect(_on_continue_pressed)
	if main_menu_button:
		main_menu_button.pressed.connect(_on_main_menu_pressed)
	if new_game_plus_button:
		new_game_plus_button.pressed.connect(_on_new_game_plus_pressed)

	_hide_all_sections()

	# Listen for the ending trigger
	EventBus.quest_state_changed.connect(_on_quest_state_changed)


## Evaluate all flags and determine which ending to fire.
func evaluate_ending() -> String:
	_endings_data = _load_endings_data()
	if _endings_data.is_empty():
		push_warning("EndingScreen: Could not load act4_endings.json")
		return "ending_exodus"

	var evaluations: Array = _endings_data.get("ending_evaluation", [])

	# Sort by priority descending
	evaluations.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return a.get("priority", 0) > b.get("priority", 0)
	)

	for entry in evaluations:
		if _check_ending_conditions(entry.get("conditions", [])):
			return entry.get("ending_id", "ending_exodus")

	return "ending_exodus"


## Start the ending sequence.
func start_ending(ending_id: String = "") -> void:
	if ending_id == "":
		ending_id = evaluate_ending()

	_ending_id = ending_id
	_ending_dialogue_id = _get_dialogue_for_ending(ending_id)

	# Load epilogue data
	_epilogue_data = _load_epilogue_data()
	_slide_order = _epilogue_data.get("slide_order", [])

	# Apply ending effects
	_apply_ending_effects(ending_id)

	# Show and fade in
	visible = true
	_phase = 0
	_current_slide_index = -1

	if background:
		background.color = Color(0.0, 0.0, 0.0, 0.0)
		var tween := create_tween()
		tween.tween_property(background, "color:a", 0.85, FADE_DURATION)
		tween.finished.connect(_begin_ending_dialogue)
	else:
		_begin_ending_dialogue()


## Begin the ending dialogue through the normal dialogue system.
func _begin_ending_dialogue() -> void:
	_phase = 0
	# Start the ending dialogue via the narrative engine
	if _ending_dialogue_id != "":
		EventBus.dialogue_started.emit(_ending_dialogue_id)
		# Wait for dialogue to end, then proceed to epilogue
		EventBus.dialogue_ended.connect(_on_ending_dialogue_finished, CONNECT_ONE_SHOT)
	else:
		_begin_epilogue_slides()


func _on_ending_dialogue_finished(_dialogue_id: String) -> void:
	# Small pause before epilogue slides
	var timer := get_tree().create_timer(1.0)
	timer.timeout.connect(_begin_epilogue_slides)


## Begin the NPC epilogue slide sequence.
func _begin_epilogue_slides() -> void:
	_phase = 1
	_current_slide_index = -1
	_show_next_slide()


func _show_next_slide() -> void:
	_current_slide_index += 1

	if _current_slide_index >= _slide_order.size():
		# Show final slide, then stats
		_show_final_slide()
		return

	var npc_key: String = _slide_order[_current_slide_index]
	var npc_slides: Dictionary = _epilogue_data.get("slides", {}).get(npc_key, {})

	if npc_slides.is_empty():
		_show_next_slide()
		return

	var display_name: String = npc_slides.get("display_name", npc_key.capitalize())
	var variants: Array = npc_slides.get("variants", [])
	var chosen_variant: Dictionary = _select_variant(variants)

	if chosen_variant.is_empty():
		_show_next_slide()
		return

	# Fade out current content, then fade in new
	_fade_content(display_name, chosen_variant.get("text", ""), chosen_variant.get("portrait", "neutral"))


func _select_variant(variants: Array) -> Dictionary:
	for variant in variants:
		var conditions: Array = variant.get("conditions", [])
		if _check_conditions(conditions):
			return variant
	return {}


func _fade_content(slide_title: String, slide_text: String, portrait_mood: String) -> void:
	if content_panel:
		content_panel.visible = true

	# Fade out
	if content_panel and content_panel.modulate.a > 0.0:
		var fade_out := create_tween()
		fade_out.tween_property(content_panel, "modulate:a", 0.0, SLIDE_FADE_DURATION * 0.5)
		fade_out.finished.connect(_populate_and_fade_in.bind(slide_title, slide_text, portrait_mood))
	else:
		_populate_and_fade_in(slide_title, slide_text, portrait_mood)


func _populate_and_fade_in(slide_title: String, slide_text: String, portrait_mood: String) -> void:
	# Populate content
	if title_label:
		title_label.text = slide_title
		title_label.add_theme_color_override("font_color", COLOR_TITLE)

	if body_text:
		body_text.text = slide_text

	if portrait_rect:
		portrait_rect.visible = false
		if portrait_mood != "none" and portrait_mood != "memorial":
			var npc_key: String = ""
			if _current_slide_index >= 0 and _current_slide_index < _slide_order.size():
				npc_key = _slide_order[_current_slide_index]
			var portrait_path: String = "res://assets/sprites/portraits/%s_%s.png" % [npc_key, portrait_mood]
			if ResourceLoader.exists(portrait_path):
				portrait_rect.texture = load(portrait_path)
				portrait_rect.visible = true

	if continue_button:
		continue_button.visible = true
		continue_button.text = "Continue"

	_hide_stats()
	_hide_buttons()

	# Fade in
	if content_panel:
		content_panel.modulate.a = 0.0
		var fade_in := create_tween()
		fade_in.tween_property(content_panel, "modulate:a", 1.0, SLIDE_FADE_DURATION)


func _show_final_slide() -> void:
	var final_slide: Dictionary = _epilogue_data.get("final_slide", {})
	var final_text: String = final_slide.get("text", "And so the story ends.")

	# Apply triggers
	var triggers: Array = final_slide.get("triggers", [])
	for trigger in triggers:
		var key: String = trigger.get("set_state", "")
		var value: Variant = trigger.get("value", null)
		if key != "" and value != null:
			GameState.set_state(key, value)

	_fade_content("The End", final_text, "none")

	# After this slide, continue_button will go to stats
	_phase = 2


func _show_stats_screen() -> void:
	_phase = 3

	if content_panel:
		content_panel.modulate.a = 0.0

	if title_label:
		title_label.text = _get_ending_display_name(_ending_id)
		title_label.add_theme_color_override("font_color", COLOR_ENDING_TITLE)

	if body_text:
		body_text.text = ""

	if portrait_rect:
		portrait_rect.visible = false

	if continue_button:
		continue_button.visible = false

	# Show stats
	if stats_panel:
		stats_panel.visible = true
		_clear_children(stats_panel)
		_populate_stats(stats_panel)

	# Show end buttons
	if button_container:
		button_container.visible = true
	if main_menu_button:
		main_menu_button.visible = true
		main_menu_button.text = "Main Menu"
	if new_game_plus_button:
		new_game_plus_button.visible = true
		new_game_plus_button.text = "New Game+"

	# Fade in
	if content_panel:
		var fade_in := create_tween()
		fade_in.tween_property(content_panel, "modulate:a", 1.0, FADE_DURATION)


func _populate_stats(parent: VBoxContainer) -> void:
	_add_stat_row(parent, "Ending", _get_ending_display_name(_ending_id))
	_add_stat_row(parent, "Days Survived", str(GameState.get_state("world.day", 1)))

	# NPCs met
	var npcs_met: int = _count_npcs_met()
	_add_stat_row(parent, "NPCs Met", str(npcs_met))

	# NPCs alive at end
	var npcs_alive: int = _count_npcs_alive()
	_add_stat_row(parent, "NPCs Alive at End", str(npcs_alive))

	# Quests completed
	var quests_completed: int = QuestManager.get_completed_quests().size()
	var quests_total: int = quests_completed + QuestManager.get_active_quests().size()
	_add_stat_row(parent, "Quests Completed", "%d / %d" % [quests_completed, quests_total])

	# Factions allied
	var factions_allied: int = _count_factions_allied()
	_add_stat_row(parent, "Factions Allied", str(factions_allied))

	# Moral vector summary
	var mercy: int = GameState.get_state("player.moral_vector.mercy", 50) as int
	var justice: int = GameState.get_state("player.moral_vector.justice", 50) as int
	var honesty: int = GameState.get_state("player.moral_vector.honesty", 50) as int
	var pragmatism: int = GameState.get_state("player.moral_vector.pragmatism", 50) as int
	_add_stat_row(parent, "Mercy / Justice", "%d / %d" % [mercy, justice])
	_add_stat_row(parent, "Honesty / Pragmatism", "%d / %d" % [honesty, pragmatism])

	# Key choices
	_add_spacer(parent, 12)
	_add_section_label(parent, "-- Key Choices --")

	if GameState.get_state("flag.silo_destroyed", false):
		_add_stat_row(parent, "Grain Silo", "Destroyed")
	else:
		_add_stat_row(parent, "Grain Silo", "Intact")

	if GameState.get_state("flag.ashworth_confession_heard", false):
		_add_stat_row(parent, "Ashworth's Secret", "Revealed")
	else:
		_add_stat_row(parent, "Ashworth's Secret", "Hidden")

	var ultimatum: String = GameState.get_state("flag.ironmarch_ultimatum_result", "unknown")
	_add_stat_row(parent, "Ironmarch Ultimatum", ultimatum.capitalize())

	if GameState.get_state("flag.factions_united", false):
		_add_stat_row(parent, "Factions", "United")
	else:
		_add_stat_row(parent, "Factions", "Divided")


func _add_stat_row(parent: VBoxContainer, label_text: String, value_text: String) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	parent.add_child(row)

	var label := Label.new()
	label.text = label_text
	label.add_theme_font_size_override("font_size", 11)
	label.add_theme_color_override("font_color", COLOR_STAT_LABEL)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)

	var value := Label.new()
	value.text = value_text
	value.add_theme_font_size_override("font_size", 11)
	value.add_theme_color_override("font_color", COLOR_STAT_VALUE)
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(value)


func _add_section_label(parent: VBoxContainer, text: String) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 11)
	label.add_theme_color_override("font_color", COLOR_TITLE)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	parent.add_child(label)
	_add_spacer(parent, 4)


func _add_spacer(parent: VBoxContainer, height: float) -> void:
	var spacer := Control.new()
	spacer.custom_minimum_size.y = height
	parent.add_child(spacer)


# ---------------------------------------------------------------------------
# Input / Button handlers
# ---------------------------------------------------------------------------

func _on_continue_pressed() -> void:
	match _phase:
		1:
			_show_next_slide()
		2:
			_show_stats_screen()
		3:
			pass  # Handled by end buttons


func _on_main_menu_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


func _on_new_game_plus_pressed() -> void:
	# Store ending data for NG+ unlocks
	GameState.set_state("ng_plus.previous_ending", _ending_id)
	GameState.set_state("ng_plus.enabled", true)

	# Preserve select flags for NG+
	var ng_plus_flags: Dictionary = {
		"ng_plus.ending_martyr_seen": GameState.get_state("flag.ending_resolved", "") == "ending_martyr",
		"ng_plus.ending_harmony_seen": GameState.get_state("flag.ending_resolved", "") == "ending_harmony",
		"ng_plus.ending_scorched_earth_seen": GameState.get_state("flag.ending_resolved", "") == "ending_scorched_earth",
		"ng_plus.ending_betrayed_seen": GameState.get_state("flag.ending_resolved", "") == "ending_betrayed",
		"ng_plus.endings_seen_count": (GameState.get_state("ng_plus.endings_seen_count", 0) as int) + 1,
	}

	# Save NG+ data before scene change
	for key in ng_plus_flags:
		GameState.set_state(key, ng_plus_flags[key])

	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


func _on_quest_state_changed(quest_id: String, _old_state: String, new_state: String) -> void:
	if quest_id != "the_reckoning":
		return
	# Trigger ending screen when any ENDING_ state is reached
	if new_state.begins_with("ENDING_"):
		# Small delay so quest state settles
		var timer := get_tree().create_timer(0.5)
		timer.timeout.connect(func() -> void: start_ending())


# ---------------------------------------------------------------------------
# Data loading
# ---------------------------------------------------------------------------

func _load_endings_data() -> Dictionary:
	var path := "res://data/narrative/consequences/act4_endings.json"
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var json := JSON.new()
	var err := json.parse(file.get_as_text())
	file.close()
	if err != OK:
		push_warning("EndingScreen: Failed to parse act4_endings.json")
		return {}
	return json.data if json.data is Dictionary else {}


func _load_epilogue_data() -> Dictionary:
	var path := "res://data/dialogues/epilogue_slides.json"
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var json := JSON.new()
	var err := json.parse(file.get_as_text())
	file.close()
	if err != OK:
		push_warning("EndingScreen: Failed to parse epilogue_slides.json")
		return {}
	return json.data if json.data is Dictionary else {}


func _get_dialogue_for_ending(ending_id: String) -> String:
	if _endings_data.is_empty():
		return ending_id
	var evaluations: Array = _endings_data.get("ending_evaluation", [])
	for entry in evaluations:
		if entry.get("ending_id", "") == ending_id:
			return entry.get("dialogue", ending_id)
	return ending_id


func _apply_ending_effects(ending_id: String) -> void:
	if _endings_data.is_empty():
		return

	# Apply ending-specific effects
	var evaluations: Array = _endings_data.get("ending_evaluation", [])
	for entry in evaluations:
		if entry.get("ending_id", "") == ending_id:
			var effects: Array = entry.get("effects", [])
			_execute_effects(effects)
			break

	# Apply modifiers
	var modifiers: Array = _endings_data.get("ending_modifiers", [])
	for mod in modifiers:
		var applies_to: Array = mod.get("applies_to", [])
		if ending_id not in applies_to:
			continue
		# Check modifier condition (simple string for now)
		var condition_str: String = mod.get("condition", "")
		if _evaluate_condition_string(condition_str):
			var effects: Array = mod.get("effects", [])
			_execute_effects(effects)


func _execute_effects(effects: Array) -> void:
	for effect in effects:
		if not effect is Dictionary:
			continue
		var key: String = effect.get("set_state", "")
		if key == "":
			continue
		if effect.has("delta"):
			GameState.delta_state(key, effect.get("delta", 0.0))
		elif effect.has("value"):
			GameState.set_state(key, effect.get("value"))


# ---------------------------------------------------------------------------
# Condition checking
# ---------------------------------------------------------------------------

func _check_ending_conditions(conditions: Array) -> bool:
	if conditions.is_empty():
		return true
	return _check_conditions(conditions)


func _check_conditions(conditions: Array) -> bool:
	for cond in conditions:
		if not cond is Dictionary:
			continue
		var key: String = cond.get("check", "")
		var op: String = cond.get("op", "==")
		var expected: Variant = cond.get("value")
		var actual: Variant = GameState.get_state(key)

		if not _compare(actual, op, expected):
			return false
	return true


func _compare(actual: Variant, op: String, expected: Variant) -> bool:
	match op:
		"==":
			return actual == expected
		"!=":
			return actual != expected
		">=":
			if actual == null:
				return false
			return float(actual) >= float(expected)
		"<=":
			if actual == null:
				return false
			return float(actual) <= float(expected)
		">":
			if actual == null:
				return false
			return float(actual) > float(expected)
		"<":
			if actual == null:
				return false
			return float(actual) < float(expected)
		_:
			return actual == expected


func _evaluate_condition_string(condition_str: String) -> bool:
	if condition_str == "":
		return true

	# Handle AND conditions
	var parts: PackedStringArray = condition_str.split(" AND ")
	for part in parts:
		part = part.strip_edges()
		if not _evaluate_single_condition(part):
			return false
	return true


func _evaluate_single_condition(cond: String) -> bool:
	# Parse patterns like "flag.key == value" or "flag.key >= 60"
	var operators: Array[String] = [">=", "<=", "!=", "==", ">", "<"]
	for op in operators:
		var idx: int = cond.find(op)
		if idx == -1:
			continue
		var key: String = cond.substr(0, idx).strip_edges()
		var value_str: String = cond.substr(idx + op.length()).strip_edges()
		var actual: Variant = GameState.get_state(key)

		# Parse value
		var expected: Variant
		if value_str == "true":
			expected = true
		elif value_str == "false":
			expected = false
		elif value_str.is_valid_int():
			expected = value_str.to_int()
		elif value_str.is_valid_float():
			expected = value_str.to_float()
		else:
			# Strip quotes if present
			expected = value_str.trim_prefix("'").trim_suffix("'").trim_prefix("\"").trim_suffix("\"")

		return _compare(actual, op, expected)

	return false


# ---------------------------------------------------------------------------
# Stats helpers
# ---------------------------------------------------------------------------

func _count_npcs_met() -> int:
	var count: int = 0
	var npc_ids: Array[String] = ["elara", "fenrick", "commander_voss", "lord_ashworth", "maren", "old_maren", "greta"]
	for npc_id in npc_ids:
		if GameState.get_state("npc.%s.met" % npc_id, false):
			count += 1
	return count


func _count_npcs_alive() -> int:
	var count: int = 0
	var npc_ids: Array[String] = ["elara", "fenrick", "commander_voss", "lord_ashworth", "maren", "old_maren", "greta"]
	for npc_id in npc_ids:
		# Default to alive (true) if not explicitly set to false
		if GameState.get_state("npc.%s.alive" % npc_id, true):
			count += 1
	return count


func _count_factions_allied() -> int:
	var count: int = 0
	var factions: Array[String] = ["ashvale_nobility", "city_guard", "thieves_guild", "church_ashen_light", "ironmarch_legion"]
	for faction_id in factions:
		var rep: int = GameState.get_state("player.reputation.%s" % faction_id, 0) as int
		if rep >= 30:
			count += 1
	return count


func _get_ending_display_name(ending_id: String) -> String:
	match ending_id:
		"ending_martyr":
			return "The Martyr's Rest"
		"ending_new_order":
			return "A New Order"
		"ending_atonement":
			return "The Atonement"
		"ending_dark_price":
			return "The Dark Price"
		"ending_exodus":
			return "The Exodus"
		"ending_last_stand":
			return "The Last Stand"
		"ending_scorched_earth":
			return "Scorched Earth"
		"ending_harmony":
			return "Harmony"
		"ending_uneasy_peace":
			return "An Uneasy Peace"
		"ending_betrayed":
			return "Betrayed"
		_:
			return ending_id.capitalize().replace("_", " ")


# ---------------------------------------------------------------------------
# UI helpers
# ---------------------------------------------------------------------------

func _hide_all_sections() -> void:
	if content_panel:
		content_panel.visible = false
	_hide_stats()
	_hide_buttons()


func _hide_stats() -> void:
	if stats_panel:
		stats_panel.visible = false


func _hide_buttons() -> void:
	if button_container:
		button_container.visible = false


func _clear_children(node: Node) -> void:
	for child in node.get_children():
		child.queue_free()
