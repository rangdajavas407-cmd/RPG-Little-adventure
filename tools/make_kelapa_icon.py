#!/usr/bin/env python3
"""Ikon Kelapa 22x22 (v9.24) dari gambar asli tools/src/kelapa-orig.png (360x360, latar hitam + bayangan cokelat).
   python3 tools/make_kelapa_icon.py"""
import numpy as np
from PIL import Image
from scipy import ndimage

src = Image.open('tools/src/kelapa-orig.png').convert('RGB')
a = np.array(src).astype(int)
lum = a.max(axis=2)
# latar = piksel gelap (hitam / bayangan cokelat) yang tersambung ke tepi gambar
dark = lum < 75
lab, n = ndimage.label(dark)
border = set(lab[0, :]) | set(lab[-1, :]) | set(lab[:, 0]) | set(lab[:, -1])
bg = np.isin(lab, [b for b in border if b != 0])
alpha = np.where(bg, 0, 255).astype(np.uint8)
alpha = ndimage.binary_opening(alpha > 0, iterations=1).astype(np.uint8) * 255
rgba = Image.fromarray(np.dstack([a.astype(np.uint8), alpha]), 'RGBA')
rgba = rgba.crop(rgba.getbbox())
side = max(rgba.size)
sq = Image.new('RGBA', (side, side), (0, 0, 0, 0))
sq.paste(rgba, ((side - rgba.width) // 2, (side - rgba.height) // 2), rgba)
out = sq.resize((22, 22), Image.LANCZOS)
# tajamkan tepi alfa supaya tidak berbayang di latar gelap
px = out.load()
for y in range(22):
    for x in range(22):
        r, g, b, al = px[x, y]
        px[x, y] = (r, g, b, 255 if al > 110 else 0)
out.save('common/items/food/kelapa.png')
big = Image.new('RGBA', (22, 22), (60, 60, 70, 255)); big.alpha_composite(out)
big.resize((220, 220), Image.NEAREST).save('/tmp/kelapa22.png')
