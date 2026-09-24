# /// script
# requires-python = ">=3.10"
# dependencies = ["numpy", "pillow"]
# ///
"""Render Wintty's app icon masters: black squircle, rainbow rim, white `>_`.

Usage: uv run make_icon.py <images/icons dir>
"""

import colorsys
import sys

import numpy as np
from PIL import Image, ImageDraw

BG = (13, 12, 18, 255)
WHITE = (255, 255, 255, 255)
SIZES = (16, 32, 64, 128, 256, 512, 1024)


def _conic(size, start_deg=225.0):
    """Clockwise rainbow sweep around the centre, red at the top-left corner."""
    y, x = np.mgrid[0:size, 0:size].astype(np.float64) + 0.5
    ang = (np.degrees(np.arctan2(y - size / 2, x - size / 2)) - start_deg) % 360 / 360
    rgb = np.array([colorsys.hsv_to_rgb(h, 0.78, 1.0) for h in np.linspace(0, 1, 721)])
    img = (rgb[(ang * 720).astype(int)] * 255).astype(np.uint8)
    alpha = np.full((size, size, 1), 255, np.uint8)
    return Image.fromarray(np.concatenate([img, alpha], axis=2), "RGBA")


def _mask_rrect(size, box, radius):
    """Hard-edged rounded-rect mask; render() supersamples for antialiasing."""
    m = Image.new("L", (size, size), 0)
    ImageDraw.Draw(m).rounded_rectangle(box, radius=radius, fill=255)
    return m


def _glyph_mask(size, tile_x, tile, stroke):
    """`>_` prompt, placed like a terminal's first line."""
    m = Image.new("L", (size, size), 0)
    d = ImageDraw.Draw(m)
    u = lambda f: tile_x + f * tile
    pts = [(u(0.27), u(0.29)), (u(0.43), u(0.43)), (u(0.27), u(0.57))]
    d.line(pts, fill=255, width=int(round(stroke)), joint="curve")
    r = stroke / 2
    for px, py in (pts[0], pts[2]):
        d.ellipse((px - r, py - r, px + r, py + r), fill=255)
    d.rounded_rectangle((u(0.50), u(0.57) - r, u(0.71), u(0.57) + r), radius=r, fill=255)
    return m


def render(px):
    """Render the icon at px x px, with heavier strokes at taskbar sizes."""
    ss = 16 if px <= 64 else 4
    size = px * ss
    small = px <= 32
    margin = 0 if small else 0.055 * size
    tile = size - 2 * margin
    radius = 0.23 * tile
    rim = (0.11 if small else 0.075) * tile

    out = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    box = (margin, margin, margin + tile, margin + tile)
    out.paste(_conic(size), (0, 0), _mask_rrect(size, box, radius))
    inner = (box[0] + rim, box[1] + rim, box[2] - rim, box[3] - rim)
    out.paste(Image.new("RGBA", (size, size), BG), (0, 0), _mask_rrect(size, inner, radius - rim))
    out.paste(Image.new("RGBA", (size, size), WHITE), (0, 0), _glyph_mask(size, margin, tile, rim))
    return out.resize((px, px), Image.LANCZOS)


if __name__ == "__main__":
    for px in SIZES:
        render(px).save(f"{sys.argv[1]}/icon_{px}.png")
