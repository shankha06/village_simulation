## Quest Manager — FSM-based quest engine.
## Each quest is a finite state machine with states, transitions, and consequences.
## Quests can update silently in the background based on world state changes.
extends Node

# All registered quest definitions: {quest_id: quest_data}
var _quest_defs: Dictionary = {}

# Active quest states: {quest_id: current_state_name}
var _quest_states: Dictionary = {}

# Quest history log: tracks all state transitions for journal
var _quest_log: Array[Dictionary] = []


func _ready() -> void:
	GameState.state_changed.connect(_on_state_changed)


## Load quest definitions from JSON data array.
func load_quests(quests: Array) -> void:
	for quest_data in quests:
		var qid: String = quest_data.id
		_quest_defs[qid] = quest_data
		# All quests start in UNKNOWN state unless already loaded from save
		if not _quest_states.has(qid):
			_quest_states[qid] = "UNKNOWN"
			GameState.set_state("quest.%s.state" % qid, "UNKNOWN")


## Get current state of a quest.
func get_quest_state(quest_id: String) -> String:
	return _quest_states.get(quest_id, "UNKNOWN")


## Check if a quest is in a terminal state (completed/failed).
func is_quest_finished(quest_id: String) -> bool:
	var state: String = get_quest_state(quest_id)
	return state.begins_with("COMPLETED") or state.begins_with("FAILED") or state == "ABANDONED"


## Check if a quest is currently active.
func is_quest_active(quest_id: String) -> bool:
	var state: String = get_quest_state(quest_id)
	return state != "UNKNOWN" and not is_quest_finished(quest_id)


## Force a quest to a specific state (for debugging or scripted events).
func force_quest_state(quest_id: String, new_state: String) -> void:
	_transition_quest(quest_id, new_state)


## Get all active quests.
func get_active_quests() -> Array[String]:
	var result: Array[String] = []
	for qid in _quest_states:
		if is_quest_active(qid):
			result.append(qid)
	return result


## Get all completed quests.
func get_completed_quests() -> Array[String]:
	var result: Array[String] = []
	for qid in _quest_states:
		if get_quest_state(qid).begins_with("COMPLETED"):
			result.append(qid)
	return result


## Get the quest definition data.
func get_quest_def(quest_id: String) -> Dictionary:
	return _quest_defs.get(quest_id, {})


## Get the current state data for a quest (journal entry, objectives, etc.)
func get_quest_state_data(quest_id: String) -> Dictionary:
	var qdef: Dictionary = _quest_defs.get(quest_id, {})
	var state: String = _quest_states.get(quest_id, "UNKNOWN")
	var states: Dictionary = qdef.get("states", {})
	return states.get(state, {})


## Get the quest log for journal display.
func get_quest_log() -> Array[Dictionary]:
	return _quest_log


## Serialize for saving.
func serialize() -> Dictionary:
	return {
		"quest_states": _quest_states.duplicate(),
		"quest_log": _quest_log.duplicate(true),
	}


## Deserialize from save.
func deserialize(data: Dictionary) -> void:
	_quest_states = data.get("quest_states", {})
	_quest_log = data.get("quest_log", [])
	# Sync states back to GameState
	for qid in _quest_states:
		GameState.set_state("quest.%s.state" % qid, _quest_states[qid])


# --- Private ---

func _transition_quest(quest_id: String, new_state: String) -> void:
	var old_state: String = _quest_states.get(quest_id, "UNKNOWN")
	if old_state == new_state:
		return

	_quest_states[quest_id] = new_state
	GameState.set_state("quest.%s.state" % quest_id, new_state)

	# Get state data for the new state
	var qdef: Dictionary = _quest_defs.get(quest_id, {})
	var state_data: Dictionary = qdef.get("states", {}).get(new_state, {})

	# Log the transition
	_quest_log.append({
		"quest_id": quest_id,
		"quest_name": qdef.get("name", quest_id),
		"from_state": old_state,
		"to_state": new_state,
		"journal_entry": state_data.get("journal_entry", ""),
		"day": TimeManager.day,
		"hour": TimeManager.hour,
	})

	# Emit signals
	if new_state == "DISCOVERED":
		EventBus.quest_discovered.emit(quest_id)
	elif new_state.begins_with("COMPLETED"):
		EventBus.quest_completed.emit(quest_id, new_state)
		# Process rewards
		_process_rewards(state_data.get("rewards", []))
	elif new_state.begins_with("FAILED"):
		EventBus.quest_failed.emit(quest_id, new_state)
	else:
		EventBus.quest_state_changed.emit(quest_id, old_state, new_state)

	# Trigger consequence chain if defined
	var chain_id: String = state_data.get("consequence_chain", "")
	if chain_id != "":
		WorldSimulation.activate_chain(chain_id)

	# Add journal notification
	var journal_entry: String = state_data.get("journal_entry", "")
	if journal_entry != "":
		EventBus.journal_entry_added.emit(quest_id)


func _process_rewards(rewards: Array) -> void:
	for reward in rewards:
		if not reward is Dictionary:
			continue
		if reward.has("give_item"):
			GameState.set_state("player.has_item.%s" % reward.give_item, true)
			EventBus.notification_requested.emit("Received: %s" % reward.give_item, "item")
		if reward.has("gold"):
			GameState.delta_state("player.gold", reward.gold)
			EventBus.notification_requested.emit("Received %d gold" % reward.gold, "gold")
		if reward.has("reputation"):
			for faction_id in reward.reputation:
				FactionManager.modify_player_rep(faction_id, reward.reputation[faction_id])


func _on_state_changed(key: String, _old: Variant, _new: Variant) -> void:
	# Check all quest transitions against the changed state
	for qid in _quest_defs:
		if is_quest_finished(qid):
			continue

		var current_state: String = _quest_states.get(qid, "UNKNOWN")
		var qdef: Dictionary = _quest_defs[qid]
		var state_data: Dictionary = qdef.get("states", {}).get(current_state, {})
		var transitions: Array = state_data.get("transitions", [])

		for transition in transitions:
			var condition: String = transition.get("on", "")
			if condition != "" and GameState.evaluate_condition(condition):
				_transition_quest(qid, transition.to)
				break  # Only one transition per state change per quest
