## Journal / Codex UI -- toggled with the "journal" input action (J key).
## Tab-based layout: Quests, Codex, Relationships, Map.
## Reads live data from QuestManager, CodexManager, FactionManager, and GameState.
extends CanvasLayer

# Node references -- bound in _ready via scene tree paths.
@onready var panel: PanelContainer = $Panel
@onready var tab_buttons: HBoxContainer = $Panel/VBox/TabBar
@onready var content_stack: Control = $Panel/VBox/Content

# Tab content panels (children of Content).
@onready var quests_panel: ScrollContainer = $Panel/VBox/Content/QuestsPanel
@onready var codex_panel: ScrollContainer = $Panel/VBox/Content/CodexPanel
@onready var relationships_panel: ScrollContainer = $Panel/VBox/Content/RelationshipsPanel
@onready var map_panel: Control = $Panel/VBox/Content/MapPanel

# Dynamic containers inside scroll panels.
@onready var quest_list: VBoxContainer = $Panel/VBox/Content/QuestsPanel/QuestList
@onready var codex_list: VBoxContainer = $Panel/VBox/Content/CodexPanel/CodexList
@onready var relationship_list: VBoxContainer = $Panel/VBox/Content/RelationshipsPanel/RelationshipList
@onready var map_label: Label = $Panel/VBox/Content/MapPanel/MapLabel

# Close button.
@onready var close_button: Button = $Panel/VBox/TabBar/CloseButton

# Tab button references are gathered dynamically.
var _tab_buttons: Array[Button] = []
var _tab_panels: Array[Control] = []
var _current_tab: int = 0

# Codex manager reference (sibling node or child -- set externally or found).
var _codex_manager: Node = null

# Track which codex entries were recently revealed for pulse effect.
var _recently_revealed: Dictionary = {}  # {entry_id: time_remaining}

var TAB_NAMES: PackedStringArray = PackedStringArray(["Quests", "Codex", "Relationships", "Map"])
var CODEX_CATEGORIES: PackedStringArray = PackedStringArray(["history", "factions", "alchemy", "mystery"])

# Style constants.
const COLOR_ACTIVE_TAB: Color = Color(0.9, 0.75, 0.4, 1.0)
const COLOR_INACTIVE_TAB: Color = Color(0.5, 0.5, 0.5, 1.0)
const COLOR_COMPLETED: Color = Color(0.45, 0.45, 0.45, 1.0)
const COLOR_FAILED: Color = Color(0.6, 0.3, 0.3, 1.0)
const COLOR_ACTIVE_QUEST: Color = Color(0.85, 0.85, 0.8, 1.0)
const COLOR_CATEGORY_HEADER: Color = Color(0.9, 0.75, 0.4, 1.0)
const COLOR_FRAGMENT_FOUND: Color = Color(0.75, 0.75, 0.7, 1.0)
const COLOR_FRAGMENT_HIDDEN: Color = Color(0.4, 0.4, 0.4, 1.0)
const COLOR_LORE_PULSE: Color = Color(1.0, 0.85, 0.3, 1.0)
const COLOR_DISPOSITION_HIGH: Color = Color(0.3, 0.8, 0.35, 1.0)
const COLOR_DISPOSITION_MID: Color = Color(0.8, 0.8, 0.3, 1.0)
const COLOR_DISPOSITION_LOW: Color = Color(0.8, 0.3, 0.3, 1.0)

const PULSE_DURATION: float = 3.0


func _ready() -> void:
	visible = false
	panel.visible = false

	# Find CodexManager -- may be a sibling, child, or autoload.
	_codex_manager = _find_codex_manager()

	# Build tab buttons programmatically (the scene provides placeholder nodes).
	_tab_panels = [quests_panel, codex_panel, relationships_panel, map_panel]
	for i in range(TAB_NAMES.size()):
		var btn: Button = tab_buttons.get_child(i) as Button
		if btn == null:
			continue
		btn.text = TAB_NAMES[i]
		btn.pressed.connect(_on_tab_pressed.bind(i))
		_tab_buttons.append(btn)

	close_button.pressed.connect(_close)

	# Signal connections.
	EventBus.quest_state_changed.connect(_on_quest_updated)
	EventBus.quest_completed.connect(_on_quest_updated_simple)
	EventBus.quest_failed.connect(_on_quest_updated_simple)
	EventBus.quest_discovered.connect(_on_quest_updated_simple)
	EventBus.codex_entry_unlocked.connect(_on_codex_updated)

	if _codex_manager:
		_codex_manager.fragment_discovered.connect(_on_fragment_discovered)

	_select_tab(0)


func _process(delta: float) -> void:
	# Tick pulse timers.
	var expired: Array[String] = []
	for eid in _recently_revealed:
		_recently_revealed[eid] -= delta
		if _recently_revealed[eid] <= 0.0:
			expired.append(eid)
	for eid in expired:
		_recently_revealed.erase(eid)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("journal"):
		_toggle()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("quest_log"):
		_toggle_to_tab(0)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("codex"):
		_toggle_to_tab(1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("map"):
		_toggle_to_tab(3)
		get_viewport().set_input_as_handled()
	elif visible and event.is_action_pressed("cycle_tab"):
		_select_tab((_current_tab + 1) % _tab_panels.size())
		get_viewport().set_input_as_handled()
	elif visible and event.is_action_pressed("pause_menu"):
		_close()
		get_viewport().set_input_as_handled()


# ---------------------------------------------------------------------------
# Toggle / Close
# ---------------------------------------------------------------------------

func _toggle() -> void:
	if visible:
		_close()
	else:
		_open()


func _toggle_to_tab(tab_index: int) -> void:
	if visible and _current_tab == tab_index:
		_close()
	else:
		_open()
		_select_tab(tab_index)


func _open() -> void:
	visible = true
	panel.visible = true
	_refresh_current_tab()
	get_tree().paused = true


func _close() -> void:
	visible = false
	panel.visible = false
	get_tree().paused = false


# ---------------------------------------------------------------------------
# Tab management
# ---------------------------------------------------------------------------

func _select_tab(index: int) -> void:
	_current_tab = clampi(index, 0, _tab_panels.size() - 1)
	for i in range(_tab_panels.size()):
		_tab_panels[i].visible = (i == _current_tab)
		if i < _tab_buttons.size():
			_tab_buttons[i].add_theme_color_override(
				"font_color",
				COLOR_ACTIVE_TAB if i == _current_tab else COLOR_INACTIVE_TAB
			)
	_refresh_current_tab()


func _refresh_current_tab() -> void:
	match _current_tab:
		0:
			_populate_quests()
		1:
			_populate_codex()
		2:
			_populate_relationships()
		3:
			_populate_map()


func _on_tab_pressed(index: int) -> void:
	_select_tab(index)


# ---------------------------------------------------------------------------
# Quests tab
# ---------------------------------------------------------------------------

func _populate_quests() -> void:
	_clear_children(quest_list)

	# Active quests first.
	var active_ids: Array[String] = QuestManager.get_active_quests()
	if active_ids.size() > 0:
		_add_section_header(quest_list, "-- Active Quests --", COLOR_ACTIVE_QUEST)
		for qid in active_ids:
			_add_quest_entry(quest_list, qid, "active")

	# Completed quests.
	var completed_ids: Array[String] = QuestManager.get_completed_quests()
	if completed_ids.size() > 0:
		_add_section_header(quest_list, "-- Completed --", COLOR_COMPLETED)
		for qid in completed_ids:
			_add_quest_entry(quest_list, qid, "completed")

	# Failed quests.
	var failed_ids: Array[String] = _get_failed_quests()
	if failed_ids.size() > 0:
		_add_section_header(quest_list, "-- Failed --", COLOR_FAILED)
		for qid in failed_ids:
			_add_quest_entry(quest_list, qid, "failed")

	if active_ids.size() == 0 and completed_ids.size() == 0 and failed_ids.size() == 0:
		_add_flavor_label(quest_list, "No quests yet. Explore Ashvale to uncover its secrets.", COLOR_COMPLETED)


func _add_quest_entry(parent: VBoxContainer, quest_id: String, status: String) -> void:
	var qdef: Dictionary = QuestManager.get_quest_def(quest_id)
	var state_data: Dictionary = QuestManager.get_quest_state_data(quest_id)
	var quest_name: String = qdef.get("name", quest_id)
	var journal_entry: String = state_data.get("journal_entry", "")
	var objectives: Array = state_data.get("objectives", [])

	# Quest name.
	var name_label := RichTextLabel.new()
	name_label.bbcode_enabled = true
	name_label.fit_content = true
	name_label.scroll_active = false
	name_label.custom_minimum_size.y = 18.0
	name_label.add_theme_font_size_override("normal_font_size", 12)

	match status:
		"completed":
			name_label.text = "[color=#737373]%s[/color]" % quest_name
		"failed":
			name_label.text = "[s][color=#994d4d]%s[/color][/s]" % quest_name
		_:
			name_label.text = "[color=#d9d9cc]%s[/color]" % quest_name

	parent.add_child(name_label)

	# Journal entry text.
	if journal_entry != "":
		var entry_label := Label.new()
		entry_label.text = "  %s" % journal_entry
		entry_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		entry_label.add_theme_font_size_override("font_size", 10)
		entry_label.add_theme_color_override(
			"font_color",
			COLOR_COMPLETED if status != "active" else Color(0.7, 0.7, 0.65, 1.0)
		)
		parent.add_child(entry_label)

	# Objectives.
	for obj in objectives:
		if not obj is Dictionary:
			continue
		var obj_text: String = obj.get("text", "")
		var obj_done: bool = obj.get("completed", false)
		var marker: String = "[x]" if obj_done else "[ ]"
		var obj_label := Label.new()
		obj_label.text = "    %s %s" % [marker, obj_text]
		obj_label.add_theme_font_size_override("font_size", 9)
		obj_label.add_theme_color_override(
			"font_color",
			COLOR_COMPLETED if obj_done else Color(0.65, 0.65, 0.6, 1.0)
		)
		parent.add_child(obj_label)

	# Spacer.
	_add_spacer(parent, 6)


# ---------------------------------------------------------------------------
# Codex tab
# ---------------------------------------------------------------------------

func _populate_codex() -> void:
	_clear_children(codex_list)

	if _codex_manager == null:
		_add_flavor_label(codex_list, "Codex system unavailable.", COLOR_COMPLETED)
		return

	var discovered: Array = _codex_manager.get_all_discovered()
	if discovered.size() == 0:
		_add_flavor_label(codex_list, "No lore entries discovered yet.", COLOR_COMPLETED)
		return

	# Group by category.
	var by_category: Dictionary = {}
	for cat in CODEX_CATEGORIES:
		by_category[cat] = []
	for entry in discovered:
		var cat: String = entry.get("category", "mystery")
		if not by_category.has(cat):
			by_category[cat] = []
		by_category[cat].append(entry)

	for cat in CODEX_CATEGORIES:
		var entries: Array = by_category.get(cat, [])
		if entries.size() == 0:
			continue

		_add_section_header(codex_list, "-- %s --" % cat.capitalize(), COLOR_CATEGORY_HEADER)

		for entry in entries:
			_add_codex_entry(codex_list, entry)


func _add_codex_entry(parent: VBoxContainer, entry: Dictionary) -> void:
	var entry_id: String = entry.get("id", "")
	var title: String = entry.get("title", "???")
	var main_text: String = entry.get("text", "")
	var fragments: Array = entry.get("fragments", [])
	var is_pulsing: bool = _recently_revealed.has(entry_id)

	# Title.
	var title_label := Label.new()
	title_label.text = title
	title_label.add_theme_font_size_override("font_size", 12)
	title_label.add_theme_color_override(
		"font_color",
		COLOR_LORE_PULSE if is_pulsing else Color(0.85, 0.8, 0.6, 1.0)
	)
	parent.add_child(title_label)

	# Pulse tween for recently revealed entries.
	if is_pulsing:
		var tween := title_label.create_tween()
		tween.set_loops(3)
		tween.tween_property(title_label, "modulate", Color(1.3, 1.1, 0.7, 1.0), 0.4)
		tween.tween_property(title_label, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.4)

	# Main text.
	var text_label := Label.new()
	text_label.text = "  %s" % main_text
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_label.add_theme_font_size_override("font_size", 10)
	text_label.add_theme_color_override("font_color", Color(0.65, 0.65, 0.6, 1.0))
	parent.add_child(text_label)

	# Fragments.
	for frag in fragments:
		if not frag is Dictionary:
			continue
		var frag_text: String = frag.get("text", "[???]")
		var frag_discovered: bool = frag.get("discovered", false)
		var frag_label := Label.new()
		frag_label.text = "    > %s" % frag_text
		frag_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		frag_label.add_theme_font_size_override("font_size", 9)
		frag_label.add_theme_color_override(
			"font_color",
			COLOR_FRAGMENT_FOUND if frag_discovered else COLOR_FRAGMENT_HIDDEN
		)
		parent.add_child(frag_label)

	_add_spacer(parent, 6)


# ---------------------------------------------------------------------------
# Relationships tab
# ---------------------------------------------------------------------------

func _populate_relationships() -> void:
	_clear_children(relationship_list)

	# Gather known NPCs from GameState keys with prefix "npc."
	var npc_keys: Array[String] = GameState.get_keys_with_prefix("npc.")
	var known_npcs: Dictionary = {}  # npc_id -> true
	for key in npc_keys:
		var parts: PackedStringArray = key.split(".")
		if parts.size() >= 2:
			var npc_id: String = parts[1]
			# Only include NPCs the player has met.
			if GameState.get_state("npc.%s.met" % npc_id, false):
				known_npcs[npc_id] = true

	if known_npcs.size() == 0:
		_add_flavor_label(relationship_list, "You haven't met anyone of note yet.", COLOR_COMPLETED)
		return

	for npc_id in known_npcs:
		_add_npc_entry(relationship_list, npc_id)


func _add_npc_entry(parent: VBoxContainer, npc_id: String) -> void:
	var display_name: String = GameState.get_state("npc.%s.name" % npc_id, npc_id.capitalize().replace("_", " "))
	var faction: String = GameState.get_state("npc.%s.faction" % npc_id, "Unknown")
	var disposition: int = GameState.get_state("npc.%s.disposition" % npc_id, 0) as int

	# Row container.
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	parent.add_child(row)

	# Portrait placeholder.
	var portrait := ColorRect.new()
	portrait.custom_minimum_size = Vector2(28, 28)
	portrait.color = Color(0.25, 0.22, 0.2, 1.0)
	row.add_child(portrait)

	var portrait_label := Label.new()
	portrait_label.text = display_name.left(1).to_upper()
	portrait_label.add_theme_font_size_override("font_size", 14)
	portrait_label.add_theme_color_override("font_color", Color(0.7, 0.65, 0.55, 1.0))
	portrait_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	portrait_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	portrait_label.custom_minimum_size = Vector2(28, 28)
	portrait_label.position = Vector2.ZERO
	portrait.add_child(portrait_label)

	# Info column.
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(info)

	# Name + faction.
	var name_label := Label.new()
	name_label.text = "%s  (%s)" % [display_name, faction.capitalize()]
	name_label.add_theme_font_size_override("font_size", 11)
	name_label.add_theme_color_override("font_color", Color(0.85, 0.8, 0.65, 1.0))
	info.add_child(name_label)

	# Disposition text.
	var feeling_text: String = _disposition_to_text(disposition)
	var feeling_label := Label.new()
	feeling_label.text = feeling_text
	feeling_label.add_theme_font_size_override("font_size", 9)
	feeling_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.55, 1.0))
	info.add_child(feeling_label)

	# Disposition bar.
	var bar := ProgressBar.new()
	bar.min_value = -100.0
	bar.max_value = 100.0
	bar.value = float(disposition)
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, 8)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# Colour the bar based on disposition.
	var bar_style := StyleBoxFlat.new()
	bar_style.bg_color = _disposition_color(disposition)
	bar_style.set_corner_radius_all(2)
	bar.add_theme_stylebox_override("fill", bar_style)

	var bar_bg_style := StyleBoxFlat.new()
	bar_bg_style.bg_color = Color(0.15, 0.14, 0.13, 1.0)
	bar_bg_style.set_corner_radius_all(2)
	bar.add_theme_stylebox_override("background", bar_bg_style)

	info.add_child(bar)

	_add_spacer(parent, 4)


func _disposition_to_text(disposition: int) -> String:
	if disposition >= 80:
		return "Trusts you deeply. Would risk their life for you."
	elif disposition >= 50:
		return "Considers you a friend. Willing to share secrets."
	elif disposition >= 20:
		return "Regards you warmly. Open to cooperation."
	elif disposition >= 0:
		return "Indifferent. Neither trusts nor distrusts you."
	elif disposition >= -20:
		return "Wary of you. Guarded in conversation."
	elif disposition >= -50:
		return "Dislikes you. Will not help willingly."
	else:
		return "Despises you. May act against your interests."


func _disposition_color(disposition: int) -> Color:
	if disposition >= 30:
		return COLOR_DISPOSITION_HIGH
	elif disposition >= -30:
		return COLOR_DISPOSITION_MID
	else:
		return COLOR_DISPOSITION_LOW


# ---------------------------------------------------------------------------
# Map tab
# ---------------------------------------------------------------------------

func _populate_map() -> void:
	map_label.text = "Ashvale and surroundings\n\nA detailed map will be drawn as you explore."


# ---------------------------------------------------------------------------
# Signal callbacks
# ---------------------------------------------------------------------------

func _on_quest_updated(_quest_id: String, _old_state: String, _new_state: String) -> void:
	if visible and _current_tab == 0:
		_populate_quests()


func _on_quest_updated_simple(_quest_id: String, _extra: String = "") -> void:
	if visible and _current_tab == 0:
		_populate_quests()


func _on_codex_updated(entry_id: String) -> void:
	_recently_revealed[entry_id] = PULSE_DURATION
	if visible and _current_tab == 1:
		_populate_codex()


func _on_fragment_discovered(entry_id: String, _fragment_id: String) -> void:
	_recently_revealed[entry_id] = PULSE_DURATION
	if visible and _current_tab == 1:
		_populate_codex()


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

func _find_codex_manager() -> Node:
	# Check as direct child first (it lives in journal_ui.tscn).
	if has_node("CodexManager"):
		return get_node("CodexManager")
	# Check as sibling in the parent scene tree.
	var parent_node: Node = get_parent()
	if parent_node:
		for child in parent_node.get_children():
			if child.name == "CodexManager":
				return child
	# Check the scene tree root (in case it was added globally).
	var root: Node = get_tree().root if get_tree() else null
	if root and root.has_node("CodexManager"):
		return root.get_node("CodexManager")
	return null


func _get_failed_quests() -> Array[String]:
	var result: Array[String] = []
	# QuestManager doesn't have a get_failed_quests helper, so iterate.
	for qid in QuestManager._quest_states:
		if QuestManager.get_quest_state(qid).begins_with("FAILED"):
			result.append(qid)
	return result


func _clear_children(node: Node) -> void:
	for child in node.get_children():
		child.queue_free()


func _add_section_header(parent: VBoxContainer, text: String, color: Color) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 11)
	label.add_theme_color_override("font_color", color)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	parent.add_child(label)
	_add_spacer(parent, 3)


func _add_flavor_label(parent: VBoxContainer, text: String, color: Color) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 10)
	label.add_theme_color_override("font_color", color)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(label)


func _add_spacer(parent: VBoxContainer, height: float) -> void:
	var spacer := Control.new()
	spacer.custom_minimum_size.y = height
	parent.add_child(spacer)
