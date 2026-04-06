## DamageNumber — floating label that shows damage/healing at a hit position.
## Spawns, floats upward, fades out, then frees itself.
## Color-coded: red for damage, green for healing.
## Created via `DamageNumber.new()` then `setup()` — no scene file needed.
extends Node2D

# Tween parameters
const FLOAT_DISTANCE: float = 24.0
const FLOAT_DURATION: float = 0.8
const FADE_DELAY: float = 0.3
const FONT_SIZE: int = 10
const CRIT_FONT_SIZE: int = 14
const CRIT_THRESHOLD: float = 15.0

# Colors
const COLOR_DAMAGE: Color = Color(0.9, 0.2, 0.15)
const COLOR_HEAL: Color = Color(0.2, 0.85, 0.3)
const COLOR_CRIT: Color = Color(1.0, 0.85, 0.1)

var _amount: float = 0.0
var _is_heal: bool = false
var _label: Label = null


## Call after new() to configure the damage number before it enters the tree.
func setup(amount: float, world_position: Vector2, is_heal: bool = false) -> void:
	_amount = amount
	_is_heal = is_heal
	global_position = world_position


func _ready() -> void:
	# Build the Label node
	_label = Label.new()
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	# Display text
	var display_text: String = ""
	if _is_heal:
		display_text = "+%d" % int(_amount)
		_label.modulate = COLOR_HEAL
	else:
		display_text = "%d" % int(_amount)
		if _amount >= CRIT_THRESHOLD:
			_label.modulate = COLOR_CRIT
		else:
			_label.modulate = COLOR_DAMAGE

	_label.text = display_text

	# Center the label
	_label.position = Vector2(-20, -8)
	_label.size = Vector2(40, 16)

	# Font size override
	var size: int = CRIT_FONT_SIZE if _amount >= CRIT_THRESHOLD else FONT_SIZE
	_label.add_theme_font_size_override("font_size", size)

	add_child(_label)

	# Small random horizontal offset for visual variety
	var x_offset: float = randf_range(-6.0, 6.0)
	position.x += x_offset

	# Animate: float up and fade out
	_animate()


func _animate() -> void:
	var tween: Tween = create_tween()
	tween.set_parallel(true)

	# Float upward
	tween.tween_property(self, "position:y", position.y - FLOAT_DISTANCE, FLOAT_DURATION) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)

	# Slight scale pop for impact feel
	if _amount >= CRIT_THRESHOLD:
		scale = Vector2(1.3, 1.3)
		tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.2) \
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

	# Fade out after a brief delay
	tween.tween_property(_label, "modulate:a", 0.0, FLOAT_DURATION - FADE_DELAY) \
		.set_delay(FADE_DELAY) \
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)

	# Free when done
	tween.chain().tween_callback(queue_free)
