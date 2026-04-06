## Audio Manager — handles music, SFX, and ambience with mood-reactive selection.
extends Node

var _music_player: AudioStreamPlayer
var _ambience_player: AudioStreamPlayer
var _sfx_players: Array[AudioStreamPlayer] = []

const MAX_SFX_PLAYERS: int = 8

var _current_music: String = ""
var _current_ambience: String = ""
var _music_volume: float = 0.8
var _sfx_volume: float = 1.0
var _ambience_volume: float = 0.6

# Mood-to-music mapping
var _mood_music: Dictionary = {}

# Footstep sounds
const FOOTSTEP_PATHS: Array[String] = [
	"res://assets/audio/sfx/footstep_1.wav",
	"res://assets/audio/sfx/footstep_2.wav",
	"res://assets/audio/sfx/footstep_3.wav",
]
var _last_footstep_index: int = -1

# Text blip
const TEXT_BLIP_PATH: String = "res://assets/audio/sfx/text_blip.wav"


func _ready() -> void:
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = "Music"
	add_child(_music_player)

	_ambience_player = AudioStreamPlayer.new()
	_ambience_player.bus = "Ambience"
	add_child(_ambience_player)

	for i in range(MAX_SFX_PLAYERS):
		var player := AudioStreamPlayer.new()
		player.bus = "SFX"
		add_child(player)
		_sfx_players.append(player)

	EventBus.time_of_day_changed.connect(_on_time_of_day_changed)


## Play a music track. Crossfades if music is already playing.
func play_music(stream_path: String, fade_duration: float = 1.0) -> void:
	if stream_path == _current_music:
		return

	_current_music = stream_path
	var stream: AudioStream = load(stream_path) if stream_path != "" else null

	if stream == null:
		_music_player.stop()
		return

	# Simple crossfade via tween
	var tween := create_tween()
	tween.tween_property(_music_player, "volume_db", -40.0, fade_duration * 0.5)
	tween.tween_callback(func() -> void:
		_music_player.stream = stream
		_music_player.play()
	)
	tween.tween_property(_music_player, "volume_db", linear_to_db(_music_volume), fade_duration * 0.5)


## Play ambience track.
func play_ambience(stream_path: String) -> void:
	if stream_path == _current_ambience:
		return

	_current_ambience = stream_path
	var stream: AudioStream = load(stream_path) if stream_path != "" else null

	if stream == null:
		_ambience_player.stop()
		return

	_ambience_player.stream = stream
	_ambience_player.volume_db = linear_to_db(_ambience_volume)
	_ambience_player.play()


## Play a one-shot sound effect.
func play_sfx(stream_path: String, volume: float = 1.0) -> void:
	var stream: AudioStream = load(stream_path)
	if stream == null:
		return

	# Find available SFX player
	for player in _sfx_players:
		if not player.playing:
			player.stream = stream
			player.volume_db = linear_to_db(_sfx_volume * volume)
			player.play()
			return

	# All busy — use the first one (interrupt oldest)
	_sfx_players[0].stream = stream
	_sfx_players[0].volume_db = linear_to_db(_sfx_volume * volume)
	_sfx_players[0].play()


## Set mood-to-music mappings.
func set_mood_music(mappings: Dictionary) -> void:
	_mood_music = mappings


## Stop all audio.
func stop_all() -> void:
	_music_player.stop()
	_ambience_player.stop()
	for player in _sfx_players:
		player.stop()
	_current_music = ""
	_current_ambience = ""


## Play a random footstep sound (avoids repeating the same one twice).
func play_footstep() -> void:
	var idx: int = randi() % FOOTSTEP_PATHS.size()
	while idx == _last_footstep_index and FOOTSTEP_PATHS.size() > 1:
		idx = randi() % FOOTSTEP_PATHS.size()
	_last_footstep_index = idx
	play_sfx(FOOTSTEP_PATHS[idx], 0.6)


## Play the text blip sound for dialogue typewriter.
func play_text_blip() -> void:
	play_sfx(TEXT_BLIP_PATH, 0.35)


func _on_time_of_day_changed(period: String) -> void:
	if _mood_music.has(period):
		play_music(_mood_music[period])
