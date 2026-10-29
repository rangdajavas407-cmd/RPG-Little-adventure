extends Node2D

# Altar api hijau: titik pemulihan di desa dan dungeon.
# Tekan E di dekat altar -> HP dan MP dipulihkan, tetapi hanya sampai batas (cap) tempat itu,
# bukan sampai penuh. Cap tiap tempat diatur saat altar dipasang (lihat scene.gd spawnHealShrine).
#
# Sprite: shrine/shrine-idle.png (6 frame nyala) dan shrine/shrine-use.png (4 frame aktif), 64x64 per frame.
# Titik node = dasar altar (kaki), jadi urutan gambar (y-sort) dengan pemain benar.

const InteractScene=preload("res://common/areas/interact.tscn")
const IDLE_SHEET="res://common/areas/shrine/shrine-idle.png"
const USE_SHEET="res://common/areas/shrine/shrine-use.png"
const CELL=64

var scene=null
var lifeCap=75
var manaCap=25
var sprite: AnimatedSprite2D
var interact=null
var busy=false

func setup(scene_, lifeCap_, manaCap_):
	scene=scene_
	lifeCap=lifeCap_
	manaCap=manaCap_

func _ready():
	var frames=SpriteFrames.new()
	if frames.has_animation("default"):
		frames.remove_animation("default")
	_addAnim(frames,"idle",IDLE_SHEET,6.0,true)
	_addAnim(frames,"use",USE_SHEET,8.0,false)
	sprite=AnimatedSprite2D.new()
	sprite.sprite_frames=frames
	sprite.position=Vector2(0,-28)   # dasar gambar (baris ke-60 dari 64) tepat di titik node
	add_child(sprite)
	sprite.play("idle")
	sprite.animation_finished.connect(_onAnimationFinished)

	# badan altar menghalangi jalan (kotak kecil di dasar)
	var body=StaticBody2D.new()
	var shape=CollisionShape2D.new()
	var box=RectangleShape2D.new()
	box.size=Vector2(16,6)
	shape.shape=box
	shape.position=Vector2(0,-3)
	body.add_child(shape)
	add_child(body)

	# area interaksi: tanda "E" muncul saat pemain berdiri di dekat altar
	interact=InteractScene.instantiate()
	var area=interact.get_node("CollisionShape2D")
	var areaBox=RectangleShape2D.new()
	areaBox.size=Vector2(46,36)
	area.shape=areaBox
	area.position=Vector2(0,-6)
	interact.promptOffset=Vector2(0,-48)
	add_child(interact)
	interact.playerOpenedDoor.connect(_use)

func _addAnim(frames_, name_, file_, fps_, loop_):
	var sheet=load(file_)
	frames_.add_animation(name_)
	frames_.set_animation_speed(name_,fps_)
	frames_.set_animation_loop(name_,loop_)
	for i in int(sheet.get_width()/CELL):
		var tex=AtlasTexture.new()
		tex.atlas=sheet
		tex.region=Rect2(i*CELL,0,CELL,CELL)
		frames_.add_frame(name_,tex)

func _onAnimationFinished():
	if sprite.animation=="use":
		sprite.play("idle")
		busy=false
		interact.interactionEnabled=true

# pulihkan sampai batas; jangan pernah menurunkan HP/MP yang sudah lebih tinggi
func _use():
	if busy:
		return
	var life=GlobalPlayer.getLife()
	var mana=GlobalPlayer.getMana()
	var newLife=maxi(life,mini(GlobalPlayer.getMaxLife(),lifeCap))
	var newMana=maxi(mana,mini(GlobalPlayer.getMaxMana(),manaCap))
	if newLife==life and newMana==mana:
		if scene!=null:
			scene.notify("HP dan MP sudah cukup.","info")
		return
	busy=true
	interact.interactionEnabled=false
	GlobalPlayer.setLife(newLife)
	GlobalPlayer.setMana(newMana)
	if scene!=null:
		var player=scene.getPlayer()
		player.reloadLife()
		player.reloadMana()
		scene.notify("HP +"+str(newLife-life)+"  MP +"+str(newMana-mana),"reward")
	sprite.play("use")
