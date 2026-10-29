#!/usr/bin/env python3
"""Menggambar sprite class Dukun (v9.31) dari nol, supaya kelihatan seperti dukun beneran
(bukan penyihir ungu hasil recolor Exorcist seperti v9.30).
  python3 tools/make_dukun_sprites.py          (jalankan dari akar project)
Menghasilkan common/fighters/classes/dukun-{idle,damage,attack-simple,attack-advanced,attack-special}.png

Tampilan: blangkon hitam berpita batik, jenggot & kumis putih, baju pangsi hitam, selendang merah,
kalung manik, jarik batik cokelat, kaki telanjang. Tangan kanan memegang HIOLO SESAT (tempat dupa) dengan
tiga batang hio berujung bara dan asap. Dukun TIDAK memakai orb (orb hanya untuk Sage): saat menyerang asap makin tebal
dan berbara, saat melepas serangan asap menyembur, skill panggil memunculkan api roh hijau. Proyektilnya seikat hio menyala.

Ukuran sheet & jumlah frame sama persis dengan versi lama (frame 64x64), posisi badan tiap frame mengikuti sheet
Exorcist (condong ke depan saat menyerang, terpental saat kena), jadi kode permainan tidak perlu diubah.
"""
import math
import random
import numpy as np
from PIL import Image

OUT = 'common/fighters/classes/dukun-%s.png'
F = 64

# ------------------------------------------------------------------ warna
K = (30, 27, 36)          # kain hitam (pangsi, blangkon)
KH = (62, 56, 76)         # sorot kain
B = (152, 98, 42)         # pita batik blangkon
BD = (222, 178, 72)       # motif emas
S = (194, 134, 96)        # kulit
SD = (150, 100, 72)       # kulit gelap
W = (240, 236, 226)       # jenggot putih
WD = (176, 172, 166)
EW = (248, 244, 232)      # putih mata
EK = (24, 16, 22)         # pupil
R = (184, 38, 46)         # selendang / ikat pinggang
RD = (112, 22, 36)
J = (124, 74, 40)         # jarik
JD = (78, 44, 26)
JL = (176, 126, 64)
NB = (244, 236, 206)      # manik kalung
NA = (214, 146, 52)
WOOD = (208, 138, 62)
WOOD_L = (238, 178, 96)
EMBER = (255, 78, 52)
GLOW = (255, 172, 92)
CUP = (84, 50, 48)
CUP_L = (132, 88, 72)
CUP_D = (44, 26, 30)
SIGIL = (214, 62, 62)
SMOKE = (214, 210, 228)
ORB_RIM = (164, 137, 196)
ORB_OUT = (92, 60, 128)
ORB_MINT = (178, 255, 191)
ORB_BIG = (88, 255, 116)
ORB_HI = (226, 255, 232)

# ------------------------------------------------------------------ alat gambar


def new():
    return np.zeros((F, F, 4), np.uint8)


def put(img, x, y, c, a=255):
    x, y = int(round(x)), int(round(y))
    if not (0 <= x < F and 0 <= y < F):
        return
    sa = a / 255.0
    da = img[y, x, 3] / 255.0
    oa = sa + da * (1 - sa)
    if oa <= 0:
        return
    for i in range(3):
        img[y, x, i] = int(round((c[i] * sa + img[y, x, i] * da * (1 - sa)) / oa))
    img[y, x, 3] = int(round(oa * 255))


def rect(img, x, y, w, h, c, a=255):
    for yy in range(h):
        for xx in range(w):
            put(img, x + xx, y + yy, c, a)


def thick_line(img, x0, y0, x1, y1, c, w=3):
    n = int(max(abs(x1 - x0), abs(y1 - y0))) * 2 + 1
    for i in range(n + 1):
        t = i / n
        x, y = x0 + (x1 - x0) * t, y0 + (y1 - y0) * t
        rect(img, int(round(x - w // 2)), int(round(y - w // 2)), w, w, c)


# ------------------------------------------------------------------ badan dukun (koordinat lokal 0..19 x 0..41)


def body(img, X, Y, arm_to):
    def r_(x, y, w, h, c):
        rect(img, X + x, Y + y, w, h, c)

    def p_(x, y, c):
        put(img, X + x, Y + y, c)

    # kaki
    r_(5, 40, 3, 2, S)
    r_(11, 40, 3, 2, S)
    r_(5, 41, 3, 1, SD)
    r_(11, 41, 3, 1, SD)
    # jarik batik
    r_(4, 28, 11, 12, J)
    r_(3, 35, 13, 5, J)
    r_(3, 39, 13, 1, JD)
    for yy in range(29, 39):
        p_(9, yy, JD)
    for i, yy in enumerate((30, 33, 36)):
        for xx in range(5 + (i % 2), 15, 3):
            if xx != 9:
                p_(xx, yy, JL)
                p_(xx, yy + 1, JD)
    # badan pangsi
    r_(4, 17, 11, 10, K)
    r_(3, 17, 13, 1, K)
    p_(5, 18, KH)
    p_(13, 18, KH)
    # leher / dada terbuka
    r_(8, 17, 3, 1, S)
    p_(9, 18, S)
    # selendang merah menyilang dari bahu kanan ke pinggul kiri
    for i in range(10):
        x, y = 13 - i * 0.7, 17 + i * 0.95
        r_(int(round(x)), int(round(y)), 2, 1, R)
        p_(int(round(x)), int(round(y)) + 1, RD)
    # ikat pinggang
    r_(4, 26, 11, 2, R)
    r_(4, 27, 11, 1, RD)
    p_(9, 26, BD)
    p_(10, 26, BD)
    # kalung manik
    for i, (x, y) in enumerate([(6, 17), (7, 18), (8, 19), (9, 20), (10, 19), (11, 18), (12, 17)]):
        p_(x, y, NB if i % 2 == 0 else NA)
    p_(9, 21, BD)
    # lengan kiri (di sisi layar kiri) menggantung
    r_(2, 18, 3, 8, K)
    r_(2, 19, 1, 6, KH)
    r_(2, 26, 3, 2, S)
    # kepala: wajah
    r_(4, 7, 11, 9, S)
    r_(6, 15, 7, 1, S)
    r_(3, 9, 1, 3, S)
    r_(15, 9, 1, 3, S)
    r_(4, 7, 11, 1, SD)
    # alis, mata, hidung
    r_(5, 10, 3, 1, W)
    r_(11, 10, 3, 1, W)
    p_(6, 11, EW)
    p_(7, 11, EK)
    p_(11, 11, EW)
    p_(12, 11, EK)
    p_(9, 12, SD)
    p_(9, 13, SD)
    # kumis dan jenggot putih
    r_(6, 13, 7, 1, W)
    r_(5, 14, 2, 1, W)
    r_(12, 14, 2, 1, W)
    r_(7, 14, 5, 2, W)
    r_(8, 16, 3, 2, W)
    p_(9, 18, WD)
    p_(7, 15, WD)
    p_(11, 15, WD)
    # blangkon hitam + mondolan (tonjolan di belakang) + pita batik
    r_(6, 0, 7, 1, K)
    r_(4, 1, 11, 1, K)
    r_(3, 2, 13, 1, K)
    r_(2, 3, 15, 2, K)
    r_(0, 3, 3, 3, K)
    r_(3, 5, 13, 1, B)
    for x in range(4, 16, 2):
        p_(x, 5, BD)
    r_(3, 6, 13, 1, K)
    p_(7, 1, KH)
    p_(8, 2, KH)
    p_(9, 2, KH)
    p_(1, 3, KH)
    # lengan kanan menjulur memegang Hiolo
    hx, hy = arm_to
    thick_line(img, X + 14, Y + 19, X + hx, Y + hy, K, 3)
    return hx, hy


def hand(img, X, Y, hx, hy):
    rect(img, X + hx - 1, Y + hy - 1, 3, 3, S)
    put(img, X + hx - 1, Y + hy + 1, SD)


# ------------------------------------------------------------------ Hiolo + asap + orb


def hiolo(img, ax, ay, glow=1.0):
    """Tempat dupa berdiri di titik (ax, ay) = tengah dasar. Mengembalikan posisi ujung tiga batang hio."""
    rect(img, ax - 3, ay - 4, 7, 1, CUP_L)
    rect(img, ax - 3, ay - 3, 7, 3, CUP)
    rect(img, ax - 2, ay, 5, 1, CUP_D)
    rect(img, ax - 3, ay - 3, 1, 3, CUP_D)
    # lambang merah
    put(img, ax, ay - 3, SIGIL)
    for dx in (-1, 0, 1):
        put(img, ax + dx, ay - 2, SIGIL)
    put(img, ax, ay - 1, SIGIL)
    tips = []
    for i in range(3):
        bx = ax - 2 + 2 * i
        for k in range(6):
            x = bx + (i - 1) * k / 5.0
            put(img, x, ay - 5 - k, WOOD_L if i == 0 else WOOD)
        tx, ty = int(round(bx + (i - 1))), ay - 11
        put(img, tx, ty, EMBER)
        put(img, tx, ty - 1, GLOW, int(150 * glow))
        if glow > 1.2:
            put(img, tx - 1, ty, GLOW, 110)
            put(img, tx + 1, ty, GLOW, 110)
        tips.append((tx, ty))
    return tips


def smoke(img, tips, phase, level):
    n = 5 + int(4 * level)
    for j, (tx, ty) in enumerate(tips):
        length = n if j == 1 else n - 3
        for k in range(1, length + 1):
            x = tx + 1.3 * math.sin(phase + k * 0.85 + j * 2.1)
            a = int(max(30, 190 - k * (150 / max(1, length))))
            put(img, x, ty - 1 - k, SMOKE, a)


def puff(img, cx, cy, r, a, seed=0):
    """Gumpalan asap bertepi kasar (bukan bola licin)."""
    n = int(r) + 2
    for y in range(int(cy) - n, int(cy) + n + 1):
        for x in range(int(cx) - n, int(cx) + n + 1):
            d = math.hypot(x - cx, y - cy)
            jitter = ((x * 7 + y * 13 + seed * 5) % 5) * 0.18
            if d <= r - jitter:
                put(img, x, y, SMOKE, a)


def embers(img, cx, cy, r, seed, n=6):
    rnd = random.Random(seed)
    for _ in range(n):
        ang, dist = rnd.uniform(0, 6.283), rnd.uniform(0.3, 1.0) * r
        put(img, cx + math.cos(ang) * dist, cy + math.sin(ang) * dist, EMBER if rnd.random() < 0.6 else GLOW, 230)


def column(img, tip, top, r_max, phase):
    """Tiang asap dari ujung hio naik ke titik (cx, cy), makin melebar."""
    (x0, y0), (x1, y1) = tip, top
    n = 6
    for k in range(n):
        t = k / (n - 1)
        x = x0 + (x1 - x0) * t + 1.2 * math.sin(phase + k * 1.1)
        y = y0 + (y1 - y0) * t
        puff(img, x, y, 1.0 + (r_max - 1.0) * t, int(185 - 95 * t), seed=k)


def flame(img, cx, cy, h, phase):
    """Api roh hijau berbentuk lidah api (dipakai skill panggil), bukan bola."""
    w0 = max(2.0, h * 0.30)
    for yy in range(int(h) + 1):
        t = yy / h                                  # 0 = ujung atas, 1 = dasar
        half = w0 * (math.sin(min(1.0, t * 1.15) * math.pi / 2) ** 1.3)
        sway = math.sin(phase + t * 3.0) * (1.0 - t) * 1.6
        y = cy - h / 2 + yy
        for xx in range(int(-half) - 1, int(half) + 2):
            d = abs(xx) / max(half, 0.5)
            if d <= 1.0:
                put(img, cx + xx + sway, y, ORB_RIM if d > 0.82 else (ORB_BIG if d > 0.38 or t < 0.4 else ORB_HI))


def tint(img, mix, color=(255, 70, 80)):
    m = img[..., 3] > 0
    for i in range(3):
        img[..., i][m] = (img[..., i][m] * (1 - mix) + color[i] * mix).astype(np.uint8)


# ------------------------------------------------------------------ definisi tiap frame
# bx, by = x0 / y0 badan (sama dengan sheet Exorcist lama); off = geser Hiolo dari posisi pegangan normal;
# orb = (cx, cy, r) atau None; big = orb hijau besar (skill panggil).
# Posisi orb mengikuti sheet lama (mengumpul -> melesat). Frame lepas proyektil: simple 3, advanced 4 & 6, special 5.

IDLE = dict(
    bx=[16, 17, 17, 17], by=[23, 22, 22, 22],
    off=[(0, 0)] * 4,
    orb=[(40, 28, 3), (40, 27, 3), (40, 27, 3), (40, 28, 3)],
)
SIMPLE = dict(
    bx=[16, 17, 17, 20, 16], by=[23, 22, 22, 22, 23],
    off=[(0, 0), (0, -3), (1, -6), (6, -4), (0, 0)],
    orb=[(40, 28, 3), (37, 27, 4.5), (38, 25, 5.5), (50, 31, 4.5), (40, 28, 3)],
)
ADVANCED = dict(
    bx=[16, 17, 17, 17, 19, 17, 19], by=[23, 22, 22, 22, 23, 22, 22],
    off=[(0, 0), (0, -3), (1, -6), (1, -8), (6, -4), (1, -8), (5, -4)],
    orb=[(40, 28, 3), (37, 27, 4.5), (38, 25, 5.5), (39, 23, 6.5), (50, 31, 5), (39, 23, 6.5), (48, 30, 4.5)],
)
SPECIAL = dict(
    bx=[16, 17, 17, 16, 15, 21, 17], by=[23, 22, 22, 22, 22, 22, 22],
    off=[(0, 0), (0, -3), (1, -7), (-1, -9), (-2, -10), (7, -5), (2, -2)],
    orb=[(40, 28, 3), (37, 27, 4.5), (36, 24, 6), (31, 19, 6.5), (29, 17, 7.5), (53, 31, 7.5), (41, 28, 5)],
)
DAMAGE = dict(
    bx=[9, 1, 5, 7, 10, 11, 17], by=[23, 24, 23, 22, 22, 22, 23],
    off=[(-3, 3), (-4, 4), (-4, 3), (-3, 2), (-2, 2), (-1, 1), (0, 0)],
    orb=[None] * 7,
)
SHEETS = [('idle', IDLE, False), ('attack-simple', SIMPLE, False), ('attack-advanced', ADVANCED, False),
          ('attack-special', SPECIAL, True), ('damage', DAMAGE, False)]
LAUNCH = {'attack-simple': [3], 'attack-advanced': [4, 6], 'attack-special': [5]}
HURT_TINT = {'damage': [1, 3]}


def frame(name, spec, i, big):
    img = new()
    X, Y = spec['bx'][i] + 1, spec['by'][i]
    ox, oy = spec['off'][i]
    ax, ay = X + 22 + ox, Y + 25 + oy
    hx, hy = ax - 4 - X, ay - 2 - Y
    body(img, X, Y, (hx, hy))
    o = spec['orb'][i]
    charging = o is not None and o[2] >= 4.5
    tips = hiolo(img, ax, ay, glow=1.0 + (0.6 if charging else 0.0))
    hand(img, X, Y, hx, hy)
    smoke(img, tips, i * 0.9, 1.0 if charging else 0.3)
    if o is not None:
        cx, cy, r = o
        launching = i in LAUNCH.get(name, [])
        if big and r >= 6:
            # skill panggil: api roh hijau menyala di atas kepala / dilempar
            flame(img, cx, cy, 2.2 * r + 2, i * 0.8)
            embers(img, cx, cy, r + 3, seed=i, n=7)
        elif launching:
            # serangan dilepas: semburan asap dan bara ke arah musuh
            for dx, dy, rr in ((-4, 1, 2.2), (0, 0, 2.8), (4, -1, 2.0)):
                puff(img, cx + dx, cy + dy, rr, 170, seed=i + dx)
            embers(img, cx + 2, cy, 6, seed=i, n=7)
        elif charging:
            column(img, tips[1], (cx, cy), r * 0.55, i * 0.9)
            embers(img, cx, cy, r + 2, seed=i, n=5)
        else:
            embers(img, tips[1][0], tips[1][1] - 8, 5, seed=i, n=2)
    if i in HURT_TINT.get(name, []):
        tint(img, 0.45)
    return img


def projectile(size, big):
    """Proyektil Dukun: seikat tiga hio menyala yang berputar (bukan bola). 10x10 dan 16x16."""
    img = np.zeros((size, size, 4), np.uint8)
    top = 2 if not big else 3
    for i, x in enumerate((3, 5, 7) if not big else (5, 8, 11)):
        for y in range(top + 1, size - 1):
            put(img, x, y, WOOD_L if i == 0 else WOOD)
        put(img, x, top, EMBER)
        put(img, x, top - 1, GLOW, 190)
        if big:
            put(img, x, top - 2, ORB_BIG, 200)
    put(img, size // 2, 0 if not big else 1, SMOKE, 150)
    return img


def main():
    for name, spec, big in SHEETS:
        n = len(spec['bx'])
        sheet = Image.new('RGBA', (F * n, F), (0, 0, 0, 0))
        for i in range(n):
            sheet.alpha_composite(Image.fromarray(frame(name, spec, i, big)), (i * F, 0))
        sheet.save(OUT % name)
    Image.fromarray(projectile(10, False)).save('common/fighters/classes/projectile-dukun.png')
    Image.fromarray(projectile(16, True)).save('common/fighters/classes/projectile-dukun-big.png')
    print('ok')


if __name__ == '__main__':
    main()
