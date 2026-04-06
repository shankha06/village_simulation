#!/usr/bin/env python3
"""
Generate all pixel art assets for the dark fantasy RPG.
Each sprite is hand-crafted pixel by pixel for a coherent, moody aesthetic.
"""

import os
from PIL import Image, ImageDraw

# ---------------------------------------------------------------------------
# Palette
# ---------------------------------------------------------------------------
P = {
    'black': (20, 12, 28),
    'dark_purple': (68, 36, 52),
    'dark_blue': (48, 52, 109),
    'dark_green': (78, 74, 78),
    'brown': (133, 76, 48),
    'dark_brown': (89, 51, 33),
    'tan': (208, 176, 128),
    'skin_light': (228, 196, 168),
    'skin_dark': (183, 137, 103),
    'red': (172, 50, 50),
    'dark_red': (127, 37, 37),
    'orange': (223, 113, 38),
    'yellow': (251, 226, 81),
    'green': (106, 137, 85),
    'dark_gray': (55, 55, 55),
    'gray': (100, 100, 100),
    'light_gray': (155, 155, 155),
    'white': (222, 222, 222),
    'gold': (218, 175, 72),
    'blue': (69, 107, 159),
    'light_blue': (109, 170, 212),
    'blood': (140, 25, 25),
    'poison_purple': (98, 52, 118),
    'holy_white': (240, 232, 220),
    'ash_gray': (168, 162, 158),
    'forest_green': (47, 72, 46),
    'moss_green': (68, 96, 56),
}

T = (0, 0, 0, 0)  # transparent


def c(name, alpha=255):
    """Get a palette color as RGBA tuple."""
    r, g, b = P[name]
    return (r, g, b, alpha)


def make_img(w, h):
    return Image.new('RGBA', (w, h), T)


def px(img, x, y, color):
    """Set a pixel. color can be a palette key string or RGBA tuple."""
    if isinstance(color, str):
        color = c(color)
    if 0 <= x < img.width and 0 <= y < img.height:
        img.putpixel((x, y), color)


def fill_rect(img, x0, y0, w, h, color):
    if isinstance(color, str):
        color = c(color)
    for yy in range(y0, y0 + h):
        for xx in range(x0, x0 + w):
            px(img, xx, yy, color)


def blit(dest, src, ox, oy):
    """Paste src onto dest at offset (ox, oy) with alpha."""
    dest.paste(src, (ox, oy), src)


def mirror_h(img):
    """Return horizontally mirrored copy."""
    return img.transpose(Image.FLIP_LEFT_RIGHT)


def save(img, path):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    img.save(path)
    print(f"  -> {path}")


ROOT = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))


# ===========================================================================
# PLAYER SPRITES
# ===========================================================================

def draw_player_down(img, ox, oy):
    """Hooded traveler facing down (toward camera) at 16x16."""
    # Hood / head
    for x in range(5, 11):
        px(img, ox+x, oy+1, 'dark_gray')  # hood top
    for x in range(4, 12):
        px(img, ox+x, oy+2, 'dark_gray')
    px(img, ox+4, oy+3, 'dark_gray')
    px(img, ox+11, oy+3, 'dark_gray')
    # Face
    for x in range(5, 11):
        px(img, ox+x, oy+3, 'skin_dark')
    for x in range(5, 11):
        px(img, ox+x, oy+4, 'skin_dark')
    # Eyes
    px(img, ox+6, oy+3, 'black')
    px(img, ox+9, oy+3, 'black')
    # Hood sides
    px(img, ox+4, oy+4, 'dark_gray')
    px(img, ox+11, oy+4, 'dark_gray')
    # Cloak body
    for y in range(5, 11):
        for x in range(4, 12):
            px(img, ox+x, oy+y, 'dark_gray')
    # Cloak center line (fold)
    for y in range(5, 11):
        px(img, ox+7, oy+y, 'black')
        px(img, ox+8, oy+y, 'black')
    # Cloak highlights
    for y in range(6, 10):
        px(img, ox+5, oy+y, 'gray')
        px(img, ox+10, oy+y, 'gray')
    # Belt
    for x in range(5, 11):
        px(img, ox+x, oy+8, 'dark_brown')
    px(img, ox+7, oy+8, 'gold')  # buckle
    # Legs / boots
    for x in range(5, 8):
        px(img, ox+x, oy+11, 'dark_gray')
        px(img, ox+x, oy+12, 'dark_brown')
    for x in range(8, 11):
        px(img, ox+x, oy+11, 'dark_gray')
        px(img, ox+x, oy+12, 'dark_brown')
    # Boot bottoms
    for x in range(5, 8):
        px(img, ox+x, oy+13, 'brown')
    for x in range(8, 11):
        px(img, ox+x, oy+13, 'brown')


def draw_player_up(img, ox, oy):
    """Hooded traveler facing up (away from camera)."""
    # Hood
    for x in range(5, 11):
        px(img, ox+x, oy+1, 'dark_gray')
    for x in range(4, 12):
        px(img, ox+x, oy+2, 'dark_gray')
    for x in range(4, 12):
        px(img, ox+x, oy+3, 'dark_gray')
    for x in range(4, 12):
        px(img, ox+x, oy+4, 'dark_gray')
    # Hood point
    px(img, ox+7, oy+0, 'dark_gray')
    px(img, ox+8, oy+0, 'dark_gray')
    # Cloak body (back)
    for y in range(5, 11):
        for x in range(4, 12):
            px(img, ox+x, oy+y, 'dark_gray')
    # Cloak back seam
    for y in range(3, 11):
        px(img, ox+7, oy+y, c('black', 120))
        px(img, ox+8, oy+y, c('black', 120))
    # Cloak edge highlights
    for y in range(5, 10):
        px(img, ox+4, oy+y, 'gray')
        px(img, ox+11, oy+y, 'gray')
    # Belt
    for x in range(5, 11):
        px(img, ox+x, oy+8, 'dark_brown')
    # Legs / boots
    for x in range(5, 8):
        px(img, ox+x, oy+11, 'dark_gray')
        px(img, ox+x, oy+12, 'dark_brown')
    for x in range(8, 11):
        px(img, ox+x, oy+11, 'dark_gray')
        px(img, ox+x, oy+12, 'dark_brown')
    for x in range(5, 8):
        px(img, ox+x, oy+13, 'brown')
    for x in range(8, 11):
        px(img, ox+x, oy+13, 'brown')


def draw_player_left(img, ox, oy):
    """Hooded traveler facing left."""
    # Hood / head side view
    for x in range(5, 10):
        px(img, ox+x, oy+1, 'dark_gray')
    for x in range(4, 11):
        px(img, ox+x, oy+2, 'dark_gray')
    px(img, ox+4, oy+3, 'dark_gray')
    px(img, ox+5, oy+3, 'dark_gray')
    # Face (side)
    for x in range(6, 10):
        px(img, ox+x, oy+3, 'skin_dark')
    for x in range(5, 10):
        px(img, ox+x, oy+4, 'skin_dark')
    px(img, ox+10, oy+3, 'dark_gray')
    px(img, ox+10, oy+4, 'dark_gray')
    # Eye
    px(img, ox+6, oy+3, 'black')
    # Cloak body
    for y in range(5, 11):
        for x in range(4, 11):
            px(img, ox+x, oy+y, 'dark_gray')
    # Arm (left side visible)
    for y in range(5, 9):
        px(img, ox+4, oy+y, 'gray')
    # Cloak fold
    for y in range(5, 11):
        px(img, ox+9, oy+y, c('black', 120))
    # Belt
    for x in range(5, 10):
        px(img, ox+x, oy+8, 'dark_brown')
    # Legs
    for x in range(5, 8):
        px(img, ox+x, oy+11, 'dark_gray')
        px(img, ox+x, oy+12, 'dark_brown')
        px(img, ox+x, oy+13, 'brown')
    for x in range(8, 10):
        px(img, ox+x, oy+11, 'dark_gray')
        px(img, ox+x, oy+12, 'dark_brown')
        px(img, ox+x, oy+13, 'brown')


def draw_player_right(img, ox, oy):
    """Hooded traveler facing right — mirror of left."""
    tmp = make_img(16, 16)
    draw_player_left(tmp, 0, 0)
    tmp = mirror_h(tmp)
    blit(img, tmp, ox, oy)


def generate_player_idle():
    print("Generating player idle spritesheet...")
    img = make_img(64, 16)  # 4 frames: down, left, right, up
    draw_player_down(img, 0, 0)
    draw_player_left(img, 16, 0)
    draw_player_right(img, 32, 0)
    draw_player_up(img, 48, 0)
    save(img, os.path.join(ROOT, 'assets/sprites/player/player_idle.png'))


def generate_player_walk():
    print("Generating player walk spritesheet...")
    # 4 directions x 4 frames = 16 frames in a row
    img = make_img(256, 16)

    draw_funcs = [draw_player_down, draw_player_left, draw_player_right, draw_player_up]

    for d, draw_fn in enumerate(draw_funcs):
        for f in range(4):
            frame = make_img(16, 16)
            draw_fn(frame, 0, 0)
            # Animate: shift legs and body slightly per frame
            # Frame 0: neutral, Frame 1: left step, Frame 2: neutral, Frame 3: right step
            anim = make_img(16, 16)
            if f == 0 or f == 2:
                blit(anim, frame, 0, 0)
            elif f == 1:
                # Slight bob up
                blit(anim, frame, 0, -1)
                # Shift left boot
                px(anim, 5, 14, 'brown')
                px(anim, 6, 14, 'brown')
            elif f == 3:
                blit(anim, frame, 0, -1)
                # Shift right boot
                px(anim, 9, 14, 'brown')
                px(anim, 10, 14, 'brown')
            blit(img, anim, (d * 4 + f) * 16, 0)

    save(img, os.path.join(ROOT, 'assets/sprites/player/player_walk.png'))


# ===========================================================================
# NPC SPRITE HELPERS
# ===========================================================================

def draw_base_body(img, ox, oy, body_color, belt_color=None, skin='skin_dark'):
    """Draw a generic humanoid base — useful for all NPCs facing down."""
    # Head area (will be customized per NPC)
    pass


def draw_npc_frame(w=16, h=16):
    return make_img(w, h)


def make_npc_spritesheet(draw_down_fn, draw_left_fn=None, draw_up_fn=None):
    """Create a 4-frame spritesheet: down, left, right, up.
    If left/up not provided, derives them."""
    img = make_img(64, 16)

    down = draw_npc_frame()
    draw_down_fn(down, 0, 0)
    blit(img, down, 0, 0)

    if draw_left_fn:
        left = draw_npc_frame()
        draw_left_fn(left, 0, 0)
    else:
        left = down.copy()  # fallback
    blit(img, left, 16, 0)

    right = mirror_h(left)
    blit(img, right, 32, 0)

    if draw_up_fn:
        up = draw_npc_frame()
        draw_up_fn(up, 0, 0)
    else:
        up = down.copy()
    blit(img, up, 48, 0)

    return img


# ----- ELARA (herbalist) -----
def draw_elara_down(img, ox, oy):
    # Hair (long, brown)
    for x in range(5, 11):
        px(img, ox+x, oy+1, 'brown')
    for x in range(4, 12):
        px(img, ox+x, oy+2, 'brown')
    # Face
    for x in range(5, 11):
        px(img, ox+x, oy+3, 'skin_light')
    for x in range(5, 11):
        px(img, ox+x, oy+4, 'skin_light')
    # Hair sides
    px(img, ox+4, oy+3, 'brown')
    px(img, ox+11, oy+3, 'brown')
    px(img, ox+4, oy+4, 'brown')
    px(img, ox+11, oy+4, 'brown')
    # Eyes
    px(img, ox+6, oy+3, 'dark_green')
    px(img, ox+9, oy+3, 'dark_green')
    # Mouth
    px(img, ox+7, oy+4, 'dark_red')
    # Green/brown clothes
    for y in range(5, 10):
        for x in range(4, 12):
            px(img, ox+x, oy+y, 'moss_green')
    # Brown apron / front
    for y in range(6, 10):
        for x in range(6, 10):
            px(img, ox+x, oy+y, 'dark_brown')
    # Belt with herb pouch
    for x in range(5, 11):
        px(img, ox+x, oy+8, 'brown')
    px(img, ox+10, oy+7, 'forest_green')  # pouch
    px(img, ox+10, oy+8, 'forest_green')
    # Long hair hanging down
    px(img, ox+4, oy+5, 'brown')
    px(img, ox+4, oy+6, 'brown')
    px(img, ox+4, oy+7, 'brown')
    px(img, ox+11, oy+5, 'brown')
    px(img, ox+11, oy+6, 'brown')
    px(img, ox+11, oy+7, 'brown')
    # Skirt
    for x in range(4, 12):
        px(img, ox+x, oy+10, 'moss_green')
    for x in range(5, 11):
        px(img, ox+x, oy+11, 'moss_green')
    # Boots
    for x in range(5, 8):
        px(img, ox+x, oy+12, 'dark_brown')
        px(img, ox+x, oy+13, 'brown')
    for x in range(8, 11):
        px(img, ox+x, oy+12, 'dark_brown')
        px(img, ox+x, oy+13, 'brown')


def draw_elara_left(img, ox, oy):
    # Hair
    for x in range(5, 10):
        px(img, ox+x, oy+1, 'brown')
    for x in range(4, 11):
        px(img, ox+x, oy+2, 'brown')
    # Face side
    for x in range(5, 9):
        px(img, ox+x, oy+3, 'skin_light')
        px(img, ox+x, oy+4, 'skin_light')
    px(img, ox+9, oy+3, 'brown')
    px(img, ox+9, oy+4, 'brown')
    px(img, ox+4, oy+3, 'brown')
    px(img, ox+4, oy+4, 'brown')
    px(img, ox+6, oy+3, 'dark_green')  # eye
    # Body
    for y in range(5, 10):
        for x in range(4, 10):
            px(img, ox+x, oy+y, 'moss_green')
    for y in range(6, 9):
        for x in range(5, 8):
            px(img, ox+x, oy+y, 'dark_brown')
    for x in range(5, 10):
        px(img, ox+x, oy+8, 'brown')
    # Hair hanging
    px(img, ox+9, oy+5, 'brown')
    px(img, ox+9, oy+6, 'brown')
    px(img, ox+9, oy+7, 'brown')
    # Skirt + boots
    for x in range(4, 10):
        px(img, ox+x, oy+10, 'moss_green')
        px(img, ox+x, oy+11, 'moss_green')
    for x in range(5, 8):
        px(img, ox+x, oy+12, 'dark_brown')
        px(img, ox+x, oy+13, 'brown')


def draw_elara_up(img, ox, oy):
    # Hair from back
    for x in range(5, 11):
        px(img, ox+x, oy+1, 'brown')
    for x in range(4, 12):
        px(img, ox+x, oy+2, 'brown')
    for x in range(4, 12):
        px(img, ox+x, oy+3, 'brown')
    for x in range(4, 12):
        px(img, ox+x, oy+4, 'brown')
    # Long hair down back
    px(img, ox+4, oy+5, 'brown')
    px(img, ox+11, oy+5, 'brown')
    px(img, ox+4, oy+6, 'brown')
    px(img, ox+11, oy+6, 'brown')
    px(img, ox+4, oy+7, 'brown')
    px(img, ox+11, oy+7, 'brown')
    # Body
    for y in range(5, 10):
        for x in range(5, 11):
            px(img, ox+x, oy+y, 'moss_green')
    for x in range(5, 11):
        px(img, ox+x, oy+8, 'brown')
    # Skirt + boots
    for x in range(5, 11):
        px(img, ox+x, oy+10, 'moss_green')
        px(img, ox+x, oy+11, 'moss_green')
    for x in range(5, 8):
        px(img, ox+x, oy+12, 'dark_brown')
        px(img, ox+x, oy+13, 'brown')
    for x in range(8, 11):
        px(img, ox+x, oy+12, 'dark_brown')
        px(img, ox+x, oy+13, 'brown')


# ----- FENRICK (thin, hooded, shifty) -----
def draw_fenrick_down(img, ox, oy):
    # Hood
    for x in range(5, 11):
        px(img, ox+x, oy+1, 'dark_gray')
    for x in range(4, 12):
        px(img, ox+x, oy+2, 'dark_gray')
    px(img, ox+4, oy+3, 'dark_gray')
    px(img, ox+11, oy+3, 'dark_gray')
    # Face — thin, shifty
    for x in range(5, 11):
        px(img, ox+x, oy+3, 'skin_dark')
    for x in range(5, 11):
        px(img, ox+x, oy+4, 'skin_dark')
    # Shifty eyes (asymmetric)
    px(img, ox+6, oy+3, 'black')
    px(img, ox+9, oy+3, 'dark_red')  # one eye glints
    # Thin body, dark clothes
    for y in range(5, 11):
        for x in range(5, 11):
            px(img, ox+x, oy+y, 'black')
    # Cloak edges
    for y in range(5, 10):
        px(img, ox+4, oy+y, 'dark_gray')
        px(img, ox+11, oy+y, 'dark_gray')
    # Belt
    for x in range(5, 11):
        px(img, ox+x, oy+8, 'dark_brown')
    # Dagger at belt
    px(img, ox+10, oy+7, 'light_gray')
    px(img, ox+10, oy+9, 'light_gray')
    # Thin legs
    for x in range(6, 8):
        px(img, ox+x, oy+11, 'black')
        px(img, ox+x, oy+12, 'dark_brown')
        px(img, ox+x, oy+13, 'dark_brown')
    for x in range(9, 11):
        px(img, ox+x, oy+11, 'black')
        px(img, ox+x, oy+12, 'dark_brown')
        px(img, ox+x, oy+13, 'dark_brown')


def draw_fenrick_left(img, ox, oy):
    # Hood
    for x in range(5, 10):
        px(img, ox+x, oy+1, 'dark_gray')
    for x in range(4, 11):
        px(img, ox+x, oy+2, 'dark_gray')
    px(img, ox+4, oy+3, 'dark_gray')
    # Face
    for x in range(5, 9):
        px(img, ox+x, oy+3, 'skin_dark')
        px(img, ox+x, oy+4, 'skin_dark')
    px(img, ox+9, oy+3, 'dark_gray')
    px(img, ox+6, oy+3, 'black')
    # Body
    for y in range(5, 11):
        for x in range(5, 10):
            px(img, ox+x, oy+y, 'black')
    for y in range(5, 10):
        px(img, ox+4, oy+y, 'dark_gray')
    for x in range(5, 10):
        px(img, ox+x, oy+8, 'dark_brown')
    # Legs
    for x in range(6, 8):
        px(img, ox+x, oy+11, 'black')
        px(img, ox+x, oy+12, 'dark_brown')
        px(img, ox+x, oy+13, 'dark_brown')


def draw_fenrick_up(img, ox, oy):
    # Hood from back
    for x in range(5, 11):
        px(img, ox+x, oy+1, 'dark_gray')
    for x in range(4, 12):
        px(img, ox+x, oy+2, 'dark_gray')
    for x in range(4, 12):
        px(img, ox+x, oy+3, 'dark_gray')
    for x in range(4, 12):
        px(img, ox+x, oy+4, 'dark_gray')
    px(img, ox+7, oy+0, 'dark_gray')
    px(img, ox+8, oy+0, 'dark_gray')
    # Body
    for y in range(5, 11):
        for x in range(5, 11):
            px(img, ox+x, oy+y, 'black')
    for y in range(5, 10):
        px(img, ox+4, oy+y, 'dark_gray')
        px(img, ox+11, oy+y, 'dark_gray')
    for x in range(5, 11):
        px(img, ox+x, oy+8, 'dark_brown')
    # Legs
    for x in range(6, 8):
        px(img, ox+x, oy+11, 'black')
        px(img, ox+x, oy+12, 'dark_brown')
        px(img, ox+x, oy+13, 'dark_brown')
    for x in range(9, 11):
        px(img, ox+x, oy+11, 'black')
        px(img, ox+x, oy+12, 'dark_brown')
        px(img, ox+x, oy+13, 'dark_brown')


# ----- BROTHER MAREN (gaunt priest) -----
def draw_brother_maren_down(img, ox, oy):
    # Bald head
    for x in range(5, 11):
        px(img, ox+x, oy+1, 'skin_dark')
    for x in range(4, 12):
        px(img, ox+x, oy+2, 'skin_dark')
    # Face
    for x in range(5, 11):
        px(img, ox+x, oy+3, 'skin_light')
    for x in range(5, 11):
        px(img, ox+x, oy+4, 'skin_light')
    # Sunken eyes
    px(img, ox+6, oy+3, 'dark_purple')
    px(img, ox+9, oy+3, 'dark_purple')
    px(img, ox+6, oy+4, 'black')
    px(img, ox+9, oy+4, 'black')
    # Gray robes (long, flowing)
    for y in range(5, 12):
        for x in range(4, 12):
            px(img, ox+x, oy+y, 'ash_gray')
    # Robe center seam
    for y in range(5, 12):
        px(img, ox+7, oy+y, 'gray')
        px(img, ox+8, oy+y, 'gray')
    # Holy symbol on chest
    px(img, ox+7, oy+6, 'gold')
    px(img, ox+8, oy+6, 'gold')
    px(img, ox+7, oy+7, 'gold')
    # Rope belt
    for x in range(5, 11):
        px(img, ox+x, oy+9, 'tan')
    # Hunched — head forward slightly
    px(img, ox+7, oy+0, 'skin_dark')
    px(img, ox+8, oy+0, 'skin_dark')
    # Sandals
    for x in range(5, 8):
        px(img, ox+x, oy+12, 'brown')
        px(img, ox+x, oy+13, 'brown')
    for x in range(8, 11):
        px(img, ox+x, oy+12, 'brown')
        px(img, ox+x, oy+13, 'brown')


def draw_brother_maren_left(img, ox, oy):
    # Bald head side
    for x in range(5, 10):
        px(img, ox+x, oy+1, 'skin_dark')
    for x in range(4, 10):
        px(img, ox+x, oy+2, 'skin_dark')
    for x in range(5, 9):
        px(img, ox+x, oy+3, 'skin_light')
        px(img, ox+x, oy+4, 'skin_light')
    px(img, ox+6, oy+3, 'dark_purple')
    px(img, ox+6, oy+4, 'black')
    # Robes
    for y in range(5, 12):
        for x in range(4, 10):
            px(img, ox+x, oy+y, 'ash_gray')
    for y in range(5, 12):
        px(img, ox+8, oy+y, 'gray')
    for x in range(5, 10):
        px(img, ox+x, oy+9, 'tan')
    # Sandals
    for x in range(5, 8):
        px(img, ox+x, oy+12, 'brown')
        px(img, ox+x, oy+13, 'brown')


def draw_brother_maren_up(img, ox, oy):
    # Bald head from back
    for x in range(5, 11):
        px(img, ox+x, oy+1, 'skin_dark')
    for x in range(4, 12):
        px(img, ox+x, oy+2, 'skin_dark')
    for x in range(4, 12):
        px(img, ox+x, oy+3, 'skin_dark')
    for x in range(5, 11):
        px(img, ox+x, oy+4, 'skin_dark')
    # Robes back
    for y in range(5, 12):
        for x in range(4, 12):
            px(img, ox+x, oy+y, 'ash_gray')
    for y in range(5, 12):
        px(img, ox+7, oy+y, 'gray')
        px(img, ox+8, oy+y, 'gray')
    for x in range(5, 11):
        px(img, ox+x, oy+9, 'tan')
    for x in range(5, 8):
        px(img, ox+x, oy+12, 'brown')
        px(img, ox+x, oy+13, 'brown')
    for x in range(8, 11):
        px(img, ox+x, oy+12, 'brown')
        px(img, ox+x, oy+13, 'brown')


# ----- GRETA (stout innkeeper) -----
def draw_greta_down(img, ox, oy):
    # Curly hair
    for x in range(4, 12):
        px(img, ox+x, oy+0, 'brown')
    for x in range(3, 13):
        px(img, ox+x, oy+1, 'brown')
    for x in range(3, 13):
        px(img, ox+x, oy+2, 'brown')
    # Face (round/stout)
    for x in range(4, 12):
        px(img, ox+x, oy+3, 'skin_light')
    for x in range(4, 12):
        px(img, ox+x, oy+4, 'skin_light')
    # Rosy cheeks
    px(img, ox+5, oy+4, 'red')
    px(img, ox+10, oy+4, 'red')
    # Eyes
    px(img, ox+6, oy+3, 'dark_brown')
    px(img, ox+9, oy+3, 'dark_brown')
    # Smile
    px(img, ox+7, oy+4, 'dark_red')
    px(img, ox+8, oy+4, 'dark_red')
    # Stout body / dress
    for y in range(5, 11):
        for x in range(3, 13):
            px(img, ox+x, oy+y, 'dark_brown')
    # White apron
    for y in range(5, 11):
        for x in range(5, 11):
            px(img, ox+x, oy+y, 'white')
    # Apron strings
    px(img, ox+5, oy+7, 'tan')
    px(img, ox+10, oy+7, 'tan')
    # Belt/waist
    for x in range(4, 12):
        px(img, ox+x, oy+8, 'brown')
    # Skirt
    for x in range(4, 12):
        px(img, ox+x, oy+10, 'dark_brown')
        px(img, ox+x, oy+11, 'dark_brown')
    # Shoes
    for x in range(5, 8):
        px(img, ox+x, oy+12, 'dark_brown')
        px(img, ox+x, oy+13, 'brown')
    for x in range(8, 11):
        px(img, ox+x, oy+12, 'dark_brown')
        px(img, ox+x, oy+13, 'brown')


def draw_greta_left(img, ox, oy):
    # Hair
    for x in range(4, 11):
        px(img, ox+x, oy+0, 'brown')
    for x in range(3, 11):
        px(img, ox+x, oy+1, 'brown')
    for x in range(3, 11):
        px(img, ox+x, oy+2, 'brown')
    # Face
    for x in range(4, 9):
        px(img, ox+x, oy+3, 'skin_light')
        px(img, ox+x, oy+4, 'skin_light')
    px(img, ox+6, oy+3, 'dark_brown')
    px(img, ox+5, oy+4, 'red')
    # Body
    for y in range(5, 11):
        for x in range(3, 11):
            px(img, ox+x, oy+y, 'dark_brown')
    for y in range(5, 10):
        for x in range(5, 9):
            px(img, ox+x, oy+y, 'white')
    for x in range(4, 10):
        px(img, ox+x, oy+8, 'brown')
    # Skirt + shoes
    for x in range(4, 10):
        px(img, ox+x, oy+10, 'dark_brown')
        px(img, ox+x, oy+11, 'dark_brown')
    for x in range(5, 8):
        px(img, ox+x, oy+12, 'dark_brown')
        px(img, ox+x, oy+13, 'brown')


def draw_greta_up(img, ox, oy):
    # Curly hair back
    for x in range(4, 12):
        px(img, ox+x, oy+0, 'brown')
    for x in range(3, 13):
        px(img, ox+x, oy+1, 'brown')
    for x in range(3, 13):
        px(img, ox+x, oy+2, 'brown')
    for x in range(4, 12):
        px(img, ox+x, oy+3, 'brown')
    for x in range(5, 11):
        px(img, ox+x, oy+4, 'brown')
    # Body
    for y in range(5, 11):
        for x in range(3, 13):
            px(img, ox+x, oy+y, 'dark_brown')
    # Apron ties
    px(img, ox+7, oy+6, 'white')
    px(img, ox+8, oy+6, 'white')
    px(img, ox+7, oy+7, 'tan')
    px(img, ox+8, oy+7, 'tan')
    for x in range(4, 12):
        px(img, ox+x, oy+8, 'brown')
    for x in range(4, 12):
        px(img, ox+x, oy+10, 'dark_brown')
        px(img, ox+x, oy+11, 'dark_brown')
    for x in range(5, 8):
        px(img, ox+x, oy+12, 'dark_brown')
        px(img, ox+x, oy+13, 'brown')
    for x in range(8, 11):
        px(img, ox+x, oy+12, 'dark_brown')
        px(img, ox+x, oy+13, 'brown')


# ----- COMMANDER VOSS (armored woman) -----
def draw_commander_voss_down(img, ox, oy):
    # Short hair
    for x in range(5, 11):
        px(img, ox+x, oy+1, 'dark_gray')
    for x in range(5, 11):
        px(img, ox+x, oy+2, 'dark_brown')
    # Face
    for x in range(5, 11):
        px(img, ox+x, oy+3, 'skin_dark')
    for x in range(5, 11):
        px(img, ox+x, oy+4, 'skin_dark')
    # Stern eyes
    px(img, ox+6, oy+3, 'dark_blue')
    px(img, ox+9, oy+3, 'dark_blue')
    # Scar
    px(img, ox+10, oy+3, 'dark_red')
    px(img, ox+10, oy+4, 'dark_red')
    # Armor
    for y in range(5, 10):
        for x in range(4, 12):
            px(img, ox+x, oy+y, 'gray')
    # Armor details — plate lines
    for y in range(5, 10):
        px(img, ox+7, oy+y, 'light_gray')
        px(img, ox+8, oy+y, 'light_gray')
    # Shoulders (pauldrons)
    px(img, ox+3, oy+5, 'gray')
    px(img, ox+3, oy+6, 'gray')
    px(img, ox+12, oy+5, 'gray')
    px(img, ox+12, oy+6, 'gray')
    px(img, ox+3, oy+5, 'light_gray')
    px(img, ox+12, oy+5, 'light_gray')
    # Belt + sword
    for x in range(5, 11):
        px(img, ox+x, oy+8, 'dark_brown')
    px(img, ox+4, oy+8, 'gold')  # sword hilt
    px(img, ox+4, oy+9, 'light_gray')  # blade peeks
    px(img, ox+4, oy+10, 'light_gray')
    px(img, ox+4, oy+11, 'light_gray')
    # Armored legs
    for x in range(5, 8):
        px(img, ox+x, oy+10, 'gray')
        px(img, ox+x, oy+11, 'gray')
        px(img, ox+x, oy+12, 'dark_gray')
        px(img, ox+x, oy+13, 'dark_brown')
    for x in range(8, 11):
        px(img, ox+x, oy+10, 'gray')
        px(img, ox+x, oy+11, 'gray')
        px(img, ox+x, oy+12, 'dark_gray')
        px(img, ox+x, oy+13, 'dark_brown')


def draw_commander_voss_left(img, ox, oy):
    for x in range(5, 10):
        px(img, ox+x, oy+1, 'dark_gray')
        px(img, ox+x, oy+2, 'dark_brown')
    for x in range(5, 9):
        px(img, ox+x, oy+3, 'skin_dark')
        px(img, ox+x, oy+4, 'skin_dark')
    px(img, ox+6, oy+3, 'dark_blue')
    for y in range(5, 10):
        for x in range(4, 10):
            px(img, ox+x, oy+y, 'gray')
    px(img, ox+3, oy+5, 'gray')
    px(img, ox+3, oy+6, 'gray')
    for y in range(5, 10):
        px(img, ox+7, oy+y, 'light_gray')
    for x in range(5, 10):
        px(img, ox+x, oy+8, 'dark_brown')
    # Sword on side
    px(img, ox+4, oy+9, 'light_gray')
    px(img, ox+4, oy+10, 'light_gray')
    px(img, ox+4, oy+11, 'light_gray')
    for x in range(5, 8):
        px(img, ox+x, oy+10, 'gray')
        px(img, ox+x, oy+11, 'gray')
        px(img, ox+x, oy+12, 'dark_gray')
        px(img, ox+x, oy+13, 'dark_brown')


def draw_commander_voss_up(img, ox, oy):
    for x in range(5, 11):
        px(img, ox+x, oy+1, 'dark_gray')
        px(img, ox+x, oy+2, 'dark_brown')
    for x in range(5, 11):
        px(img, ox+x, oy+3, 'dark_brown')
        px(img, ox+x, oy+4, 'dark_brown')
    for y in range(5, 10):
        for x in range(4, 12):
            px(img, ox+x, oy+y, 'gray')
    px(img, ox+3, oy+5, 'gray')
    px(img, ox+3, oy+6, 'gray')
    px(img, ox+12, oy+5, 'gray')
    px(img, ox+12, oy+6, 'gray')
    for y in range(5, 10):
        px(img, ox+7, oy+y, 'light_gray')
        px(img, ox+8, oy+y, 'light_gray')
    for x in range(5, 11):
        px(img, ox+x, oy+8, 'dark_brown')
    px(img, ox+4, oy+9, 'light_gray')
    px(img, ox+4, oy+10, 'light_gray')
    px(img, ox+4, oy+11, 'light_gray')
    for x in range(5, 8):
        px(img, ox+x, oy+10, 'gray')
        px(img, ox+x, oy+11, 'gray')
        px(img, ox+x, oy+12, 'dark_gray')
        px(img, ox+x, oy+13, 'dark_brown')
    for x in range(8, 11):
        px(img, ox+x, oy+10, 'gray')
        px(img, ox+x, oy+11, 'gray')
        px(img, ox+x, oy+12, 'dark_gray')
        px(img, ox+x, oy+13, 'dark_brown')


# ----- LORD ASHWORTH (disheveled noble) -----
def draw_lord_ashworth_down(img, ox, oy):
    # Messy hair
    for x in range(4, 12):
        px(img, ox+x, oy+0, 'dark_brown')
    for x in range(4, 12):
        px(img, ox+x, oy+1, 'dark_brown')
    px(img, ox+3, oy+1, 'dark_brown')
    px(img, ox+12, oy+1, 'dark_brown')
    for x in range(4, 12):
        px(img, ox+x, oy+2, 'dark_brown')
    # Face — haunted
    for x in range(5, 11):
        px(img, ox+x, oy+3, 'skin_light')
    for x in range(5, 11):
        px(img, ox+x, oy+4, 'skin_light')
    # Sunken, haunted eyes
    px(img, ox+6, oy+3, 'black')
    px(img, ox+9, oy+3, 'black')
    px(img, ox+5, oy+3, 'dark_purple')  # bags under eyes
    px(img, ox+10, oy+3, 'dark_purple')
    # Stubble
    px(img, ox+6, oy+4, 'gray')
    px(img, ox+9, oy+4, 'gray')
    # Rich but dirty clothes
    for y in range(5, 10):
        for x in range(4, 12):
            px(img, ox+x, oy+y, 'dark_purple')
    # Gold embroidery (faded)
    for y in range(5, 8):
        px(img, ox+5, oy+y, 'gold')
        px(img, ox+10, oy+y, 'gold')
    # Stained spots
    px(img, ox+7, oy+6, 'dark_brown')
    px(img, ox+8, oy+7, 'dark_brown')
    # Collar
    px(img, ox+5, oy+5, 'white')
    px(img, ox+6, oy+5, 'white')
    px(img, ox+9, oy+5, 'white')
    px(img, ox+10, oy+5, 'white')
    # Belt
    for x in range(5, 11):
        px(img, ox+x, oy+9, 'gold')
    # Pants + boots
    for x in range(5, 8):
        px(img, ox+x, oy+10, 'dark_brown')
        px(img, ox+x, oy+11, 'dark_brown')
        px(img, ox+x, oy+12, 'dark_gray')
        px(img, ox+x, oy+13, 'brown')
    for x in range(8, 11):
        px(img, ox+x, oy+10, 'dark_brown')
        px(img, ox+x, oy+11, 'dark_brown')
        px(img, ox+x, oy+12, 'dark_gray')
        px(img, ox+x, oy+13, 'brown')


def draw_lord_ashworth_left(img, ox, oy):
    for x in range(4, 10):
        px(img, ox+x, oy+0, 'dark_brown')
        px(img, ox+x, oy+1, 'dark_brown')
        px(img, ox+x, oy+2, 'dark_brown')
    for x in range(5, 9):
        px(img, ox+x, oy+3, 'skin_light')
        px(img, ox+x, oy+4, 'skin_light')
    px(img, ox+6, oy+3, 'black')
    px(img, ox+5, oy+3, 'dark_purple')
    for y in range(5, 10):
        for x in range(4, 10):
            px(img, ox+x, oy+y, 'dark_purple')
    for y in range(5, 8):
        px(img, ox+5, oy+y, 'gold')
    px(img, ox+5, oy+5, 'white')
    px(img, ox+6, oy+5, 'white')
    for x in range(5, 10):
        px(img, ox+x, oy+9, 'gold')
    for x in range(5, 8):
        px(img, ox+x, oy+10, 'dark_brown')
        px(img, ox+x, oy+11, 'dark_brown')
        px(img, ox+x, oy+12, 'dark_gray')
        px(img, ox+x, oy+13, 'brown')


def draw_lord_ashworth_up(img, ox, oy):
    for x in range(4, 12):
        px(img, ox+x, oy+0, 'dark_brown')
        px(img, ox+x, oy+1, 'dark_brown')
        px(img, ox+x, oy+2, 'dark_brown')
        px(img, ox+x, oy+3, 'dark_brown')
        px(img, ox+x, oy+4, 'dark_brown')
    for y in range(5, 10):
        for x in range(4, 12):
            px(img, ox+x, oy+y, 'dark_purple')
    for y in range(5, 8):
        px(img, ox+5, oy+y, 'gold')
        px(img, ox+10, oy+y, 'gold')
    for x in range(5, 11):
        px(img, ox+x, oy+9, 'gold')
    for x in range(5, 8):
        px(img, ox+x, oy+10, 'dark_brown')
        px(img, ox+x, oy+11, 'dark_brown')
        px(img, ox+x, oy+12, 'dark_gray')
        px(img, ox+x, oy+13, 'brown')
    for x in range(8, 11):
        px(img, ox+x, oy+10, 'dark_brown')
        px(img, ox+x, oy+11, 'dark_brown')
        px(img, ox+x, oy+12, 'dark_gray')
        px(img, ox+x, oy+13, 'brown')


# ----- OLD MAREN (blind elder) -----
def draw_old_maren_down(img, ox, oy):
    # Shawl/head covering
    for x in range(4, 12):
        px(img, ox+x, oy+0, 'ash_gray')
    for x in range(3, 13):
        px(img, ox+x, oy+1, 'ash_gray')
    for x in range(3, 13):
        px(img, ox+x, oy+2, 'ash_gray')
    # Face (elderly)
    for x in range(5, 11):
        px(img, ox+x, oy+3, 'skin_dark')
    for x in range(5, 11):
        px(img, ox+x, oy+4, 'skin_dark')
    # Blind white eyes
    px(img, ox+6, oy+3, 'white')
    px(img, ox+9, oy+3, 'white')
    # Wrinkles
    px(img, ox+5, oy+4, 'dark_brown')
    px(img, ox+10, oy+4, 'dark_brown')
    # Shawl continues
    px(img, ox+3, oy+3, 'ash_gray')
    px(img, ox+3, oy+4, 'ash_gray')
    px(img, ox+12, oy+3, 'ash_gray')
    px(img, ox+12, oy+4, 'ash_gray')
    # Body — dark draped clothes
    for y in range(5, 12):
        for x in range(4, 12):
            px(img, ox+x, oy+y, 'dark_gray')
    # Shawl drape
    for y in range(5, 8):
        px(img, ox+3, oy+y, 'ash_gray')
        px(img, ox+4, oy+y, 'ash_gray')
        px(img, ox+12, oy+y, 'ash_gray')
        px(img, ox+11, oy+y, 'ash_gray')
    # Staff (held in right hand)
    px(img, ox+12, oy+3, 'brown')
    px(img, ox+12, oy+4, 'brown')
    px(img, ox+12, oy+5, 'brown')
    px(img, ox+12, oy+6, 'brown')
    px(img, ox+12, oy+7, 'brown')
    px(img, ox+12, oy+8, 'brown')
    px(img, ox+12, oy+9, 'brown')
    px(img, ox+12, oy+10, 'brown')
    px(img, ox+12, oy+11, 'brown')
    px(img, ox+12, oy+12, 'brown')
    # Staff carving (top)
    px(img, ox+12, oy+2, 'gold')
    px(img, ox+12, oy+1, 'gold')
    # Feet
    for x in range(5, 8):
        px(img, ox+x, oy+12, 'dark_brown')
        px(img, ox+x, oy+13, 'dark_brown')
    for x in range(8, 11):
        px(img, ox+x, oy+12, 'dark_brown')
        px(img, ox+x, oy+13, 'dark_brown')


def draw_old_maren_left(img, ox, oy):
    for x in range(4, 10):
        px(img, ox+x, oy+0, 'ash_gray')
        px(img, ox+x, oy+1, 'ash_gray')
        px(img, ox+x, oy+2, 'ash_gray')
    for x in range(5, 9):
        px(img, ox+x, oy+3, 'skin_dark')
        px(img, ox+x, oy+4, 'skin_dark')
    px(img, ox+6, oy+3, 'white')  # blind eye
    px(img, ox+3, oy+3, 'ash_gray')
    px(img, ox+3, oy+4, 'ash_gray')
    for y in range(5, 12):
        for x in range(4, 10):
            px(img, ox+x, oy+y, 'dark_gray')
    for y in range(5, 8):
        px(img, ox+3, oy+y, 'ash_gray')
        px(img, ox+4, oy+y, 'ash_gray')
    # Staff
    for y in range(1, 13):
        px(img, ox+10, oy+y, 'brown')
    px(img, ox+10, oy+0, 'gold')
    for x in range(5, 8):
        px(img, ox+x, oy+12, 'dark_brown')
        px(img, ox+x, oy+13, 'dark_brown')


def draw_old_maren_up(img, ox, oy):
    for x in range(4, 12):
        px(img, ox+x, oy+0, 'ash_gray')
    for x in range(3, 13):
        px(img, ox+x, oy+1, 'ash_gray')
    for x in range(3, 13):
        px(img, ox+x, oy+2, 'ash_gray')
    for x in range(4, 12):
        px(img, ox+x, oy+3, 'ash_gray')
    for x in range(5, 11):
        px(img, ox+x, oy+4, 'ash_gray')
    for y in range(5, 12):
        for x in range(4, 12):
            px(img, ox+x, oy+y, 'dark_gray')
    for y in range(5, 8):
        px(img, ox+3, oy+y, 'ash_gray')
        px(img, ox+4, oy+y, 'ash_gray')
        px(img, ox+11, oy+y, 'ash_gray')
        px(img, ox+12, oy+y, 'ash_gray')
    # Staff
    for y in range(1, 13):
        px(img, ox+12, oy+y, 'brown')
    px(img, ox+12, oy+0, 'gold')
    for x in range(5, 8):
        px(img, ox+x, oy+12, 'dark_brown')
        px(img, ox+x, oy+13, 'dark_brown')
    for x in range(8, 11):
        px(img, ox+x, oy+12, 'dark_brown')
        px(img, ox+x, oy+13, 'dark_brown')


NPC_DEFS = {
    'elara': (draw_elara_down, draw_elara_left, draw_elara_up),
    'fenrick': (draw_fenrick_down, draw_fenrick_left, draw_fenrick_up),
    'brother_maren': (draw_brother_maren_down, draw_brother_maren_left, draw_brother_maren_up),
    'greta': (draw_greta_down, draw_greta_left, draw_greta_up),
    'commander_voss': (draw_commander_voss_down, draw_commander_voss_left, draw_commander_voss_up),
    'lord_ashworth': (draw_lord_ashworth_down, draw_lord_ashworth_left, draw_lord_ashworth_up),
    'old_maren': (draw_old_maren_down, draw_old_maren_left, draw_old_maren_up),
}


def generate_npc_sprites():
    print("Generating NPC sprites...")
    for name, (down_fn, left_fn, up_fn) in NPC_DEFS.items():
        sheet = make_npc_spritesheet(down_fn, left_fn, up_fn)
        save(sheet, os.path.join(ROOT, f'assets/sprites/npcs/{name}.png'))


# ===========================================================================
# NPC PORTRAITS (48x48)
# ===========================================================================

# Each portrait: a larger, more detailed face.
# We define a base face drawing function and overlay per-NPC features + emotion.

def draw_portrait_base(img, skin_col, hair_col, features_fn, emotion='neutral'):
    """Draw a 48x48 portrait with face, hair, and features."""
    # Background — dark vignette
    fill_rect(img, 0, 0, 48, 48, 'black')
    # Slight border
    for x in range(1, 47):
        px(img, x, 0, 'dark_gray')
        px(img, x, 47, 'dark_gray')
    for y in range(1, 47):
        px(img, 0, y, 'dark_gray')
        px(img, 47, y, 'dark_gray')

    # Neck
    fill_rect(img, 19, 36, 10, 6, skin_col)

    # Head shape (oval)
    for y in range(8, 36):
        # Width varies to make oval
        if y < 12:
            w = 6 + (y - 8) * 2
        elif y < 28:
            w = 14
        elif y < 32:
            w = 14 - (y - 28)
        else:
            w = 10 - (y - 32)
        if w < 2:
            w = 2
        x0 = 24 - w
        for x in range(x0, x0 + w * 2):
            px(img, x, y, skin_col)

    # Features callback draws hair, eyes, mouth, etc.
    features_fn(img, emotion)


# --- Per-NPC portrait features ---

def elara_features(img, emotion):
    # Long brown hair
    for y in range(4, 14):
        for x in range(8, 40):
            if img.getpixel((x, y))[3] == 0 or y < 10:
                px(img, x, y, 'brown')
    # Hair sides
    for y in range(10, 38):
        for x in range(7, 12):
            px(img, x, y, 'brown')
        for x in range(36, 41):
            px(img, x, y, 'brown')
    # Eyes
    _draw_eyes(img, 17, 20, 27, 20, 'forest_green', emotion)
    # Nose
    px(img, 23, 24, 'skin_dark')
    px(img, 24, 24, 'skin_dark')
    # Mouth
    _draw_mouth(img, 20, 28, emotion)
    # Herb pouch hint at bottom
    fill_rect(img, 36, 40, 6, 5, 'forest_green')
    fill_rect(img, 37, 41, 4, 3, 'moss_green')
    # Green/brown collar
    fill_rect(img, 14, 36, 20, 4, 'moss_green')


def fenrick_features(img, emotion):
    # Hood
    for y in range(3, 16):
        w = min(20, 8 + (y - 3) * 2)
        x0 = 24 - w
        for x in range(x0, x0 + w * 2):
            px(img, x, y, 'dark_gray')
    for y in range(16, 20):
        for x in range(6, 42):
            if img.getpixel((x, y)) == c('dark_gray'):
                continue
            if y < 18:
                px(img, x, y, 'dark_gray')
    # Shadow under hood
    for x in range(10, 38):
        px(img, x, 16, 'black')
        px(img, x, 17, c('black', 160))
    # Eyes — shifty, one glints red
    _draw_eyes(img, 17, 21, 27, 21, 'dark_red', emotion, left_color='black')
    # Thin face already from base
    # Nose
    px(img, 23, 25, 'skin_dark')
    # Mouth — thin
    _draw_mouth(img, 21, 29, emotion, width=6)
    # Dark collar
    fill_rect(img, 14, 36, 20, 4, 'black')


def brother_maren_features(img, emotion):
    # Bald — just skin on top, slightly shiny
    for y in range(6, 12):
        for x in range(12, 36):
            if img.getpixel((x, y))[3] > 0:
                px(img, x, y, 'skin_light')
    # Highlight on bald head
    for x in range(20, 28):
        px(img, x, 7, 'white')
        px(img, x, 8, c('white', 80))
    # Sunken dark eyes
    fill_rect(img, 15, 19, 5, 4, 'dark_purple')
    fill_rect(img, 26, 19, 5, 4, 'dark_purple')
    px(img, 17, 20, 'black')
    px(img, 18, 20, 'black')
    px(img, 28, 20, 'black')
    px(img, 29, 20, 'black')
    # Wrinkles
    for x in range(14, 20):
        px(img, x, 23, 'skin_dark')
    for x in range(28, 34):
        px(img, x, 23, 'skin_dark')
    # Nose
    px(img, 23, 24, 'skin_dark')
    px(img, 24, 25, 'skin_dark')
    # Mouth
    _draw_mouth(img, 20, 28, emotion, width=6)
    # Gray robe collar
    fill_rect(img, 12, 36, 24, 6, 'ash_gray')
    # Holy symbol
    px(img, 23, 38, 'gold')
    px(img, 24, 38, 'gold')
    px(img, 23, 39, 'gold')
    px(img, 24, 39, 'gold')
    px(img, 22, 38, 'gold')
    px(img, 25, 38, 'gold')


def greta_features(img, emotion):
    # Curly hair (round, voluminous)
    for y in range(2, 14):
        w = min(22, 10 + (y - 2) * 2)
        x0 = 24 - w
        for x in range(x0, x0 + w * 2):
            px(img, x, y, 'brown')
    # Curl highlights
    for y in range(4, 12, 3):
        for x in range(8, 40, 5):
            px(img, x, y, 'tan')
    # Round rosy cheeks
    fill_rect(img, 12, 24, 4, 3, 'red')
    fill_rect(img, 32, 24, 4, 3, 'red')
    # Eyes — warm
    _draw_eyes(img, 17, 20, 27, 20, 'dark_brown', emotion)
    # Nose
    px(img, 23, 24, 'skin_dark')
    px(img, 24, 24, 'skin_dark')
    # Mouth
    _draw_mouth(img, 19, 28, emotion, width=10)
    # Apron collar
    fill_rect(img, 14, 36, 20, 6, 'dark_brown')
    fill_rect(img, 17, 37, 14, 5, 'white')


def commander_voss_features(img, emotion):
    # Short dark hair
    for y in range(5, 13):
        for x in range(10, 38):
            if img.getpixel((x, y))[3] > 0:
                px(img, x, y, 'dark_brown')
    for y in range(5, 10):
        w = min(16, 6 + (y - 5) * 2)
        x0 = 24 - w
        for x in range(x0, x0 + w * 2):
            px(img, x, y, 'dark_brown')
    # Stern eyes
    _draw_eyes(img, 16, 20, 27, 20, 'dark_blue', emotion)
    # Scar on right cheek
    for y in range(22, 28):
        px(img, 33, y, 'dark_red')
        px(img, 34, y, 'dark_red')
    # Nose
    px(img, 23, 24, 'skin_dark')
    px(img, 24, 24, 'skin_dark')
    # Mouth
    _draw_mouth(img, 20, 28, emotion, width=8)
    # Armor collar
    fill_rect(img, 10, 36, 28, 8, 'gray')
    fill_rect(img, 12, 37, 24, 2, 'light_gray')
    # Pauldron hints
    fill_rect(img, 4, 38, 8, 6, 'gray')
    fill_rect(img, 36, 38, 8, 6, 'gray')
    fill_rect(img, 5, 38, 6, 2, 'light_gray')
    fill_rect(img, 37, 38, 6, 2, 'light_gray')


def lord_ashworth_features(img, emotion):
    # Messy dark hair
    for y in range(4, 14):
        w = min(18, 8 + (y - 4) * 2)
        x0 = 24 - w
        for x in range(x0, x0 + w * 2):
            px(img, x, y, 'dark_brown')
    # Stray hairs
    px(img, 6, 8, 'dark_brown')
    px(img, 5, 10, 'dark_brown')
    px(img, 40, 7, 'dark_brown')
    px(img, 41, 9, 'dark_brown')
    # Haunted, sunken eyes with bags
    fill_rect(img, 14, 19, 6, 2, 'dark_purple')
    fill_rect(img, 26, 19, 6, 2, 'dark_purple')
    _draw_eyes(img, 16, 19, 27, 19, 'black', emotion)
    # Stubble
    for x in range(18, 30):
        if x % 2 == 0:
            px(img, x, 30, 'gray')
            px(img, x, 31, 'gray')
    # Nose
    px(img, 23, 24, 'skin_dark')
    px(img, 24, 25, 'skin_dark')
    # Mouth
    _draw_mouth(img, 20, 29, emotion, width=8)
    # Rich but dirty collar
    fill_rect(img, 12, 36, 24, 6, 'dark_purple')
    # Gold trim
    for x in range(12, 36):
        px(img, x, 36, 'gold')
    # Dirt stains
    px(img, 18, 38, 'dark_brown')
    px(img, 28, 39, 'dark_brown')
    px(img, 22, 40, 'dark_brown')


def old_maren_features(img, emotion):
    # Shawl/head covering
    for y in range(2, 18):
        w = min(22, 8 + (y - 2) * 2)
        x0 = 24 - w
        for x in range(x0, x0 + w * 2):
            px(img, x, y, 'ash_gray')
    # Wrinkled face visible
    for y in range(14, 18):
        for x in range(14, 34):
            px(img, x, y, 'skin_dark')
    # Blind white eyes (no pupils)
    fill_rect(img, 15, 20, 5, 3, 'white')
    fill_rect(img, 26, 20, 5, 3, 'white')
    # Very faint iris hint
    px(img, 17, 21, c('light_blue', 80))
    px(img, 28, 21, c('light_blue', 80))
    # Deep wrinkles
    for x in range(14, 20):
        px(img, x, 24, 'dark_brown')
        px(img, x, 17, 'dark_brown')
    for x in range(28, 34):
        px(img, x, 24, 'dark_brown')
        px(img, x, 17, 'dark_brown')
    # Nose
    px(img, 23, 25, 'dark_brown')
    px(img, 24, 25, 'dark_brown')
    # Mouth (thin)
    _draw_mouth(img, 21, 29, emotion, width=6)
    # Shawl body
    fill_rect(img, 8, 36, 32, 8, 'dark_gray')
    # Shawl drape
    for y in range(18, 40):
        px(img, 8, y, 'ash_gray')
        px(img, 9, y, 'ash_gray')
        px(img, 38, y, 'ash_gray')
        px(img, 39, y, 'ash_gray')


def _draw_eyes(img, lx, ly, rx, ry, iris_color, emotion, left_color=None):
    """Draw a pair of eyes with emotion variation."""
    if left_color is None:
        left_color = iris_color
    # Eye whites
    fill_rect(img, lx - 1, ly - 1, 5, 3, 'white')
    fill_rect(img, rx - 1, ry - 1, 5, 3, 'white')
    # Iris
    px(img, lx, ly, left_color)
    px(img, lx + 1, ly, left_color)
    px(img, rx, ry, iris_color)
    px(img, rx + 1, ry, iris_color)
    # Pupil
    px(img, lx, ly, 'black')
    px(img, rx + 1, ry, 'black')

    # Emotion: eyebrows and lids
    if emotion == 'neutral':
        for dx in range(-1, 4):
            px(img, lx + dx, ly - 2, 'dark_brown')
            px(img, rx + dx, ry - 2, 'dark_brown')
    elif emotion == 'happy':
        for dx in range(-1, 4):
            px(img, lx + dx, ly - 2, 'dark_brown')
            px(img, rx + dx, ry - 2, 'dark_brown')
        # Squint — cover top of eye
        for dx in range(-1, 4):
            px(img, lx + dx, ly - 1, 'dark_brown')
            px(img, rx + dx, ry - 1, 'dark_brown')
    elif emotion == 'angry':
        # Angled brows
        px(img, lx - 1, ly - 2, 'dark_brown')
        px(img, lx, ly - 3, 'dark_brown')
        px(img, lx + 1, ly - 3, 'dark_brown')
        px(img, lx + 2, ly - 2, 'dark_brown')
        px(img, rx - 1, ry - 2, 'dark_brown')
        px(img, rx, ry - 3, 'dark_brown')
        px(img, rx + 1, ry - 3, 'dark_brown')
        px(img, rx + 2, ry - 2, 'dark_brown')
    elif emotion == 'sad':
        # Droopy brows
        px(img, lx - 1, ly - 3, 'dark_brown')
        px(img, lx, ly - 3, 'dark_brown')
        px(img, lx + 1, ly - 2, 'dark_brown')
        px(img, lx + 2, ly - 2, 'dark_brown')
        px(img, rx - 1, ry - 2, 'dark_brown')
        px(img, rx, ry - 2, 'dark_brown')
        px(img, rx + 1, ry - 3, 'dark_brown')
        px(img, rx + 2, ry - 3, 'dark_brown')
    elif emotion == 'fearful':
        # Raised brows, wide eyes
        for dx in range(-1, 4):
            px(img, lx + dx, ly - 3, 'dark_brown')
            px(img, rx + dx, ry - 3, 'dark_brown')
        # Extra white above eyes
        for dx in range(-1, 4):
            px(img, lx + dx, ly - 2, 'white')
            px(img, rx + dx, ry - 2, 'white')


def _draw_mouth(img, x, y, emotion, width=8):
    """Draw mouth at position with emotion."""
    hw = width // 2
    cx = x + hw
    if emotion == 'neutral':
        for dx in range(width):
            px(img, x + dx, y, 'dark_red')
    elif emotion == 'happy':
        # Smile curve
        for dx in range(width):
            dy = 0 if abs(dx - hw) < hw - 1 else -1
            px(img, x + dx, y - dy, 'dark_red')
        # Wider smile
        px(img, x + hw, y + 1, 'dark_red')
    elif emotion == 'angry':
        # Frown
        for dx in range(width):
            dy = 0 if abs(dx - hw) < hw - 1 else 1
            px(img, x + dx, y + dy, 'dark_red')
    elif emotion == 'sad':
        # Slight downturn
        for dx in range(width):
            dy = 1 if abs(dx - hw) > hw - 2 else 0
            px(img, x + dx, y + dy, 'dark_red')
    elif emotion == 'fearful':
        # Open mouth (O shape)
        fill_rect(img, x + 2, y - 1, width - 4, 3, 'dark_red')
        fill_rect(img, x + 3, y, width - 6, 1, 'black')


NPC_PORTRAIT_DEFS = {
    'elara': ('skin_light', elara_features),
    'fenrick': ('skin_dark', fenrick_features),
    'brother_maren': ('skin_light', brother_maren_features),
    'greta': ('skin_light', greta_features),
    'commander_voss': ('skin_dark', commander_voss_features),
    'lord_ashworth': ('skin_light', lord_ashworth_features),
    'old_maren': ('skin_dark', old_maren_features),
}

EMOTIONS = ['neutral', 'happy', 'angry', 'sad', 'fearful']


def generate_portraits():
    print("Generating NPC portraits...")
    for npc_name, (skin, feat_fn) in NPC_PORTRAIT_DEFS.items():
        for emotion in EMOTIONS:
            img = make_img(48, 48)
            draw_portrait_base(img, skin, 'brown', feat_fn, emotion)
            save(img, os.path.join(ROOT, f'assets/sprites/portraits/{npc_name}_{emotion}.png'))


# ===========================================================================
# TILESET
# ===========================================================================

def draw_tile_grass(img, ox, oy):
    fill_rect(img, ox, oy, 16, 16, 'forest_green')
    # Patchy variation
    for pos in [(2,3),(5,7),(9,2),(12,10),(3,12),(8,5),(14,8),(1,9),(10,14),(6,1)]:
        px(img, ox+pos[0], oy+pos[1], 'moss_green')
    for pos in [(4,5),(11,3),(7,11),(1,14),(13,6)]:
        px(img, ox+pos[0], oy+pos[1], 'dark_green')
    # Grass blades
    for pos in [(3,2),(8,4),(13,9),(5,13),(10,1)]:
        px(img, ox+pos[0], oy+pos[1], 'green')
        px(img, ox+pos[0], oy+pos[1]-1, 'green')


def draw_tile_grass_dead(img, ox, oy):
    fill_rect(img, ox, oy, 16, 16, 'dark_brown')
    for pos in [(2,3),(5,7),(9,2),(12,10),(3,12),(8,5),(14,8)]:
        px(img, ox+pos[0], oy+pos[1], 'brown')
    for pos in [(4,5),(11,3),(7,11)]:
        px(img, ox+pos[0], oy+pos[1], 'dark_gray')


def draw_tile_dirt(img, ox, oy):
    fill_rect(img, ox, oy, 16, 16, 'dark_brown')
    for pos in [(1,1),(4,6),(8,3),(12,9),(6,13),(14,2),(3,10),(10,7),(15,14),(2,5)]:
        px(img, ox+pos[0], oy+pos[1], 'brown')
    for pos in [(7,2),(3,8),(11,12)]:
        px(img, ox+pos[0], oy+pos[1], 'dark_gray')


def draw_tile_dirt_path(img, ox, oy):
    fill_rect(img, ox, oy, 16, 16, 'brown')
    for pos in [(2,4),(7,8),(12,2),(4,12),(9,6),(14,14),(1,10)]:
        px(img, ox+pos[0], oy+pos[1], 'tan')
    for pos in [(5,1),(10,11),(3,7)]:
        px(img, ox+pos[0], oy+pos[1], 'dark_brown')


def draw_tile_cobblestone(img, ox, oy):
    fill_rect(img, ox, oy, 16, 16, 'gray')
    # Stone pattern — mortar lines
    for x in range(16):
        px(img, ox+x, oy+0, 'dark_gray')
        px(img, ox+x, oy+4, 'dark_gray')
        px(img, ox+x, oy+8, 'dark_gray')
        px(img, ox+x, oy+12, 'dark_gray')
    # Vertical mortar (offset per row)
    for y in range(1, 4):
        px(img, ox+4, oy+y, 'dark_gray')
        px(img, ox+10, oy+y, 'dark_gray')
    for y in range(5, 8):
        px(img, ox+2, oy+y, 'dark_gray')
        px(img, ox+7, oy+y, 'dark_gray')
        px(img, ox+13, oy+y, 'dark_gray')
    for y in range(9, 12):
        px(img, ox+5, oy+y, 'dark_gray')
        px(img, ox+11, oy+y, 'dark_gray')
    for y in range(13, 16):
        px(img, ox+3, oy+y, 'dark_gray')
        px(img, ox+8, oy+y, 'dark_gray')
        px(img, ox+14, oy+y, 'dark_gray')
    # Highlight some stones
    for pos in [(2,2),(8,6),(6,10),(12,14)]:
        px(img, ox+pos[0], oy+pos[1], 'light_gray')


def draw_tile_stone_floor(img, ox, oy):
    fill_rect(img, ox, oy, 16, 16, 'dark_gray')
    for x in range(16):
        px(img, ox+x, oy+0, 'black')
        px(img, ox+x, oy+8, 'black')
    for y in range(1, 8):
        px(img, ox+5, oy+y, 'black')
        px(img, ox+12, oy+y, 'black')
    for y in range(9, 16):
        px(img, ox+3, oy+y, 'black')
        px(img, ox+9, oy+y, 'black')
    for pos in [(2,3),(8,5),(1,11),(7,13),(13,10)]:
        px(img, ox+pos[0], oy+pos[1], 'gray')


def draw_tile_wood_floor(img, ox, oy):
    fill_rect(img, ox, oy, 16, 16, 'brown')
    # Wood grain lines
    for x in range(16):
        px(img, ox+x, oy+3, 'dark_brown')
        px(img, ox+x, oy+7, 'dark_brown')
        px(img, ox+x, oy+11, 'dark_brown')
        px(img, ox+x, oy+15, 'dark_brown')
    # Plank separators
    for y in range(4):
        px(img, ox+6, oy+y, 'dark_brown')
        px(img, ox+13, oy+y, 'dark_brown')
    for y in range(4, 8):
        px(img, ox+3, oy+y, 'dark_brown')
        px(img, ox+10, oy+y, 'dark_brown')
    for y in range(8, 12):
        px(img, ox+7, oy+y, 'dark_brown')
        px(img, ox+14, oy+y, 'dark_brown')
    for y in range(12, 16):
        px(img, ox+4, oy+y, 'dark_brown')
        px(img, ox+11, oy+y, 'dark_brown')
    # Highlights
    for pos in [(2,1),(9,5),(5,9),(12,13)]:
        px(img, ox+pos[0], oy+pos[1], 'tan')


def draw_tile_mud(img, ox, oy):
    fill_rect(img, ox, oy, 16, 16, 'dark_brown')
    for pos in [(2,3),(7,1),(12,8),(4,11),(9,5),(14,13),(1,7),(6,14),(11,2)]:
        px(img, ox+pos[0], oy+pos[1], 'brown')
    # Wet shine
    for pos in [(3,6),(8,10),(13,3)]:
        px(img, ox+pos[0], oy+pos[1], c('light_gray', 60))


# Row 2 — Water/Nature
def draw_tile_water(img, ox, oy):
    fill_rect(img, ox, oy, 16, 16, 'dark_blue')
    # Wave highlights
    for pos in [(2,3),(6,7),(10,2),(14,9),(4,12),(8,5),(12,14),(1,8)]:
        px(img, ox+pos[0], oy+pos[1], 'blue')
    for pos in [(3,5),(9,11),(5,1)]:
        px(img, ox+pos[0], oy+pos[1], c('light_blue', 120))


def draw_tile_water_shallow(img, ox, oy):
    fill_rect(img, ox, oy, 16, 16, 'blue')
    for pos in [(2,4),(7,8),(12,3),(5,12),(10,6),(14,14)]:
        px(img, ox+pos[0], oy+pos[1], 'light_blue')
    for pos in [(4,2),(9,10),(1,7)]:
        px(img, ox+pos[0], oy+pos[1], 'dark_blue')


def draw_tile_farmland_healthy(img, ox, oy):
    fill_rect(img, ox, oy, 16, 16, 'dark_brown')
    # Furrow lines
    for x in range(16):
        px(img, ox+x, oy+2, 'brown')
        px(img, ox+x, oy+6, 'brown')
        px(img, ox+x, oy+10, 'brown')
        px(img, ox+x, oy+14, 'brown')
    # Green sprouts
    for pos in [(3,1),(7,5),(11,9),(2,13),(9,3),(14,7),(5,11)]:
        px(img, ox+pos[0], oy+pos[1], 'green')
        px(img, ox+pos[0], oy+pos[1]-1, 'moss_green')


def draw_tile_farmland_dead(img, ox, oy):
    fill_rect(img, ox, oy, 16, 16, 'dark_brown')
    for x in range(16):
        px(img, ox+x, oy+2, 'brown')
        px(img, ox+x, oy+6, 'brown')
        px(img, ox+x, oy+10, 'brown')
        px(img, ox+x, oy+14, 'brown')
    # Cracks
    for pos in [(4,4),(8,8),(12,12),(2,9),(10,3)]:
        px(img, ox+pos[0], oy+pos[1], 'gray')
        px(img, ox+pos[0]+1, oy+pos[1]+1, 'gray')


def draw_tile_flowers_dead(img, ox, oy):
    fill_rect(img, ox, oy, 16, 16, 'dark_brown')
    # Wilted stems
    for pos in [(4,8),(8,7),(12,9)]:
        px(img, ox+pos[0], oy+pos[1], 'dark_green')
        px(img, ox+pos[0], oy+pos[1]+1, 'dark_green')
        px(img, ox+pos[0], oy+pos[1]+2, 'dark_green')
        # Drooping flower head
        px(img, ox+pos[0]-1, oy+pos[1], 'gray')
        px(img, ox+pos[0]+1, oy+pos[1]-1, 'ash_gray')


def draw_tile_mushrooms(img, ox, oy):
    fill_rect(img, ox, oy, 16, 16, 'dark_brown')
    # Mushroom 1
    fill_rect(img, ox+2, oy+10, 4, 2, 'poison_purple')
    px(img, ox+3, oy+12, 'tan')
    px(img, ox+4, oy+12, 'tan')
    px(img, ox+3, oy+13, 'tan')
    px(img, ox+3, oy+9, 'white')  # spots
    # Mushroom 2
    fill_rect(img, ox+9, oy+8, 5, 2, 'red')
    px(img, ox+10, oy+10, 'tan')
    px(img, ox+11, oy+10, 'tan')
    px(img, ox+11, oy+11, 'tan')
    px(img, ox+10, oy+8, 'white')
    px(img, ox+12, oy+8, 'white')
    # Small one
    fill_rect(img, ox+6, oy+12, 2, 1, 'poison_purple')
    px(img, ox+6, oy+13, 'tan')


def draw_tile_fallen_leaves(img, ox, oy):
    fill_rect(img, ox, oy, 16, 16, 'dark_brown')
    leaf_positions = [(2,3),(5,8),(9,2),(12,11),(4,13),(8,6),(14,4),(1,10),(7,14),(11,7)]
    for i, pos in enumerate(leaf_positions):
        col = 'brown' if i % 3 == 0 else ('dark_red' if i % 3 == 1 else 'orange')
        px(img, ox+pos[0], oy+pos[1], col)
        px(img, ox+pos[0]+1, oy+pos[1], col)


def draw_tile_roots_creeping(img, ox, oy):
    fill_rect(img, ox, oy, 16, 16, 'dark_brown')
    # Twisted roots
    root_pixels = [
        (0,8),(1,8),(2,7),(3,7),(4,6),(5,6),(6,7),(7,8),(8,8),(9,9),
        (10,9),(11,10),(12,10),(13,11),(14,12),(15,12),
        (3,12),(4,11),(5,11),(6,12),(7,13),(8,13),(9,12),
        (0,4),(1,4),(2,3),(3,3),(4,4),(5,5),(6,5),
    ]
    for rx, ry in root_pixels:
        px(img, ox+rx, oy+ry, 'dark_green')
    # Root highlights
    for pos in [(2,7),(7,8),(12,10),(4,11)]:
        px(img, ox+pos[0], oy+pos[1], 'brown')


# Row 3 — Walls
def draw_tile_wall_stone(img, ox, oy):
    fill_rect(img, ox, oy, 16, 16, 'gray')
    # Mortar
    for x in range(16):
        px(img, ox+x, oy+0, 'dark_gray')
        px(img, ox+x, oy+5, 'dark_gray')
        px(img, ox+x, oy+10, 'dark_gray')
        px(img, ox+x, oy+15, 'dark_gray')
    for y in range(1, 5):
        px(img, ox+8, oy+y, 'dark_gray')
    for y in range(6, 10):
        px(img, ox+4, oy+y, 'dark_gray')
        px(img, ox+12, oy+y, 'dark_gray')
    for y in range(11, 15):
        px(img, ox+6, oy+y, 'dark_gray')
        px(img, ox+14, oy+y, 'dark_gray')
    # Highlights
    for pos in [(3,2),(10,7),(2,12),(9,3)]:
        px(img, ox+pos[0], oy+pos[1], 'light_gray')


def draw_tile_wall_stone_moss(img, ox, oy):
    draw_tile_wall_stone(img, ox, oy)
    # Add moss
    for pos in [(1,13),(2,12),(3,14),(4,13),(5,15),(8,14),(9,13),(10,15),(14,12),(15,13)]:
        px(img, ox+pos[0], oy+pos[1], 'moss_green')
    for pos in [(2,14),(9,14),(14,13)]:
        px(img, ox+pos[0], oy+pos[1], 'forest_green')


def draw_tile_wall_wood(img, ox, oy):
    fill_rect(img, ox, oy, 16, 16, 'brown')
    # Vertical planks
    for y in range(16):
        px(img, ox+0, oy+y, 'dark_brown')
        px(img, ox+5, oy+y, 'dark_brown')
        px(img, ox+10, oy+y, 'dark_brown')
        px(img, ox+15, oy+y, 'dark_brown')
    # Grain
    for pos in [(2,3),(7,8),(12,5),(3,11),(8,2),(13,13)]:
        px(img, ox+pos[0], oy+pos[1], 'tan')


def draw_tile_wall_wood_damaged(img, ox, oy):
    draw_tile_wall_wood(img, ox, oy)
    # Damage: dark holes and cracks
    fill_rect(img, ox+6, oy+3, 3, 4, 'black')
    px(img, ox+7, oy+2, 'dark_brown')
    px(img, ox+9, oy+5, 'dark_brown')
    # Cracks
    px(img, ox+3, oy+8, 'black')
    px(img, ox+4, oy+9, 'black')
    px(img, ox+12, oy+11, 'black')
    px(img, ox+13, oy+12, 'black')


def draw_tile_wall_chapel(img, ox, oy):
    fill_rect(img, ox, oy, 16, 16, 'ash_gray')
    # Clean white-gray stone
    for x in range(16):
        px(img, ox+x, oy+0, 'gray')
        px(img, ox+x, oy+8, 'gray')
    for y in range(1, 8):
        px(img, ox+7, oy+y, 'gray')
    for y in range(9, 16):
        px(img, ox+4, oy+y, 'gray')
        px(img, ox+12, oy+y, 'gray')
    # Subtle cross pattern
    px(img, ox+7, oy+3, 'holy_white')
    px(img, ox+7, oy+4, 'holy_white')
    px(img, ox+7, oy+5, 'holy_white')
    px(img, ox+6, oy+4, 'holy_white')
    px(img, ox+8, oy+4, 'holy_white')


def draw_tile_wall_manor(img, ox, oy):
    fill_rect(img, ox, oy, 16, 16, 'dark_gray')
    for x in range(16):
        px(img, ox+x, oy+0, 'black')
        px(img, ox+x, oy+5, 'black')
        px(img, ox+x, oy+10, 'black')
        px(img, ox+x, oy+15, 'black')
    for y in range(1, 5):
        px(img, ox+8, oy+y, 'black')
    for y in range(6, 10):
        px(img, ox+3, oy+y, 'black')
        px(img, ox+13, oy+y, 'black')
    for y in range(11, 15):
        px(img, ox+7, oy+y, 'black')
    px(img, ox+4, oy+2, 'gray')
    px(img, ox+11, oy+7, 'gray')


def draw_tile_fence_wood(img, ox, oy):
    fill_rect(img, ox, oy, 16, 16, T)
    # Posts
    fill_rect(img, ox+1, oy+2, 2, 12, 'brown')
    fill_rect(img, ox+13, oy+2, 2, 12, 'brown')
    # Rails
    fill_rect(img, ox+1, oy+5, 14, 2, 'brown')
    fill_rect(img, ox+1, oy+10, 14, 2, 'brown')
    # Post tops
    fill_rect(img, ox+0, oy+1, 4, 1, 'tan')
    fill_rect(img, ox+12, oy+1, 4, 1, 'tan')
    # Highlights
    px(img, ox+2, oy+3, 'tan')
    px(img, ox+14, oy+3, 'tan')


def draw_tile_fence_broken(img, ox, oy):
    fill_rect(img, ox, oy, 16, 16, T)
    # Left post intact
    fill_rect(img, ox+1, oy+2, 2, 12, 'brown')
    fill_rect(img, ox+0, oy+1, 4, 1, 'tan')
    # Right post broken (shorter)
    fill_rect(img, ox+13, oy+6, 2, 8, 'brown')
    # Left rail intact
    fill_rect(img, ox+1, oy+5, 8, 2, 'brown')
    fill_rect(img, ox+1, oy+10, 6, 2, 'brown')
    # Broken rail pieces
    px(img, ox+9, oy+6, 'dark_brown')
    px(img, ox+10, oy+7, 'dark_brown')
    px(img, ox+8, oy+11, 'dark_brown')


# Row 4 — Special
def draw_tile_door_wood(img, ox, oy):
    fill_rect(img, ox, oy, 16, 16, T)
    fill_rect(img, ox+2, oy+0, 12, 16, 'brown')
    # Door frame
    fill_rect(img, ox+2, oy+0, 1, 16, 'dark_brown')
    fill_rect(img, ox+13, oy+0, 1, 16, 'dark_brown')
    fill_rect(img, ox+2, oy+0, 12, 1, 'dark_brown')
    # Planks
    for y in range(16):
        px(img, ox+6, oy+y, 'dark_brown')
        px(img, ox+10, oy+y, 'dark_brown')
    # Handle
    px(img, ox+11, oy+8, 'gold')
    px(img, ox+11, oy+9, 'gold')
    # Hinges
    fill_rect(img, ox+3, oy+3, 2, 1, 'dark_gray')
    fill_rect(img, ox+3, oy+12, 2, 1, 'dark_gray')


def draw_tile_door_wood_locked(img, ox, oy):
    draw_tile_door_wood(img, ox, oy)
    # Darken
    for y in range(1, 15):
        for x in range(3, 13):
            cur = img.getpixel((ox+x, oy+y))
            if cur[3] > 0:
                px(img, ox+x, oy+y, (max(0,cur[0]-30), max(0,cur[1]-30), max(0,cur[2]-30), cur[3]))
    # Keyhole
    px(img, ox+11, oy+7, 'black')
    px(img, ox+11, oy+8, 'black')
    px(img, ox+11, oy+9, 'dark_gray')
    # Lock plate
    fill_rect(img, ox+10, oy+6, 3, 5, 'dark_gray')
    px(img, ox+11, oy+8, 'black')  # keyhole


def draw_tile_door_manor(img, ox, oy):
    fill_rect(img, ox, oy, 16, 16, T)
    fill_rect(img, ox+1, oy+0, 14, 16, 'dark_gray')
    # Ornate frame
    fill_rect(img, ox+1, oy+0, 1, 16, 'gold')
    fill_rect(img, ox+14, oy+0, 1, 16, 'gold')
    fill_rect(img, ox+1, oy+0, 14, 1, 'gold')
    # Panel insets
    fill_rect(img, ox+3, oy+2, 4, 5, 'dark_brown')
    fill_rect(img, ox+9, oy+2, 4, 5, 'dark_brown')
    fill_rect(img, ox+3, oy+9, 4, 5, 'dark_brown')
    fill_rect(img, ox+9, oy+9, 4, 5, 'dark_brown')
    # Handles
    px(img, ox+7, oy+8, 'gold')
    px(img, ox+8, oy+8, 'gold')
    px(img, ox+7, oy+9, 'gold')
    px(img, ox+8, oy+9, 'gold')


def draw_tile_stairs_down(img, ox, oy):
    fill_rect(img, ox, oy, 16, 16, 'dark_gray')
    # Steps descending
    for i in range(5):
        y = oy + i * 3
        shade = max(0, 55 - i * 12)
        col = (shade, shade, shade, 255)
        fill_rect(img, ox + i, y, 16 - i * 2, 3, col)
    # Darkness at bottom
    fill_rect(img, ox+4, oy+13, 8, 3, 'black')


def draw_tile_well(img, ox, oy):
    fill_rect(img, ox, oy, 16, 16, T)
    # Circular stone wall (top-down)
    for y in range(2, 14):
        for x in range(2, 14):
            dx, dy = x - 7.5, y - 7.5
            dist = (dx*dx + dy*dy) ** 0.5
            if 4 < dist < 6.5:
                px(img, ox+x, oy+y, 'gray')
            elif dist <= 4:
                px(img, ox+x, oy+y, 'dark_blue')  # water
    # Water highlight
    px(img, ox+7, oy+6, 'blue')
    px(img, ox+8, oy+7, 'blue')
    # Stone highlights
    px(img, ox+5, oy+3, 'light_gray')
    px(img, ox+10, oy+3, 'light_gray')


def draw_tile_market_stall(img, ox, oy):
    fill_rect(img, ox, oy, 16, 16, T)
    # Counter
    fill_rect(img, ox+1, oy+8, 14, 3, 'brown')
    fill_rect(img, ox+1, oy+8, 14, 1, 'tan')
    # Posts
    fill_rect(img, ox+1, oy+2, 2, 9, 'dark_brown')
    fill_rect(img, ox+13, oy+2, 2, 9, 'dark_brown')
    # Awning
    fill_rect(img, ox+0, oy+1, 16, 2, 'dark_red')
    for x in range(0, 16, 4):
        px(img, ox+x, oy+2, 'red')
        px(img, ox+x+1, oy+2, 'red')
    # Goods on counter
    px(img, ox+4, oy+7, 'green')
    px(img, ox+5, oy+7, 'yellow')
    px(img, ox+8, oy+7, 'orange')
    px(img, ox+10, oy+7, 'red')


def draw_tile_barrel(img, ox, oy):
    fill_rect(img, ox, oy, 16, 16, T)
    # Barrel body (top-down oval)
    for y in range(3, 13):
        for x in range(3, 13):
            dx, dy = x - 7.5, (y - 7.5) * 1.2
            if (dx*dx + dy*dy) < 22:
                px(img, ox+x, oy+y, 'brown')
    # Metal bands
    for x in range(4, 12):
        px(img, ox+x, oy+4, 'dark_gray')
        px(img, ox+x, oy+11, 'dark_gray')
    # Lid / top circle
    for y in range(5, 11):
        for x in range(4, 12):
            dx, dy = x - 7.5, (y - 7.5) * 1.3
            if (dx*dx + dy*dy) < 12:
                px(img, ox+x, oy+y, 'tan')
    # Highlight
    px(img, ox+7, oy+6, c('white', 80))


def draw_tile_crate(img, ox, oy):
    fill_rect(img, ox, oy, 16, 16, T)
    fill_rect(img, ox+2, oy+2, 12, 12, 'brown')
    # Edges
    fill_rect(img, ox+2, oy+2, 12, 1, 'dark_brown')
    fill_rect(img, ox+2, oy+13, 12, 1, 'dark_brown')
    fill_rect(img, ox+2, oy+2, 1, 12, 'dark_brown')
    fill_rect(img, ox+13, oy+2, 1, 12, 'dark_brown')
    # Cross planks
    for i in range(12):
        px(img, ox+2+i, oy+2+i, 'dark_brown')
        px(img, ox+13-i, oy+2+i, 'dark_brown')
    # Nail
    px(img, ox+7, oy+7, 'gray')


# Row 5 — Nature
def draw_tile_tree_trunk(img, ox, oy):
    fill_rect(img, ox, oy, 16, 16, T)
    # Top-down trunk (circle)
    for y in range(4, 12):
        for x in range(4, 12):
            dx, dy = x - 7.5, y - 7.5
            if (dx*dx + dy*dy) < 14:
                px(img, ox+x, oy+y, 'dark_brown')
    # Bark rings
    for y in range(5, 11):
        for x in range(5, 11):
            dx, dy = x - 7.5, y - 7.5
            if 4 < (dx*dx + dy*dy) < 9:
                px(img, ox+x, oy+y, 'brown')
    # Center
    px(img, ox+7, oy+7, 'tan')
    px(img, ox+8, oy+7, 'tan')
    px(img, ox+7, oy+8, 'tan')
    # Roots extending
    px(img, ox+3, oy+7, 'dark_brown')
    px(img, ox+2, oy+7, 'dark_brown')
    px(img, ox+12, oy+8, 'dark_brown')
    px(img, ox+7, oy+12, 'dark_brown')
    px(img, ox+7, oy+3, 'dark_brown')


def draw_tile_tree_canopy(img, ox, oy):
    fill_rect(img, ox, oy, 16, 16, T)
    for y in range(1, 15):
        for x in range(1, 15):
            dx, dy = x - 7.5, y - 7.5
            if (dx*dx + dy*dy) < 42:
                px(img, ox+x, oy+y, 'forest_green')
    # Leaf clusters (lighter)
    for pos in [(4,4),(9,3),(6,8),(11,6),(3,10),(8,12),(12,10)]:
        px(img, ox+pos[0], oy+pos[1], 'moss_green')
        px(img, ox+pos[0]+1, oy+pos[1], 'moss_green')
        px(img, ox+pos[0], oy+pos[1]+1, 'moss_green')
    # Dark depth
    for pos in [(5,6),(10,8),(7,11),(3,5)]:
        px(img, ox+pos[0], oy+pos[1], 'dark_green')


def draw_tile_bush(img, ox, oy):
    fill_rect(img, ox, oy, 16, 16, T)
    for y in range(5, 14):
        for x in range(3, 13):
            dx, dy = x - 7.5, y - 9
            if (dx*dx + dy*dy) < 22:
                px(img, ox+x, oy+y, 'moss_green')
    for pos in [(5,7),(9,8),(7,11)]:
        px(img, ox+pos[0], oy+pos[1], 'green')
    for pos in [(6,9),(10,7)]:
        px(img, ox+pos[0], oy+pos[1], 'forest_green')


def draw_tile_bush_dead(img, ox, oy):
    fill_rect(img, ox, oy, 16, 16, T)
    for y in range(5, 14):
        for x in range(3, 13):
            dx, dy = x - 7.5, y - 9
            if (dx*dx + dy*dy) < 22:
                px(img, ox+x, oy+y, 'dark_brown')
    for pos in [(5,7),(9,8),(7,11)]:
        px(img, ox+pos[0], oy+pos[1], 'brown')
    # Bare twigs poking out
    px(img, ox+4, oy+4, 'dark_brown')
    px(img, ox+11, oy+5, 'dark_brown')
    px(img, ox+3, oy+6, 'dark_brown')


def draw_tile_rock_small(img, ox, oy):
    fill_rect(img, ox, oy, 16, 16, T)
    for y in range(8, 14):
        for x in range(5, 12):
            dx, dy = x - 8, y - 11
            if (dx*dx*0.8 + dy*dy) < 10:
                px(img, ox+x, oy+y, 'gray')
    px(img, ox+7, oy+9, 'light_gray')
    px(img, ox+8, oy+9, 'light_gray')
    px(img, ox+9, oy+12, 'dark_gray')


def draw_tile_rock_large(img, ox, oy):
    fill_rect(img, ox, oy, 16, 16, T)
    for y in range(4, 14):
        for x in range(2, 14):
            dx, dy = x - 7.5, y - 9
            if (dx*dx*0.6 + dy*dy) < 22:
                px(img, ox+x, oy+y, 'gray')
    # Cracks and highlights
    for pos in [(5,6),(8,5),(10,7)]:
        px(img, ox+pos[0], oy+pos[1], 'light_gray')
    for pos in [(7,10),(4,11),(10,12)]:
        px(img, ox+pos[0], oy+pos[1], 'dark_gray')
    px(img, ox+6, oy+8, 'dark_gray')
    px(img, ox+7, oy+9, 'dark_gray')


def draw_tile_grave_marker(img, ox, oy):
    fill_rect(img, ox, oy, 16, 16, T)
    # Ground
    fill_rect(img, ox+0, oy+12, 16, 4, 'dark_brown')
    # Stone marker
    fill_rect(img, ox+5, oy+3, 6, 10, 'gray')
    fill_rect(img, ox+6, oy+2, 4, 1, 'gray')
    # Cross on stone
    px(img, ox+7, oy+4, 'light_gray')
    px(img, ox+8, oy+4, 'light_gray')
    px(img, ox+7, oy+5, 'light_gray')
    px(img, ox+8, oy+5, 'light_gray')
    px(img, ox+7, oy+6, 'light_gray')
    px(img, ox+6, oy+5, 'light_gray')
    px(img, ox+9, oy+5, 'light_gray')
    # Moss at base
    px(img, ox+5, oy+11, 'moss_green')
    px(img, ox+6, oy+12, 'moss_green')


def draw_tile_altar_stone(img, ox, oy):
    fill_rect(img, ox, oy, 16, 16, T)
    # Stone slab
    fill_rect(img, ox+2, oy+6, 12, 8, 'dark_gray')
    fill_rect(img, ox+3, oy+5, 10, 1, 'gray')
    fill_rect(img, ox+2, oy+6, 12, 1, 'gray')
    # Top surface
    fill_rect(img, ox+3, oy+5, 10, 2, 'light_gray')
    # Blood stains
    px(img, ox+6, oy+5, 'blood')
    px(img, ox+7, oy+5, 'blood')
    px(img, ox+8, oy+6, 'blood')
    px(img, ox+5, oy+6, 'blood')
    # Carved runes
    px(img, ox+4, oy+8, 'dark_purple')
    px(img, ox+6, oy+9, 'dark_purple')
    px(img, ox+9, oy+8, 'dark_purple')
    px(img, ox+11, oy+9, 'dark_purple')


# Row 6 — Structures
def draw_tile_roof_thatch(img, ox, oy):
    fill_rect(img, ox, oy, 16, 16, 'brown')
    # Thatch lines
    for y in range(0, 16, 3):
        for x in range(16):
            px(img, ox+x, oy+y, 'dark_brown')
    # Straw highlights
    for pos in [(3,1),(8,4),(12,7),(5,10),(10,13),(2,5),(14,2)]:
        px(img, ox+pos[0], oy+pos[1], 'tan')


def draw_tile_roof_tile(img, ox, oy):
    fill_rect(img, ox, oy, 16, 16, 'dark_red')
    # Tile rows
    for y in range(0, 16, 4):
        for x in range(16):
            px(img, ox+x, oy+y, 'dark_brown')
    # Offset tiles
    for y in range(0, 16, 8):
        for x in range(0, 16, 8):
            px(img, ox+x+4, oy+y+2, 'dark_brown')
    for pos in [(2,2),(6,6),(10,10),(14,2),(4,14)]:
        px(img, ox+pos[0], oy+pos[1], 'red')


def draw_tile_chimney(img, ox, oy):
    fill_rect(img, ox, oy, 16, 16, T)
    # Brick chimney top-down
    fill_rect(img, ox+4, oy+4, 8, 8, 'dark_gray')
    fill_rect(img, ox+5, oy+5, 6, 6, 'gray')
    # Opening
    fill_rect(img, ox+6, oy+6, 4, 4, 'black')
    # Smoke wisps
    px(img, ox+7, oy+3, c('ash_gray', 120))
    px(img, ox+8, oy+2, c('ash_gray', 80))
    px(img, ox+9, oy+1, c('ash_gray', 40))


def draw_tile_window_lit(img, ox, oy):
    fill_rect(img, ox, oy, 16, 16, T)
    # Window frame
    fill_rect(img, ox+3, oy+3, 10, 10, 'dark_brown')
    # Glass (lit yellow)
    fill_rect(img, ox+4, oy+4, 8, 8, 'yellow')
    # Cross pane
    fill_rect(img, ox+7, oy+4, 2, 8, 'dark_brown')
    fill_rect(img, ox+4, oy+7, 8, 2, 'dark_brown')
    # Warm glow
    px(img, ox+5, oy+5, c('yellow', 200))
    px(img, ox+10, oy+5, c('yellow', 200))
    px(img, ox+5, oy+10, c('orange', 180))
    px(img, ox+10, oy+10, c('orange', 180))
    # Glow around window
    for pos in [(2,5),(2,8),(13,5),(13,8),(5,2),(8,2),(5,13),(8,13)]:
        px(img, ox+pos[0], oy+pos[1], c('yellow', 40))


def draw_tile_window_dark(img, ox, oy):
    fill_rect(img, ox, oy, 16, 16, T)
    fill_rect(img, ox+3, oy+3, 10, 10, 'dark_brown')
    fill_rect(img, ox+4, oy+4, 8, 8, 'dark_blue')
    fill_rect(img, ox+7, oy+4, 2, 8, 'dark_brown')
    fill_rect(img, ox+4, oy+7, 8, 2, 'dark_brown')
    # Dark reflection
    px(img, ox+5, oy+5, 'blue')


def draw_tile_sign_hanging(img, ox, oy):
    fill_rect(img, ox, oy, 16, 16, T)
    # Mounting bar
    fill_rect(img, ox+2, oy+2, 12, 1, 'dark_gray')
    # Chains
    px(img, ox+5, oy+3, 'gray')
    px(img, ox+5, oy+4, 'gray')
    px(img, ox+10, oy+3, 'gray')
    px(img, ox+10, oy+4, 'gray')
    # Sign board
    fill_rect(img, ox+3, oy+5, 10, 7, 'brown')
    fill_rect(img, ox+3, oy+5, 10, 1, 'tan')
    # Text hint (squiggles)
    for x in range(5, 11):
        px(img, ox+x, oy+8, 'dark_brown')
    for x in range(6, 10):
        px(img, ox+x, oy+10, 'dark_brown')


def draw_tile_torch_wall(img, ox, oy):
    fill_rect(img, ox, oy, 16, 16, T)
    # Bracket
    fill_rect(img, ox+6, oy+8, 4, 6, 'dark_gray')
    fill_rect(img, ox+7, oy+7, 2, 1, 'gray')
    # Torch head
    fill_rect(img, ox+6, oy+5, 4, 3, 'dark_brown')
    # Flame
    px(img, ox+7, oy+2, 'yellow')
    px(img, ox+8, oy+2, 'yellow')
    px(img, ox+7, oy+3, 'orange')
    px(img, ox+8, oy+3, 'orange')
    px(img, ox+7, oy+4, 'red')
    px(img, ox+8, oy+4, 'red')
    px(img, ox+7, oy+1, c('yellow', 140))
    px(img, ox+8, oy+1, c('yellow', 100))
    # Glow
    for pos in [(5,3),(10,3),(6,1),(9,1),(6,4),(9,4),(5,5),(10,5)]:
        px(img, ox+pos[0], oy+pos[1], c('orange', 50))


def draw_tile_blood_splatter(img, ox, oy):
    fill_rect(img, ox, oy, 16, 16, T)
    splat = [
        (6,5),(7,5),(8,5),(5,6),(6,6),(7,6),(8,6),(9,6),
        (4,7),(5,7),(6,7),(7,7),(8,7),(9,7),(10,7),
        (5,8),(6,8),(7,8),(8,8),(9,8),
        (6,9),(7,9),(8,9),
        (7,10),
        # Splatter drops
        (3,5),(11,6),(4,10),(10,9),(2,8),(12,8),
    ]
    for sx, sy in splat:
        px(img, ox+sx, oy+sy, 'blood')
    # Darker center
    for pos in [(7,7),(6,7),(8,7),(7,6)]:
        px(img, ox+pos[0], oy+pos[1], 'dark_red')


TILE_DRAW_FUNCS = [
    # Row 1 — Ground
    draw_tile_grass, draw_tile_grass_dead, draw_tile_dirt, draw_tile_dirt_path,
    draw_tile_cobblestone, draw_tile_stone_floor, draw_tile_wood_floor, draw_tile_mud,
    # Row 2 — Water/Nature
    draw_tile_water, draw_tile_water_shallow, draw_tile_farmland_healthy, draw_tile_farmland_dead,
    draw_tile_flowers_dead, draw_tile_mushrooms, draw_tile_fallen_leaves, draw_tile_roots_creeping,
    # Row 3 — Walls
    draw_tile_wall_stone, draw_tile_wall_stone_moss, draw_tile_wall_wood, draw_tile_wall_wood_damaged,
    draw_tile_wall_chapel, draw_tile_wall_manor, draw_tile_fence_wood, draw_tile_fence_broken,
    # Row 4 — Special
    draw_tile_door_wood, draw_tile_door_wood_locked, draw_tile_door_manor, draw_tile_stairs_down,
    draw_tile_well, draw_tile_market_stall, draw_tile_barrel, draw_tile_crate,
    # Row 5 — Nature
    draw_tile_tree_trunk, draw_tile_tree_canopy, draw_tile_bush, draw_tile_bush_dead,
    draw_tile_rock_small, draw_tile_rock_large, draw_tile_grave_marker, draw_tile_altar_stone,
    # Row 6 — Structures
    draw_tile_roof_thatch, draw_tile_roof_tile, draw_tile_chimney, draw_tile_window_lit,
    draw_tile_window_dark, draw_tile_sign_hanging, draw_tile_torch_wall, draw_tile_blood_splatter,
]


def generate_tileset():
    print("Generating tileset...")
    cols = 16
    rows = (len(TILE_DRAW_FUNCS) + cols - 1) // cols
    img = make_img(cols * 16, rows * 16)
    for i, fn in enumerate(TILE_DRAW_FUNCS):
        col = i % cols
        row = i // cols
        # For ground tiles, fill background first (non-transparent)
        fn(img, col * 16, row * 16)
    save(img, os.path.join(ROOT, 'assets/sprites/tilesets/terrain_tileset.png'))


# ===========================================================================
# ITEM ICONS (16x16)
# ===========================================================================

def draw_item_firebomb(img):
    fill_rect(img, 0, 0, 16, 16, T)
    # Sphere
    for y in range(6, 14):
        for x in range(4, 12):
            dx, dy = x - 7.5, y - 9.5
            if (dx*dx + dy*dy) < 14:
                px(img, x, y, 'red')
    # Highlights
    px(img, 6, 7, 'orange')
    px(img, 7, 7, 'orange')
    # Dark side
    px(img, 9, 11, 'dark_red')
    px(img, 10, 10, 'dark_red')
    # Fuse
    px(img, 7, 5, 'dark_brown')
    px(img, 8, 4, 'dark_brown')
    px(img, 9, 3, 'dark_brown')
    # Spark
    px(img, 10, 2, 'yellow')
    px(img, 9, 2, 'orange')
    px(img, 10, 1, c('yellow', 160))


def draw_item_gold_pouch(img):
    fill_rect(img, 0, 0, 16, 16, T)
    # Pouch body
    for y in range(5, 14):
        for x in range(3, 13):
            dx, dy = x - 7.5, y - 9
            if (dx*dx*0.7 + dy*dy) < 18:
                px(img, x, y, 'brown')
    # Drawstring
    px(img, 6, 4, 'tan')
    px(img, 7, 3, 'tan')
    px(img, 8, 3, 'tan')
    px(img, 9, 4, 'tan')
    # String knot
    px(img, 7, 4, 'dark_brown')
    px(img, 8, 4, 'dark_brown')
    # Coins peeking out
    px(img, 6, 4, 'gold')
    px(img, 7, 3, 'gold')
    px(img, 8, 3, 'gold')
    px(img, 9, 4, 'gold')
    # Coin on side
    px(img, 3, 10, 'gold')
    px(img, 4, 10, 'gold')
    px(img, 3, 11, 'yellow')
    # Pouch shading
    px(img, 5, 7, 'tan')
    px(img, 6, 8, 'tan')


def draw_item_herb_poultice(img):
    fill_rect(img, 0, 0, 16, 16, T)
    # Cloth wrap
    fill_rect(img, 4, 6, 8, 8, 'tan')
    fill_rect(img, 5, 7, 6, 6, 'white')
    # Leaf poking out
    px(img, 6, 4, 'green')
    px(img, 7, 3, 'green')
    px(img, 7, 4, 'moss_green')
    px(img, 8, 3, 'green')
    px(img, 8, 5, 'moss_green')
    px(img, 9, 4, 'green')
    # Tied string
    px(img, 7, 6, 'dark_brown')
    px(img, 8, 6, 'dark_brown')
    px(img, 7, 5, 'dark_brown')
    # Second leaf
    px(img, 5, 5, 'forest_green')
    px(img, 4, 4, 'forest_green')
    px(img, 5, 4, 'green')


def draw_item_bread(img):
    fill_rect(img, 0, 0, 16, 16, T)
    # Loaf
    for y in range(6, 13):
        for x in range(3, 13):
            dx, dy = x - 7.5, y - 9
            if (dx*dx*0.5 + dy*dy) < 12:
                px(img, x, y, 'brown')
    # Top crust (lighter)
    for y in range(6, 9):
        for x in range(4, 12):
            dx, dy = x - 7.5, y - 7
            if (dx*dx*0.5 + dy*dy) < 6:
                px(img, x, y, 'tan')
    # Score marks
    px(img, 6, 7, 'dark_brown')
    px(img, 8, 7, 'dark_brown')
    px(img, 10, 7, 'dark_brown')
    # Bottom shadow
    for x in range(5, 11):
        px(img, x, 12, 'dark_brown')


def draw_item_iron_dagger(img):
    fill_rect(img, 0, 0, 16, 16, T)
    # Blade (diagonal)
    px(img, 11, 2, 'light_gray')
    px(img, 10, 3, 'light_gray')
    px(img, 9, 4, 'light_gray')
    px(img, 8, 5, 'light_gray')
    px(img, 7, 6, 'light_gray')
    px(img, 6, 7, 'gray')
    # Blade edge highlight
    px(img, 12, 2, 'white')
    px(img, 11, 3, 'white')
    px(img, 10, 4, 'white')
    # Guard
    px(img, 5, 8, 'dark_gray')
    px(img, 6, 8, 'dark_gray')
    px(img, 7, 8, 'dark_gray')
    px(img, 8, 8, 'dark_gray')
    # Handle
    px(img, 5, 9, 'dark_brown')
    px(img, 4, 10, 'dark_brown')
    px(img, 3, 11, 'dark_brown')
    px(img, 5, 10, 'brown')
    px(img, 4, 11, 'brown')
    # Pommel
    px(img, 2, 12, 'dark_gray')
    px(img, 3, 12, 'dark_gray')


def draw_item_leather_vest(img):
    fill_rect(img, 0, 0, 16, 16, T)
    # Vest body
    fill_rect(img, 3, 3, 10, 10, 'brown')
    # Arm holes
    fill_rect(img, 3, 3, 2, 4, T)
    fill_rect(img, 11, 3, 2, 4, T)
    # Collar
    px(img, 5, 2, 'dark_brown')
    px(img, 6, 2, 'dark_brown')
    px(img, 7, 1, 'dark_brown')
    px(img, 8, 1, 'dark_brown')
    px(img, 9, 2, 'dark_brown')
    px(img, 10, 2, 'dark_brown')
    # Center seam
    for y in range(3, 13):
        px(img, 7, y, 'dark_brown')
        px(img, 8, y, 'dark_brown')
    # Stitching
    for y in range(4, 12, 2):
        px(img, 7, y, 'tan')
    # Bottom
    fill_rect(img, 3, 12, 10, 1, 'dark_brown')
    # Shading
    px(img, 4, 6, 'tan')
    px(img, 5, 7, 'tan')


def draw_item_manor_key(img):
    fill_rect(img, 0, 0, 16, 16, T)
    # Key bow (ornate ring)
    for y in range(2, 8):
        for x in range(2, 8):
            dx, dy = x - 4.5, y - 4.5
            dist = (dx*dx + dy*dy) ** 0.5
            if 1.5 < dist < 3.5:
                px(img, x, y, 'dark_gray')
    # Ornate details on bow
    px(img, 4, 2, 'gray')
    px(img, 2, 4, 'gray')
    px(img, 6, 4, 'gray')
    px(img, 4, 6, 'gray')
    # Key shaft
    for x in range(6, 14):
        px(img, x, 5, 'dark_gray')
    px(img, 7, 5, 'gray')
    # Key teeth
    px(img, 12, 6, 'dark_gray')
    px(img, 12, 7, 'dark_gray')
    px(img, 13, 6, 'dark_gray')
    px(img, 11, 6, 'dark_gray')
    px(img, 11, 7, 'dark_gray')
    px(img, 13, 7, 'dark_gray')
    px(img, 13, 8, 'dark_gray')
    # Worn spots
    px(img, 9, 5, 'light_gray')


def draw_item_torn_cloth(img):
    fill_rect(img, 0, 0, 16, 16, T)
    # Ragged cloth
    cloth = [
        (4,3),(5,3),(6,3),(7,3),(8,3),(9,3),(10,3),
        (3,4),(4,4),(5,4),(6,4),(7,4),(8,4),(9,4),(10,4),(11,4),
        (3,5),(4,5),(5,5),(6,5),(7,5),(8,5),(9,5),(10,5),(11,5),
        (3,6),(4,6),(5,6),(6,6),(7,6),(8,6),(9,6),(10,6),
        (4,7),(5,7),(6,7),(7,7),(8,7),(9,7),(10,7),
        (4,8),(5,8),(6,8),(7,8),(8,8),(9,8),
        (5,9),(6,9),(7,9),(8,9),
        (5,10),(6,10),(7,10),
        (6,11),
    ]
    for cx, cy in cloth:
        px(img, cx, cy, 'tan')
    # Partial emblem (dark red symbol fragment)
    px(img, 6, 5, 'dark_red')
    px(img, 7, 5, 'dark_red')
    px(img, 8, 5, 'dark_red')
    px(img, 7, 4, 'dark_red')
    px(img, 7, 6, 'dark_red')
    px(img, 6, 6, 'dark_red')
    # Torn edges (darker)
    px(img, 4, 3, 'dark_brown')
    px(img, 10, 3, 'dark_brown')
    px(img, 3, 6, 'dark_brown')
    px(img, 6, 11, 'dark_brown')
    # Stain
    px(img, 5, 8, 'dark_brown')
    px(img, 8, 7, 'dark_brown')


def draw_item_nightcap_sample(img):
    fill_rect(img, 0, 0, 16, 16, T)
    # Mushroom cap
    for y in range(4, 9):
        for x in range(4, 12):
            dx, dy = x - 7.5, y - 6
            if (dx*dx*0.6 + dy*dy) < 8:
                px(img, x, y, 'poison_purple')
    # Cap top highlight
    px(img, 7, 4, 'dark_purple')
    px(img, 8, 4, 'dark_purple')
    # Spots
    px(img, 6, 5, c('white', 100))
    px(img, 9, 6, c('white', 100))
    # Stem
    px(img, 7, 9, 'tan')
    px(img, 8, 9, 'tan')
    px(img, 7, 10, 'tan')
    px(img, 8, 10, 'tan')
    px(img, 7, 11, 'tan')
    px(img, 8, 11, 'tan')
    # Root tendrils
    px(img, 6, 12, 'dark_brown')
    px(img, 7, 12, 'dark_brown')
    px(img, 8, 12, 'dark_brown')
    px(img, 9, 12, 'dark_brown')
    px(img, 5, 13, 'dark_brown')
    px(img, 10, 13, 'dark_brown')
    # Toxic aura
    px(img, 5, 4, c('poison_purple', 60))
    px(img, 11, 6, c('poison_purple', 60))


def draw_item_druid_talisman(img):
    fill_rect(img, 0, 0, 16, 16, T)
    # Cord
    px(img, 7, 1, 'dark_brown')
    px(img, 6, 2, 'dark_brown')
    px(img, 5, 3, 'dark_brown')
    px(img, 8, 1, 'dark_brown')
    px(img, 9, 2, 'dark_brown')
    px(img, 10, 3, 'dark_brown')
    # Wooden pendant (oval)
    for y in range(4, 13):
        for x in range(4, 12):
            dx, dy = x - 7.5, y - 8
            if (dx*dx + dy*dy*0.6) < 12:
                px(img, x, y, 'brown')
    # Carved border
    for y in range(5, 12):
        for x in range(5, 11):
            dx, dy = x - 7.5, y - 8
            if 6 < (dx*dx + dy*dy*0.6) < 12:
                px(img, x, y, 'dark_brown')
    # Glowing runes
    px(img, 7, 6, 'green')
    px(img, 8, 6, 'green')
    px(img, 6, 7, 'green')
    px(img, 9, 7, 'green')
    px(img, 6, 9, 'green')
    px(img, 9, 9, 'green')
    px(img, 7, 10, 'green')
    px(img, 8, 10, 'green')
    # Center glow
    px(img, 7, 8, c('green', 180))
    px(img, 8, 8, c('green', 180))
    # Faint glow
    px(img, 5, 6, c('green', 40))
    px(img, 10, 6, c('green', 40))
    px(img, 5, 10, c('green', 40))
    px(img, 10, 10, c('green', 40))


ITEM_DEFS = {
    'firebomb': draw_item_firebomb,
    'gold_pouch': draw_item_gold_pouch,
    'herb_poultice': draw_item_herb_poultice,
    'bread': draw_item_bread,
    'iron_dagger': draw_item_iron_dagger,
    'leather_vest': draw_item_leather_vest,
    'manor_key': draw_item_manor_key,
    'torn_cloth': draw_item_torn_cloth,
    'nightcap_sample': draw_item_nightcap_sample,
    'druid_talisman': draw_item_druid_talisman,
}


def generate_items():
    print("Generating item icons...")
    for name, fn in ITEM_DEFS.items():
        img = make_img(16, 16)
        fn(img)
        save(img, os.path.join(ROOT, f'assets/sprites/items/{name}.png'))


# ===========================================================================
# UI ELEMENTS
# ===========================================================================

def generate_ui():
    print("Generating UI elements...")

    # Health bar background
    img = make_img(100, 8)
    fill_rect(img, 0, 0, 100, 8, 'dark_gray')
    fill_rect(img, 0, 0, 100, 1, 'black')
    fill_rect(img, 0, 7, 100, 1, 'black')
    for y in range(8):
        px(img, 0, y, 'black')
        px(img, 99, y, 'black')
    save(img, os.path.join(ROOT, 'assets/ui/health_bar_bg.png'))

    # Health bar fill
    img = make_img(100, 8)
    fill_rect(img, 0, 0, 100, 8, 'red')
    fill_rect(img, 0, 1, 100, 2, 'dark_red')  # top shadow
    fill_rect(img, 0, 0, 100, 1, 'dark_red')
    # Bright line
    fill_rect(img, 0, 3, 100, 1, c('red'))
    # Subtle gradient
    for x in range(100):
        px(img, x, 6, 'dark_red')
        px(img, x, 7, 'dark_red')
    save(img, os.path.join(ROOT, 'assets/ui/health_bar_fill.png'))

    # Dialogue panel (9-slice, 48x48)
    img = make_img(48, 48)
    fill_rect(img, 0, 0, 48, 48, c('black', 220))
    # Gold border
    for x in range(48):
        px(img, x, 0, 'gold')
        px(img, x, 1, 'dark_brown')
        px(img, x, 46, 'dark_brown')
        px(img, x, 47, 'gold')
    for y in range(48):
        px(img, 0, y, 'gold')
        px(img, 1, y, 'dark_brown')
        px(img, 46, y, 'dark_brown')
        px(img, 47, y, 'gold')
    # Corners
    for dx in range(3):
        for dy in range(3):
            px(img, dx, dy, 'gold')
            px(img, 47-dx, dy, 'gold')
            px(img, dx, 47-dy, 'gold')
            px(img, 47-dx, 47-dy, 'gold')
    # Inner fill slightly lighter
    fill_rect(img, 3, 3, 42, 42, c('dark_gray', 200))
    save(img, os.path.join(ROOT, 'assets/ui/dialogue_panel.png'))

    # Button normal
    img = make_img(32, 12)
    fill_rect(img, 0, 0, 32, 12, 'dark_gray')
    fill_rect(img, 1, 1, 30, 10, 'gray')
    fill_rect(img, 1, 1, 30, 1, 'light_gray')  # top highlight
    fill_rect(img, 1, 10, 30, 1, 'dark_gray')  # bottom shadow
    for y in range(12):
        px(img, 0, y, 'dark_gray')
        px(img, 31, y, 'dark_gray')
    save(img, os.path.join(ROOT, 'assets/ui/button_normal.png'))

    # Button hover
    img = make_img(32, 12)
    fill_rect(img, 0, 0, 32, 12, 'gold')
    fill_rect(img, 1, 1, 30, 10, 'gray')
    fill_rect(img, 1, 1, 30, 1, 'white')
    fill_rect(img, 1, 10, 30, 1, 'dark_gray')
    for y in range(12):
        px(img, 0, y, 'gold')
        px(img, 31, y, 'gold')
    save(img, os.path.join(ROOT, 'assets/ui/button_hover.png'))

    # Interact prompt ("E" key)
    img = make_img(16, 16)
    fill_rect(img, 2, 2, 12, 12, 'dark_gray')
    fill_rect(img, 3, 3, 10, 10, 'gray')
    # Top bevel
    fill_rect(img, 3, 3, 10, 1, 'light_gray')
    # "E" letter
    for y in range(5, 12):
        px(img, 6, y, 'white')
    for x in range(6, 11):
        px(img, x, 5, 'white')
        px(img, x, 8, 'white')
        px(img, x, 11, 'white')
    save(img, os.path.join(ROOT, 'assets/ui/interact_prompt.png'))


# ===========================================================================
# EFFECTS
# ===========================================================================

def generate_effects():
    print("Generating effects...")

    # Slash effect — 4 frames, each 16x16
    img = make_img(64, 16)
    # Frame 0: start of arc
    slash0 = [(10,3),(9,4),(8,5),(7,6),(6,7)]
    for sx, sy in slash0:
        px(img, sx, sy, 'white')
        px(img, sx-1, sy, c('white', 120))
    # Frame 1: mid arc
    slash1 = [(11,2),(10,3),(9,4),(8,5),(7,6),(6,7),(5,8),(4,9)]
    for sx, sy in slash1:
        px(img, 16+sx, sy, 'white')
        px(img, 16+sx+1, sy, c('white', 80))
        px(img, 16+sx-1, sy+1, c('white', 60))
    # Frame 2: full arc
    slash2 = [(12,2),(11,3),(10,4),(9,5),(8,6),(7,7),(6,8),(5,9),(4,10),(3,11)]
    for sx, sy in slash2:
        px(img, 32+sx, sy, 'white')
        px(img, 32+sx+1, sy-1, c('white', 100))
        px(img, 32+sx-1, sy+1, c('white', 100))
    # Frame 3: fading
    slash3 = [(11,3),(9,5),(7,7),(5,9),(3,11)]
    for sx, sy in slash3:
        px(img, 48+sx, sy, c('white', 120))
        px(img, 48+sx+1, sy, c('white', 40))
    save(img, os.path.join(ROOT, 'assets/sprites/effects/slash_effect.png'))

    # Hit spark — 4 frames, each 16x16
    img = make_img(64, 16)
    # Frame 0: small burst
    for pos in [(7,7),(8,7),(7,8),(8,8)]:
        px(img, pos[0], pos[1], 'yellow')
    for pos in [(6,7),(9,7),(7,6),(8,9)]:
        px(img, pos[0], pos[1], 'orange')
    # Frame 1: expanding
    for pos in [(7,7),(8,7),(7,8),(8,8)]:
        px(img, 16+pos[0], pos[1], 'yellow')
    for pos in [(5,6),(10,6),(5,9),(10,9),(6,5),(9,5),(6,10),(9,10)]:
        px(img, 16+pos[0], pos[1], 'orange')
    for pos in [(4,7),(11,7),(7,4),(8,11)]:
        px(img, 16+pos[0], pos[1], 'red')
    # Frame 2: max spread
    for pos in [(7,7),(8,7),(7,8),(8,8)]:
        px(img, 32+pos[0], pos[1], 'white')
    for pos in [(4,4),(11,4),(4,11),(11,11),(3,7),(12,8),(7,3),(8,12)]:
        px(img, 32+pos[0], pos[1], 'orange')
    for pos in [(5,5),(10,5),(5,10),(10,10),(6,6),(9,6),(6,9),(9,9)]:
        px(img, 32+pos[0], pos[1], 'yellow')
    # Frame 3: fading sparks
    for pos in [(4,4),(11,11),(3,8),(12,7),(5,3),(10,12)]:
        px(img, 48+pos[0], pos[1], c('orange', 120))
    for pos in [(7,7),(8,8)]:
        px(img, 48+pos[0], pos[1], c('yellow', 80))
    save(img, os.path.join(ROOT, 'assets/sprites/effects/hit_spark.png'))

    # Dodge dust — 3 frames, each 16x16
    img = make_img(48, 16)
    # Frame 0: small puff
    dust0 = [(6,10),(7,10),(8,10),(9,10),(7,9),(8,9)]
    for dx, dy in dust0:
        px(img, dx, dy, c('tan', 180))
    for dx, dy in [(6,9),(9,9)]:
        px(img, dx, dy, c('tan', 100))
    # Frame 1: expanding
    dust1 = [(5,9),(6,9),(7,9),(8,9),(9,9),(10,9),(6,8),(7,8),(8,8),(9,8),(7,10),(8,10)]
    for dx, dy in dust1:
        px(img, 16+dx, dy, c('tan', 140))
    for dx, dy in [(4,9),(11,9),(5,8),(10,8),(7,7),(8,7)]:
        px(img, 16+dx, dy, c('tan', 80))
    # Frame 2: dissipating
    dust2 = [(4,8),(6,7),(9,7),(11,8),(5,10),(10,10)]
    for dx, dy in dust2:
        px(img, 32+dx, dy, c('tan', 60))
    for dx, dy in [(3,9),(12,9),(7,6),(8,6)]:
        px(img, 32+dx, dy, c('tan', 30))
    save(img, os.path.join(ROOT, 'assets/sprites/effects/dodge_dust.png'))


# ===========================================================================
# MAIN
# ===========================================================================

def main():
    print("=" * 60)
    print("Dark Fantasy RPG Asset Generator")
    print("=" * 60)

    generate_player_idle()
    generate_player_walk()
    generate_npc_sprites()
    generate_portraits()
    generate_tileset()
    generate_items()
    generate_ui()
    generate_effects()

    print("=" * 60)
    print("All assets generated successfully!")
    print("=" * 60)


if __name__ == '__main__':
    main()
