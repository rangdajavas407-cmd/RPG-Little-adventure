#!/usr/bin/env python3
"""
Menulis scene Ancient Dungeon (format .tscn) supaya tata letaknya mudah diubah:

  screens/ancient-dungeon.tscn            halaman depan dungeon (Darkus, gerbang)
  screens/ancient-dungeon/dungeon.tscn    bagian dalam dungeon (lorong + musuh)

Ubah tata letak di bawah lalu jalankan:   python3 tools/build_ancient_dungeon_scenes.py
Skrip logika ada di screens/ancient-dungeon.gd dan screens/ancient-dungeon/dungeon.gd
(daftar musuh dungeon = konstanta ENCOUNTERS di dungeon.gd).
"""
import base64
import os
import struct

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
T = 32


def tiles_b64(cells):
    """cells: [(x, y, source, ax, ay)] -> PackedByteArray base64 (format TileMapLayer Godot 4)."""
    data = b"\x00\x00"
    for (x, y, s, ax, ay) in cells:
        data += struct.pack("<hhHHHH", x, y, s, ax, ay, 0)
    return base64.b64encode(data).decode()


class Scene:
    def __init__(self, root_name, script):
        self.ext = []
        self.sub = []
        self.nodes = []
        self.conns = []
        self.root = root_name
        self.script_id = self.res("Script", script)
        self.n_sub = 0

    def res(self, kind, path):
        for (i, k, p) in self.ext:
            if p == path:
                return i
        rid = "r%d" % (len(self.ext) + 1)
        self.ext.append((rid, "PackedScene" if kind == "Scene" else ("Script" if kind == "Script" else "Texture2D"), path))
        return rid

    def tex(self, path):
        return self.res("Texture2D", path)

    def scene(self, path):
        return self.res("Scene", path)

    def add_sub(self, body, kind):
        self.n_sub += 1
        sid = "s%d" % self.n_sub
        self.sub.append('[sub_resource type="%s" id="%s"]\n%s\n' % (kind, sid, body))
        return sid

    def rect_shape(self, w, h):
        return self.add_sub("size = Vector2(%s, %s)" % (w, h), "RectangleShape2D")

    def node(self, text):
        self.nodes.append(text + "\n")

    def connect(self, sig, frm, to, method):
        self.conns.append('[connection signal="%s" from="%s" to="%s" method="%s"]' % (sig, frm, to, method))

    def tileset(self, texture_path, cell, sources, collision=False, size=None):
        """sources: [(margin_x, margin_y)] satu atlas per entri; atau region_size tile = cell."""
        tid = self.tex(texture_path)
        ids = []
        for (mx, my) in sources:
            body = 'texture = ExtResource("%s")\n' % tid
            if mx or my:
                body += "margins = Vector2i(%d, %d)\n" % (mx, my)
            body += "texture_region_size = Vector2i(%d, %d)\n0:0/0 = 0\n" % (cell, cell)
            if collision:
                h = cell / 2
                body += "0:0/0/physics_layer_0/polygon_0/points = PackedVector2Array(-%s, -%s, %s, -%s, %s, %s, -%s, %s)\n" % (h, h, h, h, h, h, h, h)
            ids.append(self.add_sub(body, "TileSetAtlasSource"))
        body = "tile_size = Vector2i(%d, %d)\n" % (cell, cell)
        if collision:
            body += "physics_layer_0/collision_layer = 1\n"
        for i, sid in enumerate(ids):
            body += 'sources/%d = SubResource("%s")\n' % (i, sid)
        return self.add_sub(body, "TileSet")

    def layer(self, name, tileset_id, cells, parent="."):
        self.node('[node name="%s" type="TileMapLayer" parent="%s"]\ntile_map_data = PackedByteArray("%s")\ntile_set = SubResource("%s")\n' % (name, parent, tiles_b64(cells), tileset_id))

    def sprite(self, name, tex, x, y, parent="."):
        self.node('[node name="%s" type="Sprite2D" parent="%s"]\nposition = Vector2(%s, %s)\ntexture = ExtResource("%s")\n' % (name, parent, x, y, self.tex(tex)))

    def anim_sprite(self, name, tex, frame_w, frame_h, count, speed, x, y, parent="."):
        """AnimatedSprite2D dari satu lembar horizontal."""
        tid = self.tex(tex)
        ids = []
        for i in range(count):
            ids.append(self.add_sub('atlas = ExtResource("%s")\nregion = Rect2(%d, 0, %d, %d)' % (tid, i * frame_w, frame_w, frame_h), "AtlasTexture"))
        frames = ", ".join('{\n"duration": 1.0,\n"texture": SubResource("%s")\n}' % i for i in ids)
        sf = self.add_sub('animations = [{\n"frames": [%s],\n"loop": true,\n"name": &"default",\n"speed": %s\n}]' % (frames, speed), "SpriteFrames")
        self.node('[node name="%s" type="AnimatedSprite2D" parent="%s"]\nposition = Vector2(%s, %s)\nsprite_frames = SubResource("%s")\nautoplay = "default"\n' % (name, parent, x, y, sf))

    def prop(self, name, tex, x, y, w, h, col_w=None, col_h=None, parent="."):
        """Benda bertabrakan: titik (x,y) = dasar benda (untuk Y-sort), gambar di atasnya."""
        self.node('[node name="%s" type="StaticBody2D" parent="%s"]\nposition = Vector2(%s, %s)\n' % (name, parent, x, y))
        pp = "%s/%s" % (parent, name) if parent != "." else name
        self.node('[node name="img" type="Sprite2D" parent="%s"]\nposition = Vector2(0, %s)\ntexture = ExtResource("%s")\n' % (pp, -h / 2, self.tex(tex)))
        if col_w:
            sh = self.rect_shape(col_w, col_h)
            self.node('[node name="col" type="CollisionShape2D" parent="%s"]\nposition = Vector2(0, %s)\nshape = SubResource("%s")\n' % (pp, -col_h / 2, sh))

    def wall_box(self, name, x0, y0, x1, y1, parent="."):
        """Kotak tabrak tak terlihat (koordinat piksel)."""
        sh = self.rect_shape(x1 - x0, y1 - y0)
        self.node('[node name="%s" type="StaticBody2D" parent="%s"]\nposition = Vector2(%s, %s)\n' % (name, parent, (x0 + x1) / 2, (y0 + y1) / 2))
        pp = "%s/%s" % (parent, name) if parent != "." else name
        self.node('[node name="col" type="CollisionShape2D" parent="%s"]\nshape = SubResource("%s")\n' % (pp, sh))

    def door(self, name, x, y, w, h, parent="."):
        self.node('[node name="%s" parent="%s" instance=ExtResource("%s")]\nposition = Vector2(%s, %s)\nscale = Vector2(%s, %s)\n' % (name, parent, self.scene("res://common/areas/door.tscn"), x, y, w / 20, h / 20))

    def write(self, path, steps_extra=0):
        out = "[gd_scene load_steps=%d format=4]\n\n" % (len(self.ext) + len(self.sub) + 1 + steps_extra)
        for (i, k, p) in self.ext:
            out += '[ext_resource type="%s" path="%s" id="%s"]\n' % (k, p, i)
        out += "\n" + "\n".join(self.sub) + "\n"
        out += '[node name="%s" type="Node2D"]\nscript = ExtResource("%s")\n\n' % (self.root, self.script_id)
        out += "\n".join(self.nodes)
        out += "\n" + "\n".join(self.conns) + "\n"
        with open(os.path.join(ROOT, path), "w") as f:
            f.write(out)


IMG = "res://screens/ancient-dungeon/images/"
INS = "res://screens/ancient-dungeon/dungeon/"


def player(sc, parent, x, y):
    sc.node('[node name="playerAndControl" parent="%s" instance=ExtResource("%s")]\nposition = Vector2(%s, %s)\n' % (parent, sc.scene("res://common/ui/playerAndControl.tscn"), x, y))


# ====================================================================== halaman depan

def build_front():
    sc = Scene("ancient-dungeon", "res://screens/ancient-dungeon.gd")
    W, H = 640, 480
    sc.node('[node name="cameraRef" type="ReferenceRect" parent="."]\noffset_right = %d\noffset_bottom = %d\n' % (W, H))

    ground_ts = sc.tileset(IMG + "ground.png", 96, [(0, 0)])
    sc.layer("ground", ground_ts, [(x, y, 0, 0, 0) for x in range(0, 7) for y in range(0, 6)])

    flag_ts = sc.tileset(IMG + "flagstone.png", 32, [(0, 0)])
    sc.layer("path", flag_ts, [(x, y, 0, 0, 0) for x in (9, 10) for y in range(5, 15)])

    rock_ts = sc.tileset(IMG + "rockwall.png", 32, [(0, 0)], collision=True)
    rocks = set()
    for x in range(20):
        rocks.add((x, 0))
        if x not in (9, 10):
            rocks.add((x, 14))
    for y in range(15):
        rocks.add((0, y))
        rocks.add((19, y))
    for y in range(1, 5):                       # kiri-kanan gerbang
        for x in list(range(1, 8)) + list(range(12, 19)):
            rocks.add((x, y))
    sc.layer("rocks", rock_ts, [(x, y, 0, 0, 0) for (x, y) in sorted(rocks)])

    sc.sprite("rune", IMG + "rune.png", 320, 262)

    # gerbang: sprite 192x128 berpusat di (320, 100); lubang di x 294..346
    sc.sprite("gate", IMG + "gate.png", 320, 100)
    sc.wall_box("gateLeft", 224, 96, 294, 162)
    sc.wall_box("gateRight", 346, 96, 416, 162)
    sc.door("gateDoor", 320, 150, 52, 12)

    sc.node('[node name="sorted" type="Node2D" parent="."]\ny_sort_enabled = true\n')
    p = "sorted"
    player(sc, p, 320, 430)
    sc.node('[node name="darkus" parent="sorted" instance=ExtResource("%s")]\nposition = Vector2(320, 238)\n' % sc.scene("res://common/characters/darkus.tscn"))

    sc.prop("pillar1", IMG + "pillar.png", 244, 214, 32, 64, 18, 8, p)
    sc.prop("pillar2", IMG + "pillar.png", 396, 214, 32, 64, 18, 8, p)
    sc.prop("pillarBroken1", IMG + "pillar-broken.png", 60, 330, 32, 44, 18, 8, p)
    sc.prop("pillarBroken2", IMG + "pillar-broken.png", 520, 300, 32, 44, 18, 8, p)
    sc.prop("tree1", IMG + "deadtree.png", 78, 250, 64, 96, 14, 8, p)
    sc.prop("tree2", IMG + "deadtree.png", 566, 236, 64, 96, 14, 8, p)
    sc.prop("tree3", IMG + "deadtree.png", 70, 420, 64, 96, 14, 8, p)
    sc.prop("tree4", IMG + "deadtree.png", 574, 410, 64, 96, 14, 8, p)
    sc.prop("rubble1", IMG + "rubble.png", 260, 405, 32, 24, 24, 8, p)
    sc.prop("rubble2", IMG + "rubble.png", 450, 372, 32, 24, 24, 8, p)
    sc.prop("rubble3", IMG + "rubble.png", 250, 160, 32, 24, 24, 8, p)
    for i, (x, y) in enumerate([(150, 200), (500, 190), (200, 410)]):
        sc.anim_sprite("crystal%d" % (i + 1), IMG + "crystal.png", 24, 32, 2, 2.0, x, y - 16, p)
    sc.sprite("bones1", IMG + "bones.png", 400, 300, p)
    sc.sprite("bones2", IMG + "bones.png", 110, 410, p)
    for i, (x, y) in enumerate([(280, 168), (360, 168), (276, 252), (364, 252)]):
        sc.anim_sprite("torch%d" % (i + 1), IMG + "torch.png", 16, 32, 3, 6.0, x, y - 16, p)

    # kios Barong (screens/ancient-dungeon/shop): kios 128x85 dengan dasar di y=340
    sc.prop("kios", "res://screens/ancient-dungeon/shop/kios-small.png", 170, 340, 128, 85, 104, 14, p)
    sc.node('[node name="barong" parent="sorted" instance=ExtResource("%s")]\nposition = Vector2(184, 356)\n' % sc.scene("res://common/characters/barong.tscn"))

    sc.door("exit", 320, 470, 64, 12)
    sc.connect("quit", "sorted/playerAndControl", ".", "_on_playerAndControl_quit")
    sc.connect("save", "sorted/playerAndControl", ".", "_on_playerAndControl_save")
    sc.connect("talk", "sorted/darkus", ".", "_on_darkus_talk")
    sc.connect("talk", "sorted/barong", ".", "_on_barong_talk")
    sc.connect("playerOpenedDoor", "gateDoor", ".", "_on_gateDoor_playerOpenedDoor")
    sc.connect("playerOpenedDoor", "exit", ".", "_on_exit_playerOpenedDoor")
    sc.write("screens/ancient-dungeon.tscn")


# ====================================================================== bagian dalam

# (x0, y0, x1, y1) petak lantai, inklusif
# CATATAN: kalau diubah, ubah juga FLOOR_AREAS di screens/ancient-dungeon/dungeon.gd (pengaman posisi
# setelah pertarungan) dan posisi musuh di ENCOUNTERS.
AREAS = {
    "R0": (13, 40, 22, 45),   # ruang awal
    "C1": (17, 35, 18, 39),
    "R1": (8, 28, 27, 34),
    "C2": (9, 23, 10, 27),
    "R2": (3, 16, 16, 22),
    "C3": (17, 18, 20, 19),
    "R3": (21, 12, 32, 22),
    "C4": (26, 7, 27, 11),
    "R4": (18, 1, 35, 6),     # ruang terakhir
}
GRID_W, GRID_H = 38, 48


def build_inside():
    sc = Scene("dungeon", "res://screens/ancient-dungeon/dungeon.gd")
    floor = set()
    for (x0, y0, x1, y1) in AREAS.values():
        for x in range(x0, x1 + 1):
            for y in range(y0, y1 + 1):
                floor.add((x, y))
    sc.node('[node name="cameraRef" type="ReferenceRect" parent="."]\noffset_right = %d\noffset_bottom = %d\n' % (GRID_W * T, GRID_H * T))
    sc.node('[node name="darkness" type="CanvasModulate" parent="."]\ncolor = Color(0.74, 0.72, 0.92, 1)\n')

    # lantai: 4 variasi ubin (atlas 2x2 dalam satu gambar)
    tid = sc.tex(INS + "floor.png")
    srcs = []
    body = 'texture = ExtResource("%s")\ntexture_region_size = Vector2i(32, 32)\n' % tid
    for (ax, ay) in [(0, 0), (1, 0), (0, 1), (1, 1)]:
        body += "%d:%d/0 = 0\n" % (ax, ay)
    fs = sc.add_sub(body, "TileSetAtlasSource")
    fts = sc.add_sub('tile_size = Vector2i(32, 32)\nsources/0 = SubResource("%s")\n' % fs, "TileSet")
    cells = []
    for (x, y) in sorted(floor):
        v = (x * 7 + y * 13 + (x * y) % 5) % 9
        ax, ay = {0: (1, 0), 1: (0, 1), 2: (1, 1)}.get(v, (0, 0)) if v < 3 else (0, 0)
        cells.append((x, y, 0, ax, ay))
    sc.layer("floor", fts, cells)

    wall_ts = sc.tileset(INS + "wall.png", 32, [(0, 0)], collision=True)
    walls = []
    for x in range(-1, GRID_W + 1):
        for y in range(-1, GRID_H + 1):
            if (x, y) not in floor:
                walls.append((x, y, 0, 0, 0))
    sc.layer("walls", wall_ts, walls)

    sc.node('[node name="sorted" type="Node2D" parent="."]\ny_sort_enabled = true\n')
    p = "sorted"
    sx, sy = (13 + 22 + 1) / 2 * T, 43 * T
    player(sc, p, sx, sy)

    # obor di dinding atas tiap ruangan
    n = 0
    for name, (x0, y0, x1, y1) in AREAS.items():
        if name.startswith("C"):
            continue
        for x in range(x0 + 2, x1, 6):
            n += 1
            sc.anim_sprite("torch%d" % n, IMG + "torch.png", 16, 32, 3, 6.0, x * T + 16, y0 * T - 2, p)
    for i, (x, y) in enumerate([(9, 29), (26, 29), (4, 18), (22, 14), (31, 14), (20, 3), (34, 3), (30, 5), (24, 2)]):
        sc.anim_sprite("crystal%d" % (i + 1), IMG + "crystal.png", 24, 32, 2, 2.0, x * T + 16, y * T + 8, p)
    for i, (x, y) in enumerate([(14, 42), (21, 44), (12, 31), (14, 20), (25, 17), (23, 4)]):
        sc.sprite("bones%d" % (i + 1), IMG + "bones.png", x * T + 16, y * T + 16, p)

    # tangga keluar di dinding bawah ruang awal
    sc.sprite("stairs", INS + "stairs.png", 18 * T, 46 * T - 8)
    sc.door("exit", 18 * T, 45 * T + 8, 64, 16)

    sc.connect("quit", "sorted/playerAndControl", ".", "_on_playerAndControl_quit")
    sc.connect("save", "sorted/playerAndControl", ".", "_on_playerAndControl_save")
    sc.connect("playerOpenedDoor", "exit", ".", "_on_exit_playerOpenedDoor")
    sc.write("screens/ancient-dungeon/dungeon.tscn")


if __name__ == "__main__":
    build_front()
    build_inside()
    print("selesai")
