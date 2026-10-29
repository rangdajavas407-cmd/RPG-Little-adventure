#!/usr/bin/env python3
"""Animasi 'melepas benang merah' Darkus iblis (v9.28), dibuat dari sprite idle iblis yang SAMA
(common/fighters/enemies/darkus_iblis-idle.png) supaya badannya tidak berbeda dengan morph/idle.
   python3 tools/make_darkus_iblis_cast.py
Versi v9.18 memakai gambar iblis merah bersayap yang beda total dari Darkus (terlihat seperti sprite asing
di akhir cutscene perasukan). Sekarang: badan = idle iblis, ditambah aura merah berdenyut dan empat benang
energi (piksel tajam) yang memanjang keluar dari badan, bergelombang, lalu menyusut dan hilang.
Frame pertama & terakhir = idle iblis polos, jadi tidak ada lompatan/sisa efek saat animasi berhenti.
Hasil: common/fighters/enemies/darkus_iblis-cast.png (24 frame, tiap frame 128x64, badan di tengah kanvas)."""
import math
import numpy as np
from PIL import Image

IDLE = 'common/fighters/enemies/darkus_iblis-idle.png'
OUT = 'common/fighters/enemies/darkus_iblis-cast.png'
CW, CH, N = 128, 64, 24
CX = CW // 2
RED = (230, 40, 60)
DRED = (140, 10, 34)
HOT = (255, 130, 130)
rng = np.random.RandomState(11)


def body(i):
    sheet = Image.open(IDLE).convert('RGBA')
    n = sheet.width // 64
    return sheet.crop(((i % n) * 64, 0, (i % n + 1) * 64, 64))


def lean(im, px_top):
    """miringkan badan per baris (kaki tetap)"""
    a = np.array(im)
    out = np.zeros_like(a)
    ys = np.where(a[..., 3].any(axis=1))[0]
    y0, y1 = ys.min(), ys.max()
    for y in range(y0, y1 + 1):
        d = int(round(px_top * (y1 - y) / max(1, y1 - y0)))
        row = np.roll(a[y], d, axis=0)
        if d > 0:
            row[:d] = 0
        elif d < 0:
            row[d:] = 0
        out[y] = row
    return Image.fromarray(out, 'RGBA')


BAYER = np.array([[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]) / 16.0


def aura(canvas, strength, color):
    """cahaya merah tipis di BELAKANG badan: lingkaran 2 px berpola dither (bukan kotak garis tepi)"""
    a = np.array(canvas)
    m = a[..., 3] > 60
    p = np.pad(m, 2)
    grown = np.zeros_like(m)
    for dy in range(-2, 3):
        for dx in range(-2, 3):
            if abs(dy) + abs(dx) <= 3:
                grown |= p[2 + dy:2 + dy + m.shape[0], 2 + dx:2 + dx + m.shape[1]]
    th = np.tile(BAYER, (m.shape[0] // 4 + 1, m.shape[1] // 4 + 1))[:m.shape[0], :m.shape[1]]
    ring = grown & ~(a[..., 3] > 0) & (th < strength)
    glow = np.zeros_like(a)
    glow[ring] = [*color, 255]
    out = Image.fromarray(glow, 'RGBA')
    out.alpha_composite(canvas)
    return out


def put(canvas, x, y, color):
    if 0 <= x < CW and 0 <= y < CH:
        canvas.putpixel((x, y), (*color, 255))


def line(canvas, p0, p1, color):
    x0, y0 = p0
    x1, y1 = p1
    steps = max(abs(x1 - x0), abs(y1 - y0), 1)
    for s in range(steps + 1):
        put(canvas, round(x0 + (x1 - x0) * s / steps), round(y0 + (y1 - y0) * s / steps), color)


# asal & arah empat benang: (x, y relatif kanvas, sudut derajat dari sumbu kanan, naik = negatif)
STRANDS = [
    (CX + 11, 40, -20, 40), (CX - 11, 40, 200, 40),
    (CX + 8, 30, -55, 34), (CX - 8, 30, 235, 34),
]


def strand(canvas, spec, t, phase):
    """t: 0 = belum ada, 0..1 tumbuh, 1..2 bertahan, 2..3 menyusut dari pangkal"""
    ox, oy, ang, length = spec
    head = min(t, 1.0)
    tail = max(0.0, t - 2.0)
    if head <= 0 or tail >= 1:
        return
    a = math.radians(ang)
    dx, dy = math.cos(a), math.sin(a)
    px_, py_ = -dy, dx
    pts = []
    for k in range(0, 41):
        u = k / 40.0
        if u > head or u < tail:
            continue
        wave = math.sin(u * 7.0 - phase) * 4.0 * u
        pts.append((ox + dx * u * length * head ** 0.5 + px_ * wave,
                    oy + dy * u * length * head ** 0.5 + py_ * wave))
    for i in range(1, len(pts)):
        line(canvas, (round(pts[i - 1][0]), round(pts[i - 1][1])), (round(pts[i][0]), round(pts[i][1])), RED)
    for i in range(1, len(pts), 3):               # urat gelap & kilap supaya tidak datar
        put(canvas, round(pts[i][0]), round(pts[i][1]) + 1, DRED)
    if pts and head >= 1.0 and tail < 0.5:
        put(canvas, round(pts[-1][0]), round(pts[-1][1]), HOT)   # percikan di ujung


def build_frame(i):
    # fase: 0-3 menarik napas (aura naik), 4-11 benang tumbuh, 12-16 bertahan, 17-21 menyusut, 22-23 polos
    canvas = Image.new('RGBA', (CW, CH), (0, 0, 0, 0))
    lean_px = 0
    if i < 4:
        lean_px = -i // 2                                        # condong ke belakang sedikit
    elif i < 12:
        lean_px = min(2, (i - 3) // 3)                           # lalu condong ke depan
    elif i < 22:
        lean_px = max(0, 2 - (i - 12) // 4)
    b = lean(body(i % 4 if i < 22 else 0), lean_px)
    if i >= 22:
        b = body(0)
    canvas.alpha_composite(b, (CX - 32, 0))
    if 2 <= i <= 20:
        strength = 0.55 if (i % 4) in (1, 2) else 0.3
        canvas = aura(canvas, strength, DRED if strength < 0.5 else RED)
    # benang
    if 3 <= i <= 21:
        for k, spec in enumerate(STRANDS):
            start = 3 + k                                         # tumbuh bergantian
            if i < start:
                continue
            t = (i - start) / 6.0                                 # 0..1 tumbuh
            if i >= 12:
                t = 1.0 + (i - 12) / 5.0                          # 1..2 bertahan
            if i >= 17:
                t = 2.0 + (i - 17) / 5.0                          # 2..3 menyusut
            strand(canvas, spec, t, phase=i * 0.9 + k)
    # bara naik
    if 6 <= i <= 20:
        for _ in range(7):
            x = CX + int(rng.randint(-26, 27))
            y = int(rng.randint(8, 56)) - (i - 6)
            put(canvas, x, y, HOT if rng.rand() < 0.3 else RED)
    return canvas


def main():
    sheet = Image.new('RGBA', (CW * N, CH), (0, 0, 0, 0))
    for i in range(N):
        sheet.paste(build_frame(i), (i * CW, 0))
    sheet.save(OUT)
    print('frames:', N, 'size:', sheet.size)


if __name__ == '__main__':
    main()
