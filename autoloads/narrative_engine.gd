## Narrative Engine — loads dialogue trees from JSON, handles template slot-filling,
## manages dialogue state machines, and evaluates conditions/triggers on dialogue nodes.
extends Node

# Cached dialogue data: {dialogue_id: dialogue_tree_dict}
var _dialogue_cache: Dictionary = {}

# Currently active dialogue state
var _current_dialogue_id: String = ""
var _current_node_id: String = ""
var _is_dialogue_active: bool = false

# Narrative atom templates: {atom_id: atom_data}
var _narrative_atoms: Dictionary = {}


func _ready() -> void:
	pass


## Load a dialogue tree from JSON file path.
func load_dialogue(file_path: String) -> Dictionary:
	var file := FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		push_error("NarrativeEngine: Cannot open dialogue file: %s" % file_path)
		return {}

	var json := JSON.new()
	var err := json.parse(file.get_as_text())
	if err != OK:
		push_error("NarrativeEngine: JSON parse error in %s: %s" % [file_path, json.get_error_message()])
		return {}

	if not json.data is Dictionary:
		# Skip non-dialogue JSON files (arrays like ambient_overhears, interjections)
		return {}
	var data: Dictionary = json.data
	_dialogue_cache[data.get("id", file_path)] = data
	return data


## Load all dialogue files from a directory.
func load_dialogues_from_dir(dir_path: String) -> int:
	var count: int = 0
	var dir := DirAccess.open(dir_path)
	if dir == null:
		push_warning("NarrativeEngine: Cannot open dialogue directory: %s" % dir_path)
		return 0

	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != "":
		if file_name.ends_with(".json"):
			load_dialogue(dir_path.path_join(file_name))
			count += 1
		file_name = dir.get_next()
	dir.list_dir_end()
	return count


## Load narrative atom templates.
func load_narrative_atoms(dir_path: String) -> int:
	var count: int = 0
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return 0

	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != "":
		if file_name.ends_with(".json"):
			var file := FileAccess.open(dir_path.path_join(file_name), FileAccess.READ)
			if file:
				var json := JSON.new()
				if json.parse(file.get_as_text()) == OK:
					if json.data is Dictionary:
						var data: Dictionary = json.data
						_narrative_atoms[data.get("id", file_name)] = data
						count += 1
					elif json.data is Array:
						for atom in json.data:
							if atom is Dictionary:
								_narrative_atoms[atom.get("id", file_name)] = atom
								count += 1
		file_name = dir.get_next()
	dir.list_dir_end()
	return count


## Start a dialogue tree. Returns the first node data (with text processed).
func start_dialogue(dialogue_id: String) -> Dictionary:
	if not _dialogue_cache.has(dialogue_id):
		push_error("NarrativeEngine: Dialogue not found: %s" % dialogue_id)
		return {}

	_current_dialogue_id = dialogue_id
	_is_dialogue_active = true
	var tree: Dictionary = _dialogue_cache[dialogue_id]
	var start_node: String = tree.get("start_node", "start")

	EventBus.dialogue_started.emit(dialogue_id)
	return advance_to_node(start_node)


## Advance to a specific node in the current dialogue.
func advance_to_node(node_id: String) -> Dictionary:
	if not _is_dialogue_active:
		return {}

	var tree: Dictionary = _dialogue_cache[_current_dialogue_id]
	var nodes: Dictionary = tree.get("nodes", {})

	if not nodes.has(node_id):
		push_error("NarrativeEngine: Node not found: %s in %s" % [node_id, _current_dialogue_id])
		end_dialogue()
		return {}

	_current_node_id = node_id
	var node: Dictionary = nodes[node_id].duplicate(true)

	EventBus.dialogue_node_entered.emit(_current_dialogue_id, node_id)

	# Process the node based on type
	var node_type: String = node.get("type", "text")

	match node_type:
		"text", "":
			# Process text with slot-filling
			node["processed_text"] = _process_template_text(
				node.get("text", ""),
				node.get("slot_fills", {})
			)
			# Execute triggers
			_execute_triggers(node.get("triggers", []))
			# Return processed node; caller should call advance_to_node(node.next)
			return node

		"choice":
			# Filter options by conditions
			var available_options: Array = []
			for option in node.get("options", []):
				if _check_conditions(option.get("conditions", [])):
					var processed_option: Dictionary = option.duplicate(true)
					processed_option["processed_text"] = _process_template_text(
						option.get("text", ""), {}
					)
					available_options.append(processed_option)
			node["available_options"] = available_options
			return node

		"end":
			end_dialogue()
			return node

	return node


## Select a dialogue choice by index. Executes triggers and advances.
func select_choice(choice_index: int) -> Dictionary:
	if not _is_dialogue_active:
		return {}

	var tree: Dictionary = _dialogue_cache[_current_dialogue_id]
	var nodes: Dictionary = tree.get("nodes", {})
	var current_node: Dictionary = nodes.get(_current_node_id, {})
	var options: Array = current_node.get("options", [])

	# Build available options (same filtering as advance_to_node)
	var available: Array = []
	for option in options:
		if _check_conditions(option.get("conditions", [])):
			available.append(option)

	if choice_index < 0 or choice_index >= available.size():
		push_error("NarrativeEngine: Invalid choice index: %d" % choice_index)
		return {}

	var chosen: Dictionary = available[choice_index]

	# Execute choice triggers
	_execute_triggers(chosen.get("triggers", []))

	# Emit choice signal
	EventBus.dialogue_choice_made.emit(
		_current_dialogue_id,
		chosen.get("id", "choice_%d" % choice_index)
	)

	# Advance to next node
	var next_node: String = chosen.get("next", "")
	if next_node == "" or next_node == "end":
		end_dialogue()
		return {"type": "end"}

	return advance_to_node(next_node)


## End the current dialogue.
func end_dialogue() -> void:
	if _is_dialogue_active:
		EventBus.dialogue_ended.emit(_current_dialogue_id)
		_is_dialogue_active = false
		_current_dialogue_id = ""
		_current_node_id = ""


## Check if dialogue is currently active.
func is_in_dialogue() -> bool:
	return _is_dialogue_active


## Process template text with slot-filling from GameState.
func process_text(text: String) -> String:
	return _process_template_text(text, {})


## Get a cached dialogue tree.
func get_dialogue(dialogue_id: String) -> Dictionary:
	return _dialogue_cache.get(dialogue_id, {})


# --- Private ---

func _process_template_text(text: String, slot_fills: Dictionary) -> String:
	var result: String = text

	# First apply explicit slot fills
	for slot_key in slot_fills:
		var fill_source: String = slot_fills[slot_key]
		var fill_value: String = ""

		if fill_source.begins_with("game_state:"):
			var state_key: String = fill_source.substr("game_state:".length())
			fill_value = str(GameState.get_state(state_key, "???"))
		else:
			fill_value = fill_source

		result = result.replace("{%s}" % slot_key, fill_value)

	# Then process any remaining {key} patterns from GameState
	var regex := RegEx.new()
	regex.compile("\\{([^}]+)\\}")
	var matches: Array[RegExMatch] = regex.search_all(result)

	for m in matches:
		var key: String = m.get_string(1)
		var value: Variant = GameState.get_state(key)
		if value != null:
			result = result.replace("{%s}" % key, str(value))

	return result


func _check_conditions(conditions: Array) -> bool:
	if conditions.is_empty():
		return true
	return GameState.evaluate_conditions(conditions)


func _execute_triggers(triggers: Array) -> void:
	for trigger in triggers:
		if not trigger is Dictionary:
			continue

		if trigger.has("set_state"):
			if trigger.has("delta"):
				GameState.delta_state(trigger.set_state, float(trigger.delta))
			elif trigger.has("value"):
				GameState.set_state(trigger.set_state, trigger.value)
			else:
				push_warning("NarrativeEngine: Trigger has set_state '%s' but no value or delta" % trigger.set_state)

		elif trigger.has("remove_item"):
			var item_id: String = trigger.remove_item
			GameState.set_state("player.has_item.%s" % item_id, false)
			if trigger.has("amount") and trigger.get("amount", 0) > 0:
				GameState.delta_state("player.gold", -trigger.amount)

		elif trigger.has("give_item"):
			GameState.set_state("player.has_item.%s" % trigger.give_item, true)

		elif trigger.has("start_quest"):
			QuestManager.force_quest_state(trigger.start_quest, "DISCOVERED")

		elif trigger.has("modify_reputation"):
			for faction_id in trigger.modify_reputation:
				FactionManager.modify_player_rep(
					faction_id, trigger.modify_reputation[faction_id]
				)

		elif trigger.has("start_combat"):
			EventBus.combat_started.emit(trigger.get("enemies", []))

		elif trigger.has("transition_scene"):
			EventBus.scene_transition_requested.emit(
				trigger.transition_scene,
				trigger.get("spawn_point", "default")
			)
