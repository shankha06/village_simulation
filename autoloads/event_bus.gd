## Global signal hub for decoupled system communication.
## Any system can emit or connect to these signals without direct references.
extends Node

# --- Player Signals ---
signal player_entered_region(region_id: String)
signal player_exited_region(region_id: String)
signal player_interacted(target: Node)
signal player_died
signal player_took_damage(amount: float, source: String)
signal player_healed(amount: float)

# --- NPC Signals ---
signal npc_died(npc_id: String, killer: String)
signal npc_spotted_player(npc_id: String)
signal npc_mood_changed(npc_id: String, new_mood: String)
signal npc_schedule_arrived(npc_id: String, location: String)
signal npc_started_dialogue(npc_id: String)
signal npc_ended_dialogue(npc_id: String)

# --- Dialogue Signals ---
signal dialogue_started(dialogue_id: String)
signal dialogue_ended(dialogue_id: String)
signal dialogue_choice_made(dialogue_id: String, choice_id: String)
signal dialogue_node_entered(dialogue_id: String, node_id: String)

# --- Quest Signals ---
signal quest_discovered(quest_id: String)
signal quest_state_changed(quest_id: String, old_state: String, new_state: String)
signal quest_objective_updated(quest_id: String, objective_idx: int)
signal quest_completed(quest_id: String, ending: String)
signal quest_failed(quest_id: String, reason: String)

# --- World Signals ---
signal region_status_changed(region_id: String, old_status: String, new_status: String)
signal faction_reputation_changed(faction_id: String, old_rep: int, new_rep: int)
signal faction_power_changed(faction_id: String, old_power: float, new_power: float)
signal economy_price_changed(region_id: String, item_id: String, new_price: float)
signal ecology_population_changed(region_id: String, species: String, new_pop: float)
signal rumor_spread(rumor_id: String, from_region: String, to_region: String)
signal visual_swap_requested(swap_id: String, variant: String)

# --- Combat Signals ---
signal combat_started(enemies: Array)
signal combat_ended(result: String)
signal enemy_defeated(enemy_id: String, was_spared: bool)
signal enemy_surrendered(enemy_id: String)

# --- Time Signals ---
signal time_of_day_changed(period: String)  # "dawn", "day", "dusk", "night"
signal weather_changed(new_weather: String)

# --- UI Signals ---
signal notification_requested(text: String, type: String)
signal journal_entry_added(entry_id: String)
signal codex_entry_unlocked(entry_id: String)
signal cliffhanger_triggered(text: String)
signal examine_requested(header: String, text: String)

# --- Save/Load Signals ---
signal save_requested(slot: int)
signal load_requested(slot: int)
signal save_completed(slot: int)
signal load_completed(slot: int)

# --- Scene Management ---
signal scene_transition_requested(target_scene: String, spawn_point: String)
signal scene_transition_started
signal scene_transition_completed
