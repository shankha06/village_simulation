## WorldStateVisuals — modifies tile appearances and spawns visual cues
## based on GameState flags and TimeManager progression.
## Attach to any region scene alongside the TileMapLayer.
extends Node2D

## Emitted when a visual layer changes so region_base or UI can react.
signal visual_layer_changed(layer_name: String, intensity: float)

## How many grass tiles to kill per day past the deadline.
const DEAD_GRASS_PER_DAY: int = 12

## Silo world position (tile coords).
const SILO_CENTER := Vector2i(22, 4)  # ~(350,60) / 16
const SILO_BLAST_RADIUS: int = 3

## Well area center (tile coords).
const WELL_CENTER := Vector2i(10, 10)
const WELL_MUD_RADIUS: int = 2

## Eastern boundary column where forest encroachment starts.
const FOREST_EDGE_START_COL: int = 38

## Tile IDs (must match terrain_tileset atlas).
const TILE_DIRT: int = 5
const TILE_MUD: int = 7
const TILE_BLOOD: int = 8
const TILE_FARMLAND_HEALTHY: int = 10
const TILE_FARMLAND_DEAD: int = 11
const TILE_ROOTS: int = 15
const TILE_GRASS: int = 0
const TILE_DEAD_GRASS: int = 6
const TILE_TREE_CANOPY: int = 33

var _rng := RandomNumberGenerator.new()
var _applied_sets: Dictionary = {}  # Track what we have already applied


func _ready() -> void:
	_rng.randomize()
	TimeManager.hour_tick.connect(_on_hour_tick)
	GameState.state_changed.connect(_on_state_changed)
	# Initial pass after the parent region finishes _ready().
	call_deferred("_update_all")


func _on_hour_tick(_hour: int, _day: int) -> void:
	_update_all()


func _on_state_changed(_key: String, _old: Variant, _new: Variant) -> void:
	_update_all()


func _update_all() -> void:
	_update_famine_visuals()
	_update_silo_visuals()
	_update_forest_encroachment()
	_update_plague_visuals()
	_update_war_visuals()
	_update_progressive_decay()


# ---------- Famine ----------

func _update_famine_visuals() -> void:
	if _applied_sets.has("famine"):
		return
	if GameState.get_state("world.region.ashvale.status", "normal") != "famine":
		return

	var tilemap := _get_tilemap()
	if tilemap == null:
		return

	# Replace a portion of healthy farmland with dead farmland.
	var cells := tilemap.get_used_cells()
	var replaced: int = 0
	for cell in cells:
		var atlas := tilemap.get_cell_atlas_coords(cell)
		var tile_id: int = atlas.y * 8 + atlas.x  # ATLAS_COLUMNS = 8
		if tile_id == TILE_FARMLAND_HEALTHY:
			if _rng.randf() < 0.6:
				_set_tile(tilemap, cell, TILE_FARMLAND_DEAD)
				replaced += 1

	_applied_sets["famine"] = true
	visual_layer_changed.emit("famine", 1.0)
	print("world_state_visuals: Famine — replaced %d farmland tiles." % replaced)


# ---------- Silo destruction ----------

func _update_silo_visuals() -> void:
	if _applied_sets.has("silo"):
		return
	if not GameState.get_state("flag.silo_destroyed", false):
		return

	var tilemap := _get_tilemap()
	if tilemap == null:
		return

	# Replace tiles in blast radius with dirt and blood.
	var replaced: int = 0
	for dy in range(-SILO_BLAST_RADIUS, SILO_BLAST_RADIUS + 1):
		for dx in range(-SILO_BLAST_RADIUS, SILO_BLAST_RADIUS + 1):
			var cell := SILO_CENTER + Vector2i(dx, dy)
			var dist := absf(dx) + absf(dy)
			if dist <= SILO_BLAST_RADIUS:
				if dist <= 1:
					_set_tile(tilemap, cell, TILE_BLOOD)
				else:
					_set_tile(tilemap, cell, TILE_DIRT)
				replaced += 1

	_applied_sets["silo"] = true
	visual_layer_changed.emit("silo_destroyed", 1.0)
	print("world_state_visuals: Silo destroyed — scorched %d tiles." % replaced)


# ---------- Forest encroachment ----------

func _update_forest_encroachment() -> void:
	if not GameState.get_state("flag.forest_encroaching", false):
		return

	var tilemap := _get_tilemap()
	if tilemap == null:
		return

	# Determine how many columns the forest has claimed.
	var day: int = TimeManager.day
	var cols_encroached: int = clampi(day - 5, 0, 10)  # 1 column per day after day 5
	var applied_key := "forest_%d" % cols_encroached
	if _applied_sets.has(applied_key):
		return

	var cells := tilemap.get_used_cells()
	var replaced: int = 0
	for cell in cells:
		if cell.x >= (FOREST_EDGE_START_COL - cols_encroached):
			var atlas := tilemap.get_cell_atlas_coords(cell)
			var tile_id: int = atlas.y * 8 + atlas.x
			if tile_id == TILE_GRASS or tile_id == TILE_DEAD_GRASS:
				if _rng.randf() < 0.5:
					_set_tile(tilemap, cell, TILE_ROOTS)
				else:
					_set_tile(tilemap, cell, TILE_TREE_CANOPY)
				replaced += 1

	_applied_sets[applied_key] = true
	visual_layer_changed.emit("forest_encroachment", float(cols_encroached) / 10.0)
	print("world_state_visuals: Forest encroached %d columns — replaced %d tiles." % [cols_encroached, replaced])


# ---------- Plague / rat infestation ----------

func _update_plague_visuals() -> void:
	if _applied_sets.has("plague"):
		return
	if not GameState.get_state("flag.rat_plague_ashvale", false):
		return

	var tilemap := _get_tilemap()
	if tilemap == null:
		return

	# Mud tiles around well area.
	var replaced: int = 0
	for dy in range(-WELL_MUD_RADIUS, WELL_MUD_RADIUS + 1):
		for dx in range(-WELL_MUD_RADIUS, WELL_MUD_RADIUS + 1):
			var cell := WELL_CENTER + Vector2i(dx, dy)
			_set_tile(tilemap, cell, TILE_MUD)
			replaced += 1

	_applied_sets["plague"] = true
	visual_layer_changed.emit("plague", 1.0)
	print("world_state_visuals: Plague — muddied %d tiles around well." % replaced)


# ---------- War / conflict visuals ----------

func _update_war_visuals() -> void:
	if _applied_sets.has("war"):
		return
	if not GameState.get_state("flag.ashvale_under_siege", false):
		return

	# War visuals are mainly handled by spawned objects; signal for listeners.
	_applied_sets["war"] = true
	visual_layer_changed.emit("war", 1.0)


# ---------- Progressive decay (pact not revealed) ----------

func _update_progressive_decay() -> void:
	var day: int = TimeManager.day
	if day < 5:
		return
	if GameState.get_state("flag.pact_fully_revealed", false):
		return

	var decay_key := "decay_%d" % day
	if _applied_sets.has(decay_key):
		return

	var tilemap := _get_tilemap()
	if tilemap == null:
		return

	# Kill some grass tiles each day the pact remains hidden.
	var cells := tilemap.get_used_cells()
	var grass_cells: Array[Vector2i] = []
	for cell in cells:
		var atlas := tilemap.get_cell_atlas_coords(cell)
		var tile_id: int = atlas.y * 8 + atlas.x
		if tile_id == TILE_GRASS:
			grass_cells.append(cell)

	var kill_count: int = mini(DEAD_GRASS_PER_DAY * (day - 4), grass_cells.size())
	grass_cells.shuffle()
	for i in range(kill_count):
		_set_tile(tilemap, grass_cells[i], TILE_DEAD_GRASS)

	_applied_sets[decay_key] = true
	visual_layer_changed.emit("decay", float(day - 4) / 10.0)


# ---------- Helpers ----------

func _get_tilemap() -> TileMapLayer:
	var parent := get_parent()
	if parent and parent.has_node("TileMapLayer"):
		return parent.get_node("TileMapLayer") as TileMapLayer
	return null


func _set_tile(tilemap: TileMapLayer, cell: Vector2i, tile_id: int) -> void:
	var atlas_x: int = tile_id % 8
	var atlas_y: int = tile_id / 8
	tilemap.set_cell(cell, 0, Vector2i(atlas_x, atlas_y))
