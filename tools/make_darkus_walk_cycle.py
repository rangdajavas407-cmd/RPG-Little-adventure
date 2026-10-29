#!/usr/bin/env python3
"""Siklus jalan Darkus baru (v9.18). Jalankan dari akar proyek:  python3 tools/make_darkus_walk_cycle.py
Membangun ulang kaki dari frame jalan lama (tools/src/darkus-walk-npc-orig.png, frame 0): kaki depan dan belakang
terpisah, berayun bergantian dengan telapak terangkat saat melangkah, badan turun sedikit saat telapak menapak,
ujung jas berkibar. Hasil:
  screens/ancient-dungeon/darkus/darkus-walk-npc.png  (8 frame 47x46, dipakai NPC dan ending)
  screens/ancient-dungeon/darkus/darkus-walk.png      (8 frame, kanvas cutscene, badan 44 px)
  screens/ancient-dungeon/darkus/darkus-bound.png     (10 frame, diperkecil dari 54 px ke 44 px)"""
import math
import numpy as np
from PIL import Image

D = 'screens/ancient-dungeon/darkus/'
SRC = 'tools/src/'
NPC_W, NPC_H = 47, 46
HIP_Y, FOOT_Y = 34, 44          # pinggul dan telapak pada kanvas 47x46
SPLIT_X = 23                    # batas kaki belakang (kiri) / depan (kanan)
STRIDE = 5.0                    # ayunan telapak (px)
LIFT = 3.0                      # tinggi angkat telapak saat melangkah (px)

def lum(px):
    return (int(px[0]) + int(px[1]) + int(px[2])) // 3

def load_base():
    im = np.array(Image.open(SRC + 'darkus-walk-npc-orig.png').convert('RGBA'))
    return im[:, 0:NPC_W].copy()

ARM_PIVOT = (20.0, 21.0)       # bahu (x, y)
ARM_Y0 = 22
FILL_X0 = 16                   # hanya isi bekas lengan yang tadinya menutupi badan (x >= ini)

def is_arm(base, y, x):
    r, g, b = int(base[y, x, 0]), int(base[y, x, 1]), int(base[y, x, 2])
    green = g > r + 18 and g > b + 18
    return base[y, x, 3] > 40 and lum(base[y, x]) > 88 and not green and x < 20 and ARM_Y0 <= y <= 39

def is_coat(base, y, x):
    return base[y, x, 3] > 40 and lum(base[y, x]) > 150 and x < 21 and 29 <= y <= 39

def build_frame(base, i, n=8):
    th_b = 2 * math.pi * i / n          # kaki depan
    th_a = th_b + math.pi               # kaki belakang
    out = np.zeros_like(base)

    def draw_leg(theta, xmin, xmax):
        swing = STRIDE * math.sin(theta)
        lift = LIFT * max(0.0, math.cos(theta))      # naik saat kaki bergerak maju
        for y in range(HIP_Y + 1, FOOT_Y + 1):
            d = (y - HIP_Y) / float(FOOT_Y - HIP_Y)
            dx = int(round(swing * d))
            dy = int(round(lift * d * d))
            for x in range(xmin, xmax):
                sy, sx = y + dy, x - dx
                if 0 <= sy < NPC_H and 0 <= sx < NPC_W and xmin <= sx < xmax:
                    if base[sy, sx, 3] > 40 and not is_arm(base, sy, sx) and not is_coat(base, sy, sx) and sy > HIP_Y - 1:
                        out[y, x] = base[sy, sx]

    draw_leg(th_a, 8, SPLIT_X)
    draw_leg(th_b, SPLIT_X, 40)

    # badan atas (kepala sampai pinggul) turun 1 px saat telapak menapak (kaki terentang paling lebar)
    bob = 1 if abs(math.sin(th_b)) > 0.7 else 0
    for y in range(0, HIP_Y + 1):
        for x in range(NPC_W):
            if base[y, x, 3] > 0 and not is_arm(base, y, x) and not is_coat(base, y, x):
                ny = y + bob
                if ny < NPC_H:
                    out[ny, x] = base[y, x]
    # lengan + ujung jas (massa putih di kiri badan) berayun seperti bandul dari bahu, berlawanan dengan kaki belakang.
    # Piksel aslinya dihapus dulu (diisi warna celana/rompi terdekat), lalu versi yang diputar digambar di atasnya.
    ang = math.radians(16.0) * math.sin(th_a)
    ca, sa = math.cos(ang), math.sin(ang)
    px, py = ARM_PIVOT
    arm = [(y, x) for y in range(ARM_Y0, 40) for x in range(NPC_W) if is_arm(base, y, x)]
    armset = set(arm)
    for (y, x) in arm:
        ny = y + bob
        if ny < NPC_H:
            out[ny, x] = 0
    # isi bekas lengan dengan piksel tetangga bukan-lengan (kiri ke kanan) supaya badan tidak bolong
    for (y, x) in sorted(arm, key=lambda t: (t[0], -t[1])):
        ny = y + bob
        if ny >= NPC_H or x < FILL_X0:
            continue
        for dx in range(1, 5):
            xx = x + dx
            if xx < NPC_W and (y, xx) not in armset and base[y, xx, 3] > 40 and lum(base[y, xx]) < 125:
                out[ny, x] = base[y, xx]
                break
    dest = np.zeros_like(base)
    for y in range(NPC_H):
        for x in range(NPC_W):
            # putar balik: cari piksel sumber untuk tujuan (x, y)
            dx, dy = x - px, y - bob - py
            sx = int(round(px + ca * dx + sa * dy))
            sy = int(round(py - sa * dx + ca * dy))
            if (sy, sx) in armset:
                dest[y, x] = base[sy, sx]
    m = dest[:, :, 3] > 40
    out[m] = dest[m]
    return out

def npc_frames():
    base = load_base()
    return [build_frame(base, i) for i in range(8)]

def feet_row(arr):
    ys = np.where(arr[:, :, 3] > 40)[0]
    return int(ys.max())

def main():
    frames = npc_frames()
    # ---- sheet NPC 8x(47x46)
    sheet = np.zeros((NPC_H, NPC_W * 8, 4), np.uint8)
    for i, f in enumerate(frames):
        sheet[:, i * NPC_W:(i + 1) * NPC_W] = f
    Image.fromarray(sheet, 'RGBA').save(D + 'darkus-walk-npc.png')

    # ---- sheet cutscene: bound lama diperkecil 54 -> 44 px, walk ditaruh di kanvas sama
    bound = Image.open(SRC + 'darkus-bound-orig.png').convert('RGBA')
    OW, OH, S = 48, 95, 44.0 / 54.0
    CW, CH = int(round(OW * S)), int(round(OH * S))          # 39 x 78
    nb = Image.new('RGBA', (CW * 10, CH), (0, 0, 0, 0))
    for i in range(10):
        c = bound.crop((i * OW, 0, (i + 1) * OW, OH)).resize((CW, CH), Image.LANCZOS)
        nb.paste(c, (i * CW, 0))
    nb.save(D + 'darkus-bound.png')
    # dasar kaki frame berdiri (frame 0 bound) -> kaki frame jalan ditaruh di baris yang sama
    b0 = np.array(nb.crop((0, 0, CW, CH)))
    ground = feet_row(b0)
    nw = Image.new('RGBA', (CW * 8, CH), (0, 0, 0, 0))
    for i, f in enumerate(frames):
        fy = feet_row(f)
        cell = Image.new('RGBA', (CW, CH), (0, 0, 0, 0))
        crop = Image.fromarray(f, 'RGBA').crop((4, 0, 4 + CW, NPC_H))
        cell.paste(crop, (0, ground - fy), crop)
        nw.paste(cell, (i * CW, 0))
    nw.save(D + 'darkus-walk.png')
    print('cutscene cell', CW, CH, 'ground row', ground, 'feet below center', ground - CH / 2.0)

if __name__ == '__main__':
    main()
