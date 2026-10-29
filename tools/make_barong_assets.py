#!/usr/bin/env python3
"""
Membuat versi ukuran-game dari gambar kios dan Barong di screens/ancient-dungeon/shop/:

  kios-barong.png             -> kios-small.png          (kios, lebar ~128 px)
  seller-ancient-barong.png   -> barong-idle-small.png   (5 frame 40x44)
  seller-ancient-barong.png   -> barong-portrait.png     (potret kotak dialog)

Jalankan dari folder proyek (butuh Pillow):   python3 tools/make_barong_assets.py
"""
import os
from PIL import Image

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
SHOP = os.path.join(ROOT, "screens", "ancient-dungeon", "shop")


def hard_alpha(img, threshold=128):
    px = img.load()
    for x in range(img.width):
        for y in range(img.height):
            r, g, b, a = px[x, y]
            px[x, y] = (r, g, b, 255 if a >= threshold else 0)
    return img


def kios():
    src = Image.open(os.path.join(SHOP, "kios-barong.png")).convert("RGBA")
    crop = src.crop(src.getbbox())
    w = 128
    small = crop.resize((w, round(crop.height * w / crop.width)), Image.LANCZOS)
    hard_alpha(small).save(os.path.join(SHOP, "kios-small.png"))
    return small.size


def barong():
    src = Image.open(os.path.join(SHOP, "seller-ancient-barong.png")).convert("RGBA")
    fw = src.width // 5
    frames = [src.crop((i * fw, 0, (i + 1) * fw, src.height)) for i in range(5)]
    left = min(f.getbbox()[0] for f in frames)
    top = min(f.getbbox()[1] for f in frames)
    right = max(f.getbbox()[2] for f in frames)
    bottom = max(f.getbbox()[3] for f in frames)
    target_h = 38
    scale = target_h / (bottom - top)
    cw, ch = 40, 44
    sheet = Image.new("RGBA", (cw * 5, ch), (0, 0, 0, 0))
    for i, fr in enumerate(frames):
        crop = fr.crop((left, top, right, bottom))
        small = crop.resize((max(1, round(crop.width * scale)), target_h), Image.LANCZOS)
        hard_alpha(small)
        cell = Image.new("RGBA", (cw, ch), (0, 0, 0, 0))
        cell.alpha_composite(small, ((cw - small.width) // 2, ch - target_h - 1))
        sheet.paste(cell, (i * cw, 0))
    sheet.save(os.path.join(SHOP, "barong-idle-small.png"))

    first = frames[0].crop((left, top, right, top + int((bottom - top) * 0.62)))
    s = min(95 / first.width, 100 / first.height)
    portrait = first.resize((round(first.width * s), round(first.height * s)), Image.LANCZOS)
    hard_alpha(portrait, 110).save(os.path.join(SHOP, "barong-portrait.png"))


if __name__ == "__main__":
    print("kios", kios())
    barong()
    print("selesai")
