## Prologue intro cinematic — text crawl with typewriter effect, then transition to village.
extends CanvasLayer

signal intro_completed

@onready var background: ColorRect = $Background
@onready var text_label: RichTextLabel = $TextContainer/TextLabel
@onready var skip_label: Label = $SkipLabel

# The narration lines with pause durations (seconds after each line)
const NARRATION: Array = [
	{"text": "The road to Ashvale was once a merchant's dream.", "pause": 2.0},
	{"text": "Fertile fields stretched to the horizon. The lord's peace\nwas kept by well-fed guards. The forest knew its place.", "pause": 2.0},
	{"text": "That was before the crops began to die.", "pause": 3.0},
	{"text": "Three weeks ago, the blight came. Not from drought\nor disease — something deeper. Something in the water.", "pause": 2.0},
	{"text": "People whisper of curses. A priest preaches divine\npunishment. The lord has locked himself away.", "pause": 3.0},
	{"text": "You arrive as the last light fades.", "pause": 2.0},
	{"text": "A stranger with no name, no past.", "pause": 1.0},
	{"text": "Only a road behind, and a dying village ahead.", "pause": 2.0},
]

const TYPEWRITER_SPEED: float = 0.04  # seconds per character
const FADE_IN_DURATION: float = 0.5
const FINAL_HOLD: float = 1.5
const FADE_OUT_DURATION: float = 1.5

var _is_skipping: bool = false
var _is_playing: bool = false
var _tween: Tween = null


func _ready() -> void:
	layer = 150
	text_label.text = ""
	text_label.visible_ratio = 0.0
	skip_label.modulate.a = 0.0

	# Fade in the skip hint after a short delay
	var skip_tween := create_tween()
	skip_tween.tween_interval(2.0)
	skip_tween.tween_property(skip_label, "modulate:a", 0.5, 1.0)


func play() -> void:
	_is_playing = true
	await _run_text_crawl()
	if not _is_skipping:
		await _fade_out()
	_finish()


func _run_text_crawl() -> void:
	var accumulated_text: String = ""

	for i in range(NARRATION.size()):
		if _is_skipping:
			return

		var entry: Dictionary = NARRATION[i]
		var line: String = entry.text
		var pause: float = entry.pause

		# Append new line (with spacing between entries)
		if accumulated_text != "":
			accumulated_text += "\n\n"
		accumulated_text += line

		text_label.text = accumulated_text

		# Typewriter: reveal from current ratio to 1.0
		var previous_length: int = accumulated_text.length() - line.length()
		if previous_length > 0:
			text_label.visible_ratio = float(previous_length) / float(accumulated_text.length())
		else:
			text_label.visible_ratio = 0.0

		var reveal_duration: float = line.length() * TYPEWRITER_SPEED
		_tween = create_tween()
		_tween.tween_property(text_label, "visible_ratio", 1.0, reveal_duration)
		await _tween.finished

		if _is_skipping:
			return

		# Pause between lines
		_tween = create_tween()
		_tween.tween_interval(pause)
		await _tween.finished


func _fade_out() -> void:
	# Hold for a moment, then fade to black
	_tween = create_tween()
	_tween.tween_interval(FINAL_HOLD)
	_tween.tween_property(text_label, "modulate:a", 0.0, FADE_OUT_DURATION)
	_tween.parallel().tween_property(skip_label, "modulate:a", 0.0, 0.5)
	await _tween.finished


func _finish() -> void:
	_is_playing = false
	intro_completed.emit()


func skip() -> void:
	if _is_skipping:
		return
	_is_skipping = true
	if _tween and _tween.is_valid():
		_tween.kill()
	# Quick fade out
	var fade := create_tween()
	fade.tween_property(text_label, "modulate:a", 0.0, 0.3)
	fade.parallel().tween_property(skip_label, "modulate:a", 0.0, 0.2)
	await fade.finished
	_finish()


func _unhandled_input(event: InputEvent) -> void:
	if not _is_playing:
		return
	if event is InputEventKey or event is InputEventMouseButton:
		if event.is_pressed():
			skip()
			get_viewport().set_input_as_handled()
