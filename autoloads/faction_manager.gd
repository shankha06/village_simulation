## Faction Manager — tracks faction-to-faction relationships and player reputation.
## Uses a 2D relationship matrix with ripple effects.
extends Node

# Faction data: {faction_id: {name, description, initial_power, allies, enemies}}
var _factions: Dictionary = {}

# Relationship matrix: _relations[faction_a][faction_b] = affinity (-100 to 100)
var _relations: Dictionary = {}

# Player reputation per faction: _player_rep[faction_id] = int (-100 to 100)
var _player_rep: Dictionary = {}

# Faction power levels: _power[faction_id] = float (0 to 100)
var _power: Dictionary = {}

# Reputation thresholds
const REP_HOSTILE: int = -50
const REP_UNFRIENDLY: int = -20
const REP_NEUTRAL: int = 20
const REP_FRIENDLY: int = 50
const REP_ALLIED: int = 80

# Ripple coefficients
const ALLY_RIPPLE: float = 0.3   # Allied factions get 30% of rep change
const ENEMY_RIPPLE: float = 0.2  # Enemy factions get -20% of rep change
const ALLY_THRESHOLD: int = 50   # Affinity above this = allied
const ENEMY_THRESHOLD: int = -50 # Affinity below this = hostile


func _ready() -> void:
	GameState.state_changed.connect(_on_state_changed)


## Load faction data from JSON.
func load_factions(data: Dictionary) -> void:
	_factions.clear()
	_relations.clear()
	_player_rep.clear()
	_power.clear()

	# Load faction definitions
	for faction_data in data.get("factions", []):
		var fid: String = faction_data.id
		_factions[fid] = faction_data
		_player_rep[fid] = faction_data.get("initial_player_rep", 0)
		_power[fid] = faction_data.get("initial_power", 50.0)

		# Sync to GameState
		GameState.set_state("player.reputation.%s" % fid, _player_rep[fid])
		GameState.set_state("faction.%s.power" % fid, _power[fid])

	# Load relationship matrix
	for relation in data.get("relations", []):
		var a: String = relation.faction_a
		var b: String = relation.faction_b
		var affinity: int = relation.affinity
		_set_relation(a, b, affinity)


## Get player reputation with a faction.
func get_player_rep(faction_id: String) -> int:
	return _player_rep.get(faction_id, 0)


## Modify player reputation with a faction (with ripple effects).
func modify_player_rep(faction_id: String, delta: int, ripple: bool = true) -> void:
	if not _factions.has(faction_id):
		return

	var old_rep: int = _player_rep.get(faction_id, 0)
	var new_rep: int = clampi(old_rep + delta, -100, 100)
	_player_rep[faction_id] = new_rep
	GameState.set_state("player.reputation.%s" % faction_id, new_rep)

	var old_standing: String = _get_standing(old_rep)
	var new_standing: String = _get_standing(new_rep)
	if old_standing != new_standing:
		EventBus.faction_reputation_changed.emit(faction_id, old_rep, new_rep)

	# Ripple to allied/enemy factions
	if ripple:
		for other_fid in _factions.keys():
			if other_fid == faction_id:
				continue
			var affinity: int = get_relation(faction_id, other_fid)
			if affinity > ALLY_THRESHOLD:
				var ripple_delta: int = int(delta * ALLY_RIPPLE * (affinity / 100.0))
				if ripple_delta != 0:
					modify_player_rep(other_fid, ripple_delta, false)
			elif affinity < ENEMY_THRESHOLD:
				var ripple_delta: int = int(-delta * ENEMY_RIPPLE * (absf(affinity) / 100.0))
				if ripple_delta != 0:
					modify_player_rep(other_fid, ripple_delta, false)


## Get relationship between two factions.
func get_relation(faction_a: String, faction_b: String) -> int:
	if _relations.has(faction_a) and _relations[faction_a].has(faction_b):
		return _relations[faction_a][faction_b]
	return 0


## Modify relationship between two factions.
func modify_relation(faction_a: String, faction_b: String, delta: int) -> void:
	var current: int = get_relation(faction_a, faction_b)
	var new_val: int = clampi(current + delta, -100, 100)
	_set_relation(faction_a, faction_b, new_val)


## Get faction power level.
func get_power(faction_id: String) -> float:
	return _power.get(faction_id, 0.0)


## Modify faction power.
func modify_power(faction_id: String, delta: float) -> void:
	var old_power: float = _power.get(faction_id, 50.0)
	var new_power: float = clampf(old_power + delta, 0.0, 100.0)
	_power[faction_id] = new_power
	GameState.set_state("faction.%s.power" % faction_id, new_power)
	if absf(old_power - new_power) > 5.0:
		EventBus.faction_power_changed.emit(faction_id, old_power, new_power)


## Get player's standing label with a faction.
func get_standing_with(faction_id: String) -> String:
	return _get_standing(_player_rep.get(faction_id, 0))


## Get all factions the player is hostile with.
func get_hostile_factions() -> Array[String]:
	var result: Array[String] = []
	for fid in _player_rep.keys():
		if _player_rep[fid] <= REP_HOSTILE:
			result.append(fid)
	return result


## Serialize for saving.
func serialize() -> Dictionary:
	return {
		"player_rep": _player_rep.duplicate(),
		"power": _power.duplicate(),
		"relations": _relations.duplicate(true),
	}


## Deserialize from save.
func deserialize(data: Dictionary) -> void:
	_player_rep = data.get("player_rep", {})
	_power = data.get("power", {})
	_relations = data.get("relations", {})
	# Sync back to GameState
	for fid in _player_rep:
		GameState.set_state("player.reputation.%s" % fid, _player_rep[fid])
	for fid in _power:
		GameState.set_state("faction.%s.power" % fid, _power[fid])


# --- Private ---

func _set_relation(a: String, b: String, value: int) -> void:
	if not _relations.has(a):
		_relations[a] = {}
	if not _relations.has(b):
		_relations[b] = {}
	_relations[a][b] = value
	_relations[b][a] = value  # Symmetric


func _get_standing(rep: int) -> String:
	if rep <= REP_HOSTILE:
		return "hostile"
	elif rep <= REP_UNFRIENDLY:
		return "unfriendly"
	elif rep <= REP_NEUTRAL:
		return "neutral"
	elif rep <= REP_FRIENDLY:
		return "friendly"
	elif rep <= REP_ALLIED:
		return "allied"
	else:
		return "revered"


func _on_state_changed(key: String, _old_value: Variant, new_value: Variant) -> void:
	# React to external state changes that affect factions
	if key.begins_with("faction.") and key.ends_with(".power"):
		var parts: PackedStringArray = key.split(".")
		if parts.size() >= 3:
			var fid: String = parts[1]
			if _power.has(fid) and new_value is float:
				_power[fid] = new_value
