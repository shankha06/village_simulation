## DayNightCycle — CanvasModulate that tints the entire scene based on TimeManager.
## Attach as a child of any Node2D parent (e.g. WorldContainer or region root).
extends CanvasModulate

## Tint colours for each time period.
const COLOR_DAWN  := Color(1.0, 0.9, 0.8)
const COLOR_DAY   := Color(1.0, 1.0, 1.0)
const COLOR_DUSK  := Color(0.9, 0.7, 0.6)
const COLOR_NIGHT := Color(0.4, 0.4, 0.6)

## Duration (in real seconds) for the lerp between tints.
@export var transition_speed: float = 2.0

var _target_color: Color = COLOR_DAY


func _ready() -> void:
	# Set initial tint immediately.
	_target_color = _color_for_period(TimeManager.get_time_period())
	color = _target_color

	# React to time-of-day changes broadcast by TimeManager via EventBus.
	EventBus.time_of_day_changed.connect(_on_time_of_day_changed)


func _process(delta: float) -> void:
	# Smoothly interpolate toward the target tint.
	if not color.is_equal_approx(_target_color):
		var weight: float = clampf(delta / transition_speed, 0.0, 1.0)
		color = color.lerp(_target_color, weight)


func _on_time_of_day_changed(period: String) -> void:
	_target_color = _color_for_period(period)


## Map a period name to its tint color.
func _color_for_period(period: String) -> Color:
	match period:
		"dawn":
			return COLOR_DAWN
		"day":
			return COLOR_DAY
		"dusk":
			return COLOR_DUSK
		"night":
			return COLOR_NIGHT
		_:
			return COLOR_DAY
