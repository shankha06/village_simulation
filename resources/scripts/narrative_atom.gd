## NarrativeAtom — a modular story event template that can be assembled procedurally.
class_name NarrativeAtom
extends Resource

@export var atom_id: String = ""
@export var description: String = ""

# Conditions for this atom to be eligible
@export var conditions: Array[String] = []

# Priority: higher = selected first when multiple atoms are eligible
@export var priority: int = 0

# The dialogue tree ID this atom triggers
@export var dialogue_id: String = ""

# Effects triggered when this atom fires
@export var effects: Array[Dictionary] = []

# Cooldown in days before this atom can fire again
@export var cooldown_days: int = 0

# Tags for filtering
@export var tags: PackedStringArray = []
