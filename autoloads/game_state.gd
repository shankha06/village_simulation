## Global State Manager — the centralized "brain" of the game.
## Stores all world state as a flat dictionary with dot-notation keys.
## Every system reads/writes through this singleton.
## Fully serializable for save/load.
extends Node

## Emitted whenever any state value changes.
signal state_changed(key: String, old_value: Variant, new_value: Variant)

## Emitted when multiple states change in a batch (for performance).
signal batch_changed(changes: Array[Dictionary])

# The master state dictionary. Keys are dot-notation strings.
# e.g. "world.region.ashvale.status" -> "normal"
var _state: Dictionary = {}

# Tracks which keys have been modified since last save
var _dirty_keys: Dictionary = {}

# When true, state_changed signals are deferred until end_batch()
var _batching: bool = false
var _batch_queue: Array[Dictionary] = []


func _ready() -> void:
	_initialize_defaults()


## Get a state value. Returns default if key doesn't exist.
func get_state(key: String, default: Variant = null) -> Variant:
	return _state.get(key, default)


## Set a state value. Emits state_changed if value actually changed.
func set_state(key: String, value: Variant) -> void:
	var old_value: Variant = _state.get(key)
	if old_value == value:
		return
	_state[key] = value
	_dirty_keys[key] = true
	if _batching:
		_batch_queue.append({"key": key, "old": old_value, "new": value})
	else:
		state_changed.emit(key, old_value, value)


## Apply a delta to a numeric state value. Creates key with delta as value if missing.
func delta_state(key: String, delta: float) -> void:
	var current: Variant = _state.get(key, 0.0)
	if current is int:
		set_state(key, current + int(delta))
	elif current is float:
		set_state(key, current + delta)
	else:
		set_state(key, delta)


## Check if a key exists in state.
func has_state(key: String) -> bool:
	return _state.has(key)


## Remove a key from state entirely.
func remove_state(key: String) -> void:
	if _state.has(key):
		var old_value: Variant = _state[key]
		_state.erase(key)
		_dirty_keys[key] = true
		state_changed.emit(key, old_value, null)


## Begin batching state changes. Signals are deferred until end_batch().
func begin_batch() -> void:
	_batching = true
	_batch_queue.clear()


## End batch and emit all accumulated changes.
func end_batch() -> void:
	_batching = false
	if _batch_queue.size() > 0:
		batch_changed.emit(_batch_queue)
		for change in _batch_queue:
			state_changed.emit(change.key, change.old, change.new)
		_batch_queue.clear()


## Evaluate a condition string against current state.
## Format: "key op value" e.g. "flag.silo_destroyed == true"
## Supported ops: ==, !=, <, >, <=, >=
func evaluate_condition(condition: String) -> bool:
	var parts: PackedStringArray = condition.strip_edges().split(" ", false)
	if parts.size() < 3:
		push_warning("GameState: Invalid condition format: %s" % condition)
		return false

	var key: String = parts[0]
	var op: String = parts[1]
	var raw_value: String = " ".join(PackedStringArray(parts.slice(2)))
	var state_value: Variant = get_state(key)
	var compare_value: Variant = _parse_value(raw_value)

	if state_value == null:
		state_value = _default_for_type(compare_value)

	match op:
		"==":
			return state_value == compare_value
		"!=":
			return state_value != compare_value
		"<":
			return state_value < compare_value
		">":
			return state_value > compare_value
		"<=":
			return state_value <= compare_value
		">=":
			return state_value >= compare_value
		_:
			push_warning("GameState: Unknown operator: %s" % op)
			return false


## Evaluate multiple conditions (all must be true).
func evaluate_conditions(conditions: Array) -> bool:
	for condition in conditions:
		if condition is String:
			if not evaluate_condition(condition):
				return false
		elif condition is Dictionary:
			if not _evaluate_dict_condition(condition):
				return false
	return true


## Get all keys matching a prefix. Useful for iterating NPC memories etc.
func get_keys_with_prefix(prefix: String) -> Array[String]:
	var result: Array[String] = []
	for key in _state.keys():
		if (key as String).begins_with(prefix):
			result.append(key)
	return result


## Get the full state dictionary (for serialization).
func serialize() -> Dictionary:
	return _state.duplicate(true)


## Replace the entire state dictionary (for deserialization).
func deserialize(data: Dictionary) -> void:
	_state = data.duplicate(true)
	_dirty_keys.clear()


## Clear all state and reinitialize defaults.
func reset() -> void:
	_state.clear()
	_dirty_keys.clear()
	_batch_queue.clear()
	_batching = false
	_initialize_defaults()


# --- Private ---

func _initialize_defaults() -> void:
	# Player defaults
	_state["player.gold"] = 0
	_state["player.health"] = 100.0
	_state["player.max_health"] = 100.0
	_state["player.last_region"] = ""
	_state["player.last_region_name"] = ""
	_state["player.has_item.marens_heirloom"] = true

	# Time tracking
	_state["time.day"] = 1
	_state["time.hour"] = 8
	_state["time.minute"] = 0
	_state["time.season"] = "autumn"


func _parse_value(raw: String) -> Variant:
	# Boolean
	if raw == "true":
		return true
	if raw == "false":
		return false
	# Integer
	if raw.is_valid_int():
		return raw.to_int()
	# Float
	if raw.is_valid_float():
		return raw.to_float()
	# String (strip quotes if present)
	if raw.begins_with("\"") and raw.ends_with("\""):
		return raw.substr(1, raw.length() - 2)
	return raw


func _default_for_type(value: Variant) -> Variant:
	if value is bool:
		return false
	if value is int:
		return 0
	if value is float:
		return 0.0
	if value is String:
		return ""
	return null


func _evaluate_dict_condition(condition: Dictionary) -> bool:
	var key: String = condition.get("check", "")
	var op: String = condition.get("op", "==")
	var value: Variant = condition.get("value")
	var state_value: Variant = get_state(key)

	if state_value == null:
		state_value = _default_for_type(value)

	match op:
		"==":
			return state_value == value
		"!=":
			return state_value != value
		"<":
			return state_value < value
		">":
			return state_value > value
		"<=":
			return state_value <= value
		">=":
			return state_value >= value
		_:
			return false
