## WeatherSystem — manages weather effects (rain, fog, snow) based on region and season.
extends Node2D

enum Weather { CLEAR, CLOUDY, RAIN, STORM, FOG, SNOW }

var current_weather: Weather = Weather.CLEAR
var _weather_timer: float = 0.0
var _weather_duration: float = 300.0  # Default duration in game-minutes

@onready var rain_particles: GPUParticles2D = $RainParticles if has_node("RainParticles") else null
@onready var fog_overlay: ColorRect = $FogOverlay if has_node("FogOverlay") else null


func _ready() -> void:
	TimeManager.hour_tick.connect(_on_hour_tick)
	_update_visuals()


func set_weather(weather: Weather, duration: float = 300.0) -> void:
	current_weather = weather
	_weather_duration = duration
	_weather_timer = 0.0
	_update_visuals()

	var weather_name: String = Weather.keys()[weather].to_lower()
	GameState.set_state("weather.current", weather_name)
	EventBus.weather_changed.emit(weather_name)


func _update_visuals() -> void:
	if rain_particles:
		rain_particles.emitting = current_weather in [Weather.RAIN, Weather.STORM]

	if fog_overlay:
		fog_overlay.visible = current_weather == Weather.FOG
		if fog_overlay.visible:
			fog_overlay.color = Color(0.7, 0.7, 0.75, 0.3)


func _on_hour_tick(_hour: int, _day: int) -> void:
	# Random weather changes based on season
	var season: String = TimeManager.get_season()
	var roll: float = randf()

	match season:
		"autumn":
			if roll < 0.15:
				set_weather(Weather.RAIN)
			elif roll < 0.25:
				set_weather(Weather.FOG)
		"winter":
			if roll < 0.2:
				set_weather(Weather.SNOW)
			elif roll < 0.3:
				set_weather(Weather.FOG)
		"spring":
			if roll < 0.1:
				set_weather(Weather.RAIN)
		"summer":
			if roll < 0.05:
				set_weather(Weather.STORM)

	# Tend back to clear
	if current_weather != Weather.CLEAR and roll > 0.7:
		set_weather(Weather.CLEAR)
