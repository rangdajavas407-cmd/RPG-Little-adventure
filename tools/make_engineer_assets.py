#!/usr/bin/env python3
"""Membuat aset Engineer + Zombie Warga Desa.
  python3 tools/make_engineer_assets.py <wrench.png> <zombie_sheet.png>
Menghasilkan:
  common/items/weapons/sci-fi-wrench.png             (ikon 16x16)
  common/fighters/classes/engineer-*.png             (sheet Engineer, dari sheet tongkat hero)
  common/fighters/enemies/zombie-{idle,attack,damage,die}.png
"""
import sys, math
import numpy as np
from PIL import Image
from collections import deque

W, Z = sys.argv[1], sys.argv[2]

def knock_out_black(im, thr=14):
    """hapus latar hitam yang tersambung ke tepi gambar"""
    a = np.array(im.convert('RGBA'))
    h, w = a.shape[:2]
    dark = a[:, :, :3].sum(axis=2) < thr * 3
    seen = np.zeros((h, w), bool)
    q = deque()
    for x in range(w):
        for y in (0, h - 1):
            if dark[y, x] and not seen[y, x]: seen[y, x] = True; q.append((y, x))
    for y in range(h):
        for x in (0, w - 1):
            if dark[y, x] and not seen[y, x]: seen[y, x] = True; q.append((y, x))
    while q:
        y, x = q.popleft()
        for dy, dx in ((1,0),(-1,0),(0,1),(0,-1)):
            ny, nx = y+dy, x+dx
            if 0 <= ny < h and 0 <= nx < w and dark[ny, nx] and not seen[ny, nx]:
                seen[ny, nx] = True; q.append((ny, nx))
    a[seen, 3] = 0
    return Image.fromarray(a)

# ---------------- wrench ----------------
wr = knock_out_black(Image.open(W))
bbox = wr.getbbox(); wr = wr.crop(bbox)
side = max(wr.size)
sq = Image.new('RGBA', (side, side), (0, 0, 0, 0))
sq.paste(wr, ((side - wr.width)//2, (side - wr.height)//2))
icon = sq.resize((16, 16), Image.LANCZOS)
ia = np.array(icon); ia[:, :, 3] = np.where(ia[:, :, 3] > 90, 255, 0); icon = Image.fromarray(ia)
icon.save('common/items/weapons/sci-fi-wrench.png')

# ---------------- engineer (dari sheet tongkat hero) ----------------
BROWN = {(176,118,66),(122,78,46),(52,30,28)}
def is_staff(p):
    r, g, b, a = p
    if a == 0: return False
    if (r, g, b) in BROWN: return True
    return r > 190 and g < 90 and b < 110          # orb merah
def is_purple(p):
    r, g, b, a = p
    return a > 0 and b > 200 and r > 140 and g < 140 and r > g + 40   # tanduk/rambut ungu

# arah wrench asli: dari gagang ke kepala
wv = np.array([-1040.0, -1170.0]); wv /= np.linalg.norm(wv)
wrench_big = wr  # sudah dicrop, dengan alpha
wang = math.degrees(math.atan2(wv[1], wv[0]))   # sudut (y ke bawah) arah gagang->kepala

def wrench_for(length):
    # putar agar sumbu gagang->kepala menjadi horizontal ke kanan, lalu skala ke 'length'
    rot = wrench_big.rotate(wang, expand=True, resample=Image.BICUBIC)   # PIL rotate: CCW; arah kepala -> sumbu +x
    rot = rot.crop(rot.getbbox())
    s = length / rot.width
    return rot.resize((max(3, round(rot.width * s)), max(3, round(rot.height * s))), Image.LANCZOS)

def convert_frame(fr):
    a = np.array(fr)
    h, w = a.shape[:2]
    pts = [(y, x) for y in range(h) for x in range(w) if is_staff(tuple(a[y, x]))]
    # buang tongkat + ubah ungu -> oranye/kuning (helm teknisi)
    for y in range(h):
        for x in range(w):
            p = tuple(a[y, x])
            if is_purple(p):
                r, g, b, al = (int(v) for v in p)
                lum = (r + g + b) / 3
                a[y, x] = (255, int(150 + lum * 0.2), 40, al) if lum > 170 else (214, 110, 20, al)
    out = Image.fromarray(a)
    if len(pts) < 6:
        return out, None
    pa = np.array(pts, float)
    # buang piksel tongkat
    arr = np.array(out)
    for (y, x) in pts: arr[y, x, 3] = 0
    out = Image.fromarray(arr)
    c = pa.mean(axis=0)
    # sumbu utama tongkat; kepala = ujung dengan piksel merah (orb)
    u, s, vt = np.linalg.svd(pa - c)
    axis = vt[0]
    proj = (pa - c) @ axis
    red = [i for i, (y, x) in enumerate(pts) if (lambda q: q[0] > 190 and q[1] < 90)(tuple(a[y, x]))]
    head_dir = 1 if (red and proj[red].mean() > 0) else -1
    axis = axis * head_dir
    length = proj.max() - proj.min() + 1
    return out, (c, axis, max(14, min(length, 26)))

def put_wrench(fr, info):
    if info is None: return fr
    c, axis, length = info
    wr_img = wrench_for(length)
    ang = -math.degrees(math.atan2(axis[0], axis[1]))   # axis=(dy,dx); PIL rotate CCW dgn y ke bawah
    ang = math.degrees(math.atan2(-axis[0], axis[1]))
    rot = wr_img.rotate(ang, expand=True, resample=Image.BICUBIC)
    ra = np.array(rot); ra[:, :, 3] = np.where(ra[:, :, 3] > 100, 255, 0); rot = Image.fromarray(ra)
    layer = Image.new('RGBA', fr.size, (0, 0, 0, 0))
    layer.paste(rot, (int(round(c[1] - rot.width / 2)), int(round(c[0] - rot.height / 2))), rot)
    base = fr.copy(); base.alpha_composite(layer)
    return base

def tool_belt(fr):
    # aksen kuning di perut (rompi teknisi)
    return fr

MAP = {'idle': 'idle', 'damage': 'damage', 'attack-simple': 'attack-simple',
       'attack-advanced': 'attack-advanced', 'attack-special': 'attack-special'}
for name in MAP:
    sheet = Image.open(f'common/fighters/hero/staff-{name}.png').convert('RGBA')
    n = sheet.width // 64
    res = Image.new('RGBA', sheet.size, (0, 0, 0, 0))
    for i in range(n):
        fr = sheet.crop((i*64, 0, i*64+64, 64))
        fr2, info = convert_frame(fr)
        fr3 = put_wrench(fr2, info)
        # saat serangan spesial: percikan listrik cyan di ujung wrench
        if name == 'attack-special' and info is not None and i >= 2:
            c, axis, length = info
            hx, hy = c[1] + axis[1]*length/2, c[0] + axis[0]*length/2
            px = fr3.load()
            for k in range(7):
                ang = k * 0.9 + i
                sx, sy = int(hx + math.cos(ang)*(3+k%3)), int(hy + math.sin(ang)*(3+k%3))
                if 0 <= sx < 64 and 0 <= sy < 64: px[sx, sy] = (90, 235, 255, 255)
        res.paste(fr3, (i*64, 0))
    res.save(f'common/fighters/classes/engineer-{name}.png')

# ---------------- zombie ----------------
zs = Image.open(Z).convert('RGB')
zs = knock_out_black(zs, thr=10)
groups = [(93,322),(508,767),(936,1197),(1368,1632),(1807,2040)]
CELL = 64; TARGET_H = 48
frames = []
for (x0, x1) in groups:
    cx = (x0 + x1)//2
    crop = zs.crop((cx - 150, 120, cx + 150, 580))
    bb = crop.getbbox(); crop = crop.crop(bb)
    s = TARGET_H / 421.0
    sm = crop.resize((max(1, round(crop.width * s)), max(1, round(crop.height * s))), Image.BOX)
    sm = sm.transpose(Image.FLIP_LEFT_RIGHT)       # musuh menghadap kiri (ke pemain)
    ca = np.array(sm); ca[:, :, 3] = np.where(ca[:, :, 3] > 110, 255, 0); sm = Image.fromarray(ca)
    cell = Image.new('RGBA', (CELL, CELL), (0, 0, 0, 0))
    cell.alpha_composite(sm, (CELL//2 - sm.width//2, 60 - sm.height))
    frames.append(cell)

def shift(img, dx, dy):
    out = Image.new('RGBA', img.size, (0, 0, 0, 0)); out.alpha_composite(img, (dx, dy)); return out
def tint(img, rgb, k):
    a = np.array(img).astype(float)
    m = a[:, :, 3] > 0
    for ch in range(3): a[:, :, ch][m] = a[:, :, ch][m]*(1-k) + rgb[ch]*k
    return Image.fromarray(a.astype('uint8'))
def sheet_of(frs):
    s = Image.new('RGBA', (CELL*len(frs), CELL), (0,0,0,0))
    for i, f in enumerate(frs): s.paste(f, (i*CELL, 0))
    return s
def rot_about_base(img, deg):
    # tumbang ke kanan: geser dulu ke kiri agar seluruh tubuh tetap di dalam bingkai 64x64
    dx = -int(round(24 * abs(deg) / 90.0))
    return shift(img, dx, 0).rotate(deg, resample=Image.NEAREST, center=(32 + dx, 60))

f0, f1, f2, f3, f4 = frames
sheet_of([f0, shift(f0,0,-1), f0, shift(f0,0,-1)]).save('common/fighters/enemies/zombie-idle.png')
sheet_of([f1, f2, f3, shift(f3,-6,0), f2]).save('common/fighters/enemies/zombie-attack.png')
sheet_of([f4, tint(shift(f4,3,0),(255,60,60),0.5), f4, f0]).save('common/fighters/enemies/zombie-damage.png')
die = [f4, rot_about_base(f4,-18), rot_about_base(f4,-45), rot_about_base(f4,-75), rot_about_base(f4,-90)]
die[4] = tint(die[4], (40, 30, 30), 0.35)
sheet_of(die).save('common/fighters/enemies/zombie-die.png')
print('ok')
