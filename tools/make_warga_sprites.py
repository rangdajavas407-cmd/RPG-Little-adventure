#!/usr/bin/env python3
"""Membuat sprite warga desa (pixel art 32x32) untuk epilog sinematik.

Hasil: screens/ending/assets/warga-{1..5}.png
Tiap file = satu baris frame 32x32:
    frame  0-3  : idle   (napas naik-turun + berkedip)
    frame  4-9  : walk   (6 frame)
    frame 10-13 : cheer  (tangan terangkat, melompat kecil, mata ^ ^)

Warga:
    1 Pak Wayan   : bapak bertopi caping
    2 Bu Made     : ibu berkebaya dengan sanggul
    3 Kadek       : pemuda berudeng merah
    4 Nenek Nyoman: nenek berkacamata dengan selendang ungu dan tongkat
    5 Putu        : anak kecil berkuncir dua

Jalankan:  python3 tools/make_warga_sprites.py
"""
import os
from PIL import Image, ImageDraw

OUT = (38, 28, 46, 255)
CLEAR = (0, 0, 0, 0)
WHITE = (255, 255, 255, 255)
EYE = (36, 26, 44, 255)
BLUSH = (255, 140, 150, 255)
MOUTH = (120, 40, 50, 255)
TONGUE = (240, 110, 120, 255)

FRAME = 32
OUT_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "screens", "ending", "assets")


def rgb(r, g, b):
    return (r, g, b, 255)


def shade(c, f):
    return (max(0, min(255, int(c[0] * f))), max(0, min(255, int(c[1] * f))), max(0, min(255, int(c[2] * f))), 255)


SPECS = {
    1: dict(  # Pak Wayan
        skin=rgb(222, 170, 120), hy=0, outfit=rgb(236, 234, 222), vest=rgb(122, 82, 51), pants=rgb(88, 72, 60),
        shoes=rgb(70, 50, 40), kind="caping", dress=False),
    2: dict(  # Bu Made
        skin=rgb(240, 198, 162), hy=0, outfit=rgb(205, 62, 84), pants=rgb(122, 72, 42), shoes=rgb(70, 40, 40),
        hair=rgb(44, 32, 44), kind="ibu", dress=True),
    3: dict(  # Kadek
        skin=rgb(208, 152, 108), hy=0, outfit=rgb(62, 112, 182), pants=rgb(52, 52, 74), shoes=rgb(60, 44, 40),
        hair=rgb(36, 28, 36), kind="pemuda", dress=False),
    4: dict(  # Nenek Nyoman
        skin=rgb(236, 192, 164), hy=1, outfit=rgb(142, 98, 192), pants=rgb(62, 102, 112), shoes=rgb(80, 60, 60),
        hair=rgb(228, 228, 238), kind="nenek", dress=True),
    5: dict(  # Putu
        skin=rgb(246, 208, 174), hy=3, outfit=rgb(242, 202, 78), pants=rgb(242, 202, 78), shoes=rgb(150, 80, 70),
        hair=rgb(112, 72, 42), kind="anak", dress=True),
}


def ellipse(d, box, fill):
    d.ellipse(box, fill=fill)


def draw_char(spec, pose, t):
    """pose: idle / walk / cheer; t = nomor frame dalam pose."""
    im = Image.new("RGBA", (FRAME, FRAME), CLEAR)
    d = ImageDraw.Draw(im)
    hy = spec["hy"]
    skin = spec["skin"]
    skin_sh = shade(skin, 0.82)
    outfit = spec["outfit"]
    outfit_sh = shade(outfit, 0.78)
    outfit_hi = shade(outfit, 1.12)

    # ---- gerak per pose ----
    dy = 0
    lf = rf = 0          # angkat kaki kiri / kanan
    arm_l = arm_r = 0    # ayunan tangan
    blink = False
    arms_up = False
    if pose == "idle":
        dy = [0, 0, 1, 0][t]
        blink = (t == 3)
    elif pose == "walk":
        dy = [0, -1, 0, 0, -1, 0][t]
        lf = [0, 1, 2, 0, 0, 0][t]
        rf = [0, 0, 0, 0, 1, 2][t]
        arm_l = [0, 1, 1, 0, -1, -1][t]
        arm_r = -arm_l
    elif pose == "cheer":
        dy = [0, -1, 0, -1][t]
        arms_up = True

    top = 19 + hy + dy   # puncak badan
    base = 28            # alas badan

    # ---- kaki ----
    if not spec["dress"] or spec["kind"] == "anak":
        d.rectangle((11, base - 3, 14, base - lf), fill=spec["pants"])
        d.rectangle((17, base - 3, 20, base - rf), fill=spec["pants"])
    d.rectangle((10, 28 - lf, 14, 29 - lf), fill=spec["shoes"])
    d.rectangle((17, 28 - rf, 21, 29 - rf), fill=spec["shoes"])

    # ---- badan ----
    if spec["dress"]:
        d.polygon([(10, top), (21, top), (23, base), (8, base)], fill=outfit)
        d.polygon([(19, top), (21, top), (23, base), (20, base)], fill=outfit_sh)
        d.line((11, top, 11, base - 1), fill=outfit_hi)
    else:
        d.rectangle((10, top, 21, base - 3), fill=outfit)
        d.rectangle((19, top, 21, base - 3), fill=outfit_sh)
        d.line((11, top, 11, base - 4), fill=outfit_hi)

    kind = spec["kind"]
    if kind == "caping":
        d.rectangle((10, top, 12, base - 3), fill=spec["vest"])
        d.rectangle((19, top, 21, base - 3), fill=shade(spec["vest"], 0.8))
        d.rectangle((15, top, 16, base - 3), fill=spec["outfit"])
    elif kind == "ibu":
        # kerah V + bros emas, kain batik di bawah
        d.polygon([(14, top), (17, top), (15.5, top + 3)], fill=outfit_hi)
        d.point((15, top + 4), fill=rgb(250, 214, 90))
        d.rectangle((8, base - 4, 23, base), fill=spec["pants"])
        for x in (10, 14, 18, 21):
            d.point((x, base - 2), fill=rgb(214, 172, 92))
        d.point((12, base - 3), fill=rgb(214, 172, 92)); d.point((16, base - 3), fill=rgb(214, 172, 92))
        d.rectangle((9, base - 1, 22, base), fill=shade(spec["pants"], 0.85))
    elif kind == "pemuda":
        d.line((15, top, 15, base - 4), fill=rgb(230, 236, 250))
        d.rectangle((10, base - 4, 21, base - 3), fill=rgb(120, 74, 44))  # ikat pinggang
    elif kind == "nenek":
        # selendang ungu melintang + rumbai
        d.polygon([(10, top), (21, top), (21, top + 3), (10, top + 6)], fill=outfit_hi)
        d.line((10, top + 6, 21, top + 3), fill=shade(outfit, 0.7))
        d.rectangle((8, base - 4, 23, base), fill=spec["pants"])
        d.rectangle((9, base - 1, 22, base), fill=shade(spec["pants"], 0.8))
    elif kind == "anak":
        d.rectangle((11, top, 20, top + 1), fill=WHITE)  # kerah putih
        d.point((15, top + 2), fill=rgb(240, 120, 150)); d.point((16, top + 2), fill=rgb(240, 120, 150))

    # ---- tangan ----
    if arms_up:
        d.line((9, top + 2, 5, top - 7), fill=outfit, width=2)
        d.line((22, top + 2, 26, top - 7), fill=outfit, width=2)
        d.rectangle((3, top - 10, 6, top - 7), fill=skin)
        d.rectangle((25, top - 10, 28, top - 7), fill=skin)
    else:
        ly = top + 2 + arm_l
        ry = top + 2 + arm_r
        d.rectangle((7, ly, 9, ly + 5), fill=outfit)
        d.rectangle((22, ry, 24, ry + 5), fill=outfit_sh)
        d.rectangle((7, ly + 5, 9, ly + 7), fill=skin)
        d.rectangle((22, ry + 5, 24, ry + 7), fill=skin_sh)
        if kind == "nenek":  # tongkat di tangan kiri
            d.line((6, ly + 6, 6, 29), fill=rgb(120, 80, 50))

    # ---- kepala ----
    hb = 5 + hy + dy
    d.ellipse((7, hb, 24, hb + 15), fill=skin_sh)
    d.ellipse((7, hb, 23, hb + 14), fill=skin)

    # rambut / topi
    if kind == "caping":
        straw = rgb(226, 190, 100)
        d.polygon([(16, hb - 4), (4, hb + 5), (28, hb + 5)], fill=straw)
        d.polygon([(16, hb - 4), (28, hb + 5), (20, hb + 5)], fill=shade(straw, 0.84))
        d.ellipse((2, hb + 3, 30, hb + 8), fill=shade(straw, 1.05))
        d.line((4, hb + 5, 28, hb + 5), fill=rgb(160, 110, 54))
        d.line((16, hb - 3, 8, hb + 3), fill=shade(straw, 1.15))
    elif kind in ("ibu", "nenek", "anak", "pemuda"):
        hair = spec["hair"]
        mask = Image.new("L", (FRAME, FRAME), 0)
        md = ImageDraw.Draw(mask)
        md.ellipse((6, hb - 1, 25, hb + 15), fill=255)
        md.ellipse((8, hb + 4, 23, hb + 20), fill=0)
        layer = Image.new("RGBA", (FRAME, FRAME), hair)
        im.paste(layer, (0, 0), mask)
        d = ImageDraw.Draw(im)
        d.line((9, hb + 1, 14, hb), fill=shade(hair, 1.4))
        if kind == "ibu":
            d.ellipse((12, hb - 5, 20, hb + 1), fill=hair)
            d.line((14, hb - 4, 17, hb - 4), fill=shade(hair, 1.5))
            d.point((16, hb - 2), fill=rgb(250, 214, 90))
        elif kind == "nenek":
            d.ellipse((11, hb - 6, 21, hb + 1), fill=hair)
            d.line((13, hb - 5, 17, hb - 5), fill=WHITE)
            d.point((16, hb - 2), fill=rgb(150, 150, 170))
        elif kind == "anak":
            d.ellipse((3, hb + 1, 9, hb + 7), fill=hair)
            d.ellipse((22, hb + 1, 28, hb + 7), fill=hair)
            d.point((5, hb + 2), fill=shade(hair, 1.5))
            d.polygon([(14, hb - 2), (16, hb), (18, hb - 2), (16, hb - 1)], fill=rgb(240, 120, 150))
            d.rectangle((15, hb - 2, 17, hb), fill=rgb(240, 120, 150))
        elif kind == "pemuda":
            for x, h in ((9, 3), (12, 5), (16, 6), (20, 5), (22, 3)):
                d.polygon([(x - 1, hb + 1), (x + 1, hb + 1), (x, hb - h + 1)], fill=hair)
            # udeng merah + hiasan emas
            d.rectangle((7, hb + 3, 24, hb + 5), fill=rgb(190, 50, 45))
            d.line((7, hb + 5, 24, hb + 5), fill=rgb(130, 30, 32))
            d.point((16, hb + 4), fill=rgb(250, 214, 90))
            d.polygon([(23, hb + 3), (27, hb + 1), (27, hb + 6), (23, hb + 5)], fill=rgb(190, 50, 45))

    # ---- wajah ----
    ey = hb + 7
    if kind == "anak":
        ey = hb + 6
    if pose == "cheer":
        for ex in (11, 18):
            d.point((ex, ey + 1), fill=EYE); d.point((ex + 1, ey), fill=EYE); d.point((ex + 2, ey + 1), fill=EYE)
        d.rectangle((14, ey + 4, 17, ey + 6), fill=MOUTH)
        d.rectangle((15, ey + 6, 16, ey + 6), fill=TONGUE)
    else:
        if blink:
            d.line((11, ey + 1, 13, ey + 1), fill=EYE)
            d.line((18, ey + 1, 20, ey + 1), fill=EYE)
        else:
            d.rectangle((12, ey - 1, 13, ey + 2), fill=EYE)
            d.rectangle((18, ey - 1, 19, ey + 2), fill=EYE)
            d.point((12, ey - 1), fill=WHITE); d.point((18, ey - 1), fill=WHITE)
        d.point((14, ey + 5), fill=MOUTH); d.point((15, ey + 6), fill=MOUTH)
        d.point((16, ey + 6), fill=MOUTH); d.point((17, ey + 5), fill=MOUTH)
    d.point((10, ey + 4), fill=BLUSH); d.point((11, ey + 4), fill=BLUSH)
    d.point((20, ey + 4), fill=BLUSH); d.point((21, ey + 4), fill=BLUSH)

    if kind == "caping":   # kumis
        d.rectangle((13, ey + 3, 18, ey + 3), fill=rgb(80, 62, 56))
    if kind == "nenek":    # kacamata bulat
        gl = rgb(96, 70, 60)
        d.rectangle((11, ey - 2, 14, ey + 3), outline=gl)
        d.rectangle((17, ey - 2, 20, ey + 3), outline=gl)
        d.line((15, ey, 16, ey), fill=gl)
    if kind == "ibu":      # anting emas
        d.point((7, ey + 5), fill=rgb(250, 214, 90)); d.point((23, ey + 5), fill=rgb(250, 214, 90))

    framed = Image.new("RGBA", (FRAME, FRAME), CLEAR)
    framed.paste(outline(im), (0, 1))   # turun 1 px: ruang untuk puncak topi/sanggul
    return framed


def outline(im):
    """Garis tepi gelap 1 px di sekeliling siluet (seperti sprite game lain)."""
    px = im.load()
    w, h = im.size
    out = im.copy()
    po = out.load()
    for y in range(h):
        for x in range(w):
            if px[x, y][3] == 0:
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    nx, ny = x + dx, y + dy
                    if 0 <= nx < w and 0 <= ny < h and px[nx, ny][3] > 0:
                        po[x, y] = OUT
                        break
    return out


def build(idx):
    spec = SPECS[idx]
    frames = []
    for t in range(4):
        frames.append(draw_char(spec, "idle", t))
    for t in range(6):
        frames.append(draw_char(spec, "walk", t))
    for t in range(4):
        frames.append(draw_char(spec, "cheer", t))
    sheet = Image.new("RGBA", (FRAME * len(frames), FRAME), CLEAR)
    for i, f in enumerate(frames):
        sheet.paste(f, (i * FRAME, 0))
    return sheet


def main():
    os.makedirs(OUT_DIR, exist_ok=True)
    for idx in SPECS:
        path = os.path.join(OUT_DIR, "warga-%d.png" % idx)
        build(idx).save(path)
        print("tulis", os.path.normpath(path))


if __name__ == "__main__":
    main()
