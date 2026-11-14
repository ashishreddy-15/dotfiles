#!/usr/bin/env python3
"""Generate the Carbon & Pewter wallpapers (needs only Pillow).

  ./scripts/gen-wallpapers.py [--out DIR] [--force]

Writes 2560x1600 PNGs (the larger of the two monitors' aspect ratios; the other is cropped).
Existing files are kept unless --force is given. Colours match home/quickshell/.../Theme.qml.
"""
import argparse, math, os, random, sys
from PIL import Image, ImageChops, ImageFilter, ImageOps

W, H = 2560, 1600
BG = (17, 17, 17)            # #111111
PEWTER = (108, 127, 145)     # #6c7f91
random.seed(11)              # same layout every time


def solid(color): return Image.new("RGB", (W, H), color)


def radial(cx, cy, radius):
    """L mask: 0 at (cx, cy) growing to 255 at `radius` pixels away (fractions of the canvas)."""
    g = Image.radial_gradient("L")                       # 256x256, 0 centre -> 255 edge
    size = int(2 * radius * max(W, H))
    g = g.resize((size, size), Image.BICUBIC)
    mask = Image.new("L", (W, H), 255)
    mask.paste(g, (int(cx * W - size / 2), int(cy * H - size / 2)))
    return mask


def grain(img, sigma=2.2):
    """Fine luminance noise: also stops the 8-bit banding that dark gradients get."""
    n = Image.effect_noise((W, H), sigma)                # mean 128
    r, g, b = img.split()
    return Image.merge("RGB", [ImageChops.add(c, n, 1.0, -128) for c in (r, g, b)])


def vignette_base():
    """#111111 a touch lighter near the top centre, darker in the corners."""
    light, dark = solid((22, 22, 22)), solid((12, 12, 12))
    return Image.composite(dark, light, radial(0.5, 0.30, 0.95))


def carbon():
    return grain(vignette_base())


def pewter_glow():
    base = vignette_base()
    m = radial(0.62, 1.05, 0.75).point(lambda v: int(((255 - v) / 255) ** 2.2 * 255 * 0.20))
    return grain(Image.composite(solid(PEWTER), base, m))


def contours():
    """Faint topographic lines. The height field is cut into bands and the band edges are drawn,
    so every line has the same thickness however steep or flat the slope is."""
    gw, gh = 8, 5
    field = Image.new("L", (gw, gh))
    field.putdata([max(0, min(255, int(random.gauss(128, 70)))) for _ in range(gw * gh)])
    field = field.resize((W, H), Image.BICUBIC).filter(ImageFilter.GaussianBlur(90))
    field = ImageOps.autocontrast(field, cutoff=0.5)
    step = 16
    bands = field.point([(v // step) * 12 for v in range(256)])           # each band has its own value
    edges = ImageChops.lighter(ImageChops.difference(bands, ImageChops.offset(bands, 1, 0)),
                               ImageChops.difference(bands, ImageChops.offset(bands, 0, 1)))
    lines = edges.point(lambda v: 255 if v else 0).filter(ImageFilter.GaussianBlur(0.9))
    lines = lines.point(lambda v: int(v * 0.20))
    return grain(Image.composite(solid(PEWTER), vignette_base(), lines))


WALLPAPERS = {"carbon": carbon, "pewter-glow": pewter_glow, "contours": contours}

if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default=os.path.expanduser("~/.local/share/wallpapers"))
    ap.add_argument("--force", action="store_true")
    a = ap.parse_args()
    os.makedirs(a.out, exist_ok=True)
    for name, make in WALLPAPERS.items():
        path = os.path.join(a.out, name + ".png")
        if os.path.exists(path) and not a.force:
            print(f"  {name}.png (exists)")
            continue
        make().save(path, optimize=True)
        print(f"  {name}.png ({os.path.getsize(path) // 1024} KiB)")
