## Save Manager — serializes and deserializes all game state to JSON files.
## Supports multiple save slots and autosave.
extends Node

const SAVE_DIR: String = "user://saves/"
const AUTOSAVE_SLOT: int = 0
const MAX_SLOTS: int = 10

# Save metadata for slot browser
var _slot_metadata: Dictionary = {}


func _ready() -> void:
	# Ensure save directory exists
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)
	_load_metadata()
	EventBus.save_requested.connect(_on_save_requested)
	EventBus.load_requested.connect(_on_load_requested)


## Save game state to a slot.
func save_game(slot: int) -> bool:
	var save_data: Dictionary = _collect_save_data()
	var file_path: String = _get_slot_path(slot)

	var file := FileAccess.open(file_path, FileAccess.WRITE)
	if file == null:
		push_error("SaveManager: Cannot write to %s" % file_path)
		return false

	var json_string: String = JSON.stringify(save_data, "\t")
	file.store_string(json_string)
	file.close()

	# Update metadata
	_slot_metadata[str(slot)] = {
		"slot": slot,
		"timestamp": Time.get_datetime_string_from_system(),
		"day": TimeManager.day,
		"hour": TimeManager.hour,
		"season": TimeManager.get_season(),
		"region": GameState.get_state("player.last_region_name", "Unknown"),
		"playtime_minutes": GameState.get_state("player.playtime_minutes", 0),
	}
	_save_metadata()

	EventBus.save_completed.emit(slot)
	return true


## Load game state from a slot.
func load_game(slot: int) -> bool:
	var file_path: String = _get_slot_path(slot)

	if not FileAccess.file_exists(file_path):
		push_error("SaveManager: Save file not found: %s" % file_path)
		return false

	var file := FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		push_error("SaveManager: Cannot read %s" % file_path)
		return false

	var json := JSON.new()
	var err := json.parse(file.get_as_text())
	file.close()

	if err != OK:
		push_error("SaveManager: JSON parse error in save file: %s" % json.get_error_message())
		return false

	var save_data: Dictionary = json.data
	_apply_save_data(save_data)

	EventBus.load_completed.emit(slot)
	return true


## Autosave the game.
func autosave() -> bool:
	return save_game(AUTOSAVE_SLOT)


## Check if a save slot has data.
func has_save(slot: int) -> bool:
	return FileAccess.file_exists(_get_slot_path(slot))


## Get metadata for a save slot (for UI display).
func get_slot_info(slot: int) -> Dictionary:
	return _slot_metadata.get(str(slot), {})


## Get all save slot metadata.
func get_all_slots() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for i in range(MAX_SLOTS):
		if has_save(i):
			result.append(get_slot_info(i))
	return result


## Delete a save slot.
func delete_save(slot: int) -> void:
	var file_path: String = _get_slot_path(slot)
	if FileAccess.file_exists(file_path):
		DirAccess.remove_absolute(file_path)
	_slot_metadata.erase(str(slot))
	_save_metadata()


## Start a new game (reset all state).
func new_game() -> void:
	GameState.reset()
	TimeManager.set_time(0, 8, 1, 2)  # 8 AM, Day 1, Autumn
	# Quest and faction managers will be initialized when data is loaded


# --- Private ---

func _collect_save_data() -> Dictionary:
	var data: Dictionary = {
		"version": 1,
		"game_state": GameState.serialize(),
		"time": TimeManager.serialize(),
		"quests": QuestManager.serialize(),
		"factions": FactionManager.serialize(),
		"world_simulation": WorldSimulation.serialize(),
		"player": {
			"position_x": GameState.get_state("player.position_x", 0.0),
			"position_y": GameState.get_state("player.position_y", 0.0),
			"current_region": GameState.get_state("player.current_region", ""),
		},
	}
	var codex: Node = _find_codex_manager()
	if codex and codex.has_method("serialize"):
		data["codex"] = codex.serialize()
	return data


func _apply_save_data(data: Dictionary) -> void:
	var version: int = data.get("version", 1)
	if version != 1:
		push_warning("SaveManager: Save version %d, expected 1" % version)

	GameState.deserialize(data.get("game_state", {}))
	TimeManager.deserialize(data.get("time", {}))
	QuestManager.deserialize(data.get("quests", {}))
	FactionManager.deserialize(data.get("factions", {}))
	WorldSimulation.deserialize(data.get("world_simulation", {}))
	var codex: Node = _find_codex_manager()
	if codex and codex.has_method("deserialize") and data.has("codex"):
		codex.deserialize(data.codex)

	# Restore player position through scene transition
	var player_data: Dictionary = data.get("player", {})
	var region: String = player_data.get("current_region", "")
	if region != "":
		EventBus.scene_transition_requested.emit(region, "save_position")


func _get_slot_path(slot: int) -> String:
	if slot == AUTOSAVE_SLOT:
		return SAVE_DIR + "autosave.json"
	return SAVE_DIR + "save_%d.json" % slot


func _save_metadata() -> void:
	var file := FileAccess.open(SAVE_DIR + "metadata.json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(_slot_metadata, "\t"))
		file.close()


func _load_metadata() -> void:
	var path: String = SAVE_DIR + "metadata.json"
	if not FileAccess.file_exists(path):
		return
	var file := FileAccess.open(path, FileAccess.READ)
	if file:
		var json := JSON.new()
		if json.parse(file.get_as_text()) == OK:
			_slot_metadata = json.data
		file.close()


func _find_codex_manager() -> Node:
	# CodexManager lives as a child of JournalUI in the scene tree.
	var root: Node = get_tree().root if get_tree() else null
	if root == null:
		return null
	var journal: Node = root.find_child("CodexManager", true, false)
	return journal


func _on_save_requested(slot: int) -> void:
	save_game(slot)


func _on_load_requested(slot: int) -> void:
	load_game(slot)
