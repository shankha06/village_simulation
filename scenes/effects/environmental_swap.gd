## EnvironmentalSwap — component that listens for visual swap signals
## and toggles child node visibility based on world state.
## Attach to a Node2D parent that contains variant children.
extends Node

@export var swap_id: String = ""
@export var state_key: String = ""  # GameState key to watch, e.g. "world.region.ashvale.silo_visual"
@export var default_variant: String = "default"

# Maps variant names to child node names
@export var variant_nodes: Dictionary = {}  # e.g. {"default": "SiloNormal", "destroyed": "SiloDestroyed"}


func _ready() -> void:
	EventBus.visual_swap_requested.connect(_on_swap_requested)
	GameState.state_changed.connect(_on_state_changed)

	# Apply initial state
	var current: String = GameState.get_state(state_key, default_variant)
	_apply_variant(current)


func _apply_variant(variant: String) -> void:
	var parent: Node = get_parent()
	if parent == null:
		return

	for var_name in variant_nodes:
		var node: Node = parent.get_node_or_null(variant_nodes[var_name])
		if node:
			node.visible = (var_name == variant)


func _on_swap_requested(requested_id: String, variant: String) -> void:
	if requested_id == swap_id:
		_apply_variant(variant)


func _on_state_changed(key: String, _old: Variant, new_value: Variant) -> void:
	if key == state_key and new_value is String:
		_apply_variant(new_value)
