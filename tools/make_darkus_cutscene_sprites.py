#!/usr/bin/env python3
"""Sprite Darkus untuk cutscene (jalan masuk dungeon, terikat benang merah, terangkat).
   python3 tools/make_darkus_cutscene_sprites.py <bound.png (latar hitam, 5x2)> <walk.png (latar kotak-kotak, 4x2)>
Output: screens/ancient-dungeon/darkus/darkus-walk.png  (8 frame, menghadap kanan)
        screens/ancient-dungeon/darkus/darkus-bound.png (10 frame: berdiri, benang melilit, lingkaran ritual, terangkat)
Semua frame berukuran sama, kaki sejajar di dasar kanvas, tinggi tubuh berdiri sekitar 54 piksel."""
import sys
from collections import deque
import numpy as np
from PIL import Image, ImageFilter

BOUND, WALK = sys.argv[1], sys.argv[2]
OUT = 'screens/ancient-dungeon/darkus/'
BODY_H = 54.0

def flood(mask):
    """True untuk piksel 'mask' yang tersambung ke tepi gambar"""
    h, w = mask.shape
    seen = np.zeros_like(mask, bool); q = deque()
    for x in range(w):
        for y in (0, h - 1):
            if mask[y, x] and not seen[y, x]: seen[y, x] = True; q.append((y, x))
    for y in range(h):
        for x in (0, w - 1):
            if mask[y, x] and not seen[y, x]: seen[y, x] = True; q.append((y, x))
    while q:
        y, x = q.popleft()
        for dy, dx in ((1,0),(-1,0),(0,1),(0,-1)):
            ny, nx = y + dy, x + dx
            if 0 <= ny < h and 0 <= nx < w and mask[ny, nx] and not seen[ny, nx]:
                seen[ny, nx] = True; q.append((ny, nx))
    return seen

def components(alpha_mask):
    h, w = alpha_mask.shape
    lab = np.zeros((h, w), int); n = 0; out = []
    for y in range(h):
        for x in range(w):
            if alpha_mask[y, x] and lab[y, x] == 0:
                n += 1; q = deque([(y, x)]); lab[y, x] = n; pts = []
                while q:
                    cy, cx = q.popleft(); pts.append((cy, cx))
                    for dy, dx in ((1,0),(-1,0),(0,1),(0,-1)):
                        ny, nx = cy + dy, cx + dx
                        if 0 <= ny < h and 0 <= nx < w and alpha_mask[ny, nx] and lab[ny, nx] == 0:
                            lab[ny, nx] = n; q.append((ny, nx))
                out.append(pts)
    return out

# ---------------- jalan (latar kotak-kotak putih) ----------------
def cut_walk():
    a = np.array(Image.open(WALK).convert('RGB')).astype(int)
    frames = []
    for r in range(2):
        for c in range(4):
            x0, y0 = c * 384, r * 512
            ch = 466 if r == 0 else 452
            cell = a[y0:y0 + ch, x0:x0 + 384]
            light = (cell.min(axis=2) > 205) & ((cell.max(axis=2) - cell.min(axis=2)) < 16)
            bg = flood(light)
            alpha = np.where(bg, 0, 255).astype(np.uint8)
            # buang sisa bayangan tipis di tepi (piksel sangat terang yang menempel ke latar)
            edge = bg.copy()
            for _ in range(1):
                d = np.zeros_like(edge)
                d[1:, :] |= edge[:-1, :]; d[:-1, :] |= edge[1:, :]; d[:, 1:] |= edge[:, :-1]; d[:, :-1] |= edge[:, 1:]
                edge = d
            fringe = edge & (cell.min(axis=2) > 232) & ~bg
            alpha[fringe] = 0
            # hanya komponen terbesar + serpihan dekat (rambut), buang label angka
            comps = components(alpha > 0)
            big = max(comps, key=len)
            ys = [p[0] for p in big]; xs = [p[1] for p in big]
            keep = np.zeros_like(alpha, bool)
            for pts in comps:
                py = [p[0] for p in pts]; px = [p[1] for p in pts]
                near = (min(px) >= min(xs) - 30 and max(px) <= max(xs) + 30 and min(py) >= min(ys) - 30 and max(py) <= max(ys) + 30)
                if pts is big or (near and len(pts) > 6):
                    for (yy, xx) in pts: keep[yy, xx] = True
            alpha = np.where(keep, 255, 0).astype(np.uint8)
            rgba = np.dstack([cell.astype(np.uint8), alpha])
            frames.append(Image.fromarray(rgba))
    return frames

# ---------------- terikat (latar hitam) ----------------
def cut_bound():
    a = np.array(Image.open(BOUND).convert('RGB')).astype(int)
    frames = []
    for r in range(2):
        for c in range(5):
            x0, y0 = int(c * 307.2), r * 512
            cell = a[y0:y0 + 512, x0:x0 + 308]
            mx = cell.max(axis=2)
            core = flood(mx < 14)
            alpha = np.where(core, 0, 255).astype(np.uint8)
            # cahaya merah redup di dekat latar: jadi transparan lembut (additive look)
            dil = core.copy()
            for _ in range(10):
                d = dil.copy()
                d[1:, :] |= dil[:-1, :]; d[:-1, :] |= dil[1:, :]; d[:, 1:] |= dil[:, :-1]; d[:, :-1] |= dil[:, 1:]
                dil = d
            red = (cell[:, :, 0] > 1.5 * np.maximum(cell[:, :, 1], cell[:, :, 2])) & (mx < 170) & dil & ~core
            # dasar sel: pudarkan cahaya di tepi kiri/kanan sel supaya tidak ada tepi lurus
            fadeX = np.minimum(np.arange(cell.shape[1]), cell.shape[1] - 1 - np.arange(cell.shape[1])) / 18.0
            fadeX = np.clip(fadeX, 0, 1)[None, :]
            soft = np.clip((mx - 30) * 2.2, 0, 255).astype(np.uint8)
            alpha = np.where(red, (soft * fadeX).astype(np.uint8), alpha)
            rgb = cell.copy().astype(float)
            sel = red & (soft > 0)
            alpha = np.where(red & (alpha == 0), 0, alpha)
            for ch in range(3):
                rgb[:, :, ch][sel] = np.clip(cell[:, :, ch][sel] * 255.0 / np.maximum(soft[sel], 1), 0, 255)
            frames.append(Image.fromarray(np.dstack([rgb.astype(np.uint8), alpha])))
    return frames

def tight_box(im, thr=100):
    a = np.array(im)[:, :, 3]
    ys, xs = np.where(a > thr)
    return xs.min(), ys.min(), xs.max(), ys.max()

def to_sheet(frames, name, scale, anchorTop=0.4):
    # tinggi sumber tubuh berdiri = frame pertama; kaki sejajar di dasar
    boxes = [tight_box(f) for f in frames]
    # titik pijak: dasar bbox (alpha tebal). titik tengah horizontal: pusat massa bagian atas (kepala/badan)
    anchors = []
    for f, b in zip(frames, boxes):
        al = np.array(f)[:, :, 3] > 200
        top = al[b[1]:b[1] + int((b[3] - b[1]) * anchorTop)]
        xs = np.where(top.any(axis=0))[0]
        cx = int((xs.min() + xs.max()) / 2) if len(xs) else (b[0] + b[2]) // 2
        anchors.append((cx, b[3]))
    # ukuran kanvas: seluruh isi frame terhadap titik pijak
    left = max(a[0] - b[0] for a, b in zip(anchors, boxes))
    right = max(b[2] - a[0] for a, b in zip(anchors, boxes))
    up = max(a[1] - b[1] for a, b in zip(anchors, boxes))
    down = 6
    W0, H0 = left + right + 2, up + down + 2
    cw, ch = int(round(W0 * scale)) + 2, int(round(H0 * scale)) + 2
    sheet = Image.new('RGBA', (cw * len(frames), ch), (0, 0, 0, 0))
    for i, (f, a, b) in enumerate(zip(frames, anchors, boxes)):
        canvas = Image.new('RGBA', (W0, H0), (0, 0, 0, 0))
        canvas.alpha_composite(f, (left - a[0], up - a[1]))
        small = canvas.resize((cw, ch), Image.LANCZOS)
        arr = np.array(small); arr[:, :, 3] = np.where(arr[:, :, 3] > 70, np.minimum(255, arr[:, :, 3] * 2), 0)
        sheet.paste(Image.fromarray(arr), (i * cw, 0))
    sheet.save(OUT + name)
    print(name, 'frame', cw, 'x', ch, 'jumlah', len(frames))
    return cw, ch

walk = cut_walk()
bound = cut_bound()
# skala: tinggi tubuh berdiri -> BODY_H piksel
wb = tight_box(walk[0]); wScale = BODY_H / (wb[3] - wb[1])
bb = tight_box(bound[0]); bScale = BODY_H / (bb[3] - bb[1])
print('skala jalan', round(wScale, 3), 'skala terikat', round(bScale, 3))
wcw, wch = to_sheet(walk, 'darkus-walk.png', wScale)
bcw, bch = to_sheet(bound, 'darkus-bound.png', bScale)

# samakan ukuran kanvas jalan dengan terikat (kaki di dasar, tengah) supaya pergantian animasi tidak melompat
sheet = Image.open(OUT + 'darkus-walk.png').convert('RGBA')
padded = Image.new('RGBA', (bcw * 8, bch), (0, 0, 0, 0))
for i in range(8):
    fr = sheet.crop((i * wcw, 0, i * wcw + wcw, wch))
    padded.alpha_composite(fr, (i * bcw + (bcw - wcw) // 2, bch - wch))
padded.save(OUT + 'darkus-walk.png')
print('darkus-walk.png dipadatkan ke', bcw, 'x', bch)


# =====================================================================
# Sheet ukuran dunia game (tinggi tubuh 44 px, seukuran Ranbyus dan NPC lain)
#   darkus-idle-npc.png  4 frame berdiri menghadap depan (NPC di depan dungeon, adegan ending)
#   darkus-walk-npc.png  8 frame berjalan ke kanan
#   darkus-sit-npc.png   4 frame duduk (menatap bulan, bercerita)
#   darkus-situp-npc.png 2 frame bangun dari berbaring (bersandar, lalu duduk tegak)
#   darkus-lie-npc.png   2 frame terbaring (kepala di kanan)
# Semua kanvas sama besar, kaki/dasar tubuh di dasar kanvas, titik tengah di tengah.
# =====================================================================
NPC_BODY_H = 44.0

def crop_to(im, pad=4):
    b = tight_box(im, 60)
    return im.crop((max(0, b[0] - pad), max(0, b[1] - pad), min(im.width, b[2] + pad + 1), min(im.height, b[3] + pad + 1)))

def squash_sit(stand, bob=0, tilt=0.0):
    """duduk: tubuh bagian atas tetap, kaki/jas bawah dipadatkan seperti lutut ke arah penonton"""
    crop = crop_to(stand, 8)
    cb = tight_box(crop, 60)
    H = cb[3] - cb[1] + 1
    cut = cb[1] + int(0.64 * H)
    upper = crop.crop((0, 0, crop.width, cut))
    lower = crop.crop((0, cut, crop.width, crop.height))
    lb = lower.getbbox()
    lower_t = lower.crop(lb)
    cxl = (lb[0] + lb[2]) / 2
    ls = lower_t.resize((int(lower_t.width * 1.18), max(4, int(lower_t.height * 0.52))), Image.LANCZOS)
    pad = 40
    canvas = Image.new('RGBA', (crop.width + pad * 2, crop.height + pad), (0, 0, 0, 0))
    canvas.alpha_composite(ls, (int(pad + cxl - ls.width / 2), cut - 10 + pad // 2))
    canvas.alpha_composite(upper, (pad, pad // 2 + bob))
    if tilt:
        b0 = tight_box(canvas, 60)
        bottom = (canvas.width // 2, b0[3])
        canvas = canvas.rotate(tilt, resample=Image.BICUBIC, center=bottom)
    return canvas

def lying(stand, deg=-86, shift=0):
    crop = crop_to(stand, 8)
    big = Image.new('RGBA', (crop.width + 160, crop.height + 160), (0, 0, 0, 0))
    big.alpha_composite(crop, (80, 80))
    r = big.rotate(deg, resample=Image.BICUBIC, expand=True)
    r2 = Image.new('RGBA', (r.width + abs(shift) * 2, r.height), (0, 0, 0, 0))
    r2.alpha_composite(r, (abs(shift) + shift, 0))
    return r2

def anchor_of(im, upright=True):
    b = tight_box(im, 100)
    if upright:
        al = np.array(im)[:, :, 3] > 200
        top = al[b[1]:b[1] + max(3, int((b[3] - b[1]) * 0.4))]
        xs = np.where(top.any(axis=0))[0]
        cx = (xs.min() + xs.max()) // 2 if len(xs) else (b[0] + b[2]) // 2
    else:
        cx = (b[0] + b[2]) // 2
    return cx, b[3], b

def shrink(im, s):
    small = im.resize((max(1, int(round(im.width * s))), max(1, int(round(im.height * s)))), Image.LANCZOS)
    a = np.array(small); a[:, :, 3] = np.where(a[:, :, 3] > 90, 255, 0); return Image.fromarray(a)

def make_npc():
    stand = bound[0]
    sS = NPC_BODY_H / (tight_box(stand)[3] - tight_box(stand)[1])
    wS = NPC_BODY_H / (tight_box(walk[0])[3] - tight_box(walk[0])[1])
    groups = {}
    # berdiri: napas halus (skala vertikal sangat kecil)
    idle = []
    for k in range(4):
        f = crop_to(stand, 6)
        sc = [1.0, 0.985, 1.0, 0.985][k]
        if sc != 1.0:
            nb = tight_box(f, 60); bot = nb[3]
            f2 = f.resize((f.width, int(f.height * sc)), Image.LANCZOS)
            canvas = Image.new('RGBA', f.size, (0, 0, 0, 0)); canvas.alpha_composite(f2, (0, f.height - f2.height)); f = canvas
        idle.append((f, True, sS))
    groups['idle'] = idle
    groups['walk'] = [(crop_to(w, 6), True, wS) for w in walk]
    groups['sit'] = [(squash_sit(stand, bob=b), True, sS) for b in (0, -3, 0, -3)]
    groups['situp'] = [(squash_sit(stand, 0, 24.0), True, sS), (squash_sit(stand, 0, 9.0), True, sS)]
    groups['lie'] = [(lying(stand, -86, 0), False, sS), (lying(stand, -84, 2), False, sS)]
    # ukuran kanvas bersama
    prepared = {}
    left = right = up = 0
    for name, items in groups.items():
        lst = []
        for im, upright, s in items:
            sm = shrink(im, s)
            cx, bot, b = anchor_of(sm, upright)
            lst.append((sm, cx, bot, b))
            left = max(left, cx - b[0]); right = max(right, b[2] - cx); up = max(up, bot - b[1])
        prepared[name] = lst
    half = max(left, right) + 1
    cw, ch = half * 2 + 1, up + 3
    for name, lst in prepared.items():
        sheet = Image.new('RGBA', (cw * len(lst), ch), (0, 0, 0, 0))
        for i, (sm, cx, bot, b) in enumerate(lst):
            sheet.alpha_composite(sm, (i * cw + half - cx, ch - 2 - bot))
        sheet.save(OUT + f'darkus-{name}-npc.png')
    print('NPC cell', cw, 'x', ch)
    return cw, ch

NPC_CW, NPC_CH = make_npc()
