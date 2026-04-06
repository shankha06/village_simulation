## Prologue cinematic — multi-phase presentation with visual effects.
## Phase 1: Title card with slow fade
## Phase 2: World-building narration (the pact, the history)
## Phase 3: The crisis (what went wrong)
## Phase 4: Your arrival (personal, intimate)
extends CanvasLayer

signal intro_completed

@onready var background: ColorRect = $Background
@onready var vignette: ColorRect = $Vignette
@onready var text_label: RichTextLabel = $TextContainer/TextLabel
@onready var title_label: RichTextLabel = $TitleContainer/TitleLabel
@onready var divider: ColorRect = $Divider
@onready var skip_label: Label = $SkipLabel

const TYPEWRITER_SPEED: float = 0.035
const FADE_OUT_DURATION: float = 1.5

var _is_skipping: bool = false
var _is_playing: bool = false
var _tween: Tween = null


# ── The narration ──────────────────────────────────────────────
# Each phase is a visual "chapter" of the intro.
# phase: changes how text is displayed
# style: bbcode wrapper applied to the line
# size: font size override (0 = use default)
# pause: seconds after line finishes revealing
# clear: if true, fades out all text before this line

const NARRATION: Array = [
	# ── PHASE 1: THE WORLD BEFORE ──
	{"text": "T H E   H O L L O W   V I L L A G E", "pause": 3.0, "style": "center_gold_large", "clear": false},
	{"text": "━━━━━━━━━━━━━━━━━━━━━━━━", "pause": 1.5, "style": "center_dim", "clear": false},
	{"text": "", "pause": 0.5, "style": "", "clear": true},

	# ── PHASE 2: THE PACT ──
	{"text": "Three hundred years ago, a desperate man knelt at the edge of an ancient forest.", "pause": 2.5, "style": "narrator", "clear": false},
	{"text": "He was starving. His people were dying. The forest offered shelter.", "pause": 2.5, "style": "narrator", "clear": false},
	{"text": "He cut his palm. The forest cut its bark.\nTheir blood mingled in the soil, and a covenant was born.", "pause": 3.5, "style": "narrator", "clear": false},
	{"text": "", "pause": 0.5, "style": "", "clear": true},

	{"text": "The land flourished. Crops grew tall. Wells ran sweet.\nPlagues turned aside at the village border.\nFor three hundred years, Ashvale prospered.", "pause": 3.5, "style": "narrator", "clear": false},
	{"text": "The price was simple.", "pause": 2.0, "style": "narrator_emphasis", "clear": false},
	{"text": "Every thirty years, one soul.\nGiven willingly to the roots.", "pause": 4.0, "style": "narrator_emphasis", "clear": false},
	{"text": "", "pause": 0.5, "style": "", "clear": true},

	# ── PHASE 3: THE CRISIS ──
	{"text": "Nine souls across three centuries.\nA servant. A thief. A woodcutter. A widow.\nA deserter. A child. A healer. A prisoner.\nA carpenter named Silas, who carved a compass\nfor children too young to remember his face.", "pause": 5.0, "style": "narrator", "clear": false},
	{"text": "", "pause": 0.5, "style": "", "clear": true},

	{"text": "This year, the tenth lord of Ashvale\nlooked at the ritual chamber beneath his manor,\nread the instructions his father left him,\nand thought:", "pause": 3.0, "style": "narrator", "clear": false},
	{"text": "\"Three hundred years of murder is enough.\"", "pause": 4.0, "style": "quote_gold", "clear": false},
	{"text": "He refused.", "pause": 2.5, "style": "narrator_emphasis", "clear": false},
	{"text": "", "pause": 0.5, "style": "", "clear": true},

	# ── PHASE 4: THE DECAY ──
	{"text": "The crops began dying within a week.\nNot blight. Not drought. Something in the water.\nSomething that tastes like bitter almonds\nand broken promises.", "pause": 3.5, "style": "narrator", "clear": false},
	{"text": "A priest arrived, preaching divine punishment.\nA thieves' guild moved through the shadows.\nThe lord locked himself in his manor\nand stopped looking in mirrors.", "pause": 3.5, "style": "narrator", "clear": false},
	{"text": "And deep in the Thornwood,\nsomething ancient began to lose patience.", "pause": 3.5, "style": "narrator_emphasis", "clear": false},
	{"text": "", "pause": 0.5, "style": "", "clear": true},

	# ── PHASE 5: YOU ──
	{"text": "You arrive as the last light fades.", "pause": 2.5, "style": "personal", "clear": false},
	{"text": "A stranger carrying a silver compass\nthat hasn't pointed north in thirty years.", "pause": 3.0, "style": "personal", "clear": false},
	{"text": "The name scratched on the back — Silas Maren —\nmeans nothing to you.\nNot yet.", "pause": 3.5, "style": "personal_emphasis", "clear": false},
	{"text": "", "pause": 1.0, "style": "", "clear": true},

	{"text": "The gate is open.\nThe guard looks tired.\nThe bread tastes like chalk.\nThe forest is watching.", "pause": 4.0, "style": "personal", "clear": false},
	{"text": "", "pause": 0.5, "style": "", "clear": true},

	{"text": "Welcome to Ashvale.", "pause": 3.0, "style": "center_gold_large", "clear": false},
	{"text": "The roots remember.\nThe roots always remember.", "pause": 4.0, "style": "center_dim", "clear": false},
]


func _ready() -> void:
	layer = 150
	text_label.text = ""
	text_label.visible_ratio = 0.0
	if title_label:
		title_label.text = ""
		title_label.visible_ratio = 0.0
	if divider:
		divider.modulate.a = 0.0
	skip_label.modulate.a = 0.0

	# Fade in skip hint after delay
	var skip_tween := create_tween()
	skip_tween.tween_interval(3.0)
	skip_tween.tween_property(skip_label, "modulate:a", 0.4, 1.5)


func play() -> void:
	_is_playing = true
	await _run_narration()
	if not _is_skipping:
		await _fade_out()
	_finish()


func _run_narration() -> void:
	var accumulated_text: String = ""

	for i in range(NARRATION.size()):
		if _is_skipping:
			return

		var entry: Dictionary = NARRATION[i]
		var line: String = entry.get("text", "")
		var pause: float = entry.get("pause", 2.0)
		var style: String = entry.get("style", "narrator")
		var should_clear: bool = entry.get("clear", false)

		# Clear screen with fade
		if should_clear:
			if accumulated_text != "":
				_tween = create_tween()
				_tween.tween_property(text_label, "modulate:a", 0.0, 0.8)
				await _tween.finished
				if _is_skipping:
					return
				accumulated_text = ""
				text_label.text = ""
				text_label.modulate.a = 1.0
				text_label.visible_ratio = 0.0
			# Short breath between sections
			_tween = create_tween()
			_tween.tween_interval(0.5)
			await _tween.finished
			if _is_skipping:
				return
			continue

		if line == "":
			continue

		# Apply style via BBCode
		var styled_line: String = _apply_style(line, style)

		# Append to accumulated text
		if accumulated_text != "":
			accumulated_text += "\n\n"
		accumulated_text += styled_line

		text_label.text = accumulated_text

		# Calculate visible ratio for typewriter
		var previous_visible: int = accumulated_text.length() - styled_line.length()
		if previous_visible > 0:
			text_label.visible_ratio = float(previous_visible) / float(accumulated_text.length())
		else:
			text_label.visible_ratio = 0.0

		# Typewriter reveal
		var raw_length: int = line.length()  # Use unstyled length for timing
		var reveal_duration: float = raw_length * TYPEWRITER_SPEED
		_tween = create_tween()
		_tween.tween_property(text_label, "visible_ratio", 1.0, reveal_duration)
		await _tween.finished

		if _is_skipping:
			return

		# Pause
		_tween = create_tween()
		_tween.tween_interval(pause)
		await _tween.finished


func _apply_style(text: String, style: String) -> String:
	match style:
		"center_gold_large":
			return "[center][color=#DAB048][font_size=24]%s[/font_size][/color][/center]" % text
		"center_dim":
			return "[center][color=#8B7D5A]%s[/color][/center]" % text
		"narrator":
			return "[color=#C8BFA8]%s[/color]" % text
		"narrator_emphasis":
			return "[color=#E0D8C4][i]%s[/i][/color]" % text
		"quote_gold":
			return "[center][color=#DAB048][i]%s[/i][/color][/center]" % text
		"personal":
			return "[color=#A8B8A0]%s[/color]" % text
		"personal_emphasis":
			return "[color=#B8C8A8][i]%s[/i][/color]" % text
		_:
			return text


func _fade_out() -> void:
	_tween = create_tween()
	_tween.tween_interval(1.0)
	_tween.tween_property(text_label, "modulate:a", 0.0, FADE_OUT_DURATION)
	_tween.parallel().tween_property(skip_label, "modulate:a", 0.0, 0.5)
	_tween.parallel().tween_property(background, "color:a", 1.0, FADE_OUT_DURATION)
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
