#!/usr/bin/env python3
"""Generate the Carbon & Pewter wallpapers (needs only Pillow).

  ./scripts/gen-wallpapers.py [--out DIR] [--force]

Writes 2560x1600 PNGs (the larger of the two monitors' aspect ratios; the other is cropped).
Existing files are kept unless --force is given, or VERSION below changed since they were made.
Colours match home/quickshell/.../Theme.qml. Each wallpaper is meant to be easy to tell apart.
"""
import argparse, math, os, random, sys
from PIL import Image, ImageChops, ImageFilter, ImageOps

W, H = 2560, 1600
BG = (17, 17, 17)            # #111111
PEWTER = (108, 127, 145)     # #6c7f91
random.seed(11)              # same layout every time
VERSION = 2                  # bump when the designs change: install.sh then regenerates them


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


def vertical(top, bottom, gamma=1.0):
    """Top-to-bottom colour gradient."""
    m = Image.linear_gradient("L").resize((W, H), Image.BICUBIC)
    if gamma != 1.0:
        m = m.point(lambda v: int(((v / 255) ** gamma) * 255))
    return Image.composite(solid(bottom), solid(top), m)


def diagonal(a, b):
    """Corner-to-corner gradient from colour a (top left) to b (bottom right)."""
    v = Image.linear_gradient("L").resize((W, H), Image.BICUBIC)
    h = v.rotate(90, expand=True).resize((W, H), Image.BICUBIC)
    m = ImageChops.add(v, h, 2.0)
    return Image.composite(solid(b), solid(a), m)


def carbon():
    """Near-flat #111111 with a faint lighter patch at the top and darker corners."""
    return grain(vignette_base())


def pewter_glow():
    """Dark top fading into a pewter-blue horizon glow at the bottom."""
    base = vertical((13, 14, 16), (28, 34, 40), gamma=1.6)
    m = radial(0.55, 1.12, 0.80).point(lambda v: int(((255 - v) / 255) ** 2.0 * 255 * 0.42))
    return grain(Image.composite(solid(PEWTER), base, m))


def dusk():
    """Diagonal wash, near-black at the top left to a cool slate at the bottom right."""
    return grain(diagonal((12, 13, 15), (44, 54, 63)))


def slate():
    """A lighter, flat blue-grey for when near-black feels heavy."""
    base = Image.composite(solid((38, 44, 50)), solid((30, 35, 40)), radial(0.5, 0.25, 1.0))
    return grain(base)


def contours():
    """Topographic lines over a flat dark base. The height field is cut into bands and the band edges
    are drawn, so every line has the same thickness however steep or flat the slope is."""
    gw, gh = 8, 5
    field = Image.new("L", (gw, gh))
    field.putdata([max(0, min(255, int(random.gauss(128, 70)))) for _ in range(gw * gh)])
    field = field.resize((W, H), Image.BICUBIC).filter(ImageFilter.GaussianBlur(90))
    field = ImageOps.autocontrast(field, cutoff=0.5)
    step = 16
    bands = field.point([(v // step) * 12 for v in range(256)])           # each band has its own value
    edges = ImageChops.lighter(ImageChops.difference(bands, ImageChops.offset(bands, 1, 0)),
                               ImageChops.difference(bands, ImageChops.offset(bands, 0, 1)))
    lines = edges.point(lambda v: 255 if v else 0).filter(ImageFilter.GaussianBlur(1.3))
    lines = lines.point(lambda v: int(v * 0.60))
    return grain(Image.composite(solid(PEWTER), solid((14, 15, 17)), lines))


WALLPAPERS = {"carbon": carbon, "contours": contours, "dusk": dusk, "pewter-glow": pewter_glow, "slate": slate}

if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default=os.path.expanduser("~/.local/share/wallpapers"))
    ap.add_argument("--force", action="store_true")
    a = ap.parse_args()
    os.makedirs(a.out, exist_ok=True)
    stamp = os.path.join(a.out, ".gen-version")
    try:
        outdated = int(open(stamp).read().strip()) != VERSION
    except (OSError, ValueError):
        outdated = True
    for name, make in WALLPAPERS.items():
        path = os.path.join(a.out, name + ".png")
        if os.path.exists(path) and not (a.force or outdated):
            print(f"  {name}.png (exists)")
            continue
        make().save(path, optimize=True)
        print(f"  {name}.png ({os.path.getsize(path) // 1024} KiB)")
    open(stamp, "w").write(str(VERSION))
