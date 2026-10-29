#!/usr/bin/env python3
"""Ikon Busur Pemburu 16x16 (v9.18), digambar piksel supaya seukuran ikon senjata lain.
Sebelumnya 577x433 (render panah silang) sehingga terlalu besar. Asli disimpan di tools/src/hunter-bow-orig.png.
   python3 tools/make_hunter_bow_icon.py"""
from PIL import Image

OUT = 'common/items/weapons/hunter-bow.png'
C = {
    'o': (58, 34, 18, 255),     # kayu gelap / lengan busur
    'd': (92, 56, 30, 255),     # kayu sedang
    'w': (200, 88, 30, 255),    # gagang oranye
    'l': (236, 140, 62, 255),   # sorot gagang
    's': (232, 224, 200, 255),  # tali
    'm': (170, 180, 204, 255),  # mata panah besi
    'k': (110, 80, 50, 255),    # batang anak panah
}
ART = [
    "................",
    ".............oo.",
    "............odo.",
    "...........odo..",   # tali mulai dari ujung atas
    "..........od....",
    "..........o.....",
    "..........o.....",
    "...llllldod.....",
    "..wwwwwwwwwkkkmm",
    "...ddddddodo....",
    "..........o.....",
    "..........o.....",
    "..........od....",
    "...........odo..",
    "............odo.",
    ".............oo.",
]
img = Image.new('RGBA', (16, 16), (0, 0, 0, 0))
for y, row in enumerate(ART):
    for x, ch in enumerate(row):
        if ch in C:
            img.putpixel((x, y), C[ch])
# tali: dari ujung atas ke belakang gagang lalu ke ujung bawah
def line(p, q):
    (x0, y0), (x1, y1) = p, q
    n = max(abs(x1 - x0), abs(y1 - y0))
    for i in range(n + 1):
        x = round(x0 + (x1 - x0) * i / n); y = round(y0 + (y1 - y0) * i / n)
        if img.getpixel((x, y))[3] == 0:
            img.putpixel((x, y), C['s'])
line((13, 2), (2, 8)); line((13, 14), (2, 8))
img.save(OUT)
