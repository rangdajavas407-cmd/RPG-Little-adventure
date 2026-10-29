#!/usr/bin/env python3
"""
Membuat sprite karakter utama yang memegang BUSUR KAYU, dari sprite Pedang Kayu aslinya
(memakai fungsi bantu dari make_hero_skins.py).

  - frame serangan : pedang dihapus, busur digambar di sisi kanan badan. Tali busur
                     ditarik makin ke belakang di tiap frame, lalu dilepas.
  - frame diam/sakit: busur dipegang di samping badan.

Jalankan dari folder proyek (butuh Pillow):   python3 tools/make_bow_skin.py
Hasil: common/fighters/hero/bow-{idle,damage,attack-simple,attack-advanced,attack-special}.png
"""
import os
import sys
from PIL import Image, ImageDraw

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import make_hero_skins as base  # noqa: E402

OUTLINE = base.OUTLINE
WOOD_LIGHT = base.WOOD_LIGHT
WOOD_DARK = base.WOOD_DARK
STRING = (236, 232, 214, 255)
ARROW_SHAFT = (196, 160, 104, 255)
ARROW_TIP = (190, 196, 206, 255)

HALF = 11          # setengah tinggi busur (piksel)
BULGE = 6          # seberapa melengkung ke depan


def bow_points(cx, cy):
    """Titik-titik lengkung busur (membulat ke kanan) berpusat di (cx, cy)."""
    pts = []
    for dy in range(-HALF, HALF + 1):
        t = dy / HALF
        dx = round(BULGE * (1 - t * t))
        pts.append((cx + dx, cy + dy))
    return pts


def draw_bow(fr, cx, cy, pull=0):
    """Gambar busur; pull = berapa piksel tali ditarik ke kiri (0 = tali lurus)."""
    d = ImageDraw.Draw(fr)
    pts = bow_points(cx, cy)
    top, bottom = pts[0], pts[-1]

    # tali busur
    nock = (cx + BULGE - pull, cy)
    if pull > 0:
        d.line([top, nock, bottom], fill=STRING, width=1)
    else:
        d.line([top, bottom], fill=STRING, width=1)

    # badan busur: garis tepi gelap, lalu kayu terang, sisi dalam kayu gelap
    for (x, y) in pts:
        d.rectangle([x - 1, y, x + 1, y], fill=OUTLINE)
    for (x, y) in pts:
        d.point((x, y), fill=WOOD_LIGHT)
    for (x, y) in pts[::2]:
        d.point((x + 1, y), fill=WOOD_DARK)

    # anak panah terpasang di tali saat ditarik
    if pull >= 2:
        shaft_left = nock[0]
        shaft_right = cx + BULGE + 4
        d.line([(shaft_left, cy), (shaft_right, cy)], fill=ARROW_SHAFT, width=1)
        d.point((shaft_right + 1, cy), fill=ARROW_TIP)
        d.point((shaft_right, cy - 1), fill=ARROW_TIP)
        d.point((shaft_right, cy + 1), fill=ARROW_TIP)


def body_box(fr, sword_set):
    px = fr.load()
    xs, ys = [], []
    for x in range(fr.width):
        for y in range(fr.height):
            if px[x, y][3] > 0 and (x, y) not in sword_set:
                xs.append(x)
                ys.append(y)
    return min(xs), min(ys), max(xs), max(ys)


def bow_from_sword(fr, pull):
    """Frame serangan: hapus pedang, pasang busur dengan tarikan tali 'pull'."""
    sword = base.sword_pixels(fr)
    sword_set = set(sword)
    if sword:
        base.erase_sword(fr, sword)
    left, top, right, bottom = body_box(fr, sword_set)
    cx = right - 2
    cy = (top + bottom) // 2 + 3
    draw_bow(fr, cx, cy, pull)
    return fr


def bow_held(fr):
    """Frame diam / terkena damage: busur dipegang di samping badan."""
    bbox = fr.getbbox()
    if bbox is None:
        return fr
    left, top, right, bottom = bbox
    draw_bow(fr, right - 1, (top + bottom) // 2 + 3, 0)
    return fr


def pull_for(index, count):
    """Tarikan tali per frame: 0,2,4,6 lalu lepas (0)."""
    steps = [0, 2, 4, 6]
    if index < len(steps) and index < count - 1:
        return steps[index]
    return 0


def build():
    os.makedirs(base.FIGHT_OUT, exist_ok=True)
    load = lambda name: Image.open(os.path.join(base.FIGHT_SRC, name)).convert("RGBA")
    idle = base.frames_of(load("player-idle.png"), 64)
    dmg = base.frames_of(load("player-damage.png"), 64)
    atk1 = base.frames_of(load("player-attack1.png"), 64)
    atk2 = base.frames_of(load("player-attack2.png"), 64)

    out = lambda name: os.path.join(base.FIGHT_OUT, name)
    base.join([bow_held(f.copy()) for f in idle]).save(out("bow-idle.png"))
    base.join([bow_held(f.copy()) for f in dmg]).save(out("bow-damage.png"))
    base.join([bow_from_sword(f.copy(), pull_for(i, len(atk1))) for i, f in enumerate(atk1)]).save(out("bow-attack-simple.png"))
    adv = [bow_from_sword(f.copy(), pull_for(i, len(atk2))) for i, f in enumerate(atk2)]
    base.join(adv).save(out("bow-attack-advanced.png"))
    base.join([f.copy() for f in adv]).save(out("bow-attack-special.png"))


if __name__ == "__main__":
    build()
    print("selesai")
