extends Node2D

# Pak Tabib sebagai pendamping non-petarung (v7).
# Berjalan di belakang pemain mengikuti jejak langkahnya. Dipasang oleh
# playerAndControl.spawnTabib() sebagai saudara node pemain agar urutan gambarnya ikut Y-sort.
# Tidak punya collision dan tidak ikut bertarung (di layar pertarungan dia tidak muncul).

const SHEET="res://screens/tree-village/assets/tabib/tabib-idle.png"
# animasi memanjat tampak belakang, 4 frame (dibuat tools/make_tabib_climbing.py)
const CLIMB_SHEET="res://screens/tree-village/assets/tabib/tabib-climbing.png"
const CLIMB_FRAMES=4
const FRAME_SIZE=32
const FRAME_COUNT=6
const TRAIL_LENGTH=26
const BEHIND_OFFSET=Vector2(-4,3)

var target=null
var trail=[]
var sprite=null
var shadow=null
var time=0.0
var moving=false
var climbing=false
var playerClimbing=false
var scriptClimb=false
var trailClimb=[]


func _ready():
	var frames=SpriteFrames.new()
	if frames.has_animation("default"):
		frames.remove_animation("default")
	frames.add_animation("idle")
	frames.set_animation_speed("idle",4.0)
	frames.set_animation_loop("idle",true)
	var sheet=load(SHEET)
	for i in FRAME_COUNT:
		var atlas=AtlasTexture.new()
		atlas.atlas=sheet
		atlas.region=Rect2(i*FRAME_SIZE,0,FRAME_SIZE,FRAME_SIZE)
		frames.add_frame("idle",atlas)
	frames.add_animation("climb")
	frames.set_animation_speed("climb",7.0)
	frames.set_animation_loop("climb",true)
	var climbSheet=load(CLIMB_SHEET)
	for i in CLIMB_FRAMES:
		var catlas=AtlasTexture.new()
		catlas.atlas=climbSheet
		catlas.region=Rect2(i*FRAME_SIZE,0,FRAME_SIZE,FRAME_SIZE)
		frames.add_frame("climb",catlas)
	shadow=ColorRect.new()
	shadow.color=Color(0,0,0,0.22)
	shadow.size=Vector2(14,3)
	shadow.position=Vector2(-7,13)
	add_child(shadow)
	sprite=AnimatedSprite2D.new()
	sprite.sprite_frames=frames
	add_child(sprite)
	sprite.play("idle")


# mulai mengikuti pemain; start_ = posisi awal (mis. tempat Tabib berdiri saat adegan)
func follow(target_, start_=null):
	target=target_
	global_position=start_ if start_!=null else target.global_position+Vector2(-26,4)
	trail.clear()
	trailClimb.clear()
	playerClimbing=false
	scriptClimb=false
	_applyClimbVisual(false)


# berjalan bebas ke suatu titik (adegan), tanpa mengikuti pemain. Mengembalikan Tween.
func walkTo(pos_, seconds_=1.8):
	target=null
	if sprite!=null and abs(pos_.x-global_position.x)>1.0:
		sprite.flip_h=pos_.x<global_position.x
	moving=true
	var tween=create_tween()
	tween.tween_property(self,"global_position",pos_,max(seconds_,0.1)).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(func(): moving=false)
	return tween


# Dipanggil playerAndControl saat Ranbyus mulai/selesai memanjat. Tabib tidak langsung ikut memanjat:
# status dicatat di jejak, jadi animasi memanjat baru muncul saat Tabib sampai di tangga.
func setClimbing(active_):
	playerClimbing=active_
	if !active_ and target==null:
		_applyClimbVisual(false)


# memanjat lurus ke titik tertentu (cutscene) dengan sprite memanjat asli. Bisa di-await.
func climbTo(pos_, seconds_=2.0):
	target=null
	moving=true
	scriptClimb=true
	_applyClimbVisual(true)
	var travel=create_tween()
	travel.tween_property(self,"global_position",pos_,max(seconds_,0.1)).set_trans(Tween.TRANS_LINEAR)
	await travel.finished
	scriptClimb=false
	moving=false
	_applyClimbVisual(false)


# ganti antara animasi idle dan memanjat (tampak belakang)
func _applyClimbVisual(on_):
	climbing=on_
	if sprite==null:
		return
	sprite.offset=Vector2.ZERO
	sprite.rotation_degrees=0.0
	if on_:
		sprite.flip_h=false
		sprite.play("climb")
	else:
		sprite.play("idle")


func face(left_):
	if sprite!=null:
		sprite.flip_h=left_


func _physics_process(delta):
	time+=delta
	if sprite==null:
		return
	# langkah kecil naik-turun saat bergerak, diam saat berhenti
	if climbing:
		sprite.offset.y=0.0
	elif moving:
		sprite.offset.y=-abs(sin(time*11.0))*1.8
	else:
		sprite.offset.y=lerp(sprite.offset.y,0.0,min(1.0,delta*12.0))
	if target==null or !is_instance_valid(target):
		return
	var p=target.global_position
	if trail.is_empty() or trail.back().distance_to(p)>0.5:
		trail.append(p)
		trailClimb.append(playerClimbing)
	while trail.size()>TRAIL_LENGTH:
		trail.pop_front()
		trailClimb.pop_front()
	var goal=trail[0]+BEHIND_OFFSET
	var goalClimb=trailClimb[0]
	var before=global_position
	global_position=global_position.lerp(goal,min(1.0,delta*8.0))
	var dx=global_position.x-before.x
	moving=before.distance_to(global_position)>0.12
	# memanjat hanya saat titik jejak yang dituju adalah tangga; berhenti kalau Tabib diam
	if goalClimb!=climbing:
		_applyClimbVisual(goalClimb)
	if climbing:
		if moving:
			if !sprite.is_playing():
				sprite.play("climb")
		else:
			sprite.pause()
	elif abs(dx)>0.05:
		sprite.flip_h=dx<0
