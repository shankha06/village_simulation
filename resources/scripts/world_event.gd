## WorldEvent — a significant world event that changes region state.
class_name WorldEvent
extends Resource

@export var event_id: String = ""
@export var display_name: String = ""
@export var description: String = ""

# Region this event affects
@export var region_id: String = ""

# Conditions for event to trigger
@export var conditions: Array[String] = []

# Effects when event fires
@export var effects: Array[Dictionary] = []

# Visual changes
@export var visual_swaps: Dictionary = {}  # {swap_id: variant}

# Notification text shown to player
@export var notification_text: String = ""
