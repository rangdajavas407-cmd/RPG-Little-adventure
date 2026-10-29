#!/usr/bin/env python3
"""Mengecilkan sprite Hiolo Sesat (500x500, buatan sendiri) jadi ikon senjata 16x16.
  python3 tools/make_hiolo_icon.py          (jalankan dari akar project)
Sumber : assets/senjata/hiolo-sesat-dukun-sumber.png
Hasil  : common/items/weapons/hiolo-sesat-dukun.png  (16x16, sama seperti ikon senjata lain)
Gambar dipotong rapat dulu (buang ruang kosong), diperkecil sampai tinggi 16 px, lalu warnanya dirapikan
supaya tepinya tegas seperti pixel art.
"""
from PIL import Image
import numpy as np

SRC = 'assets/senjata/hiolo-sesat-dukun-sumber.png'
DST = 'common/items/weapons/hiolo-sesat-dukun.png'
SIZE = 16

im = Image.open(SRC).convert('RGBA')
im = im.crop(im.getchannel('A').point(lambda v: 255 if v > 8 else 0).getbbox())

# Batang hio terlalu panjang untuk ikon 16x16: buang sebagian tengahnya (hanya batang di area itu)
# lalu sambung lagi, supaya ikon lebih "gemuk" dan tabung hionya terbaca.
CUT_FROM, CUT_TO = 0.22, 0.52          # pecahan tinggi gambar yang dibuang
y0, y1 = int(im.height * CUT_FROM), int(im.height * CUT_TO)
top = im.crop((0, 0, im.width, y0))
bottom = im.crop((0, y1, im.width, im.height))
im2 = Image.new('RGBA', (im.width, top.height + bottom.height), (0, 0, 0, 0))
im2.alpha_composite(top, (0, 0))
im2.alpha_composite(bottom, (0, top.height))
im = im2.crop(im2.getchannel('A').point(lambda v: 255 if v > 8 else 0).getbbox())

INNER = SIZE - 2                         # sisakan 1 px kiri/kanan/atas/bawah untuk outline
scale = INNER / max(im.size)
w, h = max(1, round(im.width * scale)), max(1, round(im.height * scale))
small = im.resize((w, h), Image.LANCZOS)

a = np.array(small)
a[..., 3] = np.where(a[..., 3] >= 110, 255, 0)     # alpha tegas
rgb = a[..., :3].astype(float) / 255.0
rgb = np.power(rgb, 0.62)                         # angkat bagian gelap (tabungnya hitam kemerahan)
rgb = np.clip((rgb - 0.5) * 1.2 + 0.5, 0, 1)     # sedikit kontras
a[..., :3] = (rgb * 255).astype(np.uint8)
a[a[..., 3] == 0] = 0
small = Image.fromarray(a)

# outline gelap 1 px (seperti ikon senjata lain)
OUTLINE = (26, 20, 40, 255)
canvas = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
ox, oy = (SIZE - w) // 2, SIZE - 1 - h
alpha = np.zeros((SIZE, SIZE), dtype=bool)
alpha[oy:oy + h, ox:ox + w] = np.array(small)[..., 3] > 0
cp = canvas.load()
for y in range(SIZE):
    for x in range(SIZE):
        if alpha[y, x]:
            continue
        for dy in (-1, 0, 1):
            for dx in (-1, 0, 1):
                yy, xx = y + dy, x + dx
                if (dx or dy) and 0 <= yy < SIZE and 0 <= xx < SIZE and alpha[yy, xx]:
                    cp[x, y] = OUTLINE
canvas.alpha_composite(small, (ox, oy))
canvas.save(DST)
print('ok', DST, (w, h))
