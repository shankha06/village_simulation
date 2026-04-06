## QuestTemplate — resource defining a quest's FSM structure.
class_name QuestTemplate
extends Resource

@export var quest_id: String = ""
@export var quest_name: String = ""
@export var description: String = ""
@export var giver_npc: String = ""  # NPC ID of quest giver
@export var region: String = ""     # Region where quest starts

# FSM states: {state_name: {journal_entry, objectives, transitions, consequence_chain, rewards}}
@export var states: Dictionary = {}

# Tags for categorization
@export var tags: PackedStringArray = []

# Priority for quest selection (higher = more likely to be offered)
@export var priority: int = 0
