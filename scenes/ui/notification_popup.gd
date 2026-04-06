## Toast notification system -- shows queued pop-up messages at the bottom of
## the screen with style variants for quest, item, lore, warning, and world events.
## Auto-dismisses after a configurable duration.
extends CanvasLayer

const DISPLAY_DURATION: float = 3.0
const FADE_DURATION: float = 0.4
const SLIDE_DISTANCE: float = 20.0
const MAX_VISIBLE: int = 3

## Style colours keyed by notification type.
const STYLE_COLORS: Dictionary = {
	"quest":       Color(0.3, 0.55, 0.9, 1.0),   # blue
	"item":        Color(0.3, 0.8, 0.35, 1.0),    # green
	"lore":        Color(0.9, 0.75, 0.25, 1.0),   # gold
	"warning":     Color(0.9, 0.25, 0.25, 1.0),   # red
	"world_event": Color(0.55, 0.12, 0.12, 1.0),  # dark red
}

const DEFAULT_COLOR: Color = Color(0.7, 0.7, 0.7, 1.0)

# Notification queue: Array of {text: String, type: String}
var _queue: Array[Dictionary] = []

# Currently visible labels (oldest first).
var _active: Array[Dictionary] = []  # [{label: Label, timer: float, fading: bool}]

# Container for the notification labels.
var _container: VBoxContainer


func _ready() -> void:
	layer = 50
	_build_ui()
	EventBus.notification_requested.connect(_on_notification_requested)


func _process(delta: float) -> void:
	# Tick active notifications.
	var i: int = _active.size() - 1
	while i >= 0:
		var entry: Dictionary = _active[i]
		entry.timer -= delta
		if entry.timer <= 0.0 and not entry.fading:
			_start_fade(entry)
		i -= 1

	# Spawn queued notifications if there is room.
	while _queue.size() > 0 and _active.size() < MAX_VISIBLE:
		var next: Dictionary = _queue.pop_front()
		_spawn_notification(next.text, next.type)


# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

## Enqueue a notification to be shown.
func show_notification(text: String, type: String = "item") -> void:
	_queue.append({"text": text, "type": type})


# ---------------------------------------------------------------------------
# Private
# ---------------------------------------------------------------------------

func _build_ui() -> void:
	_container = VBoxContainer.new()
	_container.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_container.offset_top = -100.0
	_container.offset_bottom = -12.0
	_container.offset_left = 80.0
	_container.offset_right = -80.0
	_container.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_container.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_container.alignment = BoxContainer.ALIGNMENT_END
	_container.add_theme_constant_override("separation", 4)
	add_child(_container)


func _spawn_notification(text: String, type: String) -> void:
	var label := Label.new()
	label.text = "  %s  " % text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 11)

	var color: Color = STYLE_COLORS.get(type, DEFAULT_COLOR)
	label.add_theme_color_override("font_color", color)

	# Slight background via a StyleBoxFlat.
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.05, 0.08, 0.85)
	style.border_color = color * Color(1, 1, 1, 0.5)
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	style.set_content_margin_all(4)
	label.add_theme_stylebox_override("normal", style)

	# Start transparent for slide-in.
	label.modulate.a = 0.0
	label.position.y += SLIDE_DISTANCE
	_container.add_child(label)

	var entry: Dictionary = {
		"label": label,
		"timer": DISPLAY_DURATION,
		"fading": false,
	}
	_active.append(entry)

	# Animate in.
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "modulate:a", 1.0, FADE_DURATION)
	tween.tween_property(label, "position:y", 0.0, FADE_DURATION).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)


func _start_fade(entry: Dictionary) -> void:
	entry.fading = true
	var label: Label = entry.label
	var tween := create_tween()
	tween.tween_property(label, "modulate:a", 0.0, FADE_DURATION)
	tween.tween_callback(_remove_entry.bind(entry))


func _remove_entry(entry: Dictionary) -> void:
	var label: Label = entry.label
	if is_instance_valid(label):
		label.queue_free()
	_active.erase(entry)


func _on_notification_requested(text: String, type: String) -> void:
	show_notification(text, type)
