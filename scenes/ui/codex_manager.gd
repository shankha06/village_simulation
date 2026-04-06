## Codex Manager -- backend for the lore/codex system.
## Loads entries from data/lore/codex_entries.json, tracks discovery state,
## evaluates fragment unlock conditions, and checks for revelations.
extends Node

signal entry_discovered(entry_id: String)
signal fragment_discovered(entry_id: String, fragment_id: String)
signal revelation_unlocked(revelation_text: String)

const CODEX_PATH: String = "res://data/lore/codex_entries.json"

## Categories recognised by the codex.
var CATEGORIES: PackedStringArray = PackedStringArray([
	"history", "factions", "alchemy", "mystery",
])

## Revelation thresholds: when a category reaches this many fragments, fire a revelation.
const REVELATION_THRESHOLDS: Array[int] = [3, 6, 10]

# Raw entry definitions keyed by entry_id.
var _entries: Dictionary = {}

# Discovered entry ids.
var _discovered_entries: Dictionary = {}  # {entry_id: true}

# Discovered fragments: {entry_id: {fragment_id: true}}
var _discovered_fragments: Dictionary = {}

# Revelations already shown (so we don't repeat them).
var _shown_revelations: Dictionary = {}  # {revelation_key: true}


func _ready() -> void:
	_load_codex_data()
	GameState.state_changed.connect(_on_state_changed)


# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

## Mark an entry as discovered. Emits entry_discovered signal.
func discover_entry(entry_id: String) -> void:
	if _discovered_entries.has(entry_id):
		return
	if not _entries.has(entry_id):
		push_warning("CodexManager: Unknown entry id '%s'" % entry_id)
		return

	_discovered_entries[entry_id] = true
	entry_discovered.emit(entry_id)
	EventBus.codex_entry_unlocked.emit(entry_id)
	EventBus.notification_requested.emit(
		"Codex: %s" % _entries[entry_id].get("title", entry_id), "lore"
	)


## Mark a specific fragment within an entry as discovered.
func discover_fragment(entry_id: String, fragment_id: String) -> void:
	if not _entries.has(entry_id):
		push_warning("CodexManager: Unknown entry '%s'" % entry_id)
		return

	# Auto-discover the parent entry when a fragment is found.
	if not _discovered_entries.has(entry_id):
		discover_entry(entry_id)

	if not _discovered_fragments.has(entry_id):
		_discovered_fragments[entry_id] = {}
	if _discovered_fragments[entry_id].has(fragment_id):
		return

	_discovered_fragments[entry_id][fragment_id] = true
	fragment_discovered.emit(entry_id, fragment_id)

	# Check if this triggers a new revelation.
	var new_revelations: Array[String] = check_connections()
	for rev in new_revelations:
		revelation_unlocked.emit(rev)
		EventBus.notification_requested.emit("Revelation: %s" % rev, "lore")


## Evaluate all fragment conditions against current GameState and auto-discover
## any fragments whose conditions are now met.
func evaluate_fragment_conditions() -> void:
	for entry_id in _entries:
		var entry: Dictionary = _entries[entry_id]
		# Check entry-level conditions first.
		var entry_conditions: Array = entry.get("conditions", [])
		if entry_conditions.size() > 0 and GameState.evaluate_conditions(entry_conditions):
			if not _discovered_entries.has(entry_id):
				discover_entry(entry_id)

		# Check per-fragment conditions.
		var fragments: Array = entry.get("fragments", [])
		for frag in fragments:
			if not frag is Dictionary:
				continue
			var frag_id: String = frag.get("id", "")
			if frag_id == "":
				continue
			# Already discovered -- skip.
			if _discovered_fragments.has(entry_id) and _discovered_fragments[entry_id].has(frag_id):
				continue
			var frag_conditions: Array = frag.get("conditions", [])
			if frag_conditions.size() > 0 and GameState.evaluate_conditions(frag_conditions):
				discover_fragment(entry_id, frag_id)


## Check whether enough fragments are known to produce new revelations.
## Returns a list of revelation strings not yet shown.
func check_connections() -> Array[String]:
	var results: Array[String] = []

	# Count discovered fragments per category.
	var category_counts: Dictionary = {}
	for cat in CATEGORIES:
		category_counts[cat] = 0

	for entry_id in _discovered_fragments:
		var entry: Dictionary = _entries.get(entry_id, {})
		var cat: String = entry.get("category", "")
		if cat != "":
			category_counts[cat] = category_counts.get(cat, 0) + _discovered_fragments[entry_id].size()

	# Cross-category connections.
	var total_fragments: int = 0
	for cat in category_counts:
		total_fragments += category_counts[cat]

	for threshold in REVELATION_THRESHOLDS:
		var key: String = "total_%d" % threshold
		if total_fragments >= threshold and not _shown_revelations.has(key):
			_shown_revelations[key] = true
			results.append(_revelation_text_for_threshold(threshold))

	return results


## Return all discovered entries grouped by category for journal display.
## Each item: {id, title, category, text, fragments: [{id, text, discovered}]}
func get_all_discovered() -> Array:
	var result: Array = []
	for entry_id in _discovered_entries:
		var entry: Dictionary = _entries.get(entry_id, {})
		var fragments_out: Array = []
		var raw_fragments: Array = entry.get("fragments", [])
		for frag in raw_fragments:
			if not frag is Dictionary:
				continue
			var frag_id: String = frag.get("id", "")
			var is_discovered: bool = (
				_discovered_fragments.has(entry_id)
				and _discovered_fragments[entry_id].has(frag_id)
			)
			var frag_text: String = frag.get("text", "") if is_discovered else "[???]"
			fragments_out.append({
				"id": frag_id,
				"text": frag_text,
				"discovered": is_discovered,
			})
		result.append({
			"id": entry_id,
			"title": entry.get("title", entry_id),
			"category": entry.get("category", ""),
			"text": entry.get("text", ""),
			"fragments": fragments_out,
		})
	return result


## Return all entry definitions (for debug / editor use).
func get_all_entries() -> Dictionary:
	return _entries


## Check if a specific entry has been discovered.
func is_entry_discovered(entry_id: String) -> bool:
	return _discovered_entries.has(entry_id)


## Check if a specific fragment has been discovered.
func is_fragment_discovered(entry_id: String, fragment_id: String) -> bool:
	return (
		_discovered_fragments.has(entry_id)
		and _discovered_fragments[entry_id].has(fragment_id)
	)


# ---------------------------------------------------------------------------
# Save / Load
# ---------------------------------------------------------------------------

func serialize() -> Dictionary:
	return {
		"discovered_entries": _discovered_entries.duplicate(),
		"discovered_fragments": _discovered_fragments.duplicate(true),
		"shown_revelations": _shown_revelations.duplicate(),
	}


func deserialize(data: Dictionary) -> void:
	_discovered_entries = data.get("discovered_entries", {})
	_discovered_fragments = data.get("discovered_fragments", {})
	_shown_revelations = data.get("shown_revelations", {})


# ---------------------------------------------------------------------------
# Private
# ---------------------------------------------------------------------------

func _load_codex_data() -> void:
	if not FileAccess.file_exists(CODEX_PATH):
		push_warning("CodexManager: Codex data not found at %s" % CODEX_PATH)
		return

	var file := FileAccess.open(CODEX_PATH, FileAccess.READ)
	if file == null:
		push_error("CodexManager: Cannot open %s" % CODEX_PATH)
		return

	var json := JSON.new()
	var err := json.parse(file.get_as_text())
	file.close()

	if err != OK:
		push_error("CodexManager: JSON parse error: %s" % json.get_error_message())
		return

	var data: Dictionary = json.data
	var entries_array: Array = data.get("entries", [])
	for entry in entries_array:
		if not entry is Dictionary:
			continue
		var eid: String = entry.get("id", "")
		if eid == "":
			continue
		_entries[eid] = entry
		# Auto-discover entries flagged as discovered_by_default.
		if entry.get("discovered_by_default", false):
			_discovered_entries[eid] = true


func _on_state_changed(_key: String, _old: Variant, _new: Variant) -> void:
	# Re-evaluate fragment conditions whenever any game state changes.
	evaluate_fragment_conditions()


func _revelation_text_for_threshold(threshold: int) -> String:
	match threshold:
		3:
			return "The threads of Ashvale's history begin to intertwine..."
		6:
			return "A deeper pattern emerges -- these events are not coincidence."
		10:
			return "The truth behind Ashvale's curse is almost within reach."
		_:
			return "New connections have been revealed."
