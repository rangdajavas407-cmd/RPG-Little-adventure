extends Node2D

# Vera: pendamping yang melayang mengikuti pemain dengan jeda kecil.
# Dipasang oleh playerAndControl.spawnCompanion() di desa pohon dan peta jalan.
#
# Sprite:
#   idle = 4 frame kepakan sayap (vera-0..3.png)
#   fly  = 20 frame terbang mendekat -> mendarat (vera-fly-0..19.png), dipakai saat datang / pergi

const IDLE_FRAMES=4
const FLY_FRAMES=20
const FLY_FPS=14.0
const PATH="res://common/characters/vera/"
const TRAIL_LENGTH=18
const SIDE_OFFSET=Vector2(-20, 0)
# skala Vera: 0.55 -> 0.8 supaya tingginya kira-kira sama dengan Bunda (Mom)
const VERA_SCALE=0.8

var target=null
var trail=[]
var sprite=null
var shadow=null
var time=0.0

func _ready():
	# Vera adalah pendamping kecil; skala ini berlaku untuk cutscene dan saat mengikuti pemain.
	scale=Vector2(VERA_SCALE,VERA_SCALE)
	var frames=SpriteFrames.new()
	if frames.has_animation("default"):
		frames.remove_animation("default")
	frames.add_animation("idle")
	frames.set_animation_speed("idle", 6.0)
	frames.set_animation_loop("idle", true)
	for i in IDLE_FRAMES:
		frames.add_frame("idle", load(PATH+"vera-"+str(i)+".png"))
	frames.add_animation("fly")
	frames.set_animation_speed("fly", FLY_FPS)
	frames.set_animation_loop("fly", false)
	for i in FLY_FRAMES:
		frames.add_frame("fly", load(PATH+"vera-fly-"+str(i)+".png"))
	# bayangan di tanah
	shadow=ColorRect.new()
	shadow.color=Color(0, 0, 0, 0.25)
	shadow.size=Vector2(16, 3)
	shadow.position=Vector2(-8, 20)
	add_child(shadow)
	sprite=AnimatedSprite2D.new()
	sprite.sprite_frames=frames
	add_child(sprite)
	sprite.play("idle")

# mulai mengikuti; start_ = posisi awal (mis. tempat Vera berdiri saat adegan)
func follow(target_, start_=null):
	target=target_
	global_position=start_ if start_!=null else target.global_position+SIDE_OFFSET
	trail.clear()
	sprite.speed_scale=1.0

# terbang bebas ke suatu titik (dipakai saat adegan, tanpa mengikuti pemain)
func flyTo(pos_, seconds_):
	target=null
	if sprite!=null and abs(pos_.x-global_position.x)>1.0:
		sprite.flip_h=pos_.x<global_position.x
	var tween=create_tween()
	tween.tween_property(self,"global_position",pos_,seconds_).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	return tween

# datang dari jauh: terbang mendekat (sprite membesar) lalu mendarat dengan sayap dilipat
func arrive(from_, to_, seconds_=1.6):
	target=null
	global_position=from_
	sprite.flip_h=false
	shadow.visible=false
	sprite.speed_scale=(float(FLY_FRAMES)/FLY_FPS)/seconds_
	sprite.play("fly")
	var tween=create_tween()
	tween.tween_property(self,"global_position",to_,seconds_).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(_landed)
	return tween

func _landed():
	sprite.speed_scale=1.0
	sprite.play("idle")
	shadow.visible=true

# pergi: animasi terbang diputar mundur (berbalik lalu mengecil di kejauhan) sambil memudar
func depart(to_, seconds_=1.8):
	target=null
	shadow.visible=false
	sprite.flip_h=false
	sprite.speed_scale=(float(FLY_FRAMES)/FLY_FPS)/seconds_
	sprite.play_backwards("fly")
	var tween=create_tween()
	tween.tween_property(self,"global_position",to_,seconds_).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(self,"modulate:a",0.0,seconds_*0.3).set_delay(seconds_*0.7)
	return tween

# ---- adegan pamit: pakai 3 pose khusus (vera-bye-0..2.png) ----
# pose 0 = melayang diam saat berpamitan, pose 1 & 2 = terbang pergi dengan sayap dan jejak merah
func useByeSkin():
	var frames=SpriteFrames.new()
	if frames.has_animation("default"):
		frames.remove_animation("default")
	frames.add_animation("idle")
	frames.set_animation_speed("idle",3.0)
	frames.set_animation_loop("idle",true)
	frames.add_frame("idle",load(PATH+"vera-bye-0.png"))
	frames.add_animation("fly")
	frames.set_animation_speed("fly",6.0)
	frames.set_animation_loop("fly",true)
	frames.add_frame("fly",load(PATH+"vera-bye-1.png"))
	frames.add_frame("fly",load(PATH+"vera-bye-2.png"))
	sprite.sprite_frames=frames
	sprite.speed_scale=1.0
	sprite.play("idle")

# terbang pergi: berganti pose 1 & 2 sambil naik, mengecil di kejauhan, lalu memudar
func bye(to_, seconds_=2.0):
	target=null
	shadow.visible=false
	sprite.flip_h=false
	sprite.play("fly")
	var tween=create_tween()
	tween.tween_property(self,"global_position",to_,seconds_).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(self,"scale",Vector2(VERA_SCALE*0.82,VERA_SCALE*0.82),seconds_)
	tween.parallel().tween_property(self,"modulate:a",0.0,seconds_*0.35).set_delay(seconds_*0.65)
	return tween

func face(left_):
	if sprite!=null:
		sprite.flip_h=left_

func _physics_process(delta):
	time+=delta
	# melayang naik-turun walau sedang tidak mengikuti
	if sprite!=null:
		sprite.offset.y=-6+sin(time*4.0)*2.5
	if target==null or !is_instance_valid(target):
		return
	var p=target.global_position
	if trail.is_empty() or trail.back().distance_to(p)>0.5:
		trail.append(p)
	while trail.size()>TRAIL_LENGTH:
		trail.pop_front()
	var goal=trail[0]+SIDE_OFFSET
	var before=global_position
	global_position=global_position.lerp(goal, min(1.0, delta*7.0))
	# menghadap arah gerak
	var dx=global_position.x-before.x
	if abs(dx)>0.05:
		sprite.flip_h=dx<0
	shadow.scale=Vector2(1.0-sin(time*4.0)*0.12, 1.0)
