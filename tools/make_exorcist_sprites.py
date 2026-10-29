#!/usr/bin/env python3
"""Mengganti orb melayang pada sprite Exorcist dengan KERTAS JIMAT (kertas kuning bertulisan merah),
sesuai senjatanya (Jimat Exorcist). Orb sekarang hanya milik Sage.
  python3 tools/make_exorcist_sprites.py          (jalankan dari akar project)
Sumber asli (yang masih ada orbnya) disimpan di tools/sumber/ supaya skrip ini bisa dijalankan ulang.
Menghasilkan:
  common/fighters/classes/exorcist-{idle,damage,attack-simple,attack-advanced,attack-special}.png
  common/fighters/classes/projectile-holy.png, projectile-holy-big.png   (kertas jimat yang berputar)
Badan Exorcist diambil dari frame idle (tanpa orb) lalu digeser mengikuti pose tiap frame (condong saat menyerang);
posisi dan ukuran kertas mengikuti tabel orb di make_dukun_sprites.py supaya waktunya sama persis.
"""
import math
import random
import numpy as np
from PIL import Image
from scipy import ndimage

import make_dukun_sprites as D   # tabel pose (bx, by, orb) dipakai bersama

SRC = 'tools/sumber/exorcist-%s.png'
DST = 'common/fighters/classes/exorcist-%s.png'
F = 64
YEL = (255, 208, 40, 255)
YEL_D = (206, 142, 20, 255)
RED = (232, 62, 52, 255)


def paper(w, h):
    """Kertas jimat w x h: kuning, tepi lebih tua, goresan merah (lengkung kiri-kanan, aksara tengah, coretan atas, bercak bawah)."""
    im = Image.new('RGBA', (w, h), YEL)
    p = im.load()
    for x in range(w):
        p[x, 0] = p[x, h - 1] = YEL_D
    for y in range(h):
        p[0, y] = p[w - 1, y] = YEL_D
    cx = w // 2
    y0 = max(2, int(h * 0.28))
    # coretan di atas
    if h >= 9:
        for x in (cx - 1, cx + 1):
            if 0 < x < w - 1:
                p[x, 1] = RED
        p[cx, 2] = RED
    # dua lengkung (bentuk guci): lebar di ujung, menyempit di tengah
    span = max(1, h - 2 - y0)
    amp = max(0.0, (w - 5) / 2.0)
    for y in range(y0, h - 2):
        off = 1 + int(round(amp * 0.5 * (1 + math.cos(2 * math.pi * (y - y0) / span))))
        for x in (off, w - 1 - off):
            if 0 < x < w - 1:
                p[x, y] = RED
    # aksara di tengah
    for y in range(int(h * 0.42), int(h * 0.78)):
        p[cx, y] = RED
        if (y % 3 == 0) and w >= 7:
            p[cx - 1, y] = RED
            p[cx + 1, y] = RED
    # bercak di bawah
    if h >= 11:
        for x in (cx - 1, cx + 1):
            if 0 < x < w - 1:
                p[x, h - 3] = RED
    return im


def tilt(im, angle):
    return im.rotate(angle, expand=True, resample=Image.NEAREST)


def stamp(frame, im, cx, cy):
    frame.alpha_composite(im, (int(round(cx - im.width / 2)), int(round(cy - im.height / 2))))


def talisman(frame, cx, cy, r, i, launching):
    w = max(4, int(round(r * 1.2)))
    h = int(round(w * 2.2))
    if launching:
        angle = 82            # melesat ke arah musuh, ujung ke kanan
    elif r >= 4.5:
        angle = -10 + 6 * math.sin(i * 1.3)
    else:
        angle = 7 * math.sin(i * 1.6 + 0.4)   # melayang goyang pelan
    stamp(frame, tilt(paper(w, h), angle), cx, cy)
    if r >= 4.5:
        rnd = random.Random(i * 17 + int(cx))
        for _ in range(5):
            a, d = rnd.uniform(0, 6.283), r + rnd.uniform(2, 4)
            x, y = int(round(cx + math.cos(a) * d)), int(round(cy + math.sin(a) * d))
            if 0 <= x < F and 0 <= y < F and frame.getpixel((x, y))[3] == 0:
                frame.putpixel((x, y), (255, 240, 170, 230))


def body_without_orb(sheet_idle):
    """Frame idle ke-2 (indeks 1) tanpa orb melayang."""
    fr = sheet_idle.crop((64, 0, 128, 64))
    a = np.array(fr)
    lab, k = ndimage.label(a[..., 3] > 0, structure=np.ones((3, 3)))
    for c in range(1, k + 1):
        ys, xs = np.where(lab == c)
        if xs.min() >= 36 and 24 <= ys.min() <= 34 and len(xs) <= 45:
            a[lab == c] = 0
    return Image.fromarray(a)


def clean_damage_frame(fr):
    """Frame damage asli: buang komponen orb (kecil, di sisi kanan badan)."""
    a = np.array(fr)
    lab, k = ndimage.label(a[..., 3] > 0, structure=np.ones((3, 3)))
    for c in range(1, k + 1):
        ys, xs = np.where(lab == c)
        if len(xs) == 37 and 24 <= ys.min() <= 36:
            a[lab == c] = 0
    return Image.fromarray(a)


def build(name, spec):
    n = len(spec['bx'])
    src = Image.open(SRC % name).convert('RGBA')
    out = Image.new('RGBA', (F * n, F), (0, 0, 0, 0))
    if name == 'damage':
        for i in range(n):
            out.alpha_composite(clean_damage_frame(src.crop((i * F, 0, i * F + F, F))), (i * F, 0))
        return out
    idle = Image.open(SRC % 'idle').convert('RGBA')
    body = body_without_orb(idle)
    for i in range(n):
        fr = Image.new('RGBA', (F, F), (0, 0, 0, 0))
        fr.alpha_composite(body, (spec['bx'][i] - 17, spec['by'][i] - 22))
        o = spec['orb'][i]
        if o is not None:
            talisman(fr, o[0], o[1], o[2], i, i in D.LAUNCH.get(name, []))
        out.alpha_composite(fr, (i * F, 0))
    return out


def projectile(size, big):
    w, h = (5, 9) if not big else (8, 15)
    im = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    stamp(im, paper(w, h), size / 2, size / 2)
    return im


def main():
    for name, spec, _ in D.SHEETS:
        build(name, spec).save(DST % name)
    projectile(10, False).save('common/fighters/classes/projectile-holy.png')
    projectile(16, True).save('common/fighters/classes/projectile-holy-big.png')
    print('ok')


if __name__ == '__main__':
    main()
