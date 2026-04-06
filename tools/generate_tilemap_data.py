#!/usr/bin/env python3
"""generate_tilemap_data.py — Produce data/world/ashvale_tilemap.json.

Run with:  uv run python tools/generate_tilemap_data.py

The JSON contains:
  - legend : dict mapping tile-ID strings to human-readable names
  - width / height : map dimensions
  - tiles : 2-D array [row][col] of integer tile IDs

The layout mirrors the Godot @tool generator in generate_tilemap.gd so the
runtime loader in region_base.gd can paint the TileMapLayer without needing
the Godot editor's tilemap painter.
"""

from __future__ import annotations

import json
import pathlib

# ── Tile IDs (canonical mapping) ──────────────────────────────────────────

TILE_LEGEND: dict[int, str] = {
    0: "grass",
    1: "grass_dead",
    2: "dirt",
    3: "dirt_path",
    4: "cobblestone",
    5: "stone_floor",
    6: "wood_floor",
    7: "mud",
    8: "water",
    9: "water_shallow",
    10: "farmland_healthy",
    11: "farmland_dead",
    12: "flowers_dead",
    13: "mushrooms",
    14: "fallen_leaves",
    15: "roots_creeping",
    16: "wall_stone",
    17: "wall_stone_moss",
    18: "wall_wood",
    19: "wall_wood_damaged",
    20: "wall_chapel",
    21: "wall_manor",
    22: "fence_wood",
    23: "fence_broken",
    24: "door_wood",
    25: "door_wood_locked",
    26: "door_manor",
    27: "stairs_down",
    28: "well",
    29: "market_stall",
    30: "barrel",
    31: "crate",
    32: "tree_trunk",
    33: "tree_canopy",
    34: "bush",
    35: "bush_dead",
    36: "rock_small",
    37: "rock_large",
    38: "grave_marker",
    39: "altar_stone",
    40: "roof_thatch",
    41: "roof_tile",
    42: "chimney",
    43: "window_lit",
    44: "window_dark",
    45: "sign_hanging",
    46: "torch_wall",
    47: "blood_splatter",
}

WIDTH = 40
HEIGHT = 30

T = type("T", (), {name.upper(): tid for tid, name in TILE_LEGEND.items()})()


# ── Helper utilities ──────────────────────────────────────────────────────

def _new_map() -> list[list[int]]:
    return [[T.GRASS] * WIDTH for _ in range(HEIGHT)]


def _rect(m: list[list[int]], x0: int, y0: int, x1: int, y1: int, tid: int) -> None:
    """Fill a rectangular region (inclusive on both ends)."""
    for y in range(max(0, y0), min(HEIGHT, y1 + 1)):
        for x in range(max(0, x0), min(WIDTH, x1 + 1)):
            m[y][x] = tid


def _border(m: list[list[int]], x0: int, y0: int, x1: int, y1: int, tid: int) -> None:
    """Draw the border of a rectangle."""
    for x in range(x0, x1 + 1):
        if 0 <= y0 < HEIGHT and 0 <= x < WIDTH:
            m[y0][x] = tid
        if 0 <= y1 < HEIGHT and 0 <= x < WIDTH:
            m[y1][x] = tid
    for y in range(y0, y1 + 1):
        if 0 <= y < HEIGHT and 0 <= x0 < WIDTH:
            m[y][x0] = tid
        if 0 <= y < HEIGHT and 0 <= x1 < WIDTH:
            m[y][x1] = tid


def _set(m: list[list[int]], x: int, y: int, tid: int) -> None:
    if 0 <= x < WIDTH and 0 <= y < HEIGHT:
        m[y][x] = tid


def _set_if_grass(m: list[list[int]], x: int, y: int, tid: int) -> None:
    if 0 <= x < WIDTH and 0 <= y < HEIGHT:
        if m[y][x] in (T.GRASS, T.GRASS_DEAD, T.DIRT):
            m[y][x] = tid


# ── Layout generators ────────────────────────────────────────────────────

def _fill_base_terrain(m: list[list[int]]) -> None:
    for y in range(HEIGHT):
        for x in range(WIDTH):
            if (x + y * 3) % 11 == 0:
                m[y][x] = T.GRASS_DEAD
            if (x * 7 + y) % 23 == 0:
                m[y][x] = T.DIRT
            if x >= 34:
                if (x + y) % 3 == 0:
                    m[y][x] = T.FALLEN_LEAVES
                if (x + y) % 5 == 0:
                    m[y][x] = T.ROOTS_CREEPING


def _place_village_square(m: list[list[int]]) -> None:
    _rect(m, 16, 11, 24, 19, T.COBBLESTONE)
    _set(m, 20, 15, T.WELL)
    _set(m, 16, 11, T.TORCH_WALL)
    _set(m, 24, 11, T.TORCH_WALL)
    _set(m, 16, 19, T.TORCH_WALL)
    _set(m, 24, 19, T.TORCH_WALL)


def _place_chapel(m: list[list[int]]) -> None:
    _border(m, 17, 1, 23, 6, T.WALL_CHAPEL)
    _rect(m, 18, 2, 22, 5, T.STONE_FLOOR)
    _set(m, 20, 2, T.ALTAR_STONE)
    _set(m, 20, 6, T.DOOR_WOOD)
    for y in range(7, 12):
        _set(m, 20, y, T.COBBLESTONE)
    _set(m, 15, 3, T.GRAVE_MARKER)
    _set(m, 15, 4, T.GRAVE_MARKER)
    _set(m, 15, 5, T.GRAVE_MARKER)
    _set(m, 25, 3, T.GRAVE_MARKER)
    _set(m, 25, 4, T.GRAVE_MARKER)
    _set(m, 20, 5, T.BLOOD_SPLATTER)
    for x in range(17, 24):
        _set(m, x, 0, T.ROOF_TILE)


def _place_inn(m: list[list[int]]) -> None:
    _border(m, 28, 2, 36, 9, T.WALL_WOOD)
    _rect(m, 29, 3, 35, 8, T.WOOD_FLOOR)
    _set(m, 36, 5, T.WALL_WOOD_DAMAGED)
    _set(m, 32, 9, T.DOOR_WOOD)
    _set(m, 30, 2, T.WINDOW_LIT)
    _set(m, 34, 2, T.WINDOW_DARK)
    for x in range(28, 37):
        _set(m, x, 1, T.ROOF_THATCH)
    _set(m, 32, 1, T.CHIMNEY)
    _set(m, 33, 9, T.SIGN_HANGING)
    _set(m, 29, 10, T.BARREL)
    _set(m, 30, 10, T.BARREL)
    _set(m, 35, 10, T.CRATE)
    for y in range(10, 15):
        _set(m, 28, y, T.DIRT_PATH)
    for x in range(25, 28):
        _set(m, x, 14, T.DIRT_PATH)


def _place_elara_cottage(m: list[list[int]]) -> None:
    _border(m, 3, 2, 9, 6, T.WALL_WOOD)
    _rect(m, 4, 3, 8, 5, T.WOOD_FLOOR)
    _set(m, 6, 6, T.DOOR_WOOD)
    _set(m, 5, 2, T.WINDOW_LIT)
    for x in range(3, 10):
        _set(m, x, 1, T.ROOF_THATCH)
    _set(m, 6, 1, T.CHIMNEY)
    # Herb garden
    for x in range(2, 11):
        for y in range(7, 10):
            if (x + y) % 2 == 0:
                _set(m, x, y, T.MUSHROOMS)
            else:
                _set(m, x, y, T.FLOWERS_DEAD)
    _border(m, 2, 7, 10, 10, T.FENCE_WOOD)
    _set(m, 6, 10, T.FENCE_BROKEN)
    # Path to square
    for y in range(10, 15):
        _set(m, 10, y, T.DIRT_PATH)
    for x in range(10, 17):
        _set(m, x, 14, T.DIRT_PATH)


def _place_market(m: list[list[int]]) -> None:
    _rect(m, 3, 20, 13, 26, T.COBBLESTONE)
    _set(m, 4, 21, T.MARKET_STALL)
    _set(m, 7, 21, T.MARKET_STALL)
    _set(m, 10, 21, T.MARKET_STALL)
    _set(m, 5, 24, T.MARKET_STALL)
    _set(m, 9, 24, T.MARKET_STALL)
    _set(m, 4, 22, T.BARREL)
    _set(m, 5, 22, T.CRATE)
    _set(m, 11, 25, T.BARREL)
    _set(m, 12, 25, T.CRATE)
    _set(m, 10, 23, T.BARREL)
    _rect(m, 14, 19, 16, 20, T.COBBLESTONE)


def _place_farmland(m: list[list[int]]) -> None:
    for x in range(15, 31):
        for y in range(22, 29):
            if (x + y) % 5 == 0:
                _set(m, x, y, T.FARMLAND_HEALTHY)
            elif (x + y) % 3 == 0:
                _set(m, x, y, T.FARMLAND_DEAD)
            else:
                _set(m, x, y, T.MUD)
    for x in range(15, 31):
        if x % 4 == 0:
            _set(m, x, 22, T.FENCE_WOOD)
    _set(m, 22, 25, T.WATER_SHALLOW)
    _set(m, 23, 25, T.WATER_SHALLOW)


def _place_east_forest(m: list[list[int]]) -> None:
    for x in range(34, 40):
        for y in range(HEIGHT):
            if (x * 3 + y * 7) % 4 == 0:
                _set(m, x, y, T.TREE_TRUNK)
            elif (x + y * 5) % 6 == 0:
                _set(m, x, y, T.TREE_CANOPY)
            elif (x + y) % 7 == 0:
                _set(m, x, y, T.BUSH_DEAD)
    for x in range(25, 40):
        _set(m, x, 15, T.DIRT_PATH)
        if x >= 30:
            _set(m, x, 14, T.FALLEN_LEAVES)
            _set(m, x, 16, T.FALLEN_LEAVES)


def _place_west_road(m: list[list[int]]) -> None:
    for x in range(0, 16):
        _set(m, x, 14, T.COBBLESTONE)
        _set(m, x, 15, T.COBBLESTONE)
    _set(m, 0, 13, T.WALL_MANOR)
    _set(m, 1, 13, T.WALL_MANOR)
    _set(m, 0, 16, T.WALL_MANOR)
    _set(m, 1, 16, T.WALL_MANOR)


def _place_southeast(m: list[list[int]]) -> None:
    for x in range(32, 39):
        for y in range(22, 29):
            if (x + y) % 4 == 0:
                _set(m, x, y, T.BUSH)
            elif (x * y) % 9 == 0:
                _set(m, x, y, T.ROCK_SMALL)
    _set(m, 34, 24, T.WOOD_FLOOR)
    _set(m, 35, 24, T.WOOD_FLOOR)
    _set(m, 33, 23, T.TORCH_WALL)
    for x in range(30, 35):
        _set(m, x, 22, T.DIRT_PATH)


def _place_scattered(m: list[list[int]]) -> None:
    # Small house south of square
    _place_small_house(m, 18, 20, T.WALL_WOOD, T.ROOF_THATCH)
    # Small house west side
    _place_small_house(m, 1, 14, T.WALL_STONE_MOSS, T.ROOF_TILE)
    # Broken fences along south edge
    for x in range(WIDTH):
        if m[29][x] in (T.GRASS, T.GRASS_DEAD):
            if x % 6 == 0:
                m[29][x] = T.FENCE_BROKEN
    # Scattered trees
    _set_if_grass(m, 0, 0, T.TREE_TRUNK)
    _set_if_grass(m, 1, 0, T.TREE_CANOPY)
    _set_if_grass(m, 14, 0, T.TREE_TRUNK)
    _set_if_grass(m, 39, 0, T.TREE_TRUNK)
    _set_if_grass(m, 0, 29, T.TREE_TRUNK)
    _set_if_grass(m, 26, 5, T.TREE_TRUNK)
    _set_if_grass(m, 12, 12, T.BUSH)
    _set_if_grass(m, 27, 18, T.ROCK_SMALL)
    _set_if_grass(m, 13, 18, T.ROCK_LARGE)


def _place_small_house(
    m: list[list[int]], sx: int, sy: int, wall_tid: int, roof_tid: int
) -> None:
    _border(m, sx, sy, sx + 3, sy + 2, wall_tid)
    _set(m, sx + 1, sy + 1, T.WOOD_FLOOR)
    _set(m, sx + 2, sy + 1, T.WOOD_FLOOR)
    _set(m, sx + 1, sy + 2, T.DOOR_WOOD)
    if sy - 1 >= 0:
        for x in range(sx, sx + 4):
            _set(m, x, sy - 1, roof_tid)


# ── Main ──────────────────────────────────────────────────────────────────

def generate() -> list[list[int]]:
    m = _new_map()
    _fill_base_terrain(m)
    _place_village_square(m)
    _place_chapel(m)
    _place_inn(m)
    _place_elara_cottage(m)
    _place_market(m)
    _place_farmland(m)
    _place_east_forest(m)
    _place_west_road(m)
    _place_southeast(m)
    _place_scattered(m)
    return m


def main() -> None:
    m = generate()

    # Flip legend to str keys for JSON
    legend = {str(k): v for k, v in TILE_LEGEND.items()}

    payload = {
        "legend": legend,
        "width": WIDTH,
        "height": HEIGHT,
        "tiles": m,
    }

    out_path = pathlib.Path(__file__).resolve().parent.parent / "data" / "world" / "ashvale_tilemap.json"
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(json.dumps(payload, separators=(",", ":")) + "\n")

    # Quick stats
    unique = set()
    for row in m:
        unique.update(row)
    print(f"Wrote {out_path}  ({WIDTH}x{HEIGHT}, {len(unique)} unique tile types)")

    # Print a small ASCII preview
    glyphs = {
        T.GRASS: ".",  T.GRASS_DEAD: ",",  T.DIRT: "~",  T.DIRT_PATH: "=",
        T.COBBLESTONE: "#",  T.STONE_FLOOR: "S",  T.WOOD_FLOOR: "W",
        T.MUD: "m",  T.WATER: "O",  T.WATER_SHALLOW: "o",
        T.FARMLAND_HEALTHY: "H",  T.FARMLAND_DEAD: "D",
        T.FLOWERS_DEAD: "f",  T.MUSHROOMS: "M",  T.FALLEN_LEAVES: ";",
        T.ROOTS_CREEPING: "r",  T.WALL_STONE: "|",  T.WALL_STONE_MOSS: "|",
        T.WALL_WOOD: "|",  T.WALL_WOOD_DAMAGED: "X",  T.WALL_CHAPEL: "+",
        T.WALL_MANOR: "A",  T.FENCE_WOOD: "-",  T.FENCE_BROKEN: "x",
        T.DOOR_WOOD: "D",  T.DOOR_WOOD_LOCKED: "L",  T.DOOR_MANOR: "G",
        T.STAIRS_DOWN: "v",  T.WELL: "0",  T.MARKET_STALL: "$",
        T.BARREL: "b",  T.CRATE: "c",  T.TREE_TRUNK: "T",
        T.TREE_CANOPY: "^",  T.BUSH: "*",  T.BUSH_DEAD: "d",
        T.ROCK_SMALL: "o",  T.ROCK_LARGE: "O",  T.GRAVE_MARKER: "+",
        T.ALTAR_STONE: "a",  T.ROOF_THATCH: "n",  T.ROOF_TILE: "n",
        T.CHIMNEY: "C",  T.WINDOW_LIT: "@",  T.WINDOW_DARK: "%",
        T.SIGN_HANGING: "s",  T.TORCH_WALL: "!",  T.BLOOD_SPLATTER: "B",
    }
    print("\nASCII preview:")
    for row in m:
        print("".join(glyphs.get(c, "?") for c in row))


if __name__ == "__main__":
    main()
