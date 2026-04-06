## ExaminePopup — displays examination text for world interactable objects.
## A dark panel at the bottom of the screen with typewriter text reveal.
## Press E (interact) to dismiss.
extends CanvasLayer

const TEXT_SPEED: float = 35.0  # Characters per second

@onready var panel: PanelContainer = $Panel
@onready var header_label: Label = $Panel/MarginContainer/VBox/Header
@onready var text_label: RichTextLabel = $Panel/MarginContainer/VBox/ExamineText
@onready var dismiss_hint: Label = $Panel/MarginContainer/VBox/DismissHint

var _full_text: String = ""
var _is_revealing: bool = false
var _is_visible: bool = false
var _reveal_tween: Tween = null


func _ready() -> void:
	layer = 25
	visible = false
	if panel:
		panel.visible = false

	EventBus.examine_requested.connect(_on_examine_requested)


func _unhandled_input(event: InputEvent) -> void:
	if not _is_visible:
		return

	if event.is_action_pressed("interact") or event.is_action_pressed("attack"):
		get_viewport().set_input_as_handled()
		if _is_revealing:
			_skip_reveal()
		else:
			_close()


func _on_examine_requested(header: String, text: String) -> void:
	_full_text = text
	_is_visible = true
	visible = true
	if panel:
		panel.visible = true

	if header_label:
		header_label.text = header

	if text_label:
		text_label.text = _full_text
		text_label.visible_characters = 0

	if dismiss_hint:
		dismiss_hint.visible = false

	# Start typewriter reveal.
	_is_revealing = true
	var char_count: int = _full_text.length()
	var duration: float = char_count / TEXT_SPEED

	if _reveal_tween and _reveal_tween.is_valid():
		_reveal_tween.kill()

	_reveal_tween = create_tween()
	_reveal_tween.tween_method(_set_visible_chars, 0, char_count, duration)
	_reveal_tween.finished.connect(_on_reveal_finished)


func _set_visible_chars(count: int) -> void:
	if text_label:
		text_label.visible_characters = count


func _skip_reveal() -> void:
	_is_revealing = false
	if _reveal_tween and _reveal_tween.is_valid():
		_reveal_tween.kill()
	if text_label:
		text_label.visible_characters = -1
	_on_reveal_finished()


func _on_reveal_finished() -> void:
	_is_revealing = false
	if dismiss_hint:
		dismiss_hint.visible = true


func _close() -> void:
	_is_visible = false
	visible = false
	if panel:
		panel.visible = false
	_is_revealing = false

	# Return control to player.
	var player: Node = get_tree().get_first_node_in_group("player")
	if player and player.has_method("end_interaction"):
		player.end_interaction()
