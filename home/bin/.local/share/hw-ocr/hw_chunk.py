"""Split very wide lines of ink at wide gaps (TrOCRProcessor squashes to 384x384, so long lines lose their tail)."""
import numpy as np
from PIL import Image

MAX_ASPECT = 9.0   # lines up to this width:height are recognised whole
TARGET = 7.0       # aim for chunks about this wide (in heights)
MIN_GAP = 0.4     # a split gap must be at least this many heights of blank columns


def split_wide(img, max_aspect=MAX_ASPECT, target=TARGET, min_gap=MIN_GAP):
    w, h = img.size
    if w / h <= max_aspect:
        return [img]
    g = np.asarray(img.convert("L"))
    ink = (g < 160).any(axis=0)
    if not ink.any():
        return [img]
    # blank runs strictly inside the ink extent: (start, end) of each, with centre
    xs = np.flatnonzero(ink)
    lo, hi = xs[0], xs[-1] + 1
    gaps, i = [], lo
    while i < hi:
        if ink[i]:
            i += 1
            continue
        j = i
        while j < hi and not ink[j]:
            j += 1
        if (j - i) >= min_gap * h:
            gaps.append(((i + j) // 2, j - i))
        i = j
    if not gaps:
        return [img]
    n = max(2, round((hi - lo) / (target * h)))
    cuts = []
    for k in range(1, n):
        ideal = lo + (hi - lo) * k / n
        # nearest gap to the ideal point, favouring wide ones
        c = min(gaps, key=lambda gp: abs(gp[0] - ideal) - 0.5 * gp[1])
        if c[0] not in cuts:
            cuts.append(c[0])
    cuts = sorted(cuts)
    edges = [0] + cuts + [w]
    return [img.crop((a, 0, b, h)) for a, b in zip(edges, edges[1:]) if b - a > 2]
