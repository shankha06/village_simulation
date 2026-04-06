## DialogueUI — displays dialogue text, portraits, and choices.
## Listens for dialogue_started signal and drives the conversation.
extends CanvasLayer

@onready var panel: PanelContainer = $Panel
@onready var portrait_rect: TextureRect = $Panel/HBox/Portrait
@onready var speaker_label: Label = $Panel/HBox/VBox/SpeakerName
@onready var text_label: RichTextLabel = $Panel/HBox/VBox/DialogueText
@onready var choices_container: VBoxContainer = $Panel/HBox/VBox/Choices
@onready var continue_indicator: Label = $Panel/HBox/VBox/ContinueIndicator

# Text reveal
var _full_text: String = ""
var _revealed_chars: int = 0
var _text_speed: float = 40.0  # Characters per second
var _is_revealing: bool = false
var _text_timer: float = 0.0
var _waiting_for_advance: bool = false

# Current node tracking
var _current_node_next: String = ""

# Choice buttons pool
var _choice_buttons: Array[Button] = []
const MAX_CHOICES: int = 6


func _ready() -> void:
	visible = false
	if panel:
		panel.visible = false

	# Pre-create choice buttons
	for i in range(MAX_CHOICES):
		var btn := Button.new()
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.pressed.connect(_on_choice_pressed.bind(i))
		if choices_container:
			choices_container.add_child(btn)
		btn.visible = false
		_choice_buttons.append(btn)

	if continue_indicator:
		continue_indicator.visible = false

	# Listen for dialogue events
	EventBus.dialogue_started.connect(_on_dialogue_started)
	EventBus.dialogue_ended.connect(_on_dialogue_ended)


func _process(_delta: float) -> void:
    # Logic moved to Tween-based reveal for better performance and smoother effect
	pass


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return

	if event.is_action_pressed("interact") or event.is_action_pressed("attack"):
		get_viewport().set_input_as_handled()

		if _is_revealing:
			# Skip text reveal — show full text immediately
			_skip_reveal()
		elif _waiting_for_advance:
			if choices_container and choices_container.visible and _has_visible_choices():
				return  # Waiting for player to click a choice
			_advance_dialogue()


func _skip_reveal() -> void:
	_is_revealing = false
	if text_label:
		text_label.visible_characters = -1
	_on_reveal_finished()


func _on_reveal_finished() -> void:
	_is_revealing = false
	_waiting_for_advance = true
	if continue_indicator:
		continue_indicator.visible = true
		# Gentle bounce animation for continue indicator
		var tween := create_tween().set_loops()
		tween.tween_property(continue_indicator, "position:y", continue_indicator.position.y + 4, 0.6).set_trans(Tween.TRANS_SINE)
		tween.tween_property(continue_indicator, "position:y", continue_indicator.position.y, 0.6).set_trans(Tween.TRANS_SINE)


## Display a dialogue node.
func show_node(node_data: Dictionary) -> void:
	if not visible:
		visible = true
		if panel:
			panel.modulate.a = 0.0
			var tween := create_tween()
			tween.tween_property(panel, "modulate:a", 1.0, 0.3)

	if panel:
		panel.visible = true
	if choices_container:
		choices_container.visible = false
	if continue_indicator:
		continue_indicator.visible = false
		_stop_indicator_anim()
	_hide_all_choices()
	_waiting_for_advance = false

	var node_type: String = node_data.get("type", "text")

	match node_type:
		"text", "":
			_show_text_node(node_data)
		"choice":
			_show_choice_node(node_data)
		"end":
			_close()


func _stop_indicator_anim() -> void:
	# Continuous loop kills previous tweens on the same object automatically in Godot 4
	pass


func _show_text_node(node_data: Dictionary) -> void:
	# Speaker name
	var speaker: String = node_data.get("speaker", "")
	if speaker_label:
		speaker_label.text = speaker.capitalize() if speaker != "" else ""

	# Portrait
	if portrait_rect:
		portrait_rect.visible = false
		if speaker != "":
			var portrait_mood: String = node_data.get("portrait", "neutral")
			# Try to construct path: res://assets/sprites/portraits/[speaker]_[mood].png
			var portrait_path: String = "res://assets/sprites/portraits/%s_%s.png" % [speaker, portrait_mood]
			
			# Fallback: some legacy paths might just be the mood or already include speaker
			if not ResourceLoader.exists(portrait_path):
				portrait_path = "res://assets/sprites/portraits/%s.png" % portrait_mood
				
			if ResourceLoader.exists(portrait_path):
				portrait_rect.texture = load(portrait_path)
				portrait_rect.visible = true

	# Text with typewriter effect
	_full_text = node_data.get("processed_text", node_data.get("text", ""))
	if text_label:
		text_label.text = _full_text
		text_label.visible_characters = 0
		
	_is_revealing = true
	var char_count = _full_text.length()
	var duration = char_count / _text_speed

	var text_tween = create_tween()
	text_tween.tween_method(func(v: int) -> void:
		text_label.visible_characters = v
		# Play blip every 3 characters for a typewriter feel
		if v > 0 and v % 3 == 0:
			AudioManager.play_text_blip()
	, 0, char_count, duration)
	text_tween.finished.connect(_on_reveal_finished)

	# Store next node
	_current_node_next = node_data.get("next", "")


func _play_voice_blip(_speaker_id: String) -> void:
	# Infrastructure for per-NPC voice blips — can be expanded per personality
	AudioManager.play_text_blip()


func _show_choice_node(node_data: Dictionary) -> void:
	if speaker_label:
		speaker_label.text = ""
	if text_label:
		text_label.text = ""
	if portrait_rect:
		portrait_rect.visible = false
	if choices_container:
		choices_container.visible = true
	if continue_indicator:
		continue_indicator.visible = false
	_is_revealing = false
	_waiting_for_advance = false

	var options: Array = node_data.get("available_options", [])
	for i in range(MAX_CHOICES):
		if i < options.size():
			_choice_buttons[i].text = options[i].get("processed_text", options[i].get("text", "???"))
			_choice_buttons[i].visible = true
		else:
			_choice_buttons[i].visible = false

	# Focus first choice
	if options.size() > 0:
		_choice_buttons[0].grab_focus()


func _advance_dialogue() -> void:
	_waiting_for_advance = false
	if continue_indicator:
		continue_indicator.visible = false

	if _current_node_next == "" or _current_node_next == "end":
		_close()
		return

	var node_data: Dictionary = NarrativeEngine.advance_to_node(_current_node_next)
	if node_data.is_empty():
		_close()
		return

	show_node(node_data)


func _on_choice_pressed(index: int) -> void:
	var node_data: Dictionary = NarrativeEngine.select_choice(index)
	if node_data.is_empty() or node_data.get("type", "") == "end":
		_close()
		return

	show_node(node_data)


var _is_closing: bool = false

func _close() -> void:
	if _is_closing:
		return  # Prevent recursion from dialogue_ended -> _close -> end_dialogue -> dialogue_ended
	_is_closing = true

	visible = false
	if panel:
		panel.visible = false
	_is_revealing = false
	_waiting_for_advance = false
	_current_node_next = ""

	if NarrativeEngine.is_in_dialogue():
		NarrativeEngine.end_dialogue()

	# Return control to player
	var player: Node = get_tree().get_first_node_in_group("player")
	if player and player.has_method("end_interaction"):
		player.end_interaction()

	_is_closing = false


func _hide_all_choices() -> void:
	for btn in _choice_buttons:
		btn.visible = false


func _has_visible_choices() -> bool:
	for btn in _choice_buttons:
		if btn.visible:
			return true
	return false


func _on_dialogue_started(dialogue_id: String) -> void:
	# Use the engine to get properly processed node data (triggers fire, text filled).
	var tree: Dictionary = NarrativeEngine.get_dialogue(dialogue_id)
	if tree.is_empty():
		print("DialogueUI: No dialogue tree found for '%s'" % dialogue_id)
		var player: Node = get_tree().get_first_node_in_group("player")
		if player and player.has_method("end_interaction"):
			player.end_interaction()
		return

	var start_node: String = tree.get("start_node", "start")
	var node: Dictionary = NarrativeEngine.advance_to_node(start_node)
	if node.is_empty():
		print("DialogueUI: Empty node for '%s'" % start_node)
		var player: Node = get_tree().get_first_node_in_group("player")
		if player and player.has_method("end_interaction"):
			player.end_interaction()
		return

	show_node(node)


func _on_dialogue_ended(_dialogue_id: String) -> void:
	_close()
