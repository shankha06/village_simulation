## InteractPrompt — floating "E" indicator that appears above the nearest
## interactable object when the player is within range.
## Attach as a child of the player scene or add via code.
extends Node2D

const BOB_AMPLITUDE: float = 3.0
const BOB_SPEED: float = 3.0
const OFFSET_Y: float = -24.0  # Above the interactable

var _label: Label
var _bg: ColorRect
var _bob_time: float = 0.0
var _target: Node2D = null
var _player: Node2D = null


func _ready() -> void:
	# Build the prompt visually: a small dark rounded panel with gold "E" text.
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(18, 18)
	panel.position = Vector2(-9, -9)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.06, 0.04, 0.85)
	style.border_color = Color(0.855, 0.69, 0.28, 0.6)
	style.set_border_width_all(1)
	style.set_corner_radius_all(9)  # Fully rounded corners for circle look
	style.content_margin_left = 0
	style.content_margin_right = 0
	style.content_margin_top = 0
	style.content_margin_bottom = 0
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)

	_label = Label.new()
	_label.text = "E"
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 11)
	_label.add_theme_color_override("font_color", Color(0.855, 0.69, 0.28, 1.0))
	_label.size = Vector2(18, 18)
	_label.position = Vector2(-9, -11)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_label)

	visible = false
	# We are top-level so we aren't affected by parent transforms
	top_level = true


func _process(delta: float) -> void:
	if _player == null:
		_player = get_tree().get_first_node_in_group("player")
		if _player == null:
			visible = false
			return

	# Find nearest interactable from player's list.
	_target = _get_nearest_interactable()

	if _target == null or not is_instance_valid(_target):
		visible = false
		return

	visible = true
	_bob_time += delta * BOB_SPEED
	var bob_offset: float = sin(_bob_time) * BOB_AMPLITUDE
	global_position = _target.global_position + Vector2(0, OFFSET_Y + bob_offset)


func _get_nearest_interactable() -> Node2D:
	if _player == null:
		return null

	# Access the player's _nearby_interactables array.
	if not "_nearby_interactables" in _player:
		return null

	var nearby: Array = _player._nearby_interactables
	if nearby.is_empty():
		return null

	var closest: Node2D = null
	var closest_dist: float = INF
	for node in nearby:
		if not is_instance_valid(node):
			continue
		if node is Node2D:
			var dist: float = _player.global_position.distance_squared_to(node.global_position)
			if dist < closest_dist:
				closest = node
				closest_dist = dist

	return closest
