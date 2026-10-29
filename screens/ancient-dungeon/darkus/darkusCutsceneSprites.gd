extends RefCounted

# SpriteFrames Darkus untuk cutscene perasukan (v9.14). Sheet dibuat tools/make_darkus_cutscene_sprites.py.
#   walk  : 8 frame berjalan ke kanan (tangan di saku, jas lab melambai)
#   idle  : berdiri menghadap depan (frame pertama sheet terikat)
#   bind  : benang merah melilit -> lingkaran ritual menyala -> terangkat (sekali jalan, berhenti di frame terangkat)
#   float : melayang terikat, cincin merah berputar (loop)
# Semua frame berukuran sama (kaki/lingkaran di dasar kanvas), jadi pergantian animasi tidak melompat.

const WALK_SHEET = "res://screens/ancient-dungeon/darkus/darkus-walk.png"
const BOUND_SHEET = "res://screens/ancient-dungeon/darkus/darkus-bound.png"
# v9.18: kanvas dikecilkan (badan 44 px, sama dengan Ranbyus) supaya Darkus tidak kebesaran
const CELL_W = 39
const CELL_H = 77
# jarak dari titik tengah sprite ke telapak kaki (dasar kanvas)
const FEET_BELOW_CENTER = 37.5

static func _addAnim(frames_, name_, sheet_, indexes_, fps_, loop_):
    frames_.add_animation(name_)
    frames_.set_animation_speed(name_, fps_)
    frames_.set_animation_loop(name_, loop_)
    for i in indexes_:
        var atlas = AtlasTexture.new()
        atlas.atlas = sheet_
        atlas.region = Rect2(i * CELL_W, 0, CELL_W, CELL_H)
        frames_.add_frame(name_, atlas)

static func build():
    var frames = SpriteFrames.new()
    if frames.has_animation("default"):
        frames.remove_animation("default")
    var walkSheet = load(WALK_SHEET)
    var boundSheet = load(BOUND_SHEET)
    _addAnim(frames, "walk", walkSheet, [0, 1, 2, 3, 4, 5, 6, 7], 12.0, true)
    _addAnim(frames, "idle", boundSheet, [0], 4.0, true)
    _addAnim(frames, "bind", boundSheet, [1, 2, 3, 4], 5.0, false)
    _addAnim(frames, "float", boundSheet, [5, 6, 7, 8, 9], 6.0, true)
    return frames

# v9.18: animasi benang merah Darkus iblis (dari gambar sprite sheet baru). 24 frame 128x64, badan di tengah kanvas,
# benang mengarah ke kanan. Ditambahkan ke SpriteFrames iblis (EnemySprites.build("darkus_iblis", true)) sebagai "cast".
const CAST_SHEET = "res://common/fighters/enemies/darkus_iblis-cast.png"
const CAST_W = 128
const CAST_H = 64
const CAST_FRAMES = 24

static func addIblisCast(frames_):
    var sheet = load(CAST_SHEET)
    frames_.add_animation("cast")
    frames_.set_animation_speed("cast", 12.0)
    frames_.set_animation_loop("cast", false)
    for i in CAST_FRAMES:
        var atlas = AtlasTexture.new()
        atlas.atlas = sheet
        atlas.region = Rect2(i * CAST_W, 0, CAST_W, CAST_H)
        frames_.add_frame("cast", atlas)
    return frames_
