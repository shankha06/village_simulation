## RegionBase — base script for all region/map scenes.
## Handles NPC spawning, visual state swaps, and transition zones.
extends Node2D

@export var region_id: String = ""
@export var region_name: String = ""
@export var adjacent_regions: PackedStringArray = []

## Path to JSON tilemap file. If set, tiles are painted automatically at _ready().
@export var tilemap_json: String = ""

## Optional audio paths for this region. Set in inspector or override in subclass.
@export var ambience_day: String = "res://assets/audio/ambience/village_day.wav"
@export var ambience_night: String = "res://assets/audio/ambience/village_night.wav"
@export var region_music: String = "res://assets/audio/music/ashvale_theme.wav"

# Visual swap targets: {swap_id: {default: NodePath, variants: {variant_name: NodePath}}}
@export var visual_swap_map: Dictionary = {}

# NPC spawn points: {npc_id: spawn_marker_path}
@export var npc_spawn_points: Dictionary = {}

# Player spawn points for transitions: {spawn_id: marker_path}
@export var player_spawn_points: Dictionary = {}

@onready var tilemap: TileMapLayer = $TileMapLayer if has_node("TileMapLayer") else null


func _ready() -> void:
	# Register region with GameState
	GameState.set_state("player.current_region", region_id)
	GameState.set_state("player.last_region", region_id)
	GameState.set_state("player.last_region_name", region_name)

	# Auto-detect spawn points from scene children
	_auto_detect_spawn_points()

	# Build and assign TileSet, then paint tiles from JSON
	if tilemap and tilemap_json != "":
		_setup_tileset_and_paint()

	# Listen for visual swaps
	EventBus.visual_swap_requested.connect(_on_visual_swap)

	# Apply existing visual state
	_apply_saved_visuals()

	# Spawn NPCs
	_spawn_npcs()

	# Spawn interactable world objects
	_spawn_interactables()

	# Apply dynamic tile changes based on world state
	apply_dynamic_tile_changes()

	# Start region audio
	_start_region_audio()

	# Add day/night cycle tinting
	_setup_day_night_cycle()

	# Autosave on region entry
	SaveManager.autosave()


## Auto-detect player and NPC spawn points from child Marker2D nodes.
func _auto_detect_spawn_points() -> void:
	# Player spawn points: look under "SpawnPoints" node
	var sp_node: Node = get_node_or_null("SpawnPoints")
	if sp_node:
		for child in sp_node.get_children():
			if child is Marker2D:
				var spawn_name: String = child.name.to_snake_case().replace("_spawn", "")
				player_spawn_points[spawn_name] = "SpawnPoints/%s" % child.name

	# NPC spawn points: look under "NPCSpawnPoints" node
	var npc_sp: Node = get_node_or_null("NPCSpawnPoints")
	if npc_sp:
		for child in npc_sp.get_children():
			if child is Marker2D:
				# Convert "ElaraSpawn" -> "elara"
				var npc_name: String = child.name.replace("Spawn", "").to_snake_case()
				npc_spawn_points[npc_name] = "NPCSpawnPoints/%s" % child.name


## Build a TileSet from the tileset texture and paint the tilemap from JSON.
func _setup_tileset_and_paint() -> void:
	var tex_path: String = "res://assets/sprites/tilesets/terrain_tileset.png"
	var texture: Texture2D = load(tex_path)
	if texture == null:
		push_warning("region_base: Cannot load tileset texture at %s" % tex_path)
		return

	# Create TileSet programmatically
	var ts := TileSet.new()
	ts.tile_size = Vector2i(16, 16)

	# Create atlas source
	var source := TileSetAtlasSource.new()
	source.texture = texture
	source.texture_region_size = Vector2i(16, 16)

	var tex_w: int = texture.get_width()
	var tex_h: int = texture.get_height()
	var cols: int = tex_w / 16
	var rows: int = tex_h / 16

	for y in range(rows):
		for x in range(cols):
			source.create_tile(Vector2i(x, y))

	ts.add_source(source, 0)

	# Add physics layer for solid tile collisions
	ts.add_physics_layer()

	# Solid tile IDs: walls (16-21), fences (22-23), well (28), barrels (30),
	# crates (31), tree trunk (32), rocks (36-37)
	# Solid tiles: walls, fences, well, barrels, crates, trees, rocks, roofs, water
	var solid_ids: Array[int] = [16, 17, 18, 19, 20, 21, 22, 23, 28, 30, 31, 32, 33, 36, 37, 40, 41, 8]
	var full_tile_polygon := PackedVector2Array([
		Vector2(0, 0), Vector2(16, 0), Vector2(16, 16), Vector2(0, 16)
	])
	for tile_id in solid_ids:
		var ax: int = tile_id % ATLAS_COLUMNS
		var ay: int = tile_id / ATLAS_COLUMNS
		var coords := Vector2i(ax, ay)
		if ax < cols and ay < rows:
			var tile_data: TileData = source.get_tile_data(coords, 0)
			if tile_data:
				tile_data.add_collision_polygon(0)
				tile_data.set_collision_polygon_points(0, 0, full_tile_polygon)

	tilemap.tile_set = ts
	tilemap.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	tilemap.position = tilemap.position.round()
	
	load_tilemap_from_json(tilemap_json)


## Start ambient sound and music for this region based on time of day.
func _start_region_audio() -> void:
	# Pick ambient track by time of day
	var time_period: String = GameState.get_state("world.time_period", "day")
	var amb_path: String = ambience_night if time_period == "night" else ambience_day
	if amb_path != "":
		AudioManager.play_ambience(amb_path)

	# Start region music
	if region_music != "":
		AudioManager.play_music(region_music)


## Spawn the player at a named spawn point.
func spawn_player_at(spawn_id: String) -> void:
	var player: CharacterBody2D = get_tree().get_first_node_in_group("player")
	if player == null:
		return

	if player_spawn_points.has(spawn_id):
		var marker_path: String = player_spawn_points[spawn_id]
		var marker: Node2D = get_node_or_null(marker_path)
		if marker:
			player.global_position = marker.global_position
			return

	# Fallback: check for a "default" spawn point
	if player_spawn_points.has("default"):
		var marker_path: String = player_spawn_points["default"]
		var marker: Node2D = get_node_or_null(marker_path)
		if marker:
			player.global_position = marker.global_position


## Get the region's current status from GameState.
func get_region_status() -> String:
	return GameState.get_state("world.region.%s.status" % region_id, "normal")


# --- Private ---

## Spawn interactable world objects from a JSON data file.
## Looks for res://data/world/{region_id}_interactables.json.
func _spawn_interactables() -> void:
	var json_path: String = "res://data/world/%s_interactables.json" % region_id
	if not FileAccess.file_exists(json_path):
		return

	var file := FileAccess.open(json_path, FileAccess.READ)
	if file == null:
		push_warning("region_base: Could not open interactables file: %s" % json_path)
		return

	var json := JSON.new()
	var err := json.parse(file.get_as_text())
	file.close()
	if err != OK:
		push_warning("region_base: JSON parse error in %s: %s" % [json_path, json.get_error_message()])
		return

	var data: Dictionary = json.data
	var entries: Array = data.get("interactables", [])

	# Create or get container node.
	var container: Node2D = get_node_or_null("Interactables")
	if container == null:
		container = Node2D.new()
		container.name = "Interactables"
		add_child(container)

	for entry in entries:
		var obj := Interactable.new()
		obj.interact_id = entry.get("id", "")
		obj.interact_type = entry.get("type", "examine")
		obj.display_name = entry.get("name", "")
		obj.interaction_text = entry.get("text", "")
		obj.state_condition = entry.get("state_condition", "")
		obj.state_alt_text = entry.get("state_alt_text", "")
		obj.one_shot = entry.get("one_shot", false)
		obj.gives_item = entry.get("gives_item", "")
		obj.sets_flag = entry.get("sets_flag", "")
		obj.required_item = entry.get("required_item", "")
		obj.locked_text = entry.get("locked_text", "You need something to interact with this.")
		obj.name = "Interactable_%s" % entry.get("id", "unknown")

		var pos: Array = entry.get("position", [0, 0])
		obj.position = Vector2(pos[0], pos[1])

		container.add_child(obj)

	print("region_base: Spawned %d interactables for %s" % [entries.size(), region_id])


## Create a DayNightCycle CanvasModulate if the script exists.
func _setup_day_night_cycle() -> void:
	var script_res: Script = load("res://scenes/effects/day_night_cycle.gd")
	if script_res == null:
		return
	var cycle := CanvasModulate.new()
	cycle.set_script(script_res)
	cycle.name = "DayNightCycle"
	add_child(cycle)


func _spawn_npcs() -> void:
	for spawn_npc_id in npc_spawn_points:
		# Check if NPC is alive
		if not GameState.get_state("npc.%s.alive" % spawn_npc_id, true):
			continue

		var spawn_path: String = npc_spawn_points[spawn_npc_id]
		var spawn_point: Node2D = get_node_or_null(spawn_path)
		if spawn_point == null:
			continue

		# Load and instance NPC scene
		var npc_scene: PackedScene = load("res://scenes/npcs/npc_base.tscn")
		if npc_scene:
			var npc: CharacterBody2D = npc_scene.instantiate()
			npc.npc_id = spawn_npc_id
			npc.global_position = spawn_point.global_position
			add_child(npc)


func _apply_saved_visuals() -> void:
	# Check GameState for any visual overrides in this region
	var prefix: String = "world.region.%s." % region_id
	var keys: Array[String] = GameState.get_keys_with_prefix(prefix)
	for key in keys:
		if key.ends_with("_visual"):
			var swap_id: String = key.get_slice(".", 3).replace("_visual", "")
			var variant: String = GameState.get_state(key, "default")
			_apply_visual_swap(swap_id, variant)


func _on_visual_swap(swap_id: String, variant: String) -> void:
	_apply_visual_swap(swap_id, variant)


func _apply_visual_swap(swap_id: String, variant: String) -> void:
	if not visual_swap_map.has(swap_id):
		return

	var swap_data: Dictionary = visual_swap_map[swap_id]

	# Hide all variants
	for key in swap_data:
		var node: Node = get_node_or_null(swap_data[key])
		if node:
			node.visible = (key == variant)


# --- Tilemap JSON loader --------------------------------------------------

## Number of tile columns in the atlas texture (must match setup_tileset.gd).
const ATLAS_COLUMNS: int = 16

## Load a JSON tilemap file and paint it onto this region's TileMapLayer.
##
## The JSON is expected to have:
##   "width"  : int
##   "height" : int
##   "tiles"  : Array[Array[int]]   — row-major 2-D tile-ID grid
##   "legend" : Dictionary           — tile-ID -> name (informational)
##
## Each tile ID is mapped to atlas coordinates via:
##   atlas_x = tile_id % ATLAS_COLUMNS
##   atlas_y = tile_id / ATLAS_COLUMNS
## The atlas source ID is assumed to be 0.
func load_tilemap_from_json(json_path: String) -> void:
	if tilemap == null:
		push_error("region_base: No TileMapLayer found — cannot load tilemap.")
		return

	# Read and parse the JSON file
	if not FileAccess.file_exists(json_path):
		push_error("region_base: Tilemap JSON not found at %s" % json_path)
		return

	var file := FileAccess.open(json_path, FileAccess.READ)
	if file == null:
		push_error("region_base: Could not open %s — error %d" % [json_path, FileAccess.get_open_error()])
		return

	var text: String = file.get_as_text()
	file.close()

	var json := JSON.new()
	var err := json.parse(text)
	if err != OK:
		push_error("region_base: JSON parse error at line %d: %s" % [json.get_error_line(), json.get_error_message()])
		return

	var data: Dictionary = json.data
	if not data.has("tiles"):
		push_error("region_base: JSON missing 'tiles' key.")
		return

	var tiles: Array = data["tiles"]
	var map_height: int = tiles.size()
	if map_height == 0:
		push_warning("region_base: Tilemap has zero rows.")
		return

	var map_width: int = tiles[0].size()

	# Clear existing tiles
	tilemap.clear()

	# Paint every cell
	for y in range(map_height):
		var row: Array = tiles[y]
		for x in range(row.size()):
			var tile_id: int = int(row[x])
			var atlas_x: int = tile_id % ATLAS_COLUMNS
			var atlas_y: int = tile_id / ATLAS_COLUMNS
			tilemap.set_cell(Vector2i(x, y), 0, Vector2i(atlas_x, atlas_y))

	# Add invisible boundary walls around the map edge
	_add_map_boundaries(map_width, map_height)

	print("region_base: Loaded %dx%d tilemap from %s" % [map_width, map_height, json_path])


## Add invisible collision walls around the map edge so the player cannot leave.
## Also adds a camera limit to prevent seeing the void.
func _add_map_boundaries(map_w: int, map_h: int) -> void:
	var tile_size: int = 16
	var pixel_w: float = map_w * tile_size
	var pixel_h: float = map_h * tile_size
	var wall_thickness: float = 16.0

	# Create a StaticBody2D with 4 wall segments around the map
	var boundary := StaticBody2D.new()
	boundary.name = "MapBoundary"
	boundary.collision_layer = 4  # Environment layer
	boundary.collision_mask = 0
	add_child(boundary)

	# Top wall
	var top := CollisionShape2D.new()
	var top_shape := RectangleShape2D.new()
	top_shape.size = Vector2(pixel_w + wall_thickness * 2, wall_thickness)
	top.shape = top_shape
	top.position = Vector2(pixel_w / 2.0, -wall_thickness / 2.0)
	boundary.add_child(top)

	# Bottom wall
	var bottom := CollisionShape2D.new()
	var bottom_shape := RectangleShape2D.new()
	bottom_shape.size = Vector2(pixel_w + wall_thickness * 2, wall_thickness)
	bottom.shape = bottom_shape
	bottom.position = Vector2(pixel_w / 2.0, pixel_h + wall_thickness / 2.0)
	boundary.add_child(bottom)

	# Left wall
	var left := CollisionShape2D.new()
	var left_shape := RectangleShape2D.new()
	left_shape.size = Vector2(wall_thickness, pixel_h + wall_thickness * 2)
	left.shape = left_shape
	left.position = Vector2(-wall_thickness / 2.0, pixel_h / 2.0)
	boundary.add_child(left)

	# Right wall
	var right := CollisionShape2D.new()
	var right_shape := RectangleShape2D.new()
	right_shape.size = Vector2(wall_thickness, pixel_h + wall_thickness * 2)
	right.shape = right_shape
	right.position = Vector2(pixel_w + wall_thickness / 2.0, pixel_h / 2.0)
	boundary.add_child(right)

	# Set camera limits on the player's camera to prevent seeing the void
	var player: Node = get_tree().get_first_node_in_group("player")
	if player:
		var camera: Camera2D = player.get_node_or_null("Camera2D")
		if camera:
			camera.limit_left = 0
			camera.limit_top = 0
			camera.limit_right = int(pixel_w)
			camera.limit_bottom = int(pixel_h)
			camera.limit_smoothed = true


# --- Dynamic tile changes based on world state -----------------------------------

## Tile IDs matching the terrain atlas.
const TILE_DIRT: int = 5
const TILE_DEAD_GRASS: int = 6
const TILE_MUD: int = 7
const TILE_BLOOD: int = 8
const TILE_FARMLAND_HEALTHY: int = 10
const TILE_FARMLAND_DEAD: int = 11
const TILE_ROOTS: int = 15
const TILE_GRASS: int = 0
const TILE_TREE_CANOPY: int = 33

## Apply immediate tile modifications based on current GameState flags.
## Called from _ready() after the tilemap has been loaded.
func apply_dynamic_tile_changes() -> void:
	if tilemap == null:
		return

	var rng := RandomNumberGenerator.new()
	rng.randomize()

	# --- Silo destroyed: scorch the area around (350,60) -> tile (22,4) ---
	if GameState.get_state("flag.silo_destroyed", false):
		var silo_center := Vector2i(22, 4)
		var radius: int = 3
		for dy in range(-radius, radius + 1):
			for dx in range(-radius, radius + 1):
				var cell := silo_center + Vector2i(dx, dy)
				var dist: int = absi(dx) + absi(dy)
				if dist <= radius:
					if dist <= 1:
						_paint_tile(cell, TILE_BLOOD)
					else:
						_paint_tile(cell, TILE_DIRT)
		print("region_base: Dynamic tiles — silo destruction applied.")

	# --- Famine: kill farmland ---
	if GameState.get_state("world.region.%s.status" % region_id, "normal") == "famine":
		var cells := tilemap.get_used_cells()
		for cell in cells:
			var tid := _read_tile_id(cell)
			if tid == TILE_FARMLAND_HEALTHY and rng.randf() < 0.6:
				_paint_tile(cell, TILE_FARMLAND_DEAD)
		print("region_base: Dynamic tiles — famine farmland decay applied.")

	# --- Forest encroaching: roots and canopy on eastern edge ---
	if GameState.get_state("flag.forest_encroaching", false):
		var day: int = TimeManager.day
		var cols: int = clampi(day - 5, 1, 10)
		var edge_start: int = 38
		var cells := tilemap.get_used_cells()
		for cell in cells:
			if cell.x >= (edge_start - cols):
				var tid := _read_tile_id(cell)
				if tid == TILE_GRASS or tid == TILE_DEAD_GRASS:
					_paint_tile(cell, TILE_ROOTS if rng.randf() < 0.5 else TILE_TREE_CANOPY)
		print("region_base: Dynamic tiles — forest encroachment applied (%d cols)." % cols)

	# --- Rat plague: mud around the well area ---
	if GameState.get_state("flag.rat_plague_ashvale", false):
		var well_center := Vector2i(10, 10)
		var mud_radius: int = 2
		for dy in range(-mud_radius, mud_radius + 1):
			for dx in range(-mud_radius, mud_radius + 1):
				_paint_tile(well_center + Vector2i(dx, dy), TILE_MUD)
		print("region_base: Dynamic tiles — rat plague mud applied.")

	# --- Progressive decay: pact not revealed after day 5 ---
	var current_day: int = TimeManager.day
	if current_day >= 5 and not GameState.get_state("flag.pact_fully_revealed", false):
		var cells := tilemap.get_used_cells()
		var grass_cells: Array[Vector2i] = []
		for cell in cells:
			if _read_tile_id(cell) == TILE_GRASS:
				grass_cells.append(cell)
		var kill_count: int = mini(12 * (current_day - 4), grass_cells.size())
		grass_cells.shuffle()
		for i in range(kill_count):
			_paint_tile(grass_cells[i], TILE_DEAD_GRASS)
		print("region_base: Dynamic tiles — progressive decay (%d grass tiles killed)." % kill_count)


## Paint a single tile by tile ID, using the atlas column count.
func _paint_tile(cell: Vector2i, tile_id: int) -> void:
	var ax: int = tile_id % ATLAS_COLUMNS
	var ay: int = tile_id / ATLAS_COLUMNS
	tilemap.set_cell(cell, 0, Vector2i(ax, ay))


## Read the tile ID from atlas coords at a cell.
func _read_tile_id(cell: Vector2i) -> int:
	var atlas := tilemap.get_cell_atlas_coords(cell)
	if atlas == Vector2i(-1, -1):
		return -1
	return atlas.y * ATLAS_COLUMNS + atlas.x
