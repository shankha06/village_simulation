## TransitionZone — triggers scene transitions when the player enters.
extends Area2D

@export var target_scene: String = ""  # e.g. "res://scenes/world/thornwood_forest.tscn"
@export var spawn_point: String = "default"  # Spawn point ID in target scene
@export var require_confirmation: bool = false
@export var locked: bool = false
@export var lock_condition: String = ""  # GameState condition to unlock


func _ready() -> void:
	add_to_group("transition_zones")
	collision_layer = 32  # Layer 6: TransitionZones
	collision_mask = 1    # Layer 1: Player
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return

	# Check lock
	if locked:
		if lock_condition != "" and GameState.evaluate_condition(lock_condition):
			locked = false
		else:
			EventBus.notification_requested.emit("This path is blocked.", "info")
			return

	if target_scene == "":
		return

	if require_confirmation:
		# In full implementation: show confirmation dialog
		EventBus.notification_requested.emit("Travel to next area? [E]", "info")
		return

	EventBus.scene_transition_requested.emit(target_scene, spawn_point)
