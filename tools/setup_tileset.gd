@tool
## setup_tileset.gd — Creates a TileSet resource from terrain_tileset.png.
##
## Run as an EditorScript inside the Godot editor.  It will:
##   1. Load the terrain tileset texture.
##   2. Build a TileSetAtlasSource with 16x16 tiles.
##   3. Add a physics layer for walls/obstacles.
##   4. Save the result to res://scenes/world/ashvale_tileset.tres.
extends EditorScript

const TILE_SIZE := Vector2i(16, 16)
const ATLAS_COLUMNS := 8  # 8 tiles per row in the atlas
const TILE_COUNT := 48
const TEXTURE_PATH := "res://assets/sprites/tilesets/terrain_tileset.png"
const OUTPUT_PATH := "res://scenes/world/ashvale_tileset.tres"

# Tiles that should have physics collision (walls, obstacles, solid objects).
const SOLID_TILES: Array[int] = [
	16, 17, 18, 19, 20, 21,  # walls
	22, 23,                    # fences
	28,                        # well
	30, 31,                    # barrel, crate
	32, 37,                    # tree trunk, rock large
	39,                        # altar stone
]


func _run() -> void:
	var texture: Texture2D = load(TEXTURE_PATH)
	if texture == null:
		push_error("setup_tileset: Could not load texture at %s" % TEXTURE_PATH)
		return

	# --- TileSet -------------------------------------------------------
	var tileset := TileSet.new()
	tileset.tile_size = TILE_SIZE

	# Physics layer 0 — collision for walls / obstacles
	tileset.add_physics_layer()
	tileset.set_physics_layer_collision_layer(0, 1)   # layer bit 1
	tileset.set_physics_layer_collision_mask(0, 1)

	# --- Atlas source --------------------------------------------------
	var atlas := TileSetAtlasSource.new()
	atlas.texture = texture
	atlas.texture_region_size = TILE_SIZE

	var source_id: int = tileset.add_source(atlas, 0)  # source id = 0

	# Create tiles in the atlas
	var rows := ceili(float(TILE_COUNT) / ATLAS_COLUMNS)
	for idx in range(TILE_COUNT):
		var atlas_coords := Vector2i(idx % ATLAS_COLUMNS, idx / ATLAS_COLUMNS)
		atlas.create_tile(atlas_coords)

		# Assign collision to solid tiles
		if idx in SOLID_TILES:
			var tile_data: TileData = atlas.get_tile_data(atlas_coords, 0)
			if tile_data:
				# Full-tile collision polygon
				var polygon := PackedVector2Array([
					Vector2(0, 0),
					Vector2(TILE_SIZE.x, 0),
					Vector2(TILE_SIZE.x, TILE_SIZE.y),
					Vector2(0, TILE_SIZE.y),
				])
				tile_data.add_collision_polygon(0)
				tile_data.set_collision_polygon_points(0, 0, polygon)

	# --- Save -----------------------------------------------------------
	var err := ResourceSaver.save(tileset, OUTPUT_PATH)
	if err != OK:
		push_error("setup_tileset: Failed to save TileSet — error %d" % err)
	else:
		print("setup_tileset: Saved TileSet to %s (%d tiles, %d solid)." % [
			OUTPUT_PATH, TILE_COUNT, SOLID_TILES.size()
		])
