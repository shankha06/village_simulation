## Interactable — base class for all world objects the player can interact with.
## Supports examine, search, read, pickup, and door interaction types.
## Driven by data (JSON) and wired through EventBus.
extends Area2D
class_name Interactable

## Unique identifier for this interactable (e.g. "notice_board", "village_well").
@export var interact_id: String = ""

## Interaction type: examine, search, read, pickup, door.
@export var interact_type: String = "examine"

## Display name shown in the examine popup header.
@export var display_name: String = ""

## Primary text shown when player interacts.
@export var interaction_text: String = ""

## GameState condition string. When true, state_alt_text is shown instead.
@export var state_condition: String = ""

## Alternate text shown when state_condition evaluates to true.
@export var state_alt_text: String = ""

## If true, this interactable can only be used once.
@export var one_shot: bool = false

## Item ID to give the player on interaction (only when state_condition met for
## items gated behind conditions, or always if no condition).
@export var gives_item: String = ""

## Flag key to set in GameState when this object is interacted with.
@export var sets_flag: String = ""

## Required item — if the player doesn't have this, show locked_text instead.
@export var required_item: String = ""

## Text shown when the player lacks the required_item.
@export var locked_text: String = "You need something to interact with this."

# Internal: tracks whether a one_shot interactable has been used.
var _used: bool = false


func _ready() -> void:
	add_to_group("interactable")

	# Collision: layer 4 (Interactables), mask 0 (doesn't detect anything itself).
	collision_layer = 4
	collision_mask = 0
	monitorable = true
	monitoring = false

	# Create collision shape if none exists.
	if get_child_count() == 0 or not _has_collision_shape():
		var shape := CollisionShape2D.new()
		var circle := CircleShape2D.new()
		circle.radius = 16.0
		shape.shape = circle
		add_child(shape)

	# Listen for player interactions.
	EventBus.player_interacted.connect(_on_player_interacted)


func _has_collision_shape() -> bool:
	for child in get_children():
		if child is CollisionShape2D:
			return true
	return false


func _on_player_interacted(target: Node) -> void:
	if target != self:
		return

	# Restore one_shot state from GameState on first interaction check.
	if one_shot and GameState.get_state("interactable.%s.used" % interact_id, false):
		_used = true

	# Already used (one-shot)?
	if one_shot and _used:
		_show_examine("Nothing more of interest here.", interact_type)
		return

	# Required item check.
	if required_item != "":
		if not GameState.get_state("player.inventory.%s" % required_item, false):
			_show_examine(locked_text, interact_type)
			return

	# Determine which text to show.
	var text_to_show: String = interaction_text
	var condition_met: bool = false

	if state_condition != "":
		condition_met = GameState.evaluate_condition(state_condition)
		if condition_met and state_alt_text != "":
			text_to_show = state_alt_text

	# Set flags.
	if sets_flag != "":
		GameState.set_state(sets_flag, true)

	# Give items (only when condition is met if there's a condition, or always if none).
	if gives_item != "":
		var should_give: bool = true
		if state_condition != "" and not condition_met:
			should_give = false
		if should_give:
			GameState.set_state("player.inventory.%s" % gives_item, true)
			EventBus.notification_requested.emit("Obtained: %s" % gives_item.replace("_", " ").capitalize(), "item")

	# Mark as used for one-shot.
	if one_shot:
		_used = true
		GameState.set_state("interactable.%s.used" % interact_id, true)

	# Show the examine popup.
	_show_examine(text_to_show, interact_type)


func _show_examine(text: String, type: String) -> void:
	# Build a header based on type.
	var header: String = ""
	match type:
		"examine":
			header = "* Examine *"
		"read":
			header = "* %s *" % display_name if display_name != "" else "* Read *"
		"search":
			header = "* Search *"
		"pickup":
			header = "* Pick Up *"
		"door":
			header = "* %s *" % display_name if display_name != "" else "* Door *"
		_:
			header = "* %s *" % display_name if display_name != "" else "* Examine *"

	EventBus.examine_requested.emit(header, text)
