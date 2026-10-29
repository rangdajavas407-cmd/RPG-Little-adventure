#!/usr/bin/env python3
"""
Membuat sprite karakter utama yang memegang Tongkat Kayu, dari sprite Pedang Kayu aslinya.

  - frame serangan : piksel pedang (merah) + garis tepinya dihapus, lalu tongkat digambar
                     di sumbu & posisi tangan yang sama dengan pedangnya
  - frame diam/sakit: tongkat digambar berdiri di samping tubuh
  - "Serangan Api" pedang kayu: pedang diwarnai ulang jadi api

Jalankan dari folder proyek (butuh Pillow):   python3 tools/make_hero_skins.py
Hasil ada di common/fighters/hero/ dan common/characters/player/.
"""
import math
import os
from collections import Counter
from PIL import Image, ImageDraw

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
FIGHT_SRC = os.path.join(ROOT, "common", "fighters", "player")
FIGHT_OUT = os.path.join(ROOT, "common", "fighters", "hero")
MAP_DIR = os.path.join(ROOT, "common", "characters", "player")

OUTLINE = (52, 30, 28, 255)
WOOD_LIGHT = (176, 118, 66, 255)
WOOD_DARK = (122, 78, 46, 255)
ORB = (226, 62, 74, 255)
ORB_SHINE = (255, 176, 176, 255)

NEIGHBORS = [(-1, -1), (0, -1), (1, -1), (-1, 0), (1, 0), (-1, 1), (0, 1), (1, 1)]


def is_sword(p):
    r, g, b, a = p
    return a > 0 and r > b + 30 and r > g + 25


def is_dark(p):
    return p[3] > 0 and max(p[:3]) < 90


def frames_of(img, frame_w):
    return [img.crop((i * frame_w, 0, (i + 1) * frame_w, img.height)) for i in range(img.width // frame_w)]


def join(frames):
    out = Image.new("RGBA", (frames[0].width * len(frames), frames[0].height), (0, 0, 0, 0))
    for i, fr in enumerate(frames):
        out.paste(fr, (i * fr.width, 0))
    return out


def inside(fr, x, y):
    return 0 <= x < fr.width and 0 <= y < fr.height


def sword_pixels(fr):
    px = fr.load()
    return [(x, y) for x in range(fr.width) for y in range(fr.height) if is_sword(px[x, y])]


def erase_sword(fr, sword):
    """Hapus pedang dan garis tepi gelapnya, lalu tutup lubang di wajah."""
    px = fr.load()
    sword_set = set(sword)
    dark_count = lambda x, y: sum(1 for dx, dy in NEIGHBORS if inside(fr, x + dx, y + dy) and is_dark(px[x + dx, y + dy]))

    outline = set()
    for (x, y) in sword:
        for dx, dy in NEIGHBORS:
            nx, ny = x + dx, y + dy
            if inside(fr, nx, ny) and (nx, ny) not in sword_set and is_dark(px[nx, ny]) and dark_count(nx, ny) <= 4:
                outline.add((nx, ny))

    face_colors = Counter(px[x, y] for x in range(fr.width) for y in range(fr.height) if is_dark(px[x, y]))
    face = face_colors.most_common(1)[0][0] if face_colors else (20, 14, 40, 255)

    erased = sword_set | outline
    for (x, y) in erased:
        px[x, y] = (0, 0, 0, 0)

    # lubang di dalam wajah (pedang sempat menutupi wajah) diisi warna wajah
    for _ in range(2):
        fills = [(x, y) for (x, y) in erased if px[x, y][3] == 0 and dark_count(x, y) >= 4]
        for (x, y) in fills:
            px[x, y] = face

    # bintik gelap sisa garis tepi pedang (piksel gelap yang hampir tidak menempel apa pun) dibuang
    opaque_count = lambda x, y: sum(1 for dx, dy in NEIGHBORS if inside(fr, x + dx, y + dy) and px[x + dx, y + dy][3] > 0)
    for x in range(fr.width):
        for y in range(fr.height):
            if is_dark(px[x, y]) and opaque_count(x, y) <= 2:
                px[x, y] = (0, 0, 0, 0)


def sword_axis(sword, body_center):
    """Arah pedang: (ujung tangan, ujung tajam, panjang)."""
    n = len(sword)
    mx = sum(x for x, _ in sword) / n
    my = sum(y for _, y in sword) / n
    sxx = sum((x - mx) ** 2 for x, _ in sword)
    syy = sum((y - my) ** 2 for _, y in sword)
    sxy = sum((x - mx) * (y - my) for x, y in sword)
    angle = 0.5 * math.atan2(2 * sxy, sxx - syy)
    d = (math.cos(angle), math.sin(angle))
    ts = [((x - mx) * d[0] + (y - my) * d[1]) for x, y in sword]
    a = (mx + min(ts) * d[0], my + min(ts) * d[1])
    b = (mx + max(ts) * d[0], my + max(ts) * d[1])
    dist = lambda p: math.hypot(p[0] - body_center[0], p[1] - body_center[1])
    hand, tip = (a, b) if dist(a) <= dist(b) else (b, a)
    return hand, tip, math.hypot(tip[0] - hand[0], tip[1] - hand[1])


def draw_staff(fr, base, top):
    """Gambar tongkat dari base ke top (koordinat piksel), orb merah di ujung atas."""
    d = ImageDraw.Draw(fr)
    d.line([base, top], fill=OUTLINE, width=3)
    d.line([base, top], fill=WOOD_LIGHT, width=1)
    # sisi bawah batang sedikit lebih gelap supaya terlihat bulat
    d.line([(base[0] + 1, base[1]), (top[0] + 1, top[1])], fill=WOOD_DARK, width=1)
    ox, oy = round(top[0]), round(top[1])
    d.ellipse([ox - 3, oy - 3, ox + 3, oy + 3], fill=OUTLINE)
    d.ellipse([ox - 2, oy - 2, ox + 2, oy + 2], fill=ORB)
    d.point((ox - 1, oy - 1), fill=ORB_SHINE)


def staff_from_sword(fr):
    """Ganti pedang di frame serangan dengan tongkat di sumbu yang sama."""
    sword = sword_pixels(fr)
    if not sword:
        return fr
    px = fr.load()
    sword_set = set(sword)
    body = [(x, y) for x in range(fr.width) for y in range(fr.height) if px[x, y][3] > 0 and (x, y) not in sword_set]
    center = (sum(x for x, _ in body) / len(body), sum(y for _, y in body) / len(body))
    hand, tip, length = sword_axis(sword, center)
    erase_sword(fr, sword)
    ux, uy = (tip[0] - hand[0]) / length, (tip[1] - hand[1]) / length
    base = (hand[0] - ux * length * 0.45, hand[1] - uy * length * 0.45)
    # ujung atas boleh melewati ujung pedang, tapi orb harus tetap di dalam frame
    reach = length * 0.25
    while reach > 0:
        top = (tip[0] + ux * reach, tip[1] + uy * reach)
        if 4 <= top[0] <= fr.width - 5 and 4 <= top[1] <= fr.height - 5:
            break
        reach -= 0.5
    top = (tip[0] + ux * max(reach, 0), tip[1] + uy * max(reach, 0))
    top = (min(max(top[0], 4), fr.width - 5), min(max(top[1], 4), fr.height - 5))
    draw_staff(fr, base, top)
    return fr


def staff_held(fr):
    """Frame diam / terkena damage: tongkat berdiri di samping tubuh."""
    bbox = fr.getbbox()
    if bbox is None:
        return fr
    right, bottom = bbox[2], bbox[3]
    base = (right - 1, bottom - 2)
    top = (right + 2, bottom - 29)
    draw_staff(fr, base, top)
    return fr


def burning_sword(fr):
    """Pedang diwarnai ulang jadi api oranye-kuning (untuk Serangan Api)."""
    px = fr.load()
    for (x, y) in sword_pixels(fr):
        px[x, y] = (255, 214, 82, 255) if (x + y) % 2 == 0 else (255, 120, 28, 255)
    # percikan api di sekitar pedang
    sparks = [(x + dx, y + dy) for (x, y) in sword_pixels(fr)[::9] for dx, dy in ((0, -2), (2, 0))]
    for (x, y) in sparks:
        if inside(fr, x, y) and px[x, y][3] == 0:
            px[x, y] = (255, 236, 150, 255)
    return fr


def build_fighter_sheets():
    os.makedirs(FIGHT_OUT, exist_ok=True)
    load = lambda name: Image.open(os.path.join(FIGHT_SRC, name)).convert("RGBA")
    idle, dmg = frames_of(load("player-idle.png"), 64), frames_of(load("player-damage.png"), 64)
    atk1, atk2 = frames_of(load("player-attack1.png"), 64), frames_of(load("player-attack2.png"), 64)

    join([staff_held(f.copy()) for f in idle]).save(os.path.join(FIGHT_OUT, "staff-idle.png"))
    join([staff_held(f.copy()) for f in dmg]).save(os.path.join(FIGHT_OUT, "staff-damage.png"))
    join([staff_from_sword(f.copy()) for f in atk1]).save(os.path.join(FIGHT_OUT, "staff-attack-simple.png"))
    join([staff_from_sword(f.copy()) for f in atk2]).save(os.path.join(FIGHT_OUT, "staff-attack-advanced.png"))
    join([staff_from_sword(f.copy()) for f in atk2]).save(os.path.join(FIGHT_OUT, "staff-attack-special.png"))
    join([burning_sword(f.copy()) for f in atk2]).save(os.path.join(FIGHT_OUT, "sword-attack-special.png"))


def build_map_sheet():
    src = Image.open(os.path.join(MAP_DIR, "player-attack1.png")).convert("RGBA")
    join([staff_from_sword(f.copy()) for f in frames_of(src, 64)]).save(os.path.join(MAP_DIR, "player-attack-staff.png"))


if __name__ == "__main__":
    build_fighter_sheets()
    build_map_sheet()
    print("selesai")
