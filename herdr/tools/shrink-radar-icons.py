#!/usr/bin/env python3
"""Shrink the herdr-radar vendor marks inside the merged JetBrains Mono Herdr font.

The marks live in the Private Use Area (U+E1A0-U+E1B6, U+E1C0-U+E1C5). Each is
scaled about its own bounding-box centre, advance width untouched, so text
metrics and alignment do not move — only the mark gets smaller. Writes a new
family so Ghostty does not serve a cached copy of the old outlines.

    python3 shrink-radar-icons.py <in.ttf> <out.ttf> <scale> "<family name>"

Needs fonttools (pip install fonttools).
"""
import sys
from fontTools.ttLib import TTFont

RANGES = [(0xE1A0, 0xE1B6), (0xE1C0, 0xE1C5)]

src, dst, scale, family = sys.argv[1], sys.argv[2], float(sys.argv[3]), sys.argv[4]
font = TTFont(src)
cmap = font.getBestCmap()
glyf = font["glyf"]
targets = {cmap[cp] for a, b in RANGES for cp in range(a, b + 1) if cp in cmap}

done = 0
for name in sorted(targets):
    g = glyf[name]
    if g.isComposite() or g.numberOfContours == 0:
        continue
    xmin, ymin, xmax, ymax = g.xMin, g.yMin, g.xMax, g.yMax
    cx, cy = (xmin + xmax) / 2, (ymin + ymax) / 2
    coords = g.coordinates
    for i, (x, y) in enumerate(coords):
        coords[i] = (round(cx + (x - cx) * scale), round(cy + (y - cy) * scale))
    g.recalcBounds(glyf)
    done += 1

# rename so the font system treats it as a new family
for rec in font["name"].names:
    if rec.nameID in (1, 4, 16):
        rec.string = family
    elif rec.nameID == 6:
        rec.string = family.replace(" ", "") + "-Regular"
font.save(dst)
print(f"{done} marks scaled by {scale}; saved {dst} as '{family}'")
