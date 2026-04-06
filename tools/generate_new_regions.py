#!/usr/bin/env python3
"""generate_new_regions.py — Produce tilemap JSONs for 5 new regions.

Run with:  uv run python tools/generate_new_regions.py

Generates:
  - data/world/eastern_road_tilemap.json      (50x20)
  - data/world/manor_catacombs_tilemap.json    (25x25)
  - data/world/ritual_chamber_tilemap.json     (20x20)
  - data/world/heartwood_clearing_tilemap.json (30x30)
  - data/world/church_outpost_tilemap.json     (25x20)
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

T = type("T", (), {name.upper(): tid for tid, name in TILE_LEGEND.items()})()


# ── Helper utilities ──────────────────────────────────────────────────────

def _new_map(width: int, height: int, fill: int = 0) -> list[list[int]]:
    return [[fill] * width for _ in range(height)]


def _rect(m: list[list[int]], x0: int, y0: int, x1: int, y1: int, tid: int, w: int, h: int) -> None:
    for y in range(max(0, y0), min(h, y1 + 1)):
        for x in range(max(0, x0), min(w, x1 + 1)):
            m[y][x] = tid


def _border(m: list[list[int]], x0: int, y0: int, x1: int, y1: int, tid: int, w: int, h: int) -> None:
    for x in range(x0, x1 + 1):
        if 0 <= y0 < h and 0 <= x < w:
            m[y0][x] = tid
        if 0 <= y1 < h and 0 <= x < w:
            m[y1][x] = tid
    for y in range(y0, y1 + 1):
        if 0 <= y < h and 0 <= x0 < w:
            m[y][x0] = tid
        if 0 <= y < h and 0 <= x1 < w:
            m[y][x1] = tid


def _set(m: list[list[int]], x: int, y: int, tid: int, w: int, h: int) -> None:
    if 0 <= x < w and 0 <= y < h:
        m[y][x] = tid


# ── Eastern Road (50x20) ─────────────────────────────────────────────────

def generate_eastern_road() -> tuple[list[list[int]], int, int]:
    W, H = 50, 20
    m = _new_map(W, H, T.GRASS)

    # Base terrain — dead grass and rocks scattered
    for y in range(H):
        for x in range(W):
            if (x + y * 3) % 11 == 0:
                _set(m, x, y, T.GRASS_DEAD, W, H)
            if (x * 7 + y) % 19 == 0:
                _set(m, x, y, T.ROCK_SMALL, W, H)

    # Forest edge on north side (rows 0-3)
    for x in range(W):
        for y in range(0, 4):
            if (x * 3 + y * 7) % 5 == 0:
                _set(m, x, y, T.TREE_TRUNK, W, H)
            elif (x + y * 5) % 4 == 0:
                _set(m, x, y, T.TREE_CANOPY, W, H)
            elif (x + y) % 6 == 0:
                _set(m, x, y, T.BUSH, W, H)
        if (x * 3 + 4 * 7) % 8 == 0:
            _set(m, x, 4, T.FALLEN_LEAVES, W, H)

    # Rocky terrain south side
    for x in range(W):
        for y in range(16, 20):
            if (x + y * 2) % 7 == 0:
                _set(m, x, y, T.ROCK_SMALL, W, H)
            elif (x * y) % 13 == 0:
                _set(m, x, y, T.ROCK_LARGE, W, H)
            elif (x + y) % 9 == 0:
                _set(m, x, y, T.GRASS_DEAD, W, H)

    # Main dirt road running east-west (rows 9-11)
    for x in range(W):
        for y in range(9, 12):
            _set(m, x, y, T.DIRT_PATH, W, H)
    # Road edges — dirt/mud
    for x in range(W):
        if (x + 8) % 5 != 0:
            _set(m, x, 8, T.DIRT, W, H)
        if (x + 12) % 5 != 0:
            _set(m, x, 12, T.DIRT, W, H)

    # Crossroads marker at center
    for y in range(5, 15):
        _set(m, 25, y, T.DIRT_PATH, W, H)
    _set(m, 25, 7, T.SIGN_HANGING, W, H)  # Crossroads sign

    # Broken cart (around x=15, y=10)
    _set(m, 14, 9, T.WOOD_FLOOR, W, H)
    _set(m, 15, 9, T.WOOD_FLOOR, W, H)
    _set(m, 14, 10, T.CRATE, W, H)
    _set(m, 15, 10, T.CRATE, W, H)
    _set(m, 16, 10, T.BARREL, W, H)
    _set(m, 13, 10, T.FENCE_BROKEN, W, H)  # Broken wheel

    # Ironmarch camp (east side, around x=35-44, y=5-8)
    _rect(m, 35, 5, 44, 8, T.DIRT, W, H)
    # Tents (roof_tile)
    _rect(m, 36, 5, 39, 7, T.ROOF_TILE, W, H)
    _rect(m, 41, 5, 44, 7, T.ROOF_TILE, W, H)
    _set(m, 37, 7, T.DOOR_WOOD, W, H)
    _set(m, 42, 7, T.DOOR_WOOD, W, H)
    # Camp details
    _set(m, 40, 6, T.BARREL, W, H)
    _set(m, 40, 7, T.CRATE, W, H)
    _set(m, 38, 8, T.TORCH_WALL, W, H)
    _set(m, 43, 8, T.TORCH_WALL, W, H)
    # Banner/flag position
    _set(m, 40, 5, T.SIGN_HANGING, W, H)

    # Abandoned campfire (x=8, y=14)
    _set(m, 8, 14, T.ROCK_SMALL, W, H)
    _set(m, 9, 14, T.DIRT, W, H)
    _set(m, 10, 14, T.ROCK_SMALL, W, H)
    _set(m, 9, 13, T.ROCK_SMALL, W, H)
    _set(m, 9, 15, T.ROCK_SMALL, W, H)

    # Torn map location (near camp)
    _set(m, 35, 8, T.WOOD_FLOOR, W, H)

    # East edge blocked (barricade)
    for y in range(8, 13):
        _set(m, 49, y, T.FENCE_WOOD, W, H)
    _set(m, 49, 10, T.SIGN_HANGING, W, H)

    return m, W, H


# ── Manor Catacombs (25x25) ──────────────────────────────────────────────

def generate_manor_catacombs() -> tuple[list[list[int]], int, int]:
    W, H = 25, 25
    m = _new_map(W, H, T.WALL_STONE)

    # Entrance corridor from north (stairs down from manor)
    _rect(m, 10, 0, 14, 4, T.STONE_FLOOR, W, H)
    _set(m, 12, 0, T.STAIRS_DOWN, W, H)  # Stairs up to manor

    # Main north-south corridor
    _rect(m, 10, 4, 14, 20, T.STONE_FLOOR, W, H)

    # Central crypt chamber (wider room)
    _rect(m, 5, 8, 19, 14, T.STONE_FLOOR, W, H)
    _border(m, 5, 8, 19, 14, T.WALL_STONE_MOSS, W, H)
    # Openings in the chamber walls
    _set(m, 10, 8, T.STONE_FLOOR, W, H)
    _set(m, 14, 8, T.STONE_FLOOR, W, H)
    _set(m, 10, 14, T.STONE_FLOOR, W, H)
    _set(m, 14, 14, T.STONE_FLOOR, W, H)
    _set(m, 12, 8, T.STONE_FLOOR, W, H)
    _set(m, 12, 14, T.STONE_FLOOR, W, H)

    # Grave markers in central chamber
    _set(m, 7, 10, T.GRAVE_MARKER, W, H)
    _set(m, 9, 10, T.GRAVE_MARKER, W, H)
    _set(m, 11, 10, T.GRAVE_MARKER, W, H)
    _set(m, 13, 10, T.GRAVE_MARKER, W, H)
    _set(m, 15, 10, T.GRAVE_MARKER, W, H)
    _set(m, 17, 10, T.GRAVE_MARKER, W, H)
    _set(m, 7, 12, T.GRAVE_MARKER, W, H)
    _set(m, 9, 12, T.GRAVE_MARKER, W, H)
    _set(m, 11, 12, T.GRAVE_MARKER, W, H)
    _set(m, 13, 12, T.GRAVE_MARKER, W, H)
    _set(m, 15, 12, T.GRAVE_MARKER, W, H)
    _set(m, 17, 12, T.GRAVE_MARKER, W, H)

    # Torch-lit alcoves on sides
    # West alcove
    _rect(m, 2, 9, 4, 13, T.STONE_FLOOR, W, H)
    _set(m, 5, 11, T.STONE_FLOOR, W, H)  # Opening
    _set(m, 3, 9, T.TORCH_WALL, W, H)
    _set(m, 3, 13, T.TORCH_WALL, W, H)

    # East alcove
    _rect(m, 20, 9, 22, 13, T.STONE_FLOOR, W, H)
    _set(m, 19, 11, T.STONE_FLOOR, W, H)  # Opening
    _set(m, 21, 9, T.TORCH_WALL, W, H)
    _set(m, 21, 13, T.TORCH_WALL, W, H)

    # Ghost letter alcove (east alcove)
    _set(m, 21, 11, T.CRATE, W, H)  # Letter container

    # Ancient Ashworth sarcophagus (center of crypt)
    _set(m, 12, 11, T.ALTAR_STONE, W, H)

    # South corridor to ritual gate
    _rect(m, 10, 14, 14, 22, T.STONE_FLOOR, W, H)

    # Torches along south corridor
    _set(m, 10, 16, T.TORCH_WALL, W, H)
    _set(m, 14, 16, T.TORCH_WALL, W, H)
    _set(m, 10, 19, T.TORCH_WALL, W, H)
    _set(m, 14, 19, T.TORCH_WALL, W, H)

    # Blood channels near the gate
    _set(m, 11, 20, T.BLOOD_SPLATTER, W, H)
    _set(m, 12, 20, T.BLOOD_SPLATTER, W, H)
    _set(m, 13, 20, T.BLOOD_SPLATTER, W, H)
    _set(m, 12, 21, T.BLOOD_SPLATTER, W, H)

    # Locked ritual gate at south
    _set(m, 12, 22, T.DOOR_WOOD_LOCKED, W, H)
    _set(m, 11, 22, T.WALL_STONE_MOSS, W, H)
    _set(m, 13, 22, T.WALL_STONE_MOSS, W, H)

    # Broken shackles (west wall of south corridor)
    _set(m, 10, 18, T.FENCE_BROKEN, W, H)

    # Dried blood channel groove
    _set(m, 12, 17, T.BLOOD_SPLATTER, W, H)
    _set(m, 12, 18, T.BLOOD_SPLATTER, W, H)
    _set(m, 12, 19, T.BLOOD_SPLATTER, W, H)

    # Cobwebs (use roots_creeping as cobweb stand-in)
    _set(m, 6, 9, T.ROOTS_CREEPING, W, H)
    _set(m, 18, 9, T.ROOTS_CREEPING, W, H)
    _set(m, 6, 13, T.ROOTS_CREEPING, W, H)
    _set(m, 18, 13, T.ROOTS_CREEPING, W, H)
    _set(m, 2, 10, T.ROOTS_CREEPING, W, H)
    _set(m, 22, 10, T.ROOTS_CREEPING, W, H)

    # Sacrifice names wall (east side of south corridor)
    _set(m, 14, 17, T.WALL_STONE_MOSS, W, H)
    _set(m, 14, 18, T.WALL_STONE_MOSS, W, H)

    return m, W, H


# ── Ritual Chamber (20x20) ──────────────────────────────────────────────

def generate_ritual_chamber() -> tuple[list[list[int]], int, int]:
    W, H = 20, 20
    m = _new_map(W, H, T.WALL_STONE)

    # Circular-ish chamber carved from stone
    # Create a rough circle of stone floor
    cx, cy = 10, 10
    for y in range(H):
        for x in range(W):
            dx = x - cx
            dy = y - cy
            if dx * dx + dy * dy <= 64:  # radius ~8
                m[y][x] = T.STONE_FLOOR

    # Stone wall border around the circle
    for y in range(H):
        for x in range(W):
            if m[y][x] == T.STONE_FLOOR:
                for dx, dy in [(-1, 0), (1, 0), (0, -1), (0, 1)]:
                    nx, ny = x + dx, y + dy
                    if 0 <= nx < W and 0 <= ny < H and m[ny][nx] == T.WALL_STONE:
                        pass  # Wall stays

    # Central altar
    _set(m, 10, 10, T.ALTAR_STONE, W, H)

    # Root formation through the center
    _set(m, 10, 8, T.ROOTS_CREEPING, W, H)
    _set(m, 10, 9, T.TREE_TRUNK, W, H)
    _set(m, 10, 11, T.ROOTS_CREEPING, W, H)
    _set(m, 10, 12, T.ROOTS_CREEPING, W, H)
    _set(m, 9, 10, T.ROOTS_CREEPING, W, H)
    _set(m, 11, 10, T.ROOTS_CREEPING, W, H)
    _set(m, 9, 9, T.ROOTS_CREEPING, W, H)
    _set(m, 11, 9, T.ROOTS_CREEPING, W, H)
    _set(m, 9, 11, T.ROOTS_CREEPING, W, H)
    _set(m, 11, 11, T.ROOTS_CREEPING, W, H)

    # Blood channels radiating like a star from altar
    # North ray
    for i in range(3, 8):
        _set(m, 10, 10 - i, T.BLOOD_SPLATTER, W, H)
    # South ray
    for i in range(3, 8):
        _set(m, 10, 10 + i, T.BLOOD_SPLATTER, W, H)
    # East ray
    for i in range(3, 8):
        _set(m, 10 + i, 10, T.BLOOD_SPLATTER, W, H)
    # West ray
    for i in range(3, 8):
        _set(m, 10 - i, 10, T.BLOOD_SPLATTER, W, H)
    # Diagonal rays
    for i in range(3, 6):
        _set(m, 10 + i, 10 + i, T.BLOOD_SPLATTER, W, H)
        _set(m, 10 - i, 10 + i, T.BLOOD_SPLATTER, W, H)
        _set(m, 10 + i, 10 - i, T.BLOOD_SPLATTER, W, H)
        _set(m, 10 - i, 10 - i, T.BLOOD_SPLATTER, W, H)

    # Bioluminescent mushrooms (near roots)
    _set(m, 8, 8, T.MUSHROOMS, W, H)
    _set(m, 12, 8, T.MUSHROOMS, W, H)
    _set(m, 8, 12, T.MUSHROOMS, W, H)
    _set(m, 12, 12, T.MUSHROOMS, W, H)
    _set(m, 7, 10, T.MUSHROOMS, W, H)
    _set(m, 13, 10, T.MUSHROOMS, W, H)

    # Torch brackets on walls
    _set(m, 10, 2, T.TORCH_WALL, W, H)
    _set(m, 2, 10, T.TORCH_WALL, W, H)
    _set(m, 18, 10, T.TORCH_WALL, W, H)
    _set(m, 5, 5, T.TORCH_WALL, W, H)
    _set(m, 15, 5, T.TORCH_WALL, W, H)
    _set(m, 5, 15, T.TORCH_WALL, W, H)
    _set(m, 15, 15, T.TORCH_WALL, W, H)

    # North doorway (entrance from catacombs)
    _rect(m, 9, 0, 11, 2, T.STONE_FLOOR, W, H)
    _set(m, 10, 0, T.DOOR_WOOD, W, H)

    # Offering bowl near altar
    _set(m, 8, 10, T.BARREL, W, H)  # Stand-in for offering bowl

    # Silas's footprints (leading to root)
    _set(m, 10, 14, T.DIRT, W, H)
    _set(m, 10, 13, T.DIRT, W, H)

    # Ancient inscription on south wall
    _set(m, 10, 17, T.WALL_STONE_MOSS, W, H)

    return m, W, H


# ── Heartwood Clearing (30x30) ──────────────────────────────────────────

def generate_heartwood_clearing() -> tuple[list[list[int]], int, int]:
    W, H = 30, 30
    m = _new_map(W, H, T.TREE_CANOPY)

    # Dense canopy border (everything outside the clearing)
    # Fill border with mixed forest
    for y in range(H):
        for x in range(W):
            if (x * 3 + y * 7) % 4 == 0:
                _set(m, x, y, T.TREE_TRUNK, W, H)
            elif (x + y) % 3 == 0:
                _set(m, x, y, T.BUSH, W, H)

    # Circular clearing in center (radius ~10)
    cx, cy = 15, 15
    for y in range(H):
        for x in range(W):
            dx = x - cx
            dy = y - cy
            if dx * dx + dy * dy <= 100:  # radius 10
                m[y][x] = T.GRASS
                # Moss / mushrooms scatter
                if (x + y) % 7 == 0:
                    m[y][x] = T.MUSHROOMS
                elif (x + y * 3) % 11 == 0:
                    m[y][x] = T.FALLEN_LEAVES

    # Massive Heartwood tree at dead center
    _set(m, 15, 15, T.TREE_TRUNK, W, H)
    _set(m, 14, 15, T.TREE_TRUNK, W, H)
    _set(m, 16, 15, T.TREE_TRUNK, W, H)
    _set(m, 15, 14, T.TREE_TRUNK, W, H)
    _set(m, 15, 16, T.TREE_TRUNK, W, H)
    _set(m, 14, 14, T.TREE_CANOPY, W, H)
    _set(m, 16, 14, T.TREE_CANOPY, W, H)
    _set(m, 14, 16, T.TREE_CANOPY, W, H)
    _set(m, 16, 16, T.TREE_CANOPY, W, H)

    # Roots radiating outward in spiral pattern
    # Spiral roots from center
    root_positions = [
        (13, 15), (12, 14), (11, 13), (10, 12), (9, 11), (8, 10),
        (17, 15), (18, 16), (19, 17), (20, 18), (21, 19), (22, 20),
        (15, 13), (16, 12), (17, 11), (18, 10), (19, 9), (20, 8),
        (15, 17), (14, 18), (13, 19), (12, 20), (11, 21), (10, 22),
        (13, 13), (12, 12), (11, 11),
        (17, 17), (18, 18), (19, 19),
        (13, 17), (12, 18), (11, 19),
        (17, 13), (18, 12), (19, 11),
    ]
    for rx, ry in root_positions:
        _set(m, rx, ry, T.ROOTS_CREEPING, W, H)

    # Water pools around the base
    _set(m, 13, 16, T.WATER, W, H)
    _set(m, 17, 14, T.WATER, W, H)
    _set(m, 14, 17, T.WATER, W, H)
    _set(m, 16, 13, T.WATER, W, H)
    _set(m, 12, 15, T.WATER_SHALLOW, W, H)
    _set(m, 18, 15, T.WATER_SHALLOW, W, H)

    # Moonpetal flowers (using flowers_dead as moonpetals)
    moonpetal_pos = [
        (10, 15), (20, 15), (15, 10), (15, 20),
        (11, 11), (19, 19), (11, 19), (19, 11),
        (9, 14), (21, 16),
    ]
    for mx, my in moonpetal_pos:
        _set(m, mx, my, T.FLOWERS_DEAD, W, H)

    # Blood-root (the original pact root)
    _set(m, 15, 18, T.ROOTS_CREEPING, W, H)
    _set(m, 15, 19, T.BLOOD_SPLATTER, W, H)  # Blood stain on root

    # West path entrance from Thornwood
    _rect(m, 0, 14, 5, 16, T.DIRT_PATH, W, H)
    _set(m, 5, 14, T.GRASS, W, H)
    _set(m, 5, 16, T.GRASS, W, H)

    # Bioluminescent mushrooms clusters
    for x, y in [(8, 15), (22, 15), (15, 8), (15, 22), (9, 9), (21, 21)]:
        _set(m, x, y, T.MUSHROOMS, W, H)

    return m, W, H


# ── Church Outpost (25x20) ──────────────────────────────────────────────

def generate_church_outpost() -> tuple[list[list[int]], int, int]:
    W, H = 25, 20
    m = _new_map(W, H, T.ROCK_SMALL)

    # Cave/ruin base - stone floor interior
    for y in range(H):
        for x in range(W):
            if (x + y * 2) % 7 == 0:
                m[y][x] = T.ROCK_LARGE
            elif (x * 3 + y) % 11 == 0:
                m[y][x] = T.WALL_STONE_MOSS

    # Main interior (stone floor)
    _rect(m, 3, 3, 21, 16, T.STONE_FLOOR, W, H)
    _border(m, 3, 3, 21, 16, T.WALL_CHAPEL, W, H)

    # Entrance from south
    _set(m, 12, 16, T.DOOR_WOOD, W, H)
    _rect(m, 11, 17, 13, 19, T.DIRT_PATH, W, H)

    # Makeshift chapel area (west side)
    _rect(m, 4, 4, 10, 9, T.STONE_FLOOR, W, H)
    _set(m, 7, 4, T.ALTAR_STONE, W, H)
    _set(m, 6, 4, T.TORCH_WALL, W, H)
    _set(m, 8, 4, T.TORCH_WALL, W, H)

    # Ash sigil circle on floor (cobblestone pattern)
    _set(m, 7, 6, T.COBBLESTONE, W, H)
    _set(m, 6, 7, T.COBBLESTONE, W, H)
    _set(m, 8, 7, T.COBBLESTONE, W, H)
    _set(m, 7, 8, T.COBBLESTONE, W, H)
    _set(m, 6, 6, T.COBBLESTONE, W, H)
    _set(m, 8, 6, T.COBBLESTONE, W, H)
    _set(m, 6, 8, T.COBBLESTONE, W, H)
    _set(m, 8, 8, T.COBBLESTONE, W, H)

    # Supply storage (east side)
    _rect(m, 13, 4, 20, 9, T.STONE_FLOOR, W, H)
    # Crates of alchemical supplies
    _set(m, 14, 5, T.CRATE, W, H)
    _set(m, 15, 5, T.CRATE, W, H)
    _set(m, 16, 5, T.CRATE, W, H)
    _set(m, 14, 6, T.CRATE, W, H)
    # Barrels of nightcap root
    _set(m, 18, 5, T.BARREL, W, H)
    _set(m, 19, 5, T.BARREL, W, H)
    _set(m, 18, 6, T.BARREL, W, H)
    _set(m, 19, 6, T.BARREL, W, H)

    # War table (center south)
    _set(m, 12, 11, T.WOOD_FLOOR, W, H)
    _set(m, 13, 11, T.WOOD_FLOOR, W, H)
    _set(m, 11, 11, T.WOOD_FLOOR, W, H)
    _set(m, 12, 12, T.CRATE, W, H)  # Maps on table

    # Cage (fence) in southeast
    _border(m, 16, 11, 19, 14, T.FENCE_WOOD, W, H)
    _rect(m, 17, 12, 18, 13, T.STONE_FLOOR, W, H)
    _set(m, 16, 12, T.DOOR_WOOD_LOCKED, W, H)

    # Alchemist's journal location
    _set(m, 20, 7, T.WOOD_FLOOR, W, H)

    # Torches
    _set(m, 4, 4, T.TORCH_WALL, W, H)
    _set(m, 10, 4, T.TORCH_WALL, W, H)
    _set(m, 4, 15, T.TORCH_WALL, W, H)
    _set(m, 20, 15, T.TORCH_WALL, W, H)
    _set(m, 20, 4, T.TORCH_WALL, W, H)

    # Blood stain near cage
    _set(m, 17, 14, T.BLOOD_SPLATTER, W, H)
    _set(m, 18, 14, T.BLOOD_SPLATTER, W, H)

    return m, W, H


# ── Output ───────────────────────────────────────────────────────────────

def write_tilemap(name: str, tiles: list[list[int]], width: int, height: int) -> None:
    legend = {str(k): v for k, v in TILE_LEGEND.items()}
    payload = {
        "legend": legend,
        "width": width,
        "height": height,
        "tiles": tiles,
    }
    out_path = pathlib.Path(__file__).resolve().parent.parent / "data" / "world" / f"{name}_tilemap.json"
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(json.dumps(payload, separators=(",", ":")) + "\n")

    unique = set()
    for row in tiles:
        unique.update(row)
    print(f"Wrote {out_path}  ({width}x{height}, {len(unique)} unique tile types)")


def main() -> None:
    regions = [
        ("eastern_road", generate_eastern_road),
        ("manor_catacombs", generate_manor_catacombs),
        ("ritual_chamber", generate_ritual_chamber),
        ("heartwood_clearing", generate_heartwood_clearing),
        ("church_outpost", generate_church_outpost),
    ]
    for name, gen_fn in regions:
        tiles, w, h = gen_fn()
        write_tilemap(name, tiles, w, h)

    print("\nAll 5 region tilemaps generated successfully!")


if __name__ == "__main__":
    main()
