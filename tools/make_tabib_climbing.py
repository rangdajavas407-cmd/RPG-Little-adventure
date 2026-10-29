#!/usr/bin/env python3
"""Membuat sheet animasi memanjat Pak Tabib (tampak belakang, 4 frame 32x32).
   python3 tools/make_tabib_climbing.py
Dasar: tabib-idle.png (palet dan helm yang sama), wajah diganti belakang kepala, lengan dan kaki bergantian."""
from PIL import Image, ImageDraw

SRC = 'screens/tree-village/assets/tabib/tabib-idle.png'
OUT = 'screens/tree-village/assets/tabib/tabib-climbing.png'
idle = Image.open(SRC).convert('RGBA').crop((0, 0, 32, 32))
P = idle.load()

C = {k: P[x, y] for k, (x, y) in {
    'a': (6, 9), 'b': (8, 4), 'c': (14, 7), 'd': (12, 9), 'e': (13, 15), 'f': (8, 9), 'g': (13, 22),
    'h': (24, 9), 'i': (8, 21), 'j': (10, 19), 'k': (11, 21), 'l': (25, 25), 'n': (22, 24), 'm': (11, 25),
    'p': (12, 19), 'r': (10, 21), 's': (15, 28), 'v': (11, 26), 'o': (11, 28), 'y': (21, 18)}.items()}
C['t'] = C['b']

def build_base():
    im = idle.copy()
    px = im.load()
    def col(k): return C[k]
    # helm: buang kilau lampu depan
    for y in range(0, 9):
        for x in range(32):
            if px[x, y][:3] == (255, 240, 160): px[x, y] = col('b')
    # belakang kepala: wajah -> rambut putih
    for y in range(9, 14):
        for x in range(32):
            if px[x, y][:3] in [(255,211,166),(255,255,255),(42,29,46)]:
                px[x, y] = col('e') if (x + y) % 5 else (238, 238, 238, 255)
    # leher + sisa rambut
    for y in range(14, 18):
        xs = [x for x in range(32) if px[x, y][:3] == (226, 226, 226)]
        if xs:
            lo, hi = min(xs), max(xs)
            for x in xs:
                if lo + 2 <= x <= hi - 2: px[x, y] = col('f') if y < 17 else (187, 152, 120, 255)
    # syal dari belakang
    for x in range(32):
        if px[x, 18][:3] in [(226,226,226),(187,152,120)]: px[x, 18] = col('j')
    # bersihkan lengan, tongkat, dan bagian depan badan
    for y in range(19, 31):
        for x in range(32):
            if x < 9 or x > 22: px[x, y] = (0, 0, 0, 0)
    for y in range(19, 25):
        px[9, y] = col('a'); px[22, y] = col('a')
    # punggung overall dengan tali silang
    rows = ["jjggggggggjj", "nggkgggggkgn", "ngggkggkgggn", "nggggkkggggn", "ngggkggkgggn", "nggkgggggkgn"]
    for i, r in enumerate(rows):
        for j, ch in enumerate(r):
            px[10 + j, 19 + i] = col(ch)
    # tambalan kecil di punggung bawah dan sabuk tanpa gesper
    for y in range(25, 31):
        for x in range(9, 23):
            if px[x, y][:3] == (226, 219, 203): px[x, y] = col('n') if y == 26 else col('m')
    return im

BASE = build_base()

def legs_split(img, raiseLeft, raiseRight):
    """rows 25..30: pisahkan kaki kiri/kanan, naikkan salah satu supaya terlihat melangkah di tangga"""
    out = img.copy()
    o = out.load(); s = img.load()
    for y in range(26, 31):
        for x in range(9, 23):
            o[x, y] = (0, 0, 0, 0)
    for y in range(26, 31):
        for x in range(9, 23):
            c = s[x, y]
            if c[3] == 0: continue
            dy = -(raiseLeft if x <= 15 else raiseRight)
            ny = y + dy
            if 0 <= ny < 32: o[x, ny] = c
    # sambung betis yang terangkat dengan satu piksel gelap
    return out

def arm(d, shoulder, hand, left):
    sx, sy = shoulder; hx, hy = hand
    out_ = C['a']; green = C['g']; light = C['r']; skin = C['f']
    d.line([sx, sy, hx, hy + 2], fill=out_, width=4)
    d.line([sx, sy, hx, hy + 2], fill=green, width=2)
    d.line([sx + (1 if left else -1), sy, hx + (1 if left else -1), hy + 2], fill=light, width=1)
    d.rectangle([hx - 2, hy - 1, hx + 2, hy + 3], fill=out_)
    d.rectangle([hx - 1, hy, hx + 1, hy + 2], fill=skin)
    d.point([hx, hy], fill=C['d'])

# (tangan kiri y, tangan kanan y, kaki kiri naik, kaki kanan naik, bob)
POSES = [(9, 17, 3, 0, 0), (13, 13, 1, 1, -1), (17, 9, 0, 3, 0), (13, 13, 1, 1, -1)]
sheet = Image.new('RGBA', (32 * len(POSES), 32), (0, 0, 0, 0))
for i, (hl, hr, ll, lr, bob) in enumerate(POSES):
    body = legs_split(BASE, ll, lr)
    frame = Image.new('RGBA', (32, 32), (0, 0, 0, 0))
    frame.alpha_composite(body, (0, bob))
    d = ImageDraw.Draw(frame)
    sh_y = 21 + bob
    arm(d, (9, sh_y), (4, hl + bob), True)
    arm(d, (22, sh_y), (27, hr + bob), False)
    sheet.paste(frame, (32 * i, 0))
sheet.save(OUT)
print('ok', OUT, sheet.size)
