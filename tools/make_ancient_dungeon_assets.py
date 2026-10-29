#!/usr/bin/env python3
"""
Membuat semua aset Ancient Dungeon (gaya piksel, garis tepi gelap, 2-3 nada warna):

  screens/macro-map/images/ancient-dungeon.png   ikon di peta dunia
  screens/macro-map/images/road-north.png        jalan dari persimpangan ke Ancient Dungeon
  screens/ancient-dungeon/images/*               halaman depan dungeon (tempat Darkus berdiri)
  screens/ancient-dungeon/dungeon/*              bagian dalam dungeon
  screens/ancient-dungeon/darkus/idle-small.png  sprite Darkus berukuran game (dari idle.png asli)
  screens/ancient-dungeon/darkus/portrait.png    potret untuk kotak dialog
  common/fighters/enemies/<musuh>-*.png          varian warna musuh khusus dungeon

Jalankan dari folder proyek (butuh Pillow):   python3 tools/make_ancient_dungeon_assets.py
Semua gambar dibuat ulang dengan hasil yang sama setiap kali dijalankan (seed tetap).
"""
import colorsys
import math
import os
import random

from PIL import Image, ImageDraw, ImageFilter

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
MACRO = os.path.join(ROOT, "screens", "macro-map", "images")
FRONT = os.path.join(ROOT, "screens", "ancient-dungeon", "images")
INSIDE = os.path.join(ROOT, "screens", "ancient-dungeon", "dungeon")
DARKUS = os.path.join(ROOT, "screens", "ancient-dungeon", "darkus")
ENEMIES = os.path.join(ROOT, "common", "fighters", "enemies")

INK = (20, 16, 28, 255)
STONE_D = (62, 62, 84, 255)
STONE_M = (92, 94, 118, 255)
STONE_L = (132, 134, 158, 255)
STONE_XL = (170, 172, 194, 255)
MOSS = (70, 112, 84, 255)
GLOW = (120, 230, 220, 255)
VOID = (16, 12, 28, 255)
VOID_GLOW = (88, 44, 132, 255)

NEIGHBORS4 = [(1, 0), (-1, 0), (0, 1), (0, -1)]


def new(w, h, fill=(0, 0, 0, 0)):
    return Image.new("RGBA", (w, h), fill)


def save(img, folder, name):
    os.makedirs(folder, exist_ok=True)
    img.save(os.path.join(folder, name))


def jitter(color, rng, amount=8):
    d = rng.randint(-amount, amount)
    return tuple(max(0, min(255, c + d)) for c in color[:3]) + (color[3] if len(color) > 3 else 255,)


def speckle(img, rng, palette, density, box=None):
    """Taburkan piksel acak dari palette di atas piksel yang sudah terisi."""
    px = img.load()
    x0, y0, x1, y1 = box if box else (0, 0, img.width, img.height)
    for x in range(x0, x1):
        for y in range(y0, y1):
            if px[x, y][3] > 0 and rng.random() < density:
                px[x, y] = rng.choice(palette)


def outline(img, color=INK):
    """Tambah garis tepi 1 piksel di sekeliling bagian yang terisi (kanvas diberi ruang)."""
    w, h = img.size
    out = new(w, h)
    src = img.load()
    dst = out.load()
    for x in range(w):
        for y in range(h):
            if src[x, y][3] == 0:
                for dx, dy in NEIGHBORS4:
                    nx, ny = x + dx, y + dy
                    if 0 <= nx < w and 0 <= ny < h and src[nx, ny][3] > 200:
                        dst[x, y] = color
                        break
    out.alpha_composite(img)
    return out


def shadow_ellipse(img, box, alpha=70):
    layer = new(*img.size)
    ImageDraw.Draw(layer).ellipse(box, fill=(60, 60, 60, alpha))
    layer.alpha_composite(img)
    return layer


# ---------------------------------------------------------------- bagian-bagian kecil

def flame(draw, cx, base_y, height, shape=0):
    """Api piksel: luar merah, tengah oranye, inti kuning."""
    sway = (-1, 0, 1)[shape % 3]
    for i in range(height):
        t = i / max(1, height - 1)
        half = max(0, round((1 - t) * 3 - (1 if i > height - 3 else 0)))
        y = base_y - i
        off = round(sway * t * 2)
        draw.line([(cx - half + off, y), (cx + half + off, y)], fill=(224, 60, 40, 255))
        if half >= 1:
            draw.line([(cx - half + 1 + off, y), (cx + half - 1 + off, y)], fill=(255, 150, 40, 255))
        if half >= 2 and i < height - 3:
            draw.point((cx + off, y), fill=(255, 232, 130, 255))


def torch_frames():
    frames = []
    for f in range(3):
        fr = new(16, 32)
        d = ImageDraw.Draw(fr)
        d.rectangle([7, 14, 8, 30], fill=(70, 64, 82, 255))
        d.rectangle([4, 12, 11, 14], fill=(110, 104, 124, 255))
        d.rectangle([5, 14, 10, 15], fill=(60, 56, 72, 255))
        flame(d, 8, 12, 11 + (f % 2), f)
        d.rectangle([5, 30, 10, 31], fill=(54, 50, 64, 255))
        frames.append(outline(fr))
    sheet = new(48, 32)
    for i, fr in enumerate(frames):
        sheet.paste(fr, (i * 16, 0))
    return sheet


def crystal_frames():
    sheet = new(48, 32)
    for f in range(2):
        fr = new(24, 32)
        d = ImageDraw.Draw(fr)
        base = [(4, 30), (11, 12), (18, 30)]
        d.polygon(base, fill=(60, 120, 200, 255))
        d.polygon([(11, 12), (14, 30), (18, 30)], fill=(40, 90, 170, 255))
        d.polygon([(11, 12), (9, 22), (7, 30), (4, 30)], fill=(120, 190, 250, 255))
        d.polygon([(14, 30), (18, 20), (22, 30)], fill=(80, 150, 230, 255))
        d.polygon([(2, 30), (6, 22), (9, 30)], fill=(100, 170, 240, 255))
        glow = (200, 250, 255, 255) if f == 0 else (150, 230, 255, 255)
        d.point((10, 17), fill=glow)
        d.point((10, 18), fill=glow)
        d.point((19, 25 - f), fill=glow)
        sheet.paste(outline(fr), (f * 24, 0))
    return sheet


def rune_circle():
    img = new(64, 32)
    d = ImageDraw.Draw(img)
    d.ellipse([2, 4, 61, 29], outline=(90, 220, 214, 150), width=2)
    d.ellipse([9, 8, 54, 25], outline=(150, 120, 240, 130), width=1)
    for i in range(8):
        a = i * math.pi / 4
        x = 32 + math.cos(a) * 26
        y = 16 + math.sin(a) * 10
        d.rectangle([x - 1, y - 1, x + 1, y + 1], fill=(170, 255, 245, 200))
    d.line([(32, 9), (32, 23)], fill=(150, 240, 235, 140))
    d.line([(20, 16), (44, 16)], fill=(150, 240, 235, 140))
    return img


def bones():
    img = new(32, 16)
    d = ImageDraw.Draw(img)
    bone = (226, 220, 200, 255)
    d.line([(3, 12), (14, 9)], fill=bone, width=2)
    d.line([(8, 6), (20, 13)], fill=bone, width=2)
    d.ellipse([19, 3, 27, 11], fill=bone)
    d.rectangle([21, 9, 25, 12], fill=bone)
    d.point((21, 6), fill=INK)
    d.point((24, 6), fill=INK)
    d.point((23, 9), fill=INK)
    return outline(img)


def rubble(rng):
    img = new(32, 24)
    d = ImageDraw.Draw(img)
    for (cx, cy, r) in [(9, 16, 6), (20, 17, 7), (15, 10, 5), (27, 20, 3)]:
        d.polygon([(cx - r, cy + 3), (cx - r + 2, cy - r + 2), (cx + 1, cy - r), (cx + r, cy - 1), (cx + r - 1, cy + 4)], fill=STONE_M)
        d.polygon([(cx - r + 2, cy - r + 2), (cx + 1, cy - r), (cx + 3, cy - 2), (cx - 2, cy)], fill=STONE_L)
    speckle(img, rng, [STONE_D, STONE_L], 0.08)
    return outline(img)


def pillar(height, broken, rng):
    w = 32
    img = new(w, height)
    d = ImageDraw.Draw(img)
    top = 6 if not broken else 14
    d.rectangle([6, height - 8, 25, height - 2], fill=STONE_M)
    d.rectangle([6, height - 8, 25, height - 6], fill=STONE_L)
    d.rectangle([9, top, 22, height - 8], fill=STONE_M)
    d.rectangle([9, top, 13, height - 8], fill=STONE_L)
    d.rectangle([19, top, 22, height - 8], fill=STONE_D)
    if not broken:
        d.rectangle([5, 2, 26, 8], fill=STONE_M)
        d.rectangle([5, 2, 26, 4], fill=STONE_XL)
    else:
        d.polygon([(9, top), (12, top - 6), (15, top - 1), (18, top - 8), (22, top)], fill=STONE_M)
        d.polygon([(9, top), (12, top - 6), (14, top)], fill=STONE_L)
    for y in range(top + 6, height - 10, 9):
        d.line([(9, y), (22, y)], fill=STONE_D)
    speckle(img, rng, [STONE_D, STONE_L, MOSS], 0.06)
    return outline(img)


def dead_tree(rng):
    img = new(64, 96)
    d = ImageDraw.Draw(img)
    bark, bark_d, bark_l = (82, 66, 74, 255), (56, 44, 54, 255), (110, 92, 98, 255)
    d.polygon([(26, 92), (29, 52), (33, 52), (39, 92)], fill=bark)
    d.polygon([(26, 92), (29, 52), (31, 52), (31, 92)], fill=bark_l)
    d.polygon([(35, 92), (33, 52), (33, 52), (39, 92)], fill=bark_d)
    branches = [((30, 56), (12, 34), 3), ((32, 52), (50, 28), 3), ((31, 60), (52, 50), 2),
                ((30, 62), (8, 56), 2), ((12, 34), (6, 20), 2), ((50, 28), (58, 14), 2),
                ((24, 40), (20, 22), 2), ((38, 40), (40, 16), 2)]
    for (a, b, wd) in branches:
        d.line([a, b], fill=bark, width=wd)
        d.line([(a[0] - 1, a[1]), (b[0] - 1, b[1])], fill=bark_l, width=1)
    speckle(img, rng, [bark_d, bark_l], 0.07)
    return outline(img)


# ---------------------------------------------------------------- ubin

def ground_tile(rng):
    img = new(96, 96, (72, 68, 84, 255))
    px = img.load()
    pal = [(66, 62, 78, 255), (78, 74, 90, 255), (60, 57, 72, 255), (84, 80, 96, 255)]
    for x in range(96):
        for y in range(96):
            if rng.random() < 0.28:
                px[x, y] = rng.choice(pal)
    d = ImageDraw.Draw(img)
    for _ in range(9):
        cx, cy, r = rng.randint(0, 95), rng.randint(0, 95), rng.randint(2, 4)
        for ox in (-96, 0, 96):
            for oy in (-96, 0, 96):
                d.ellipse([cx + ox - r, cy + oy - r + 1, cx + ox + r, cy + oy + r], fill=(94, 90, 108, 255))
                d.ellipse([cx + ox - r, cy + oy - r, cx + ox + r - 1, cy + oy + r - 2], fill=(110, 106, 126, 255))
    return img


def flagstone(rng):
    img = new(32, 32, (122, 118, 138, 255))
    d = ImageDraw.Draw(img)
    d.rectangle([0, 0, 31, 31], outline=(86, 82, 104, 255))
    d.line([(0, 15), (31, 15)], fill=(86, 82, 104, 255))
    d.line([(15, 0), (15, 15)], fill=(86, 82, 104, 255))
    d.line([(23, 15), (23, 31)], fill=(86, 82, 104, 255))
    speckle(img, rng, [(138, 134, 154, 255), (106, 102, 124, 255)], 0.12)
    return img


def rockwall(rng):
    """Blok tebing / batu untuk pagar halaman (bisa ditabrak)."""
    img = new(32, 32, STONE_M)
    d = ImageDraw.Draw(img)
    d.rectangle([0, 0, 31, 9], fill=STONE_L)
    d.rectangle([0, 24, 31, 31], fill=STONE_D)
    d.polygon([(0, 10), (8, 14), (14, 10), (22, 16), (31, 11), (31, 24), (0, 24)], fill=STONE_M)
    for (x0, y0, x1, y1) in [(4, 6, 10, 16), (18, 4, 25, 12), (12, 18, 20, 26)]:
        d.line([(x0, y0), (x1, y1)], fill=STONE_D)
    speckle(img, rng, [STONE_D, STONE_L, jitter(STONE_M, rng)], 0.12)
    d.line([(0, 31), (31, 31)], fill=INK)
    return img


def dungeon_floor(rng):
    """64x64 = 4 ubin lantai 32x32 (variasi: polos, retak, lumut, retak halus)."""
    sheet = new(64, 64)
    for v in range(4):
        tile = new(32, 32, (68, 66, 90, 255))
        d = ImageDraw.Draw(tile)
        d.rectangle([0, 0, 31, 31], outline=(50, 48, 70, 255))
        d.line([(0, 16), (31, 16)], fill=(52, 50, 72, 255))
        d.line([(16 if v % 2 == 0 else 11, 0), (16 if v % 2 == 0 else 11, 16)], fill=(52, 50, 72, 255))
        d.line([(22, 16), (22, 31)], fill=(52, 50, 72, 255))
        speckle(tile, rng, [(80, 78, 104, 255), (58, 56, 80, 255)], 0.14)
        if v == 1:
            d.line([(4, 5), (9, 10), (7, 14), (13, 19)], fill=(40, 38, 58, 255))
        if v == 2:
            for _ in range(10):
                x, y = rng.randint(2, 29), rng.randint(2, 29)
                d.rectangle([x, y, x + 1, y], fill=MOSS)
        if v == 3:
            d.line([(20, 20), (25, 25), (23, 29)], fill=(40, 38, 58, 255))
        sheet.paste(tile, ((v % 2) * 32, (v // 2) * 32))
    return sheet


def dungeon_wall(rng):
    img = new(32, 32, (52, 50, 72, 255))
    d = ImageDraw.Draw(img)
    d.rectangle([0, 0, 31, 7], fill=(70, 68, 94, 255))
    d.rectangle([0, 8, 31, 9], fill=(40, 38, 58, 255))
    brick = (64, 62, 88, 255)
    for row, y in enumerate((10, 17, 24)):
        d.rectangle([0, y, 31, y + 5], fill=brick)
        off = 0 if row % 2 == 0 else 8
        for x in range(off, 32, 16):
            d.line([(x, y), (x, y + 6)], fill=(40, 38, 58, 255))
        d.line([(0, y + 6), (31, y + 6)], fill=(40, 38, 58, 255))
    speckle(img, rng, [(76, 74, 100, 255), (46, 44, 64, 255), (72, 90, 84, 255)], 0.07)
    return img


def stairs():
    img = new(64, 48)
    d = ImageDraw.Draw(img)
    d.rectangle([4, 0, 59, 47], fill=(44, 42, 62, 255))
    for i in range(5):
        y = 4 + i * 8
        shade = 150 - i * 16
        d.rectangle([8 + i * 2, y, 55 - i * 2, y + 6], fill=(shade, shade, shade + 24, 255))
        d.line([(8 + i * 2, y + 7), (55 - i * 2, y + 7)], fill=(40, 38, 58, 255))
    return outline(img)


# ---------------------------------------------------------------- gerbang

def gate(rng):
    w, h = 192, 128
    img = new(w, h)
    d = ImageDraw.Draw(img)
    # tubuh gerbang
    d.rectangle([4, 24, 187, 123], fill=STONE_M)
    d.rectangle([4, 24, 187, 34], fill=STONE_L)
    d.rectangle([4, 110, 187, 123], fill=STONE_D)
    # gigi-gigi atas
    for x in range(4, 188, 24):
        d.rectangle([x, 12, x + 15, 24], fill=STONE_M)
        d.rectangle([x, 12, x + 15, 15], fill=STONE_L)
    # susunan bata
    for row, y in enumerate(range(40, 110, 14)):
        d.line([(4, y), (187, y)], fill=STONE_D)
        off = 0 if row % 2 == 0 else 12
        for x in range(4 + off, 188, 24):
            d.line([(x, y), (x, y + 14)], fill=STONE_D)
    speckle(img, rng, [STONE_L, STONE_D, MOSS], 0.06, (4, 24, 188, 124))
    # tiang pembingkai lengkungan
    d.rectangle([54, 40, 70, 123], fill=STONE_L)
    d.rectangle([122, 40, 138, 123], fill=STONE_L)
    d.rectangle([54, 40, 57, 123], fill=STONE_XL)
    d.rectangle([135, 40, 138, 123], fill=STONE_M)
    # lengkungan: lingkaran besar di atas pintu
    d.pieslice([54, 22, 138, 92], 180, 360, fill=STONE_L)
    d.pieslice([62, 30, 130, 92], 180, 360, fill=STONE_XL)
    # lubang gerbang (gelap + cahaya ungu dari dalam)
    d.pieslice([70, 38, 122, 90], 180, 360, fill=VOID)
    d.rectangle([70, 64, 121, 123], fill=VOID)
    for i in range(18):
        t = i / 17
        c = tuple(int(VOID[k] + (VOID_GLOW[k] - VOID[k]) * t * t) for k in range(3)) + (255,)
        d.line([(71, 123 - i), (120, 123 - i)], fill=c)
    # anak tangga
    d.rectangle([60, 116, 131, 123], fill=STONE_L)
    d.rectangle([66, 110, 125, 115], fill=STONE_XL)
    # rune bercahaya di sisi
    for (x, y) in [(26, 56), (26, 80), (160, 56), (160, 80)]:
        d.rectangle([x, y, x + 5, y + 13], outline=GLOW, width=1)
        d.line([(x + 2, y + 3), (x + 2, y + 10)], fill=GLOW)
        d.line([(x, y + 7), (x + 5, y + 7)], fill=GLOW)
    # kepala batu di puncak lengkungan
    d.ellipse([88, 24, 104, 40], fill=STONE_XL)
    d.rectangle([91, 30, 93, 32], fill=VOID)
    d.rectangle([99, 30, 101, 32], fill=VOID)
    d.rectangle([94, 35, 98, 36], fill=VOID)
    return outline(img)


# ---------------------------------------------------------------- ikon peta dunia

def macro_icon(rng):
    w, h = 192, 176
    obj = new(w, h)
    d = ImageDraw.Draw(obj)
    # bukit batu
    hill = [(10, 150), (22, 110), (46, 76), (78, 48), (96, 40), (118, 48), (148, 76), (172, 110), (184, 150)]
    d.polygon(hill, fill=STONE_M)
    d.polygon([(46, 76), (78, 48), (96, 40), (118, 48), (148, 76), (132, 92), (60, 92)], fill=STONE_L)
    d.polygon([(10, 150), (22, 128), (60, 134), (60, 150)], fill=STONE_D)
    d.polygon([(184, 150), (172, 128), (130, 134), (130, 150)], fill=STONE_D)
    speckle(obj, rng, [STONE_D, STONE_L, MOSS], 0.1)
    # celah retakan
    for (a, b) in [((52, 84), (60, 104)), ((140, 84), (132, 108)), ((96, 52), (100, 70))]:
        d.line([a, b], fill=STONE_D)
    # gerbang
    d.rectangle([64, 86, 128, 150], fill=STONE_L)
    d.rectangle([64, 86, 128, 92], fill=STONE_XL)
    d.pieslice([70, 78, 122, 126], 180, 360, fill=STONE_XL)
    d.pieslice([76, 84, 116, 124], 180, 360, fill=VOID)
    d.rectangle([76, 104, 115, 150], fill=VOID)
    for i in range(14):
        t = i / 13
        c = tuple(int(VOID[k] + (VOID_GLOW[k] - VOID[k]) * t * t) for k in range(3)) + (255,)
        d.line([(77, 150 - i), (114, 150 - i)], fill=c)
    # tangga
    d.rectangle([70, 146, 122, 154], fill=STONE_L)
    d.rectangle([64, 152, 128, 158], fill=STONE_M)
    # dua obor di sisi gerbang
    for cx in (52, 140):
        d.rectangle([cx - 1, 118, cx, 148], fill=(70, 64, 82, 255))
        d.rectangle([cx - 4, 114, cx + 3, 118], fill=(110, 104, 124, 255))
        flame(d, cx, 113, 13, 1)
    # tengkorak penjaga di atas
    d.ellipse([88, 52, 104, 68], fill=STONE_XL)
    d.rectangle([91, 58, 93, 61], fill=VOID)
    d.rectangle([99, 58, 101, 61], fill=VOID)
    d.rectangle([94, 64, 98, 65], fill=VOID)
    obj = outline(obj)
    # pohon mati di kiri-kanan (digambar terpisah agar ikut bergaris tepi)
    tree = dead_tree(rng).resize((40, 60), Image.NEAREST)
    obj.alpha_composite(tree, (2, 92))
    obj.alpha_composite(tree.transpose(Image.FLIP_LEFT_RIGHT), (150, 96))
    return shadow_ellipse(obj, (2, 128, 189, 172), 70)


def macro_road():
    """Strip jalan vertikal 32x192 (y -256 .. -64 di peta) dengan persimpangan ke barat di bawah."""
    sand = (170, 159, 125, 255)
    edge1 = (196, 162, 50, 255)
    edge2 = (155, 133, 62, 255)
    rng = random.Random(7)
    img = new(32, 192)
    px = img.load()
    left, right = 7, 24
    open_from, open_to = 166, 186      # bukaan ke jalan barat
    for y in range(192):
        for x in range(left, right + 1):
            px[x, y] = sand
    for y in range(0, 192):
        for x, side in ((left - 1, "l"), (right + 1, "r")):
            if side == "l" and open_from <= y <= open_to:
                continue
            px[x, y] = rng.choice([edge1, edge2])
    # tutup ujung atas jalan
    for x in range(left - 1, right + 2):
        px[x, 0] = rng.choice([edge1, edge2])
    # bukaan barat harus menyambung ke pita jalan barat: isi pasir sampai tepi kiri
    for y in range(open_from, open_to + 1):
        for x in range(0, left):
            px[x, y] = sand
    for x in range(0, left):
        px[x, open_from - 1] = rng.choice([edge1, edge2])
        px[x, open_to + 1] = rng.choice([edge1, edge2])
    return img


# ---------------------------------------------------------------- Darkus

def darkus_small():
    src = Image.open(os.path.join(DARKUS, "idle.png")).convert("RGBA")
    fw = src.width // 5
    frames = [src.crop((i * fw, 0, (i + 1) * fw, src.height)) for i in range(5)]
    left = min(f.getbbox()[0] for f in frames)
    top = min(f.getbbox()[1] for f in frames)
    right = max(f.getbbox()[2] for f in frames)
    bottom = max(f.getbbox()[3] for f in frames)
    target_h = 44
    scale = target_h / (bottom - top)
    out_w, out_h = 32, 48
    sheet = new(out_w * 5, out_h)
    for i, fr in enumerate(frames):
        crop = fr.crop((left, top, right, bottom))
        small = crop.resize((max(1, round(crop.width * scale)), target_h), Image.LANCZOS)
        px = small.load()
        for x in range(small.width):
            for y in range(small.height):
                r, g, b, a = px[x, y]
                px[x, y] = (r, g, b, 255 if a >= 128 else 0)
        cell = new(out_w, out_h)
        cell.alpha_composite(small, ((out_w - small.width) // 2, out_h - target_h - 1))
        sheet.paste(cell, (i * out_w, 0))
    save(sheet, DARKUS, "idle-small.png")

    first = frames[0].crop((left, top, right, top + int((bottom - top) * 0.72)))
    scale = min(95 / first.width, 125 / first.height)
    portrait = first.resize((round(first.width * scale), round(first.height * scale)), Image.LANCZOS)
    px = portrait.load()
    for x in range(portrait.width):
        for y in range(portrait.height):
            r, g, b, a = px[x, y]
            px[x, y] = (r, g, b, 255 if a >= 110 else 0)
    save(portrait, DARKUS, "portrait.png")


# ---------------------------------------------------------------- musuh varian dungeon

def hue_shift_sheet(path_in, path_out, degrees, sat=1.0, val=1.0):
    img = Image.open(path_in).convert("RGBA")
    px = img.load()
    for x in range(img.width):
        for y in range(img.height):
            r, g, b, a = px[x, y]
            if a == 0:
                continue
            h, s, v = colorsys.rgb_to_hsv(r / 255, g / 255, b / 255)
            h = (h + degrees / 360.0) % 1.0
            s = min(1.0, s * sat)
            v = min(1.0, v * val)
            nr, ng, nb = colorsys.hsv_to_rgb(h, s, v)
            px[x, y] = (round(nr * 255), round(ng * 255), round(nb * 255), a)
    img.save(path_out)


ENEMY_VARIANTS = [
    # (sprite asli, sprite baru, geser hue, saturasi, kecerahan)
    ("bat", "cavebat", 285, 0.95, 1.15),      # ungu -> biru kehijauan
    ("snake", "nightsnake", 160, 0.9, 0.72),  # hijau -> ungu gelap
    ("imp", "frostimp", 170, 0.9, 1.0),       # merah -> biru es
    ("leak", "flameleak", 215, 1.0, 1.1),     # cyan -> oranye
]


def enemy_variants():
    for (src, dst, deg, sat, val) in ENEMY_VARIANTS:
        for part in ("idle", "attack", "damage", "die"):
            hue_shift_sheet(os.path.join(ENEMIES, "%s-%s.png" % (src, part)),
                            os.path.join(ENEMIES, "%s-%s.png" % (dst, part)), deg, sat, val)


# ---------------------------------------------------------------- jalankan semua

def main():
    rng = random.Random(2026)
    save(macro_icon(rng), MACRO, "ancient-dungeon.png")
    save(macro_road(), MACRO, "road-north.png")

    save(ground_tile(rng), FRONT, "ground.png")
    save(flagstone(rng), FRONT, "flagstone.png")
    save(rockwall(rng), FRONT, "rockwall.png")
    save(gate(rng), FRONT, "gate.png")
    save(pillar(64, False, rng), FRONT, "pillar.png")
    save(pillar(44, True, rng), FRONT, "pillar-broken.png")
    save(torch_frames(), FRONT, "torch.png")
    save(crystal_frames(), FRONT, "crystal.png")
    save(rune_circle(), FRONT, "rune.png")
    save(dead_tree(rng), FRONT, "deadtree.png")
    save(bones(), FRONT, "bones.png")
    save(rubble(rng), FRONT, "rubble.png")

    save(dungeon_floor(rng), INSIDE, "floor.png")
    save(dungeon_wall(rng), INSIDE, "wall.png")
    save(stairs(), INSIDE, "stairs.png")

    darkus_small()
    enemy_variants()
    print("selesai")


if __name__ == "__main__":
    main()
