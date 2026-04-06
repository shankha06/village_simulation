"""Generate tilemap JSON data for Thornwood Forest and Ashworth Manor regions."""

import json
import random
from pathlib import Path

random.seed(42)  # Deterministic output

OUTPUT_DIR = Path(__file__).resolve().parent.parent / "data" / "world"

LEGEND = {
    0: "grass", 1: "grass_dead", 2: "dirt", 3: "dirt_path",
    4: "cobblestone", 5: "stone_floor", 6: "wood_floor", 7: "mud",
    8: "water", 9: "water_shallow", 10: "farmland_healthy",
    11: "farmland_dead", 12: "flowers_dead", 13: "mushrooms",
    14: "fallen_leaves", 15: "roots_creeping", 16: "wall_stone",
    17: "wall_stone_moss", 18: "wall_wood", 19: "wall_wood_damaged",
    20: "wall_chapel", 21: "wall_manor", 22: "fence_wood",
    23: "fence_broken", 24: "door_wood", 25: "door_wood_locked",
    26: "door_manor", 27: "stairs_down", 28: "well", 29: "market_stall",
    30: "barrel", 31: "crate", 32: "tree_trunk", 33: "tree_canopy",
    34: "bush", 35: "bush_dead", 36: "rock_small", 37: "rock_large",
    38: "grave_marker", 39: "altar_stone", 40: "roof_thatch",
    41: "roof_tile", 42: "chimney", 43: "window_lit", 44: "window_dark",
    45: "sign_hanging", 46: "torch_wall", 47: "blood_splatter",
}


# ---------------------------------------------------------------------------
# Thornwood Forest  (40 x 30)
# ---------------------------------------------------------------------------
def generate_thornwood() -> dict:
    W, H = 40, 30
    tiles = [[33] * W for _ in range(H)]  # Default: tree canopy

    # --- Helper: carve a region ---
    def fill_rect(x1, y1, x2, y2, tile_id):
        for yy in range(max(0, y1), min(H, y2)):
            for xx in range(max(0, x1), min(W, x2)):
                tiles[yy][xx] = tile_id

    def scatter(x1, y1, x2, y2, tile_id, density=0.3):
        for yy in range(max(0, y1), min(H, y2)):
            for xx in range(max(0, x1), min(W, x2)):
                if random.random() < density:
                    tiles[yy][xx] = tile_id

    # --- Path from west edge (row 14-15) winding east to center clearing ---
    # Main path enters from west edge
    for x in range(0, 20):
        y_base = 14 + (1 if x % 5 < 2 else 0)  # slight wobble
        tiles[y_base][x] = 3      # dirt_path
        tiles[y_base + 1][x] = 3

    # Path widening as it approaches clearing
    for x in range(16, 22):
        for y in range(13, 17):
            tiles[y][x] = 3

    # --- Central clearing (roughly 17-26 x, 10-20 y) ---
    fill_rect(17, 10, 27, 20, 0)  # grass base

    # Mushrooms, moss-covered rocks, fallen leaves in clearing
    clearing_features = [
        (19, 12, 13), (21, 14, 13), (24, 11, 13), (22, 17, 13),  # mushrooms
        (20, 13, 37), (25, 15, 37), (18, 16, 37),                  # moss rocks
        (23, 12, 14), (19, 15, 14), (21, 18, 14), (26, 13, 14),   # fallen leaves
        (20, 11, 14), (24, 17, 14), (18, 14, 14),
    ]
    for fx, fy, fid in clearing_features:
        if 0 <= fy < H and 0 <= fx < W:
            tiles[fy][fx] = fid

    # --- Carved rune tree in clearing (special position) ---
    tiles[15][22] = 32  # tree trunk (the rune tree marker)

    # --- Stream running NE to SW through the map ---
    # Water source upstream in northeast (around x=34, y=3)
    stream_points = [
        (35, 2), (34, 3), (34, 4), (33, 5), (33, 6), (32, 7),
        (31, 8), (30, 9), (29, 10), (28, 11), (27, 12), (26, 13),
        (25, 14), (24, 15), (23, 16), (22, 17), (21, 18), (20, 19),
        (19, 20), (18, 21), (17, 22), (16, 23), (15, 24), (14, 25),
        (13, 26), (12, 27), (11, 28), (10, 29),
    ]
    for sx, sy in stream_points:
        if 0 <= sy < H and 0 <= sx < W:
            tiles[sy][sx] = 8  # deep water
            # Shallow banks
            for dx, dy in [(-1, 0), (1, 0), (0, -1), (0, 1)]:
                nx, ny = sx + dx, sy + dy
                if 0 <= ny < H and 0 <= nx < W and tiles[ny][nx] not in (8, 9):
                    if random.random() < 0.5:
                        tiles[ny][nx] = 9  # shallow water

    # Water source area (NE) -- disturbed earth around it
    fill_rect(33, 1, 37, 5, 9)  # shallow water pool
    tiles[2][35] = 8
    tiles[3][34] = 8
    tiles[1][34] = 7   # mud (disturbed earth)
    tiles[1][35] = 7
    tiles[2][36] = 7
    tiles[4][35] = 7

    # --- Wolf den in northwest (rocks forming cave entrance) ---
    den_cx, den_cy = 5, 4
    # Ring of rocks
    for dx, dy in [(-1, -1), (0, -1), (1, -1), (-1, 0), (1, 0), (-1, 1), (1, 1)]:
        rx, ry = den_cx + dx, den_cy + dy
        if 0 <= ry < H and 0 <= rx < W:
            tiles[ry][rx] = 37  # rock_large
    tiles[den_cy][den_cx] = 2       # dirt (cave floor)
    tiles[den_cy + 1][den_cx] = 2   # entrance opening
    tiles[den_cy + 2][den_cx] = 7   # mud tracks at entrance
    tiles[den_cy + 2][den_cx - 1] = 7
    tiles[den_cy + 2][den_cx + 1] = 7

    # --- Ancient druid circle (south-center, around x=20, y=25) ---
    druid_cx, druid_cy = 20, 25
    tiles[druid_cy][druid_cx] = 39      # altar_stone center
    for angle_idx, (dx, dy) in enumerate([
        (-2, 0), (2, 0), (0, -2), (0, 2),
        (-1, -1), (1, -1), (-1, 1), (1, 1)
    ]):
        rx, ry = druid_cx + dx, druid_cy + dy
        if 0 <= ry < H and 0 <= rx < W:
            tiles[ry][rx] = 37 if angle_idx < 4 else 36

    # Clear ground around druid circle
    for dy in range(-1, 2):
        for dx in range(-1, 2):
            rx, ry = druid_cx + dx, druid_cy + dy
            if 0 <= ry < H and 0 <= rx < W and tiles[ry][rx] == 33:
                tiles[ry][rx] = 0

    # --- Creeping roots near map edges ---
    for y in range(H):
        for x in range(W):
            if tiles[y][x] == 33:
                # Near edges
                near_edge = (x <= 2 or x >= W - 3 or y <= 1 or y >= H - 2)
                if near_edge and random.random() < 0.15:
                    tiles[y][x] = 15  # roots_creeping

    # --- Scatter tree trunks among canopy ---
    for y in range(H):
        for x in range(W):
            if tiles[y][x] == 33:
                # Denser in the east
                trunk_chance = 0.08 + (x / W) * 0.06
                if random.random() < trunk_chance:
                    tiles[y][x] = 32

    # --- Narrow secondary paths ---
    # Path from clearing south to druid circle
    for y in range(19, 25):
        tiles[y][20] = 3
        if random.random() < 0.3:
            tiles[y][21] = 3

    # Path from clearing east deeper into forest
    for x in range(26, 33):
        wobble = 14 + (1 if x % 3 == 0 else 0)
        tiles[wobble][x] = 3

    # --- West edge: ensure clear entrance from Ashvale ---
    for y in range(12, 18):
        tiles[y][0] = 0   # grass at edge
        tiles[y][1] = 0
        if 14 <= y <= 15:
            tiles[y][0] = 3
            tiles[y][1] = 3

    # --- Bush/dead bush scatter on clearings ---
    for y in range(H):
        for x in range(W):
            if tiles[y][x] == 0 and random.random() < 0.05:
                tiles[y][x] = 34  # bush

    return {
        "legend": {str(k): v for k, v in LEGEND.items()},
        "width": W,
        "height": H,
        "tiles": tiles,
    }


# ---------------------------------------------------------------------------
# Ashworth Manor  (30 x 25)
# ---------------------------------------------------------------------------
def generate_manor() -> dict:
    W, H = 30, 25
    tiles = [[21] * W for _ in range(H)]  # Default: dark stone walls

    def fill_rect(x1, y1, x2, y2, tile_id):
        for yy in range(max(0, y1), min(H, y2)):
            for xx in range(max(0, x1), min(W, x2)):
                tiles[yy][xx] = tile_id

    # --- Manor exterior courtyard (south half) ---
    # Cobblestone courtyard at entrance
    fill_rect(8, 18, 22, 24, 4)   # cobblestone courtyard

    # Iron gate entrance at south center
    tiles[23][14] = 26  # door_manor (gate)
    tiles[23][15] = 26
    tiles[24][14] = 4   # path leading out
    tiles[24][15] = 4

    # Courtyard decorations
    tiles[20][10] = 46  # torch_wall
    tiles[20][19] = 46
    tiles[22][12] = 30  # barrel
    tiles[22][17] = 31  # crate

    # --- Main hall / entrance corridor (center, y=14-18) ---
    fill_rect(10, 14, 20, 18, 5)   # stone_floor
    tiles[17][14] = 26  # door into hall from courtyard
    tiles[17][15] = 26

    # Pillars in corridor
    tiles[15][11] = 21
    tiles[15][18] = 21
    tiles[16][11] = 21
    tiles[16][18] = 21

    # --- Dining hall (center, y=8-14) ---
    fill_rect(10, 8, 20, 14, 5)    # stone_floor base

    # Long table (wood floor for table area)
    fill_rect(12, 9, 18, 13, 6)    # wood_floor (table)
    tiles[9][14] = 46   # torch on wall
    tiles[9][15] = 46

    # Door into dining hall from corridor
    tiles[13][14] = 24  # door_wood
    tiles[13][15] = 24

    # --- Lord's study (northwest, y=2-8, x=2-10) ---
    fill_rect(2, 2, 10, 8, 6)      # wood_floor

    # Walls around study
    fill_rect(2, 1, 10, 2, 21)     # north wall
    fill_rect(1, 2, 2, 8, 21)      # west wall
    fill_rect(10, 2, 11, 8, 21)    # east wall partition
    tiles[7][6] = 24               # door into study

    # Furnishings
    tiles[3][4] = 6     # desk area (kept as wood_floor)
    tiles[3][5] = 31    # crate (bookshelves)
    tiles[3][6] = 31    # more bookshelves
    tiles[2][3] = 44    # window_dark
    tiles[2][8] = 44    # window_dark
    tiles[4][3] = 30    # barrel (storage)
    tiles[5][8] = 46    # torch

    # --- Library / east wing (x=20-28, y=2-10) ---
    fill_rect(20, 2, 28, 10, 5)    # stone_floor

    # Walls around library
    fill_rect(20, 1, 28, 2, 21)
    fill_rect(28, 2, 29, 10, 21)
    fill_rect(19, 2, 20, 10, 21)   # partition wall
    tiles[9][23] = 24              # door into library

    # Bookshelves (crates representing shelves)
    for y in range(3, 9):
        tiles[y][21] = 31
        tiles[y][27] = 31
    tiles[4][24] = 46   # torch
    tiles[2][22] = 44   # window_dark
    tiles[2][26] = 44   # window_dark

    # Secret passage behind east bookshelf (x=27, y=5)
    tiles[5][27] = 25   # door_wood_locked (hidden behind bookshelf)

    # Secret passage corridor
    fill_rect(28, 4, 30, 7, 5)     # small hidden stone corridor

    # --- Family crypt entrance (south-center, lower) ---
    tiles[16][14] = 27  # stairs_down
    tiles[16][15] = 27

    # --- Wine cellar (southeast, x=20-27, y=14-18) ---
    fill_rect(20, 14, 27, 18, 5)   # stone_floor
    tiles[17][20] = 24             # door
    # Barrels of wine
    tiles[15][22] = 30
    tiles[15][23] = 30
    tiles[15][24] = 30
    tiles[16][22] = 30
    tiles[16][25] = 30

    # --- Bedroom / upper chambers (x=11-19, y=2-7) ---
    fill_rect(11, 2, 19, 7, 6)     # wood_floor
    tiles[6][14] = 24              # door
    tiles[2][13] = 44              # window
    tiles[2][16] = 44              # window
    tiles[3][12] = 46              # torch

    # --- Bloodstain on carpet (in dining hall) ---
    tiles[11][15] = 47  # blood_splatter

    # --- Corridor connecting rooms (y=7-8, x=2-28) ---
    fill_rect(2, 7, 28, 9, 5)      # stone corridor

    # Doors along corridor
    tiles[7][6] = 24    # to study
    tiles[8][14] = 24   # to bedroom above
    tiles[7][23] = 24   # to library

    # Torches along corridor
    tiles[7][4] = 46
    tiles[7][10] = 46
    tiles[7][17] = 46
    tiles[7][26] = 46

    # --- Family portraits (wall markers along dining hall north wall) ---
    # represented by window_dark tiles along the wall
    tiles[8][11] = 44
    tiles[8][13] = 44
    tiles[8][16] = 44
    tiles[8][18] = 44

    # --- Guard post at gate ---
    tiles[21][10] = 5
    tiles[21][19] = 5
    tiles[22][10] = 46
    tiles[22][19] = 46

    # --- Exterior path south of gate ---
    fill_rect(12, 23, 18, 25, 3)   # dirt_path leading away

    # --- Grass patches in courtyard edges ---
    for y in range(18, 23):
        for x in [8, 9, 20, 21]:
            if tiles[y][x] == 4 and random.random() < 0.3:
                tiles[y][x] = 1  # dead grass

    # --- Graves near crypt ---
    tiles[19][12] = 38
    tiles[19][13] = 38
    tiles[19][16] = 38
    tiles[19][17] = 38

    return {
        "legend": {str(k): v for k, v in LEGEND.items()},
        "width": W,
        "height": H,
        "tiles": tiles,
    }


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
def main():
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    thornwood = generate_thornwood()
    thornwood_path = OUTPUT_DIR / "thornwood_tilemap.json"
    with open(thornwood_path, "w") as f:
        json.dump(thornwood, f, separators=(",", ":"))
    print(f"Generated {thornwood_path}  ({thornwood['width']}x{thornwood['height']})")

    manor = generate_manor()
    manor_path = OUTPUT_DIR / "manor_tilemap.json"
    with open(manor_path, "w") as f:
        json.dump(manor, f, separators=(",", ":"))
    print(f"Generated {manor_path}  ({manor['width']}x{manor['height']})")


if __name__ == "__main__":
    main()
