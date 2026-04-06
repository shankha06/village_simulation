## Relationship Manager — multi-dimensional relationship tracking between entities.
## Replaces the simple disposition system with trust, affection, respect, fear, and debt.
## Supports gossip propagation, history tracking, and backward-compatible disposition.
extends Node

## Emitted whenever a relationship dimension changes.
signal relationship_changed(from_id: String, to_id: String, dimension: String, old_val: float, new_val: float)

## Emitted when a relationship crosses a named threshold.
signal relationship_threshold_crossed(from_id: String, to_id: String, dimension: String, threshold_name: String)

# Dimension definitions with allowed ranges
const DIMENSIONS: Dictionary = {
	"trust": {"min": -1.0, "max": 1.0},
	"affection": {"min": -1.0, "max": 1.0},
	"respect": {"min": -1.0, "max": 1.0},
	"fear": {"min": 0.0, "max": 1.0},
	"debt": {"min": -1.0, "max": 1.0},
}

# Weights for computing overall disposition (backward compat)
const DISPOSITION_WEIGHTS: Dictionary = {
	"trust": 0.25,
	"affection": 0.30,
	"respect": 0.25,
	"fear": -0.10,
	"debt": 0.10,
}

# Named thresholds for each dimension — emitted via relationship_threshold_crossed
const THRESHOLDS: Dictionary = {
	"hostile": -0.5,
	"cold": -0.25,
	"neutral_low": -0.1,
	"neutral_high": 0.1,
	"warm": 0.25,
	"friendly": 0.5,
	"devoted": 0.75,
}

# Fear-specific thresholds (0-1 range)
const FEAR_THRESHOLDS: Dictionary = {
	"calm": 0.1,
	"uneasy": 0.25,
	"nervous": 0.4,
	"afraid": 0.6,
	"terrified": 0.8,
}

# All relationships: _relationships[from_id][to_id] = {trust, affection, respect, fear, debt}
var _relationships: Dictionary = {}

# Relationship history: _history[from_id][to_id] = [{event, day, impact}]
var _history: Dictionary = {}

# Maximum history entries per relationship pair
const MAX_HISTORY_PER_PAIR: int = 50


func _ready() -> void:
	# Connect to EventBus signals for automatic relationship updates
	EventBus.npc_died.connect(_on_npc_died)
	EventBus.dialogue_choice_made.connect(_on_dialogue_choice_made)
	EventBus.quest_completed.connect(_on_quest_completed)
	EventBus.quest_failed.connect(_on_quest_failed)
	EventBus.enemy_defeated.connect(_on_enemy_defeated)
	EventBus.enemy_surrendered.connect(_on_enemy_surrendered)


# --- Public API ---


## Get the full relationship dictionary between two entities.
## Returns a dictionary with all dimensions, defaulting to zero.
func get_relationship(from_id: String, to_id: String) -> Dictionary:
	if _relationships.has(from_id) and _relationships[from_id].has(to_id):
		return _relationships[from_id][to_id].duplicate()
	return _make_default_relationship()


## Modify a single dimension of a relationship by a delta amount.
## Clamps to the dimension's valid range and emits signals.
func modify_relationship(from_id: String, to_id: String, dimension: String, delta: float) -> void:
	if not DIMENSIONS.has(dimension):
		push_warning("RelationshipManager: Unknown dimension '%s'" % dimension)
		return

	_ensure_relationship_exists(from_id, to_id)

	var dim_range: Dictionary = DIMENSIONS[dimension]
	var old_val: float = _relationships[from_id][to_id][dimension]
	var new_val: float = clampf(old_val + delta, dim_range.min, dim_range.max)

	if is_equal_approx(old_val, new_val):
		return

	_relationships[from_id][to_id][dimension] = new_val
	relationship_changed.emit(from_id, to_id, dimension, old_val, new_val)

	# Check threshold crossings
	_check_threshold_crossings(from_id, to_id, dimension, old_val, new_val)

	# Sync overall disposition to GameState for backward compat
	_sync_disposition_to_game_state(from_id, to_id)


## Set a dimension to an absolute value (clamped).
func set_relationship(from_id: String, to_id: String, dimension: String, value: float) -> void:
	if not DIMENSIONS.has(dimension):
		push_warning("RelationshipManager: Unknown dimension '%s'" % dimension)
		return

	_ensure_relationship_exists(from_id, to_id)

	var dim_range: Dictionary = DIMENSIONS[dimension]
	var old_val: float = _relationships[from_id][to_id][dimension]
	var new_val: float = clampf(value, dim_range.min, dim_range.max)

	if is_equal_approx(old_val, new_val):
		return

	_relationships[from_id][to_id][dimension] = new_val
	relationship_changed.emit(from_id, to_id, dimension, old_val, new_val)
	_check_threshold_crossings(from_id, to_id, dimension, old_val, new_val)
	_sync_disposition_to_game_state(from_id, to_id)


## Get the overall disposition as a single float (-1.0 to 1.0).
## Weighted average of all dimensions for backward compatibility.
func get_overall_disposition(from_id: String, to_id: String) -> float:
	var rel: Dictionary = get_relationship(from_id, to_id)
	var total: float = 0.0
	var weight_sum: float = 0.0

	for dim: String in DISPOSITION_WEIGHTS:
		var weight: float = absf(DISPOSITION_WEIGHTS[dim])
		var sign_mult: float = signf(DISPOSITION_WEIGHTS[dim])
		total += rel[dim] * sign_mult * weight
		weight_sum += weight

	if weight_sum > 0.0:
		return clampf(total / weight_sum, -1.0, 1.0)
	return 0.0


## Get a human-readable opinion string for how an NPC feels about the player.
func get_npc_opinion_of_player(npc_id: String) -> String:
	var rel: Dictionary = get_relationship(npc_id, "player")
	var fragments: Array[String] = []

	# Trust
	if rel.trust > 0.5:
		fragments.append("They trust you deeply")
	elif rel.trust > 0.2:
		fragments.append("They trust you somewhat")
	elif rel.trust < -0.5:
		fragments.append("They deeply distrust you")
	elif rel.trust < -0.2:
		fragments.append("They are wary of your word")

	# Affection
	if rel.affection > 0.5:
		fragments.append("they hold great affection for you")
	elif rel.affection > 0.2:
		fragments.append("they have a certain fondness for you")
	elif rel.affection < -0.5:
		fragments.append("they despise you")
	elif rel.affection < -0.2:
		fragments.append("they dislike you")

	# Respect
	if rel.respect > 0.5:
		fragments.append("they hold you in high regard")
	elif rel.respect > 0.2:
		fragments.append("they see some worth in your abilities")
	elif rel.respect < -0.5:
		fragments.append("they see you as beneath contempt")
	elif rel.respect < -0.2:
		fragments.append("they question your competence")

	# Fear
	if rel.fear > 0.6:
		fragments.append("but they are terrified of you")
	elif rel.fear > 0.4:
		fragments.append("but they fear your methods")
	elif rel.fear > 0.25:
		fragments.append("you make them uneasy")

	# Debt
	if rel.debt > 0.5:
		fragments.append("they feel deeply indebted to you")
	elif rel.debt > 0.2:
		fragments.append("they feel they owe you")
	elif rel.debt < -0.5:
		fragments.append("they feel you owe them greatly")
	elif rel.debt < -0.2:
		fragments.append("they feel you owe them")

	if fragments.is_empty():
		return "They have no strong feelings about you"

	# Capitalize the first fragment and join
	fragments[0] = fragments[0].capitalize()
	if fragments.size() == 1:
		return fragments[0]

	# Join with commas and "and" for the last item
	var last: String = fragments[-1]
	var rest: Array[String] = []
	for i in range(fragments.size() - 1):
		rest.append(fragments[i])
	return ", ".join(PackedStringArray(rest)) + " — " + last


## Find all NPCs whose relationship with from_id has dimension >= min_val.
func get_npcs_with_threshold(dimension: String, min_val: float, from_id: String) -> Array[String]:
	var result: Array[String] = []
	if not DIMENSIONS.has(dimension):
		push_warning("RelationshipManager: Unknown dimension '%s'" % dimension)
		return result

	if not _relationships.has(from_id):
		return result

	for to_id: String in _relationships[from_id]:
		var val: float = _relationships[from_id][to_id].get(dimension, 0.0)
		if val >= min_val:
			result.append(to_id)

	return result


## Record a relationship event in history.
func record_event(from_id: String, to_id: String, event: String, impact: Dictionary) -> void:
	if not _history.has(from_id):
		_history[from_id] = {}
	if not _history[from_id].has(to_id):
		_history[from_id][to_id] = []

	var current_day: int = GameState.get_state("time.day", 1)
	_history[from_id][to_id].append({
		"event": event,
		"day": current_day,
		"impact": impact.duplicate(),
	})

	# Trim history if too long
	if _history[from_id][to_id].size() > MAX_HISTORY_PER_PAIR:
		_history[from_id][to_id] = _history[from_id][to_id].slice(-MAX_HISTORY_PER_PAIR)


## Get the event history between two entities.
func get_history(from_id: String, to_id: String) -> Array:
	if _history.has(from_id) and _history[from_id].has(to_id):
		return _history[from_id][to_id].duplicate(true)
	return []


## Apply a relationship change and record it in history simultaneously.
func apply_event(from_id: String, to_id: String, event: String, changes: Dictionary) -> void:
	for dimension: String in changes:
		modify_relationship(from_id, to_id, dimension, changes[dimension])
	record_event(from_id, to_id, event, changes)


## Gossip propagation: listener adjusts opinion of about_id based on source's opinion,
## weighted by how much listener trusts source.
func propagate_opinion(source_npc: String, listener_npc: String, about_id: String) -> void:
	var listener_trust_of_source: float = get_relationship(listener_npc, source_npc).trust
	if is_equal_approx(listener_trust_of_source, 0.0):
		return  # Listener doesn't care what source thinks

	var source_opinion: Dictionary = get_relationship(source_npc, about_id)
	var propagation_strength: float = listener_trust_of_source * 0.3  # Cap influence at 30% of trust

	var changes: Dictionary = {}
	for dim: String in ["trust", "affection", "respect"]:
		var source_val: float = source_opinion[dim]
		if not is_equal_approx(source_val, 0.0):
			var delta: float = source_val * propagation_strength
			changes[dim] = delta
			modify_relationship(listener_npc, about_id, dim, delta)

	# Fear is propagated differently — hearing that someone is dangerous increases fear
	if source_opinion.fear > 0.3:
		var fear_delta: float = source_opinion.fear * absf(propagation_strength) * 0.5
		changes["fear"] = fear_delta
		modify_relationship(listener_npc, about_id, "fear", fear_delta)

	if not changes.is_empty():
		record_event(listener_npc, about_id, "gossip_from_%s" % source_npc, changes)


## Remove all relationships involving a specific entity (e.g., on NPC death).
func remove_entity(entity_id: String) -> void:
	_relationships.erase(entity_id)
	_history.erase(entity_id)
	for from_id: String in _relationships:
		_relationships[from_id].erase(entity_id)
	for from_id: String in _history:
		_history[from_id].erase(entity_id)


## Serialize all relationship data for saving.
func serialize() -> Dictionary:
	return {
		"relationships": _relationships.duplicate(true),
		"history": _history.duplicate(true),
	}


## Deserialize relationship data from a save.
func deserialize(data: Dictionary) -> void:
	_relationships = data.get("relationships", {}).duplicate(true)
	_history = data.get("history", {}).duplicate(true)

	# Re-sync all dispositions to GameState
	for from_id: String in _relationships:
		for to_id: String in _relationships[from_id]:
			_sync_disposition_to_game_state(from_id, to_id)


## Reset all relationships to empty state.
func reset() -> void:
	_relationships.clear()
	_history.clear()


# --- Private ---


## Create a default zero-value relationship dictionary.
func _make_default_relationship() -> Dictionary:
	return {
		"trust": 0.0,
		"affection": 0.0,
		"respect": 0.0,
		"fear": 0.0,
		"debt": 0.0,
	}


## Ensure the relationship entry exists in the nested dictionary.
func _ensure_relationship_exists(from_id: String, to_id: String) -> void:
	if not _relationships.has(from_id):
		_relationships[from_id] = {}
	if not _relationships[from_id].has(to_id):
		_relationships[from_id][to_id] = _make_default_relationship()


## Sync the overall disposition to GameState for backward compatibility.
func _sync_disposition_to_game_state(from_id: String, to_id: String) -> void:
	var disposition: float = get_overall_disposition(from_id, to_id)
	# Only sync NPC->player dispositions to the standard GameState key
	if to_id == "player":
		GameState.set_state("npc.%s.disposition" % from_id, disposition)


## Check if any named thresholds were crossed and emit signals.
func _check_threshold_crossings(from_id: String, to_id: String, dimension: String, old_val: float, new_val: float) -> void:
	var thresholds: Dictionary = FEAR_THRESHOLDS if dimension == "fear" else THRESHOLDS

	for threshold_name: String in thresholds:
		var threshold_val: float = thresholds[threshold_name]
		var crossed_up: bool = old_val < threshold_val and new_val >= threshold_val
		var crossed_down: bool = old_val >= threshold_val and new_val < threshold_val
		if crossed_up or crossed_down:
			relationship_threshold_crossed.emit(from_id, to_id, dimension, threshold_name)


# --- EventBus Handlers ---


func _on_npc_died(npc_id: String, killer: String) -> void:
	if killer == "player" or killer == "":
		# Other NPCs who were close to the deceased may resent the player
		if not _relationships.has(npc_id):
			return
		# Check who had positive affection toward the dead NPC
		for from_id: String in _relationships:
			if from_id == npc_id or from_id == "player":
				continue
			var rel_to_dead: Dictionary = get_relationship(from_id, npc_id)
			if rel_to_dead.affection > 0.2 and killer == "player":
				var grief_penalty: float = -rel_to_dead.affection * 0.5
				apply_event(from_id, "player", "killed_%s" % npc_id, {
					"affection": grief_penalty,
					"trust": grief_penalty * 0.5,
					"fear": rel_to_dead.affection * 0.3,
				})


func _on_dialogue_choice_made(dialogue_id: String, choice_id: String) -> void:
	# Dialogue systems should call apply_event directly for specific impacts.
	# This handler exists for any global dialogue-driven relationship hooks.
	pass


func _on_quest_completed(quest_id: String, ending: String) -> void:
	# Quest completion can be hooked into by external systems calling apply_event.
	pass


func _on_quest_failed(quest_id: String, reason: String) -> void:
	# Quest failure can be hooked into by external systems calling apply_event.
	pass


func _on_enemy_defeated(enemy_id: String, was_spared: bool) -> void:
	if was_spared:
		# Sparing an enemy improves their view of the player
		apply_event(enemy_id, "player", "spared_in_combat", {
			"affection": 0.15,
			"respect": 0.1,
			"fear": 0.1,
			"debt": 0.2,
		})
	else:
		# Defeating (killing) an enemy — witnesses may react via _on_npc_died
		pass


func _on_enemy_surrendered(enemy_id: String) -> void:
	# Surrendered enemy fears the player more
	apply_event(enemy_id, "player", "surrendered_to_player", {
		"fear": 0.2,
		"respect": 0.1,
	})
