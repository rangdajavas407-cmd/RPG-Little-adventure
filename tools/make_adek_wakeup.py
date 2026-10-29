#!/usr/bin/env python3
"""Sprite Adek bangun dari kasur, menyambung ke sprite idle (adek-ending.png).
   python3 tools/make_adek_wakeup.py
Output: screens/tree-village/assets/adek-wakeup.png  (8 frame, 320x282; tinggi sama dengan sheet idle)
Frame terakhir identik dengan pose idle (frame 0) di tengah kanvas, jadi bisa langsung disambung ke idle."""
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

SRC = 'screens/tree-village/assets/adek-ending.png'
OUT = 'screens/tree-village/assets/adek-wakeup.png'
CELL_W, CELL_H, N = 320, 282, 8
sheet = Image.open(SRC).convert('RGBA')
IDLE_CELL = [(0, 220), (220, 440), (440, 660), (660, 883)]

def cell(i):
    x0, x1 = IDLE_CELL[i]
    c = Image.new('RGBA', (220, 282), (0, 0, 0, 0))
    c.alpha_composite(sheet.crop((x0, 0, x1, 282)), (0, 0))
    return c

def flat(im):
    bg = Image.new('RGBA', im.size, (255, 255, 255, 255)); bg.alpha_composite(im)
    return np.array(bg.convert('RGB')).astype(float)

def align(img, ref, rows=(45, 115), search=18):
    """geser img agar tudung (bagian atas yang sama di semua frame) menimpa ref"""
    r = flat(ref)[rows[0]:rows[1], 20:200]
    best, bs = None, (0, 0)
    f = flat(img)
    for dy in range(-search, search + 1):
        for dx in range(-search, search + 1):
            sh = np.roll(np.roll(f, dy, 0), dx, 1)[rows[0]:rows[1], 20:200]
            d = np.abs(sh - r).mean()
            if best is None or d < best: best, bs = d, (dx, dy)
    out = Image.new('RGBA', img.size, (0, 0, 0, 0)); out.alpha_composite(img, bs)
    return out

c0, c1, c2, c3 = cell(0), cell(1), cell(2), cell(3)
c1a, c3a, c0a = align(c1, c2), align(c3, c2), align(c0, c2)

# wajah tidur: dasar frame 2 (mata terbuka, mulut kecil) + mata terpejam dari frame 3
def sleepy(base, closed):
    out = base.copy()
    box = (62, 128, 168, 160)       # area kedua mata
    mask = Image.new('L', base.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle(box, radius=8, fill=255)
    mask = mask.filter(ImageFilter.GaussianBlur(3))
    out.paste(closed, (0, 0), mask)
    return out

SLEEP = sleepy(c2, c3a)         # tidur: mata terpejam
OPEN_CONFUSED = c2              # baru bangun: mata terbuka, mulut kecil
HAPPY = c0a                     # senang
STRETCH = c1a                   # mata terpejam tersenyum (menggeliat)

def tight(im):
    return im.crop(im.getbbox())

# ---------- tempat tidur ----------
def draw_bed(frame, lift=0):
    d = ImageDraw.Draw(frame)
    wood, woodD, woodL = (122, 84, 62, 255), (84, 56, 44, 255), (160, 118, 88, 255)
    # papan kepala (kiri) dan kaki (kanan)
    d.rounded_rectangle((6, 128, 30, 262), radius=5, fill=woodD)
    d.rounded_rectangle((9, 132, 27, 258), radius=4, fill=wood)
    d.rounded_rectangle((300, 196, 314, 262), radius=4, fill=woodD)
    d.rounded_rectangle((302, 199, 312, 258), radius=3, fill=wood)
    # rangka dan kasur
    d.rounded_rectangle((20, 222, 308, 244), radius=5, fill=woodD)
    d.rounded_rectangle((22, 224, 306, 241), radius=4, fill=woodL)
    d.rounded_rectangle((26, 206, 304, 226), radius=7, fill=(205, 214, 238, 255))
    d.rounded_rectangle((26, 206, 304, 212), radius=4, fill=(228, 233, 250, 255))
    d.rectangle((30, 244, 40, 266), fill=woodD); d.rectangle((288, 244, 298, 266), fill=woodD)

def draw_pillow(frame, dy=0):
    d = ImageDraw.Draw(frame)
    d.rounded_rectangle((32, 176 + dy, 100, 214 + dy), radius=14, fill=(176, 190, 232, 255))
    d.rounded_rectangle((35, 179 + dy, 97, 207 + dy), radius=12, fill=(214, 224, 250, 255))

def draw_blanket(frame, from_x, top_y, wave=0.0):
    """selimut menutup dari from_x sampai kaki ranjang, melambai di tepi atas"""
    pts = [(from_x, top_y)]
    for i in range(0, 9):
        x = from_x + (300 - from_x) * i / 8
        pts.append((x, top_y - 6 * np.sin(i * 0.9 + wave) + (3 if i % 2 else 0)))
    pts += [(304, 236), (from_x - 4, 238)]
    d = ImageDraw.Draw(frame)
    d.polygon(pts, fill=(150, 170, 225, 255), outline=(108, 128, 196, 255))
    d.line([(from_x + 8, top_y + 12), (298, top_y + 12)], fill=(190, 205, 245, 255), width=3)
    for k in range(3):
        x = from_x + 28 + k * 56
        d.line([(x, top_y + 14), (x - 6, 232)], fill=(122, 144, 210, 255), width=2)
    d.rectangle((from_x - 4, 224, 304, 238), fill=(150, 170, 225, 255))

def place(frame, sprite, pivot, angle, scale=(1.0, 1.0)):
    """tempel sprite (rapat) dengan pusat-bawahnya di 'pivot' setelah diputar 'angle' derajat (CCW)"""
    t = tight(sprite)
    if scale != (1.0, 1.0):
        t = t.resize((max(1, int(t.width * scale[0])), max(1, int(t.height * scale[1]))), Image.LANCZOS)
    w, h = t.size
    pad = int(max(w, h) * 1.2)
    big = Image.new('RGBA', (pad * 2, pad * 2), (0, 0, 0, 0))
    bottomCenter = (pad, pad + h // 2 + h // 2)  # titik dasar sprite ada di (pad, pad+h)
    big.alpha_composite(t, (pad - w // 2, pad))
    rot = big.rotate(angle, resample=Image.BICUBIC, center=(pad, pad + h))
    frame.alpha_composite(rot, (int(pivot[0] - pad), int(pivot[1] - (pad + h))))

# sprite idle pada kanvas tengah: dasar sprite (tight) di (160, 247)
def build():
    frames = []
    def new(): return Image.new('RGBA', (CELL_W, CELL_H), (0, 0, 0, 0))

    # F0, F1: tidur, napas naik-turun (selimut ikut naik)
    for i, (py, sy, wave) in enumerate([(152, 1.0, 0.0), (149, 1.012, 1.2)]):
        f = new(); draw_bed(f); draw_pillow(f)
        place(f, SLEEP, (250, py), 90, (1.0, sy))
        draw_blanket(f, 128, 196 - (2 if i else 0), wave)
        frames.append(f)
    # F2: bergerak, kepala mulai miring
    f = new(); draw_bed(f); draw_pillow(f, -2)
    place(f, SLEEP, (250, 151), 86); draw_blanket(f, 132, 197, 2.0); frames.append(f)
    # F3: mata terbuka, masih berbaring
    f = new(); draw_bed(f); draw_pillow(f, -2)
    place(f, OPEN_CONFUSED, (250, 150), 82); draw_blanket(f, 134, 198, 3.0); frames.append(f)
    # F4: setengah duduk, selimut turun ke pinggang
    f = new(); draw_bed(f); draw_pillow(f, 0)
    place(f, OPEN_CONFUSED, (238, 214), 40); draw_blanket(f, 150, 204, 4.0); frames.append(f)
    # F5: duduk tegak, menggeliat (mata terpejam senyum)
    f = new(); draw_bed(f); draw_pillow(f, 0)
    place(f, STRETCH, (218, 214), 10, (0.98, 1.03)); draw_blanket(f, 170, 208, 5.0); frames.append(f)
    # F6: turun dari ranjang, melayang ke posisi berdiri (selimut tersingkap)
    f = new(); draw_bed(f)
    place(f, HAPPY, (186, 232), 0, (1.0, 1.04)); frames.append(f)
    # F7: pose idle persis, di tengah kanvas
    f = new(); draw_bed(f)
    bbH = c0a.getbbox()
    f.alpha_composite(c0a, (160 - (bbH[0] + bbH[2]) // 2, 0))
    frames.append(f)
    return frames

frames = build()
# frame terakhir: pose idle persis (bbox 34..247 pada sheet idle), tengah kanvas, tanpa ranjang di bawahnya
out = Image.new('RGBA', (CELL_W * N, CELL_H), (0, 0, 0, 0))
for i, f in enumerate(frames):
    out.paste(f, (i * CELL_W, 0))
out.save(OUT)
# sheet idle lebar (4 frame, 320x282) dengan penempatan yang sama dengan frame terakhir animasi bangun
bb0 = c0a.getbbox()
off = 160 - (bb0[0] + bb0[2]) // 2
idle = Image.new('RGBA', (CELL_W * 4, CELL_H), (0, 0, 0, 0))
for i, fr in enumerate([c0a, c1a, c2, c3a]):
    idle.alpha_composite(fr, (i * CELL_W + off, 0))
idle.save('screens/tree-village/assets/adek-idle-wide.png')
print('ok', out.size, 'offset', off)
