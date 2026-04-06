## World Simulation — processes daily ticks for ecology, economy, consequences.
## The engine that makes the world feel alive and actions have ripple effects.
extends Node

# Active consequence chains being tracked
var _active_chains: Array[Dictionary] = []

# Ecology data: {region_id: {species: {pop: float, growth_rate: float, predators: Array, prey: Array}}}
var _ecology: Dictionary = {}

# Economy data: {region_id: {base_prices: Dictionary, supply: Dictionary}}
var _economy: Dictionary = {}

# Rumor queue: {rumor_id, source_region, day_created, spread_radius}
var _rumors: Array[Dictionary] = []

# Threshold watchers: conditions checked every tick
var _threshold_watchers: Array[Dictionary] = []


func _ready() -> void:
	TimeManager.day_tick.connect(_on_day_tick)
	TimeManager.hour_tick.connect(_on_hour_tick)
	GameState.state_changed.connect(_on_state_changed)


## Load consequence chain definitions from JSON data.
func load_consequence_chains(chains_data: Array) -> void:
	for chain in chains_data:
		_register_chain(chain)


## Load ecology definitions for a region.
func load_ecology(region_id: String, data: Dictionary) -> void:
	_ecology[region_id] = data


## Load economy definitions for a region.
func load_economy(region_id: String, data: Dictionary) -> void:
	_economy[region_id] = data


## Activate a consequence chain by ID.
func activate_chain(chain_id: String) -> void:
	for chain in _active_chains:
		if chain.id == chain_id and chain.get("activated", false):
			return  # Already active
	# Find chain definition and activate it
	for chain in _active_chains:
		if chain.id == chain_id:
			chain.activated = true
			_process_chain_consequences(chain)
			return


## Manually trigger a consequence chain from data.
func trigger_consequence_chain(chain_data: Dictionary) -> void:
	chain_data.activated = true
	_active_chains.append(chain_data)
	_process_chain_consequences(chain_data)


## Serialize for saving.
func serialize() -> Dictionary:
	return {
		"active_chains": _active_chains.duplicate(true),
		"ecology": _ecology.duplicate(true),
		"economy": _economy.duplicate(true),
		"rumors": _rumors.duplicate(true),
		"threshold_watchers": _threshold_watchers.duplicate(true),
	}


## Deserialize from save.
func deserialize(data: Dictionary) -> void:
	_active_chains = data.get("active_chains", [])
	_ecology = data.get("ecology", {})
	_economy = data.get("economy", {})
	_rumors = data.get("rumors", [])
	_threshold_watchers = data.get("threshold_watchers", [])


# --- Daily Tick Processing ---

func _on_day_tick(current_day: int) -> void:
	_tick_ecology(current_day)
	_tick_economy(current_day)
	_tick_rumors(current_day)
	_check_thresholds()
	_tick_faction_power()


func _on_hour_tick(_hour: int, _current_day: int) -> void:
	# Hourly checks for more responsive world reactions
	_check_thresholds()
	_check_narrative_atoms()


# --- Ecology Simulation ---

func _tick_ecology(_current_day: int) -> void:
	for region_id in _ecology:
		var region_eco: Dictionary = _ecology[region_id]
		for species in region_eco:
			var data: Dictionary = region_eco[species]
			var pop: float = data.get("pop", 1.0)
			var growth: float = data.get("growth_rate", 0.01)
			var capacity: float = data.get("carrying_capacity", 5.0)

			# Check if predators exist
			var predator_pressure: float = 0.0
			for predator in data.get("predators", []):
				if region_eco.has(predator):
					predator_pressure += region_eco[predator].get("pop", 0.0) * 0.1

			# Logistic growth with predation
			var new_pop: float = pop + pop * growth * (1.0 - pop / capacity) - predator_pressure * pop
			new_pop = maxf(new_pop, 0.0)
			data.pop = new_pop

			# Sync to GameState
			var state_key: String = "ecology.%s.%s.pop" % [region_id, species]
			GameState.set_state(state_key, snapped(new_pop, 0.01))


# --- Economy Simulation ---

func _tick_economy(_current_day: int) -> void:
	for region_id in _economy:
		var region_econ: Dictionary = _economy[region_id]
		var region_status: String = GameState.get_state(
			"world.region.%s.status" % region_id, "normal"
		)

		# Adjust prices based on region status
		var price_mod: float = 1.0
		match region_status:
			"famine":
				price_mod = lerpf(
					GameState.get_state("economy.%s.price_mod" % region_id, 1.0),
					3.0,
					0.05
				)
			"war":
				price_mod = lerpf(
					GameState.get_state("economy.%s.price_mod" % region_id, 1.0),
					2.0,
					0.03
				)
			"normal":
				price_mod = lerpf(
					GameState.get_state("economy.%s.price_mod" % region_id, 1.0),
					1.0,
					0.02
				)

		GameState.set_state("economy.%s.price_mod" % region_id, snapped(price_mod, 0.01))

		# Update food supply based on ecology
		var food_supply: float = GameState.get_state(
			"world.region.%s.food_supply" % region_id, 100.0
		)
		if region_status == "famine":
			food_supply = maxf(food_supply - 2.0, 0.0)
		elif region_status == "normal":
			food_supply = minf(food_supply + 0.5, 100.0)
		GameState.set_state(
			"world.region.%s.food_supply" % region_id, snapped(food_supply, 0.1)
		)


# --- Rumor Propagation ---

func _tick_rumors(current_day: int) -> void:
	for rumor in _rumors:
		if rumor.get("fully_spread", false):
			continue
		var age: int = current_day - rumor.day_created
		var spread_speed: int = rumor.get("spread_speed", 3)  # days to spread one region

		if age > 0 and age % spread_speed == 0:
			# Spread to adjacent regions
			var adjacent: Array = rumor.get("adjacent_regions", [])
			for region_id in adjacent:
				if region_id not in rumor.get("reached_regions", []):
					rumor.get("reached_regions", []).append(region_id)
					# Set rumor flags on NPCs in that region
					var rumor_key: String = "rumor.%s.%s" % [region_id, rumor.rumor_id]
					GameState.set_state(rumor_key, true)
					EventBus.rumor_spread.emit(
						rumor.rumor_id, rumor.source_region, region_id
					)


## Add a new rumor to the propagation system.
func create_rumor(rumor_id: String, source_region: String, adjacent_regions: Array, spread_speed: int = 3) -> void:
	_rumors.append({
		"rumor_id": rumor_id,
		"source_region": source_region,
		"day_created": TimeManager.day,
		"spread_speed": spread_speed,
		"adjacent_regions": adjacent_regions,
		"reached_regions": [source_region],
		"fully_spread": false,
	})


# --- Threshold Checking ---

func _check_thresholds() -> void:
	for i in range(_threshold_watchers.size() - 1, -1, -1):
		var watcher: Dictionary = _threshold_watchers[i]
		var condition: String = "%s %s %s" % [
			watcher.watch_key,
			watcher.get("op", ">"),
			str(watcher.threshold)
		]
		if GameState.evaluate_condition(condition):
			# Fire threshold effects
			_execute_effects(watcher.get("effects", []))
			_threshold_watchers.remove_at(i)


# --- Faction Power Decay ---

func _tick_faction_power() -> void:
	# Factions in regions with problems lose power
	for region_id in _economy:
		var status: String = GameState.get_state(
			"world.region.%s.status" % region_id, "normal"
		)
		var ruler: String = GameState.get_state(
			"world.region.%s.ruler" % region_id, ""
		)
		if ruler != "" and status != "normal":
			var power_drain: float = 0.0
			match status:
				"famine":
					power_drain = 1.0
				"war":
					power_drain = 0.5
				"plague":
					power_drain = 1.5
			if power_drain > 0:
				FactionManager.modify_power(ruler, -power_drain)


# --- Consequence Chain Processing ---

func _register_chain(chain_data: Dictionary) -> void:
	chain_data["activated"] = false
	_active_chains.append(chain_data)


func _process_chain_consequences(chain: Dictionary) -> void:
	for consequence in chain.get("consequences", []):
		var ctype: String = consequence.get("type", "")
		match ctype:
			"immediate":
				_execute_effects(consequence.get("effects", []))
			"delayed":
				var delay_days: int = consequence.get("delay_days", 1)
				TimeManager.schedule_delayed(
					chain.id + "_delayed",
					delay_days,
					consequence.get("effects", [])
				)
			"conditional_delayed":
				var delay_days: int = consequence.get("delay_days", 1)
				# Schedule the check, not the execution
				TimeManager.schedule_delayed(
					chain.id + "_conditional",
					delay_days,
					[{
						"conditional_effects": consequence.get("effects", []),
						"condition": consequence.get("condition", ""),
					}]
				)
			"threshold":
				_threshold_watchers.append({
					"watch_key": consequence.watch_key,
					"op": consequence.get("op", ">"),
					"threshold": consequence.get("condition", "").split(" ").pop_back(),
					"effects": consequence.get("effects", []),
				})


func _execute_effects(effects: Array) -> void:
	for effect in effects:
		if not effect is Dictionary:
			continue
		if effect.has("set_state"):
			if effect.has("delta"):
				GameState.delta_state(effect.set_state, float(effect.delta))
			else:
				GameState.set_state(effect.set_state, effect.value)
		elif effect.has("give_item"):
			# Handled through EventBus -> player inventory
			EventBus.notification_requested.emit(
				"Received: %s" % effect.give_item, "item"
			)
			GameState.set_state("player.has_item.%s" % effect.give_item, true)
		elif effect.has("remove_item"):
			GameState.set_state("player.has_item.%s" % effect.remove_item, false)
		elif effect.has("spawn_event"):
			EventBus.notification_requested.emit(
				effect.spawn_event, "world_event"
			)
		elif effect.has("swap_visuals"):
			EventBus.visual_swap_requested.emit(
				effect.swap_visuals, effect.get("variant", "default")
			)
		elif effect.has("conditional_effects"):
			# Deferred conditional: check condition now, execute if true
			if GameState.evaluate_condition(effect.condition):
				_execute_effects(effect.conditional_effects)


func _on_state_changed(key: String, _old: Variant, _new_value: Variant) -> void:
	# Check narrative atoms on any flag change for immediate-response atoms
	_check_narrative_atoms()

	# Check if any inactive chains should activate based on this state change
	for chain in _active_chains:
		if chain.get("activated", false):
			continue
		var trigger: String = chain.get("trigger_condition", "")
		if trigger != "" and GameState.evaluate_condition(trigger):
			chain.activated = true
			_process_chain_consequences(chain)


# --- Narrative Atom Evaluation ---

func _check_narrative_atoms() -> void:
	for atom_id in NarrativeEngine._narrative_atoms:
		var atom: Dictionary = NarrativeEngine._narrative_atoms[atom_id]
		if atom.get("_fired", false):
			continue
		if atom.get("once_only", true):
			if GameState.get_state("atom.%s.fired" % atom_id, false):
				continue
		# Check cooldown
		var cooldown: int = atom.get("cooldown_days", 0)
		if cooldown > 0:
			var last: int = GameState.get_state("atom.%s.last_day" % atom_id, -999)
			if TimeManager.day - last < cooldown:
				continue
		# Check all conditions
		var conditions: Array = atom.get("conditions", [])
		if conditions.is_empty() or GameState.evaluate_conditions(conditions):
			_fire_atom(atom_id, atom)


func _fire_atom(atom_id: String, atom: Dictionary) -> void:
	atom["_fired"] = true
	GameState.set_state("atom.%s.fired" % atom_id, true)
	GameState.set_state("atom.%s.last_day" % atom_id, TimeManager.day)

	# Apply effects
	for effect in atom.get("effects", []):
		if not effect is Dictionary:
			continue
		if effect.has("set_state"):
			if effect.has("delta"):
				GameState.delta_state(effect.set_state, float(effect.delta))
			elif effect.has("value"):
				GameState.set_state(effect.set_state, effect.value)
		elif effect.has("swap_visuals"):
			EventBus.visual_swap_requested.emit(effect.swap_visuals, effect.get("variant", "default"))
		elif effect.has("spawn_event"):
			EventBus.notification_requested.emit(effect.spawn_event, "world_event")

	# Show notification text
	var text: String = atom.get("notification_text", "")
	if text != "":
		EventBus.notification_requested.emit(text, "world_event")

	print("WorldSimulation: Fired narrative atom '%s'" % atom_id)
