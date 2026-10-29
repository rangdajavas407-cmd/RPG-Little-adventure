#!/usr/bin/env python3
"""Animasi menyerang Busur Kayu untuk karakter di peta/desa (64x32, 5 frame), dari sprite pedang aslinya.
Jalankan dari folder proyek (butuh Pillow):  python3 tools/make_map_bow.py
Hasil: common/characters/player/player-attack-bow.png"""
import os, sys
from PIL import Image
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import make_hero_skins as base
import make_bow_skin as bow

src = Image.open(os.path.join(base.MAP_DIR, "player-attack1.png")).convert("RGBA")
frames = base.frames_of(src, 64)
out = [bow.bow_from_sword(f.copy(), bow.pull_for(i, len(frames))) for i, f in enumerate(frames)]
base.join(out).save(os.path.join(base.MAP_DIR, "player-attack-bow.png"))
print("ok", len(out))
