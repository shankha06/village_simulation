@tool
## generate_tilemap.gd — Procedurally generates the Ashvale village tilemap layout.
## Run from the Godot editor via the "Run" button in the script editor, or call
## generate() from another @tool script.
##
## The village is ~40x30 tiles (640x480 px at 16x16).  Tile IDs match the
## canonical mapping shared by generate_tilemap_data.py and the runtime loader
## in region_base.gd.
extends EditorScript


# --- Tile ID constants (must stay in sync with the Python generator) ----------

enum Tile {
	GRASS = 0,
	GRASS_DEAD = 1,
	DIRT = 2,
	DIRT_PATH = 3,
	COBBLESTONE = 4,
	STONE_FLOOR = 5,
	WOOD_FLOOR = 6,
	MUD = 7,
	WATER = 8,
	WATER_SHALLOW = 9,
	FARMLAND_HEALTHY = 10,
	FARMLAND_DEAD = 11,
	FLOWERS_DEAD = 12,
	MUSHROOMS = 13,
	FALLEN_LEAVES = 14,
	ROOTS_CREEPING = 15,
	WALL_STONE = 16,
	WALL_STONE_MOSS = 17,
	WALL_WOOD = 18,
	WALL_WOOD_DAMAGED = 19,
	WALL_CHAPEL = 20,
	WALL_MANOR = 21,
	FENCE_WOOD = 22,
	FENCE_BROKEN = 23,
	DOOR_WOOD = 24,
	DOOR_WOOD_LOCKED = 25,
	DOOR_MANOR = 26,
	STAIRS_DOWN = 27,
	WELL = 28,
	MARKET_STALL = 29,
	BARREL = 30,
	CRATE = 31,
	TREE_TRUNK = 32,
	TREE_CANOPY = 33,
	BUSH = 34,
	BUSH_DEAD = 35,
	ROCK_SMALL = 36,
	ROCK_LARGE = 37,
	GRAVE_MARKER = 38,
	ALTAR_STONE = 39,
	ROOF_THATCH = 40,
	ROOF_TILE = 41,
	CHIMNEY = 42,
	WINDOW_LIT = 43,
	WINDOW_DARK = 44,
	SIGN_HANGING = 45,
	TORCH_WALL = 46,
	BLOOD_SPLATTER = 47,
}

const WIDTH: int = 40
const HEIGHT: int = 30


# ---------------------------------------------------------------------------
# Entry point when run as EditorScript
# ---------------------------------------------------------------------------
func _run() -> void:
	var map: Array = generate()
	# Attempt to paint onto the currently-open scene's TileMapLayer
	var root := get_editor_interface().get_edited_scene_root()
	if root == null:
		push_warning("generate_tilemap: No scene open — tilemap data generated but not painted.")
		return

	var tilemap_layer: TileMapLayer = root.find_child("TileMapLayer", true, false)
	if tilemap_layer == null:
		push_warning("generate_tilemap: Scene has no TileMapLayer node.")
		return

	_paint(tilemap_layer, map)
	print("generate_tilemap: Painted %dx%d Ashvale tilemap." % [WIDTH, HEIGHT])


# ---------------------------------------------------------------------------
# Public: build a 2-D array [y][x] of Tile IDs
# ---------------------------------------------------------------------------
func generate() -> Array:
	var map: Array = []
	for y in range(HEIGHT):
		var row: Array = []
		row.resize(WIDTH)
		row.fill(int(Tile.GRASS))
		map.append(row)

	_fill_base_terrain(map)
	_place_village_square(map)
	_place_chapel(map)
	_place_inn(map)
	_place_elara_cottage(map)
	_place_market(map)
	_place_farmland(map)
	_place_east_forest(map)
	_place_west_road(map)
	_place_southeast(map)
	_place_scattered(map)

	return map


# ---------------------------------------------------------------------------
# Private generation helpers
# ---------------------------------------------------------------------------

func _fill_base_terrain(map: Array) -> void:
	# Edges: dead grass / dirt / fallen leaves
	for x in range(WIDTH):
		for y in range(HEIGHT):
			# Sparse dead grass patches
			if (x + y * 3) % 11 == 0:
				map[y][x] = int(Tile.GRASS_DEAD)
			if (x * 7 + y) % 23 == 0:
				map[y][x] = int(Tile.DIRT)
			# Eastern edge gets darker
			if x >= 34:
				if (x + y) % 3 == 0:
					map[y][x] = int(Tile.FALLEN_LEAVES)
				if (x + y) % 5 == 0:
					map[y][x] = int(Tile.ROOTS_CREEPING)

func _place_village_square(map: Array) -> void:
	# Center cobblestone square roughly 16-24 x, 11-19 y
	for x in range(16, 25):
		for y in range(11, 20):
			map[y][x] = int(Tile.COBBLESTONE)
	# Well right in the middle
	map[15][20] = int(Tile.WELL)
	# Torch posts around square
	map[11][16] = int(Tile.TORCH_WALL)
	map[11][24] = int(Tile.TORCH_WALL)
	map[19][16] = int(Tile.TORCH_WALL)
	map[19][24] = int(Tile.TORCH_WALL)

func _place_chapel(map: Array) -> void:
	# North-center: chapel ~17-23 x, 1-6 y
	for x in range(17, 24):
		map[1][x] = int(Tile.WALL_CHAPEL)
		map[6][x] = int(Tile.WALL_CHAPEL)
	for y in range(1, 7):
		map[y][17] = int(Tile.WALL_CHAPEL)
		map[y][23] = int(Tile.WALL_CHAPEL)
	# Interior stone floor
	for x in range(18, 23):
		for y in range(2, 6):
			map[y][x] = int(Tile.STONE_FLOOR)
	# Altar
	map[2][20] = int(Tile.ALTAR_STONE)
	# Door
	map[6][20] = int(Tile.DOOR_WOOD)
	# Path from chapel to square
	for y in range(7, 12):
		map[y][20] = int(Tile.COBBLESTONE)
	# Grave markers beside chapel
	map[3][15] = int(Tile.GRAVE_MARKER)
	map[4][15] = int(Tile.GRAVE_MARKER)
	map[5][15] = int(Tile.GRAVE_MARKER)
	map[3][25] = int(Tile.GRAVE_MARKER)
	map[4][25] = int(Tile.GRAVE_MARKER)
	# Blood near entrance (dark fantasy touch)
	map[5][20] = int(Tile.BLOOD_SPLATTER)
	# Roof
	for x in range(17, 24):
		map[0][x] = int(Tile.ROOF_TILE)

func _place_inn(map: Array) -> void:
	# Northeast: inn ~28-36 x, 2-9 y
	for x in range(28, 37):
		map[2][x] = int(Tile.WALL_WOOD)
		map[9][x] = int(Tile.WALL_WOOD)
	for y in range(2, 10):
		map[y][28] = int(Tile.WALL_WOOD)
		map[y][36] = int(Tile.WALL_WOOD)
	# Interior
	for x in range(29, 36):
		for y in range(3, 9):
			map[y][x] = int(Tile.WOOD_FLOOR)
	# Damaged wall section
	map[5][36] = int(Tile.WALL_WOOD_DAMAGED)
	# Door
	map[9][32] = int(Tile.DOOR_WOOD)
	# Windows
	map[2][30] = int(Tile.WINDOW_LIT)
	map[2][34] = int(Tile.WINDOW_DARK)
	# Roof
	for x in range(28, 37):
		map[1][x] = int(Tile.ROOF_THATCH)
	map[1][32] = int(Tile.CHIMNEY)
	# Sign
	map[9][33] = int(Tile.SIGN_HANGING)
	# Barrels outside
	map[10][29] = int(Tile.BARREL)
	map[10][30] = int(Tile.BARREL)
	map[10][35] = int(Tile.CRATE)
	# Path from inn to square
	for y in range(10, 15):
		map[y][28] = int(Tile.DIRT_PATH)
	for x in range(25, 28):
		map[14][x] = int(Tile.DIRT_PATH)

func _place_elara_cottage(map: Array) -> void:
	# Northwest: cottage ~3-9 x, 2-6 y
	for x in range(3, 10):
		map[2][x] = int(Tile.WALL_WOOD)
		map[6][x] = int(Tile.WALL_WOOD)
	for y in range(2, 7):
		map[y][3] = int(Tile.WALL_WOOD)
		map[y][9] = int(Tile.WALL_WOOD)
	for x in range(4, 9):
		for y in range(3, 6):
			map[y][x] = int(Tile.WOOD_FLOOR)
	map[6][6] = int(Tile.DOOR_WOOD)
	map[2][5] = int(Tile.WINDOW_LIT)
	for x in range(3, 10):
		map[1][x] = int(Tile.ROOF_THATCH)
	map[1][6] = int(Tile.CHIMNEY)
	# Herb garden: south of cottage
	for x in range(2, 11):
		for y in range(7, 10):
			if (x + y) % 2 == 0:
				map[y][x] = int(Tile.MUSHROOMS)
			else:
				map[y][x] = int(Tile.FLOWERS_DEAD)
	# Fence around garden
	for x in range(2, 11):
		map[7][x] = int(Tile.FENCE_WOOD)
		map[10][x] = int(Tile.FENCE_WOOD)
	for y in range(7, 11):
		map[y][2] = int(Tile.FENCE_WOOD)
		map[y][10] = int(Tile.FENCE_WOOD)
	map[10][6] = int(Tile.FENCE_BROKEN)
	# Path from cottage to square
	for y in range(10, 15):
		map[y][10] = int(Tile.DIRT_PATH)
	for x in range(10, 17):
		map[14][x] = int(Tile.DIRT_PATH)

func _place_market(map: Array) -> void:
	# Southwest: market ~3-14 x, 20-26 y
	for x in range(3, 14):
		for y in range(20, 27):
			map[y][x] = int(Tile.COBBLESTONE)
	# Market stalls
	map[21][4] = int(Tile.MARKET_STALL)
	map[21][7] = int(Tile.MARKET_STALL)
	map[21][10] = int(Tile.MARKET_STALL)
	map[24][5] = int(Tile.MARKET_STALL)
	map[24][9] = int(Tile.MARKET_STALL)
	# Barrels and crates
	map[22][4] = int(Tile.BARREL)
	map[22][5] = int(Tile.CRATE)
	map[25][11] = int(Tile.BARREL)
	map[25][12] = int(Tile.CRATE)
	map[23][10] = int(Tile.BARREL)
	# Path from market to square
	for y in range(19, 21):
		for x in range(14, 17):
			map[y][x] = int(Tile.COBBLESTONE)

func _place_farmland(map: Array) -> void:
	# South: farming fields ~15-30 x, 22-29 y
	for x in range(15, 31):
		for y in range(22, 29):
			if (x + y) % 5 == 0:
				map[y][x] = int(Tile.FARMLAND_HEALTHY)
			elif (x + y) % 3 == 0:
				map[y][x] = int(Tile.FARMLAND_DEAD)
			else:
				map[y][x] = int(Tile.MUD)
	# A scarecrow/fence row
	for x in range(15, 31):
		if x % 4 == 0:
			map[22][x] = int(Tile.FENCE_WOOD)
	# Water trough
	map[25][22] = int(Tile.WATER_SHALLOW)
	map[25][23] = int(Tile.WATER_SHALLOW)

func _place_east_forest(map: Array) -> void:
	# Eastern edge: transition to Thornwood (x >= 34)
	for x in range(34, 40):
		for y in range(0, 30):
			if (x * 3 + y * 7) % 4 == 0:
				map[y][x] = int(Tile.TREE_TRUNK)
			elif (x + y * 5) % 6 == 0:
				map[y][x] = int(Tile.TREE_CANOPY)
			elif (x + y) % 7 == 0:
				map[y][x] = int(Tile.BUSH_DEAD)
	# Path leading east
	for x in range(25, 40):
		map[15][x] = int(Tile.DIRT_PATH)
		if x >= 30:
			map[14][x] = int(Tile.FALLEN_LEAVES)
			map[16][x] = int(Tile.FALLEN_LEAVES)

func _place_west_road(map: Array) -> void:
	# West: cobblestone road leading off-screen toward Ashworth Manor
	for x in range(0, 16):
		map[14][x] = int(Tile.COBBLESTONE)
		map[15][x] = int(Tile.COBBLESTONE)
	# Some stone walls along the road
	map[13][0] = int(Tile.WALL_MANOR)
	map[13][1] = int(Tile.WALL_MANOR)
	map[16][0] = int(Tile.WALL_MANOR)
	map[16][1] = int(Tile.WALL_MANOR)

func _place_southeast(map: Array) -> void:
	# Southeast: Old Maren's bench, forest edge (30-39 x, 22-29 y)
	for x in range(32, 39):
		for y in range(22, 29):
			if (x + y) % 4 == 0:
				map[y][x] = int(Tile.BUSH)
			elif (x * y) % 9 == 0:
				map[y][x] = int(Tile.ROCK_SMALL)
	# Bench area
	map[24][34] = int(Tile.WOOD_FLOOR)
	map[24][35] = int(Tile.WOOD_FLOOR)
	# Nearby torch
	map[23][33] = int(Tile.TORCH_WALL)
	# Path connecting
	for x in range(30, 35):
		map[22][x] = int(Tile.DIRT_PATH)

func _place_scattered(map: Array) -> void:
	# Small houses scattered around the village
	# House 1: south of square
	_place_small_house(map, 18, 20, int(Tile.WALL_WOOD), int(Tile.ROOF_THATCH))
	# House 2: west side
	_place_small_house(map, 1, 14, int(Tile.WALL_STONE_MOSS), int(Tile.ROOF_TILE))
	# Fences along south edge
	for x in range(0, 40):
		if map[29][x] == int(Tile.GRASS) or map[29][x] == int(Tile.GRASS_DEAD):
			if x % 6 == 0:
				map[29][x] = int(Tile.FENCE_BROKEN)
	# Scattered trees in open areas
	_set_if_grass(map, 0, 0, int(Tile.TREE_TRUNK))
	_set_if_grass(map, 1, 0, int(Tile.TREE_CANOPY))
	_set_if_grass(map, 14, 0, int(Tile.TREE_TRUNK))
	_set_if_grass(map, 39, 0, int(Tile.TREE_TRUNK))
	_set_if_grass(map, 0, 29, int(Tile.TREE_TRUNK))
	_set_if_grass(map, 26, 5, int(Tile.TREE_TRUNK))
	_set_if_grass(map, 12, 12, int(Tile.BUSH))
	_set_if_grass(map, 27, 18, int(Tile.ROCK_SMALL))
	_set_if_grass(map, 13, 18, int(Tile.ROCK_LARGE))

func _place_small_house(map: Array, sx: int, sy: int, wall_tile: int, roof_tile: int) -> void:
	# 4x3 house
	for x in range(sx, sx + 4):
		map[sy][x] = wall_tile
		map[sy + 2][x] = wall_tile
	for y in range(sy, sy + 3):
		map[y][sx] = wall_tile
		map[y][sx + 3] = wall_tile
	map[sy + 1][sx + 1] = int(Tile.WOOD_FLOOR)
	map[sy + 1][sx + 2] = int(Tile.WOOD_FLOOR)
	map[sy + 2][sx + 1] = int(Tile.DOOR_WOOD)
	# Roof
	for x in range(sx, sx + 4):
		if sy - 1 >= 0:
			map[sy - 1][x] = roof_tile

func _set_if_grass(map: Array, x: int, y: int, tile: int) -> void:
	if x < 0 or x >= WIDTH or y < 0 or y >= HEIGHT:
		return
	if map[y][x] == int(Tile.GRASS) or map[y][x] == int(Tile.GRASS_DEAD) or map[y][x] == int(Tile.DIRT):
		map[y][x] = tile


# ---------------------------------------------------------------------------
# Paint a 2-D tile array onto a TileMapLayer.
# Assumes atlas source 0 with columns = 8 (48 tiles / 8 = 6 rows).
# ---------------------------------------------------------------------------
func _paint(layer: TileMapLayer, map: Array) -> void:
	var atlas_columns: int = 8
	for y in range(map.size()):
		var row: Array = map[y]
		for x in range(row.size()):
			var tile_id: int = row[x]
			var atlas_x: int = tile_id % atlas_columns
			var atlas_y: int = tile_id / atlas_columns
			layer.set_cell(Vector2i(x, y), 0, Vector2i(atlas_x, atlas_y))
