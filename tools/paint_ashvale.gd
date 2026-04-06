@tool
## paint_ashvale.gd — Paints the Ashvale village tilemap onto the open scene.
##
## This EditorScript:
##   1. Loads (or generates) the TileSet at res://scenes/world/ashvale_tileset.tres.
##   2. Generates the tilemap layout via generate_tilemap.gd.
##   3. Paints every tile onto the TileMapLayer in the active scene.
##
## Usage: open ashvale_village.tscn in the editor, then run this script.
extends EditorScript

const TILESET_PATH := "res://scenes/world/ashvale_tileset.tres"
const ATLAS_COLUMNS := 8


func _run() -> void:
	var root := get_editor_interface().get_edited_scene_root()
	if root == null:
		push_error("paint_ashvale: No scene is open.")
		return

	var tilemap_layer: TileMapLayer = root.find_child("TileMapLayer", true, false)
	if tilemap_layer == null:
		push_error("paint_ashvale: The open scene has no TileMapLayer node.")
		return

	# Load TileSet
	var tileset: TileSet = load(TILESET_PATH)
	if tileset == null:
		push_error("paint_ashvale: TileSet not found at %s — run setup_tileset.gd first." % TILESET_PATH)
		return

	tilemap_layer.tile_set = tileset

	# Generate the village layout
	var generator := preload("res://tools/generate_tilemap.gd").new()
	var map: Array = generator.generate()

	# Paint tiles
	for y in range(map.size()):
		var row: Array = map[y]
		for x in range(row.size()):
			var tile_id: int = row[x]
			var atlas_coords := Vector2i(tile_id % ATLAS_COLUMNS, tile_id / ATLAS_COLUMNS)
			tilemap_layer.set_cell(Vector2i(x, y), 0, atlas_coords)

	print("paint_ashvale: Painted %dx%d tilemap with %d unique tile types." % [
		map[0].size(), map.size(), _count_unique(map)
	])


func _count_unique(map: Array) -> int:
	var seen := {}
	for row in map:
		for cell in row:
			seen[cell] = true
	return seen.size()
