## Global Time Manager — in-game clock with scheduled event system.
## Tracks minutes, hours, days, seasons. Provides cron-job style delayed events.
extends Node

signal minute_tick(minute: int, hour: int, day: int)
signal hour_tick(hour: int, day: int)
signal day_tick(day: int)
signal season_tick(season: String)

# Time configuration
const MINUTES_PER_HOUR: int = 60
const HOURS_PER_DAY: int = 24
const DAYS_PER_SEASON: int = 30
const SEASONS: Array[String] = ["spring", "summer", "autumn", "winter"]
const REAL_SECONDS_PER_GAME_MINUTE: float = 0.1  # 10 game-minutes per real second

# Current time state
var minute: int = 0
var hour: int = 8    # Start at 8 AM
var day: int = 1
var season_index: int = 2  # Start in autumn
var total_minutes_elapsed: int = 0

# Time control
var time_scale: float = 1.0
var paused: bool = false

# Accumulator for real-time to game-time conversion
var _time_accumulator: float = 0.0

# Scheduled events queue
# Each entry: {id: String, trigger_day: int, trigger_hour: int, effects: Array, metadata: Dictionary}
var _scheduled_events: Array[Dictionary] = []

# Unique ID counter for scheduled events
var _next_event_id: int = 0


func _ready() -> void:
	pass


func _process(delta: float) -> void:
	if paused:
		return

	_time_accumulator += delta * time_scale
	while _time_accumulator >= REAL_SECONDS_PER_GAME_MINUTE:
		_time_accumulator -= REAL_SECONDS_PER_GAME_MINUTE
		_advance_minute()


## Schedule an event to fire at a specific future day (and optionally hour).
## Returns the event ID for cancellation.
func schedule_event(event_id: String, trigger_day: int, effects: Array = [], trigger_hour: int = -1, metadata: Dictionary = {}) -> String:
	var uid: String = "%s_%d" % [event_id, _next_event_id]
	_next_event_id += 1
	_scheduled_events.append({
		"id": event_id,
		"uid": uid,
		"trigger_day": trigger_day,
		"trigger_hour": trigger_hour,
		"effects": effects,
		"metadata": metadata,
		"fired": false,
	})
	return uid


## Schedule an event relative to current time.
## delay_days: how many in-game days from now.
func schedule_delayed(event_id: String, delay_days: int, effects: Array = [], delay_hours: int = 0, metadata: Dictionary = {}) -> String:
	var target_day: int = day + delay_days
	var target_hour: int = -1
	if delay_hours > 0:
		target_hour = (hour + delay_hours) % HOURS_PER_DAY
		target_day += (hour + delay_hours) / HOURS_PER_DAY
	return schedule_event(event_id, target_day, effects, target_hour, metadata)


## Cancel a scheduled event by its unique ID.
func cancel_event(uid: String) -> bool:
	for i in range(_scheduled_events.size() - 1, -1, -1):
		if _scheduled_events[i].uid == uid:
			_scheduled_events.remove_at(i)
			return true
	return false


## Cancel all scheduled events with a given base event_id.
func cancel_events_by_id(event_id: String) -> int:
	var count: int = 0
	for i in range(_scheduled_events.size() - 1, -1, -1):
		if _scheduled_events[i].id == event_id:
			_scheduled_events.remove_at(i)
			count += 1
	return count


## Get the current time period ("dawn", "day", "dusk", "night").
func get_time_period() -> String:
	if hour >= 5 and hour < 7:
		return "dawn"
	elif hour >= 7 and hour < 18:
		return "day"
	elif hour >= 18 and hour < 20:
		return "dusk"
	else:
		return "night"


## Get current season name.
func get_season() -> String:
	return SEASONS[season_index]


## Check if it's currently nighttime.
func is_night() -> bool:
	return hour >= 20 or hour < 5


## Fast-forward time by a number of hours (for sleeping, waiting, etc.)
func advance_hours(hours_to_skip: int) -> void:
	for _i in range(hours_to_skip * MINUTES_PER_HOUR):
		_advance_minute()


## Set time directly (for loading saves).
func set_time(p_minute: int, p_hour: int, p_day: int, p_season_index: int) -> void:
	minute = p_minute
	hour = p_hour
	day = p_day
	season_index = p_season_index
	_sync_to_game_state()


## Serialize time state for saving.
func serialize() -> Dictionary:
	var events_data: Array[Dictionary] = []
	for event in _scheduled_events:
		if not event.fired:
			events_data.append(event.duplicate())
	return {
		"minute": minute,
		"hour": hour,
		"day": day,
		"season_index": season_index,
		"total_minutes_elapsed": total_minutes_elapsed,
		"scheduled_events": events_data,
		"next_event_id": _next_event_id,
	}


## Deserialize time state from save.
func deserialize(data: Dictionary) -> void:
	minute = data.get("minute", 0)
	hour = data.get("hour", 8)
	day = data.get("day", 1)
	season_index = data.get("season_index", 2)
	total_minutes_elapsed = data.get("total_minutes_elapsed", 0)
	_next_event_id = data.get("next_event_id", 0)
	_scheduled_events.clear()
	for event_data in data.get("scheduled_events", []):
		_scheduled_events.append(event_data)
	_sync_to_game_state()


# --- Private ---

func _advance_minute() -> void:
	minute += 1
	total_minutes_elapsed += 1

	if minute >= MINUTES_PER_HOUR:
		minute = 0
		_advance_hour()

	minute_tick.emit(minute, hour, day)


func _advance_hour() -> void:
	var old_period: String = get_time_period()
	hour += 1

	if hour >= HOURS_PER_DAY:
		hour = 0
		_advance_day()

	hour_tick.emit(hour, day)

	# Check hourly scheduled events
	_check_scheduled_events()

	# Notify time-of-day changes
	var new_period: String = get_time_period()
	if old_period != new_period:
		EventBus.time_of_day_changed.emit(new_period)

	_sync_to_game_state()


func _advance_day() -> void:
	day += 1

	if day > DAYS_PER_SEASON:
		day = 1
		_advance_season()

	day_tick.emit(day)

	# Check daily scheduled events
	_check_scheduled_events()


func _advance_season() -> void:
	season_index = (season_index + 1) % SEASONS.size()
	season_tick.emit(get_season())


func _check_scheduled_events() -> void:
	var events_to_fire: Array[Dictionary] = []

	for event in _scheduled_events:
		if event.fired:
			continue
		if event.trigger_day > day:
			continue
		if event.trigger_day == day and event.trigger_hour > hour and event.trigger_hour != -1:
			continue
		# Event is ready to fire
		events_to_fire.append(event)
		event.fired = true

	# Execute fired events
	for event in events_to_fire:
		_execute_scheduled_event(event)

	# Clean up fired events
	_scheduled_events = _scheduled_events.filter(func(e: Dictionary) -> bool: return not e.fired)


func _execute_scheduled_event(event: Dictionary) -> void:
	# Apply effects through GameState
	for effect in event.effects:
		if effect is Dictionary:
			if effect.has("set_state"):
				if effect.has("delta"):
					GameState.delta_state(effect.set_state, effect.delta)
				else:
					GameState.set_state(effect.set_state, effect.value)
			elif effect.has("spawn_event"):
				EventBus.notification_requested.emit(
					"Event: %s" % effect.spawn_event, "world_event"
				)
			elif effect.has("swap_visuals"):
				EventBus.visual_swap_requested.emit(
					effect.swap_visuals, effect.get("variant", "default")
				)


func _sync_to_game_state() -> void:
	GameState.set_state("time.minute", minute)
	GameState.set_state("time.hour", hour)
	GameState.set_state("time.day", day)
	GameState.set_state("time.season", get_season())
