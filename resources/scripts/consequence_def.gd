## ConsequenceDef — resource defining a consequence chain.
class_name ConsequenceDef
extends Resource

@export var chain_id: String = ""
@export var description: String = ""
@export var trigger_condition: String = ""  # GameState condition to auto-activate

# Array of consequence steps
# Each: {type: "immediate"|"delayed"|"conditional_delayed"|"threshold",
#         delay_days: int, condition: String, effects: Array[Dictionary]}
@export var consequences: Array[Dictionary] = []
