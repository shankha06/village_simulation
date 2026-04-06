"""
Generate a professional-quality dark fantasy tileset.
Each 16x16 tile is hand-crafted with proper pixel art techniques:
- 3-tone shading (highlight, midtone, shadow)
- Dithering for texture
- Clear silhouettes
- Tileable edges

Run with: uv run python tools/generate_pro_tileset.py
"""

from PIL import Image, ImageDraw
import random
import os

random.seed(42)  # Reproducible art

PROJECT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT_PATH = os.path.join(PROJECT, "assets/sprites/tilesets/terrain_tileset.png")

# Professional dark fantasy palette - carefully chosen for contrast and mood
P = {
    # Grass tones (living)
    'grass_hi':   (82, 115, 62),
    'grass_mid':  (62, 92, 48),
    'grass_lo':   (45, 68, 35),
    'grass_dark': (32, 52, 28),

    # Grass tones (dead/dying)
    'dead_hi':    (128, 108, 72),
    'dead_mid':   (105, 88, 58),
    'dead_lo':    (82, 68, 45),

    # Dirt/path
    'dirt_hi':    (148, 118, 82),
    'dirt_mid':   (120, 92, 62),
    'dirt_lo':    (92, 68, 45),
    'path_hi':    (165, 138, 98),
    'path_mid':   (138, 112, 78),
    'path_lo':    (108, 85, 58),

    # Cobblestone
    'cobble_hi':  (142, 138, 128),
    'cobble_mid': (112, 108, 98),
    'cobble_lo':  (82, 78, 72),
    'cobble_gap': (55, 52, 48),

    # Stone
    'stone_hi':   (135, 130, 122),
    'stone_mid':  (98, 95, 88),
    'stone_lo':   (68, 65, 60),
    'stone_dark': (45, 42, 38),

    # Wood
    'wood_hi':    (155, 108, 65),
    'wood_mid':   (125, 82, 48),
    'wood_lo':    (92, 58, 32),
    'wood_dark':  (62, 38, 22),

    # Water
    'water_hi':   (72, 108, 148),
    'water_mid':  (48, 82, 125),
    'water_lo':   (32, 58, 98),
    'water_deep': (22, 42, 75),

    # Farmland
    'farm_hi':    (105, 78, 52),
    'farm_mid':   (82, 58, 38),
    'farm_lo':    (62, 42, 28),
    'crop_green': (68, 98, 48),

    # Wall colors
    'wall_hi':    (148, 142, 132),
    'wall_mid':   (115, 110, 102),
    'wall_lo':    (78, 75, 68),
    'wall_dark':  (52, 48, 42),

    # Chapel (lighter stone)
    'chapel_hi':  (178, 172, 162),
    'chapel_mid': (148, 142, 132),
    'chapel_lo':  (112, 108, 98),

    # Manor (dark stone)
    'manor_hi':   (92, 88, 82),
    'manor_mid':  (68, 65, 58),
    'manor_lo':   (48, 45, 40),

    # Special
    'blood':      (120, 28, 28),
    'blood_dark': (82, 18, 18),
    'gold':       (218, 175, 72),
    'gold_dark':  (168, 128, 48),
    'torch_glow': (245, 198, 82),
    'torch_fire': (228, 128, 42),
    'moss':       (58, 82, 42),
    'mushroom':   (148, 118, 88),
    'purple':     (98, 52, 118),
    'leaf_brown': (118, 82, 42),
    'leaf_red':   (148, 58, 38),
    'root_brown': (78, 52, 32),
    'black':      (18, 14, 22),
    'near_black': (28, 22, 32),
}


def noise_color(base: tuple, variation: int = 12) -> tuple:
    """Add slight random variation to a color for texture."""
    return tuple(max(0, min(255, c + random.randint(-variation, variation))) for c in base)


def dither_fill(img: Image.Image, x: int, y: int, w: int, h: int,
                c1: tuple, c2: tuple, density: float = 0.3):
    """Fill area with dithered pattern between two colors."""
    for py in range(y, y + h):
        for px in range(x, x + w):
            if 0 <= px < img.width and 0 <= py < img.height:
                if random.random() < density:
                    img.putpixel((px, py), c2 + (255,))
                else:
                    img.putpixel((px, py), noise_color(c1, 6) + (255,))


def draw_grass(img, ox, oy):
    """Living grass tile with variation."""
    for y in range(16):
        for x in range(16):
            r = random.random()
            if r < 0.15:
                c = P['grass_hi']
            elif r < 0.55:
                c = P['grass_mid']
            elif r < 0.85:
                c = P['grass_lo']
            else:
                c = P['grass_dark']
            img.putpixel((ox+x, oy+y), noise_color(c, 5) + (255,))
    # Add grass blade accents
    for _ in range(5):
        gx = random.randint(1, 14)
        gy = random.randint(1, 14)
        img.putpixel((ox+gx, oy+gy), P['grass_hi'] + (255,))
        if gy > 0:
            img.putpixel((ox+gx, oy+gy-1), P['grass_hi'] + (255,))


def draw_dead_grass(img, ox, oy):
    """Dead/dying grass."""
    for y in range(16):
        for x in range(16):
            r = random.random()
            if r < 0.2:
                c = P['dead_hi']
            elif r < 0.6:
                c = P['dead_mid']
            else:
                c = P['dead_lo']
            img.putpixel((ox+x, oy+y), noise_color(c, 8) + (255,))
    # Cracks
    for _ in range(3):
        cx = random.randint(2, 13)
        cy = random.randint(2, 13)
        for i in range(3):
            img.putpixel((ox+cx+i, oy+cy), P['dirt_lo'] + (255,))


def draw_dirt(img, ox, oy):
    """Plain dirt."""
    for y in range(16):
        for x in range(16):
            r = random.random()
            if r < 0.2:
                c = P['dirt_hi']
            elif r < 0.65:
                c = P['dirt_mid']
            else:
                c = P['dirt_lo']
            img.putpixel((ox+x, oy+y), noise_color(c, 6) + (255,))


def draw_path(img, ox, oy):
    """Dirt path - lighter and smoother."""
    for y in range(16):
        for x in range(16):
            r = random.random()
            if r < 0.25:
                c = P['path_hi']
            elif r < 0.7:
                c = P['path_mid']
            else:
                c = P['path_lo']
            img.putpixel((ox+x, oy+y), noise_color(c, 4) + (255,))


def draw_cobblestone(img, ox, oy):
    """Cobblestone with visible stone pattern."""
    # Fill base gap color
    for y in range(16):
        for x in range(16):
            img.putpixel((ox+x, oy+y), noise_color(P['cobble_gap'], 4) + (255,))

    # Draw stones in a staggered pattern
    stones = [
        (1,1,5,3), (7,1,5,3), (13,1,2,3),
        (0,5,4,3), (5,5,5,3), (11,5,4,3),
        (1,9,5,3), (7,9,5,3), (13,9,2,3),
        (0,13,4,2), (5,13,5,2), (11,13,4,2),
    ]
    for sx, sy, sw, sh in stones:
        for y in range(sy, min(sy+sh, 16)):
            for x in range(sx, min(sx+sw, 16)):
                r = random.random()
                if r < 0.3:
                    c = P['cobble_hi']
                elif r < 0.7:
                    c = P['cobble_mid']
                else:
                    c = P['cobble_lo']
                img.putpixel((ox+x, oy+y), noise_color(c, 5) + (255,))


def draw_stone_floor(img, ox, oy):
    """Interior stone floor."""
    for y in range(16):
        for x in range(16):
            r = random.random()
            if r < 0.2:
                c = P['stone_hi']
            elif r < 0.6:
                c = P['stone_mid']
            else:
                c = P['stone_lo']
            img.putpixel((ox+x, oy+y), noise_color(c, 4) + (255,))
    # Subtle grid lines
    for x in range(16):
        img.putpixel((ox+x, oy+8), noise_color(P['stone_dark'], 3) + (255,))
    for y in range(16):
        img.putpixel((ox+8, oy+y), noise_color(P['stone_dark'], 3) + (255,))


def draw_wood_floor(img, ox, oy):
    """Wood plank floor with grain."""
    for y in range(16):
        for x in range(16):
            # Horizontal planks
            plank = y // 4
            if y % 4 == 3:  # plank gap
                c = P['wood_dark']
            elif plank % 2 == 0:
                r = random.random()
                c = P['wood_hi'] if r < 0.3 else P['wood_mid']
            else:
                r = random.random()
                c = P['wood_mid'] if r < 0.3 else P['wood_lo']
            img.putpixel((ox+x, oy+y), noise_color(c, 5) + (255,))


def draw_mud(img, ox, oy):
    """Wet mud."""
    for y in range(16):
        for x in range(16):
            r = random.random()
            if r < 0.15:
                c = P['dirt_mid']
            elif r < 0.5:
                c = P['dirt_lo']
            else:
                c = (58, 42, 30)
            img.putpixel((ox+x, oy+y), noise_color(c, 6) + (255,))
    # Puddle highlights
    for _ in range(3):
        px = random.randint(2, 12)
        py = random.randint(2, 12)
        img.putpixel((ox+px, oy+py), (78, 92, 108, 180))


def draw_water(img, ox, oy, shallow=False):
    """Water with wave pattern."""
    base = P['water_mid'] if not shallow else P['water_hi']
    dark = P['water_lo'] if not shallow else P['water_mid']
    for y in range(16):
        for x in range(16):
            # Wave pattern
            wave = ((x + y * 2) % 6)
            if wave < 2:
                c = base
            elif wave < 4:
                c = dark
            else:
                c = P['water_hi'] if not shallow else (108, 148, 178)
            img.putpixel((ox+x, oy+y), noise_color(c, 4) + (255,))


def draw_farmland(img, ox, oy, healthy=True):
    """Farmland with crop rows."""
    base = P['farm_mid'] if healthy else P['dead_mid']
    for y in range(16):
        for x in range(16):
            if y % 4 < 2:  # furrow
                c = P['farm_lo'] if healthy else P['dead_lo']
            else:  # ridge
                c = P['farm_hi'] if healthy else P['dead_hi']
            img.putpixel((ox+x, oy+y), noise_color(c, 5) + (255,))
    # Crops on ridges
    if healthy:
        for x in range(0, 16, 3):
            for row_y in [3, 7, 11, 15]:
                if row_y < 16:
                    img.putpixel((ox+x, oy+row_y), P['crop_green'] + (255,))
                    if row_y > 0:
                        img.putpixel((ox+x, oy+row_y-1), P['crop_green'] + (255,))


def draw_wall(img, ox, oy, hi, mid, lo, dark):
    """Generic wall tile with brick pattern."""
    for y in range(16):
        for x in range(16):
            img.putpixel((ox+x, oy+y), noise_color(mid, 4) + (255,))

    # Brick pattern
    bricks = [
        (0,0,7,3), (8,0,7,3),
        (0,4,5,3), (6,4,5,3), (12,4,3,3),
        (0,8,7,3), (8,8,7,3),
        (0,12,5,3), (6,12,5,3), (12,12,3,3),
    ]
    for bx, by, bw, bh in bricks:
        # Top edge highlight
        for x in range(bx, min(bx+bw, 16)):
            img.putpixel((ox+x, oy+by), noise_color(hi, 4) + (255,))
        # Bottom edge shadow
        by_end = min(by+bh-1, 15)
        for x in range(bx, min(bx+bw, 16)):
            img.putpixel((ox+x, oy+by_end), noise_color(lo, 4) + (255,))

    # Mortar lines
    for x in range(16):
        for gap_y in [3, 7, 11, 15]:
            if gap_y < 16:
                img.putpixel((ox+x, oy+gap_y), noise_color(dark, 3) + (255,))


def draw_door(img, ox, oy, style='wood'):
    """Door tile."""
    # Frame
    for y in range(16):
        img.putpixel((ox+0, oy+y), P['stone_lo'] + (255,))
        img.putpixel((ox+1, oy+y), P['stone_mid'] + (255,))
        img.putpixel((ox+14, oy+y), P['stone_mid'] + (255,))
        img.putpixel((ox+15, oy+y), P['stone_lo'] + (255,))
    # Top arch
    for x in range(2, 14):
        img.putpixel((ox+x, oy+0), P['stone_mid'] + (255,))
        img.putpixel((ox+x, oy+1), P['stone_lo'] + (255,))

    # Door planks
    door_c = P['wood_mid'] if style == 'wood' else P['manor_mid']
    for y in range(2, 16):
        for x in range(2, 14):
            if x in [5, 9]:  # plank divisions
                c = P['wood_dark'] if style == 'wood' else P['manor_lo']
            else:
                c = door_c
            img.putpixel((ox+x, oy+y), noise_color(c, 4) + (255,))

    # Handle
    img.putpixel((ox+11, oy+9), P['gold'] + (255,))
    img.putpixel((ox+11, oy+10), P['gold_dark'] + (255,))


def draw_well(img, ox, oy):
    """Top-down well."""
    # Stone ring
    for y in range(16):
        for x in range(16):
            dist = ((x-7.5)**2 + (y-7.5)**2) ** 0.5
            if 4 < dist < 7:
                img.putpixel((ox+x, oy+y), noise_color(P['stone_mid'], 5) + (255,))
            elif dist <= 4:
                img.putpixel((ox+x, oy+y), noise_color(P['water_deep'], 4) + (255,))
            else:
                img.putpixel((ox+x, oy+y), noise_color(P['cobble_mid'], 4) + (255,))
    # Rope and bucket
    img.putpixel((ox+8, oy+2), P['wood_mid'] + (255,))
    img.putpixel((ox+8, oy+3), P['wood_mid'] + (255,))


def draw_tree(img, ox, oy, trunk=False):
    """Tree trunk or canopy."""
    if trunk:
        # Tree trunk from top-down
        for y in range(16):
            for x in range(16):
                dist = ((x-7.5)**2 + (y-7.5)**2) ** 0.5
                if dist < 3:
                    c = P['wood_lo']
                elif dist < 4:
                    c = P['wood_dark']
                else:
                    c = P['grass_mid']
                img.putpixel((ox+x, oy+y), noise_color(c, 5) + (255,))
    else:
        # Canopy - dense dark green
        for y in range(16):
            for x in range(16):
                dist = ((x-7.5)**2 + (y-7.5)**2) ** 0.5
                if dist < 6:
                    r = random.random()
                    if r < 0.2:
                        c = P['grass_hi']
                    elif r < 0.5:
                        c = (42, 65, 35)
                    else:
                        c = (32, 52, 28)
                    img.putpixel((ox+x, oy+y), noise_color(c, 5) + (255,))
                elif dist < 7:
                    img.putpixel((ox+x, oy+y), noise_color((28, 45, 22), 4) + (255,))


def draw_bush(img, ox, oy, dead=False):
    """Bush."""
    for y in range(16):
        for x in range(16):
            img.putpixel((ox+x, oy+y), (0, 0, 0, 0))

    c1 = P['dead_mid'] if dead else P['grass_mid']
    c2 = P['dead_lo'] if dead else P['grass_lo']
    c3 = P['dead_hi'] if dead else P['grass_hi']

    for y in range(4, 14):
        for x in range(3, 13):
            dist = ((x-7.5)**2 + (y-8.5)**2) ** 0.5
            if dist < 4.5:
                r = random.random()
                c = c3 if r < 0.2 else (c1 if r < 0.6 else c2)
                img.putpixel((ox+x, oy+y), noise_color(c, 5) + (255,))


def draw_fence(img, ox, oy, broken=False):
    """Wooden fence."""
    for y in range(16):
        for x in range(16):
            img.putpixel((ox+x, oy+y), (0, 0, 0, 0))

    # Horizontal rail
    for x in range(16):
        img.putpixel((ox+x, oy+6), P['wood_mid'] + (255,))
        img.putpixel((ox+x, oy+10), P['wood_mid'] + (255,))

    # Vertical posts
    for y in range(3, 14):
        img.putpixel((ox+2, oy+y), P['wood_lo'] + (255,))
        img.putpixel((ox+3, oy+y), P['wood_mid'] + (255,))
        if not broken:
            img.putpixel((ox+12, oy+y), P['wood_lo'] + (255,))
            img.putpixel((ox+13, oy+y), P['wood_mid'] + (255,))
        else:
            # Broken post
            for y2 in range(7, 14):
                img.putpixel((ox+12, oy+y2), (0, 0, 0, 0))
                img.putpixel((ox+13, oy+y2), (0, 0, 0, 0))


def draw_simple_object(img, ox, oy, obj_type):
    """Draw various small objects."""
    # Clear to transparent
    for y in range(16):
        for x in range(16):
            img.putpixel((ox+x, oy+y), (0, 0, 0, 0))

    d = ImageDraw.Draw(img)

    if obj_type == 'rock_small':
        d.ellipse([ox+4, oy+8, ox+12, oy+14], fill=P['stone_mid']+(255,), outline=P['stone_lo']+(255,))
        d.line([(ox+5, oy+9), (ox+10, oy+9)], fill=P['stone_hi']+(255,))

    elif obj_type == 'rock_large':
        d.ellipse([ox+2, oy+4, ox+14, oy+14], fill=P['stone_mid']+(255,), outline=P['stone_lo']+(255,))
        d.ellipse([ox+3, oy+5, ox+11, oy+10], fill=P['stone_hi']+(255,))

    elif obj_type == 'grave':
        d.rectangle([ox+5, oy+3, ox+10, oy+5], fill=P['stone_mid']+(255,))
        d.rectangle([ox+6, oy+2, ox+9, oy+8], fill=P['stone_mid']+(255,))
        d.line([(ox+6, oy+4), (ox+9, oy+4)], fill=P['stone_hi']+(255,))
        d.rectangle([ox+4, oy+9, ox+11, oy+14], fill=P['dirt_mid']+(255,))

    elif obj_type == 'altar':
        d.rectangle([ox+3, oy+5, ox+12, oy+13], fill=P['stone_mid']+(255,), outline=P['stone_lo']+(255,))
        d.line([(ox+4, oy+6), (ox+11, oy+6)], fill=P['stone_hi']+(255,))
        # Candle
        d.rectangle([ox+7, oy+2, ox+8, oy+5], fill=(220, 200, 160, 255))
        img.putpixel((ox+7, oy+1), P['torch_fire']+(255,))

    elif obj_type == 'barrel':
        d.ellipse([ox+3, oy+3, ox+12, oy+13], fill=P['wood_mid']+(255,), outline=P['wood_dark']+(255,))
        d.ellipse([ox+4, oy+5, ox+11, oy+11], fill=P['wood_hi']+(255,))
        # Metal bands
        d.arc([ox+3, oy+5, ox+12, oy+11], 0, 360, fill=P['stone_lo']+(255,))

    elif obj_type == 'crate':
        d.rectangle([ox+3, oy+4, ox+12, oy+13], fill=P['wood_mid']+(255,), outline=P['wood_dark']+(255,))
        d.line([(ox+3, oy+8), (ox+12, oy+8)], fill=P['wood_dark']+(255,))
        d.line([(ox+7, oy+4), (ox+7, oy+13)], fill=P['wood_dark']+(255,))

    elif obj_type == 'market_stall':
        # Awning top
        d.rectangle([ox+0, oy+0, ox+15, oy+5], fill=P['wood_mid']+(255,))
        for x in range(0, 16, 4):
            d.rectangle([ox+x, oy+0, ox+x+1, oy+5], fill=P['wood_dark']+(255,))
        # Counter
        d.rectangle([ox+1, oy+6, ox+14, oy+10], fill=P['wood_hi']+(255,), outline=P['wood_lo']+(255,))

    elif obj_type == 'stairs':
        for i in range(4):
            y_pos = oy + 2 + i * 3
            shade = P['stone_hi'] if i % 2 == 0 else P['stone_mid']
            d.rectangle([ox+2, y_pos, ox+13, y_pos+2], fill=shade+(255,), outline=P['stone_lo']+(255,))

    elif obj_type == 'mushroom':
        d.ellipse([ox+5, oy+5, ox+11, oy+10], fill=P['mushroom']+(255,), outline=P['wood_dark']+(255,))
        d.rectangle([ox+7, oy+10, ox+8, oy+13], fill=P['mushroom']+(255,))
        # Spots
        img.putpixel((ox+7, oy+7), P['dead_hi']+(255,))
        img.putpixel((ox+9, oy+6), P['dead_hi']+(255,))

    elif obj_type == 'flowers_dead':
        for i in range(4):
            fx = ox + 3 + i * 3
            d.line([(fx, oy+12), (fx, oy+6)], fill=P['dead_lo']+(255,))
            img.putpixel((fx-1, oy+5), P['dead_mid']+(255,))
            img.putpixel((fx, oy+5), P['dead_hi']+(255,))
            img.putpixel((fx+1, oy+5), P['dead_mid']+(255,))

    elif obj_type == 'leaves':
        for _ in range(12):
            lx = ox + random.randint(1, 14)
            ly = oy + random.randint(1, 14)
            c = random.choice([P['leaf_brown'], P['leaf_red'], P['dead_mid']])
            img.putpixel((lx, ly), c+(255,))
            img.putpixel((lx+1, ly), c+(255,))

    elif obj_type == 'roots':
        # Creeping roots
        for i in range(5):
            rx = random.randint(2, 12)
            ry = random.randint(2, 12)
            for j in range(4):
                nx = rx + random.randint(-1, 1)
                ny = ry + j
                if 0 <= nx < 16 and 0 <= ny < 16:
                    img.putpixel((ox+nx, oy+ny), P['root_brown']+(255,))

    elif obj_type == 'roof_thatch':
        for y in range(16):
            for x in range(16):
                r = random.random()
                c = P['dead_hi'] if r < 0.3 else (P['dead_mid'] if r < 0.7 else P['dead_lo'])
                img.putpixel((ox+x, oy+y), noise_color(c, 6)+(255,))
        # Thatch lines
        for y in range(0, 16, 3):
            for x in range(16):
                img.putpixel((ox+x, oy+y), P['dead_lo']+(255,))

    elif obj_type == 'roof_tile':
        for y in range(16):
            for x in range(16):
                tile_row = y // 4
                tile_col = (x + (tile_row % 2) * 4) // 8
                if y % 4 == 0:
                    c = P['wood_dark']
                elif tile_row % 2 == 0:
                    c = (142, 68, 48)
                else:
                    c = (128, 58, 42)
                img.putpixel((ox+x, oy+y), noise_color(c, 5)+(255,))

    elif obj_type == 'chimney':
        d.rectangle([ox+4, oy+2, ox+11, oy+13], fill=P['stone_mid']+(255,), outline=P['stone_lo']+(255,))
        # Smoke
        img.putpixel((ox+7, oy+1), (120, 115, 110, 140))
        img.putpixel((ox+8, oy+0), (130, 125, 120, 100))

    elif obj_type == 'window_lit':
        d.rectangle([ox+3, oy+3, ox+12, oy+12], fill=P['stone_lo']+(255,))
        d.rectangle([ox+4, oy+4, ox+11, oy+11], fill=P['torch_glow']+(255,))
        d.line([(ox+7, oy+4), (ox+7, oy+11)], fill=P['wood_dark']+(255,))
        d.line([(ox+4, oy+7), (ox+11, oy+7)], fill=P['wood_dark']+(255,))

    elif obj_type == 'window_dark':
        d.rectangle([ox+3, oy+3, ox+12, oy+12], fill=P['stone_lo']+(255,))
        d.rectangle([ox+4, oy+4, ox+11, oy+11], fill=P['near_black']+(255,))
        d.line([(ox+7, oy+4), (ox+7, oy+11)], fill=P['wood_dark']+(255,))
        d.line([(ox+4, oy+7), (ox+11, oy+7)], fill=P['wood_dark']+(255,))

    elif obj_type == 'sign':
        d.rectangle([ox+6, oy+4, ox+9, oy+14], fill=P['wood_lo']+(255,))
        d.rectangle([ox+2, oy+2, ox+13, oy+7], fill=P['wood_mid']+(255,), outline=P['wood_dark']+(255,))

    elif obj_type == 'torch':
        d.rectangle([ox+6, oy+6, ox+9, oy+14], fill=P['wood_lo']+(255,))
        d.ellipse([ox+5, oy+2, ox+10, oy+7], fill=P['torch_fire']+(255,))
        img.putpixel((ox+7, oy+1), P['torch_glow']+(255,))
        img.putpixel((ox+8, oy+1), P['torch_glow']+(255,))
        # Glow around
        for dx in range(-2, 3):
            for dy in range(-2, 3):
                px, py = ox+7+dx, oy+4+dy
                if 0 <= px < img.width and 0 <= py < img.height:
                    r, g, b, a = img.getpixel((px, py))
                    if a < 50:
                        img.putpixel((px, py), (P['torch_glow'][0], P['torch_glow'][1], P['torch_glow'][2], 60))

    elif obj_type == 'blood':
        for _ in range(8):
            bx = ox + random.randint(3, 12)
            by = oy + random.randint(3, 12)
            c = random.choice([P['blood'], P['blood_dark']])
            img.putpixel((bx, by), c+(255,))
            img.putpixel((bx+1, by), c+(255,))
            img.putpixel((bx, by+1), c+(255,))


# === MAIN GENERATION ===

print("Generating professional tileset (16 cols x 6 rows = 96 tiles)...")

# 16 columns x 6 rows = 96 tiles, but we only need 48. Use 16x3.
COLS = 16
ROWS = 3
img = Image.new('RGBA', (COLS * 16, ROWS * 16), (0, 0, 0, 0))

# Row 0: Ground tiles (0-15)
draw_grass(img, 0*16, 0)          # 0: grass
draw_dead_grass(img, 1*16, 0)     # 1: grass_dead
draw_dirt(img, 2*16, 0)           # 2: dirt
draw_path(img, 3*16, 0)           # 3: dirt_path
draw_cobblestone(img, 4*16, 0)    # 4: cobblestone
draw_stone_floor(img, 5*16, 0)    # 5: stone_floor
draw_wood_floor(img, 6*16, 0)     # 6: wood_floor
draw_mud(img, 7*16, 0)            # 7: mud
draw_water(img, 8*16, 0)          # 8: water
draw_water(img, 9*16, 0, True)    # 9: water_shallow
draw_farmland(img, 10*16, 0, True)  # 10: farmland_healthy
draw_farmland(img, 11*16, 0, False) # 11: farmland_dead
draw_simple_object(img, 12*16, 0, 'flowers_dead')  # 12
draw_simple_object(img, 13*16, 0, 'mushroom')       # 13
draw_simple_object(img, 14*16, 0, 'leaves')          # 14
draw_simple_object(img, 15*16, 0, 'roots')            # 15

# Row 1: Walls and structures (16-31)
draw_wall(img, 0*16, 16, P['wall_hi'], P['wall_mid'], P['wall_lo'], P['wall_dark'])  # 16: wall_stone
# 17: wall_stone_moss
draw_wall(img, 1*16, 16, P['wall_hi'], P['wall_mid'], P['wall_lo'], P['wall_dark'])
# Add moss
for _ in range(8):
    mx = 1*16 + random.randint(0, 15)
    my = 16 + random.randint(0, 15)
    img.putpixel((mx, my), P['moss']+(255,))

draw_wall(img, 2*16, 16, P['wood_hi'], P['wood_mid'], P['wood_lo'], P['wood_dark'])  # 18: wall_wood
draw_wall(img, 3*16, 16, P['wood_hi'], P['wood_mid'], P['wood_lo'], P['wood_dark'])  # 19: wall_wood_damaged
# Add damage marks
for _ in range(5):
    dx = 3*16 + random.randint(2, 13)
    dy = 16 + random.randint(2, 13)
    img.putpixel((dx, dy), P['black']+(255,))

draw_wall(img, 4*16, 16, P['chapel_hi'], P['chapel_mid'], P['chapel_lo'], P['stone_dark'])  # 20: wall_chapel
draw_wall(img, 5*16, 16, P['manor_hi'], P['manor_mid'], P['manor_lo'], P['near_black'])  # 21: wall_manor
draw_fence(img, 6*16, 16)  # 22: fence_wood
draw_fence(img, 7*16, 16, True)  # 23: fence_broken

draw_door(img, 8*16, 16, 'wood')  # 24: door_wood
draw_door(img, 9*16, 16, 'wood')  # 25: door_wood_locked (add keyhole)
img.putpixel((9*16+11, 16+8), P['gold']+(255,))
draw_door(img, 10*16, 16, 'manor')  # 26: door_manor
draw_simple_object(img, 11*16, 16, 'stairs')  # 27: stairs_down
draw_well(img, 12*16, 16)  # 28: well
draw_simple_object(img, 13*16, 16, 'market_stall')  # 29: market_stall
draw_simple_object(img, 14*16, 16, 'barrel')  # 30: barrel
draw_simple_object(img, 15*16, 16, 'crate')  # 31: crate

# Row 2: Nature and decorations (32-47)
draw_tree(img, 0*16, 32, trunk=True)  # 32: tree_trunk
draw_tree(img, 1*16, 32, trunk=False)  # 33: tree_canopy
draw_bush(img, 2*16, 32)  # 34: bush
draw_bush(img, 3*16, 32, dead=True)  # 35: bush_dead
draw_simple_object(img, 4*16, 32, 'rock_small')  # 36: rock_small
draw_simple_object(img, 5*16, 32, 'rock_large')  # 37: rock_large
draw_simple_object(img, 6*16, 32, 'grave')  # 38: grave_marker
draw_simple_object(img, 7*16, 32, 'altar')  # 39: altar_stone
draw_simple_object(img, 8*16, 32, 'roof_thatch')  # 40: roof_thatch
draw_simple_object(img, 9*16, 32, 'roof_tile')  # 41: roof_tile
draw_simple_object(img, 10*16, 32, 'chimney')  # 42: chimney
draw_simple_object(img, 11*16, 32, 'window_lit')  # 43: window_lit
draw_simple_object(img, 12*16, 32, 'window_dark')  # 44: window_dark
draw_simple_object(img, 13*16, 32, 'sign')  # 45: sign_hanging
draw_simple_object(img, 14*16, 32, 'torch')  # 46: torch_wall
draw_simple_object(img, 15*16, 32, 'blood')  # 47: blood_splatter

img.save(OUT_PATH)
print(f"Saved to {OUT_PATH}")
print(f"Tileset: {img.width}x{img.height} ({COLS}x{ROWS} = {COLS*ROWS} tiles)")
