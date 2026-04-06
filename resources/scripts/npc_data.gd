## NPCData — resource defining an NPC's identity, personality, schedule, and dialogue pools.
class_name NPCData
extends Resource

@export var npc_id: String = ""
@export var display_name: String = ""
@export var description: String = ""

# Personality traits (0.0 to 1.0)
@export_group("Personality")
@export_range(0.0, 1.0) var courage: float = 0.5
@export_range(0.0, 1.0) var greed: float = 0.5
@export_range(0.0, 1.0) var loyalty: float = 0.5
@export_range(0.0, 1.0) var cruelty: float = 0.5
@export_range(0.0, 1.0) var curiosity: float = 0.5
@export_range(0.0, 1.0) var honesty: float = 0.5

# Visual
@export_group("Visual")
@export var sprite_sheet: Texture2D
@export var portrait_neutral: Texture2D
@export var portrait_happy: Texture2D
@export var portrait_angry: Texture2D
@export var portrait_sad: Texture2D
@export var portrait_fearful: Texture2D

# Schedule: array of {hour: int, location_id: String, activity: String}
@export_group("Schedule")
@export var schedule: Array[Dictionary] = []
@export var home_location: String = ""
@export var faction_id: String = ""

# Dialogue pools: {context_key: dialogue_file_id}
@export_group("Dialogue")
@export var dialogue_pools: Dictionary = {}
@export var default_greeting: String = ""

# Combat stats (if applicable)
@export_group("Combat")
@export var is_combatant: bool = false
@export var max_health: float = 50.0
@export var attack_damage: float = 5.0
@export var can_surrender: bool = true

# Relationships with other NPCs: {npc_id: affinity}
@export_group("Relationships")
@export var npc_relationships: Dictionary = {}


## Get the portrait texture for a given mood.
func get_portrait(mood: String = "neutral") -> Texture2D:
	match mood:
		"happy":
			return portrait_happy if portrait_happy else portrait_neutral
		"angry":
			return portrait_angry if portrait_angry else portrait_neutral
		"sad":
			return portrait_sad if portrait_sad else portrait_neutral
		"fearful":
			return portrait_fearful if portrait_fearful else portrait_neutral
		_:
			return portrait_neutral


## Get the schedule entry for a given hour.
func get_schedule_for_hour(hour: int) -> Dictionary:
	var best: Dictionary = {}
	for entry in schedule:
		if entry.get("hour", 0) <= hour:
			best = entry
	# If no entry found, use the last one (wrap around)
	if best.is_empty() and not schedule.is_empty():
		best = schedule.back()
	return best
