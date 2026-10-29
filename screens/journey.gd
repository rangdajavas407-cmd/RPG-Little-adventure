extends Node2D

# Adegan perjalanan (v7): Bu Kepiting mengantar Ranbyus dan Pak Tabib dari Desa Kepiting ke Desa Beruang.
# Semuanya digambar lewat kode (tanpa aset baru): langit berlapis, bukit jauh, pohon, tanah dan jalan yang
# bergulir ke kiri, tiga tokoh berjalan ke kanan, dan kabut dingin yang makin tebal ke arah utara.
# Setelah selesai langsung masuk ke Desa Beruang (tiba bersama Bu Kepiting, lihat bear-village.gd).
#
# Ubah di sini kalau mau menyetel: DURASI (WAIT_*), warna langit (SKY_*), kecepatan (SPEED_*).

const SCREEN=Vector2(320,180)
const GROUND_Y=128.0

const HERO_SHEET="res://common/characters/player/Player-walking-right.png"
const HERO_FRAMES=8
const TABIB_SHEET="res://screens/tree-village/assets/tabib/tabib-idle.png"
const TABIB_FRAMES=6
const SELLER_SHEET="res://screens/crabs-village/characters/crab-seller/crab-seller-idle.png"
const SELLER_FRAMES=5

const SKY_TOP=Color(0.38,0.58,0.82)
const SKY_BOTTOM=Color(0.82,0.88,0.93)
const SPEED_HILLS=6.0
const SPEED_TREES=22.0
const SPEED_GROUND=48.0
const SPEED_CLOUDS=3.0

const WAIT_BEFORE_FIRST=1.8
const WAIT_BETWEEN=2.0
const WAIT_AFTER=1.6

var layers=[]      # [{node, speed, width}]
var walkers=[]     # NPC yang melangkah (naik-turun kecil)
var mist=null
var time=0.0
var rng=RandomNumberGenerator.new()


func _ready():
	rng.seed=7
	_buildSky()
	_buildClouds()
	_buildHills()
	_buildTrees()
	_buildGround()
	_buildWalkers()
	_buildMist()
	_buildCaption()
	_run()


func _process(delta):
	time+=delta
	for l in layers:
		var n=l.node
		n.position.x-=l.speed*delta
		if n.position.x<=-l.width:
			n.position.x+=l.width
	for w in walkers:
		w.sprite.offset.y=-abs(sin(time*9.0+w.phase))*1.6
	if mist!=null:
		mist.color.a=min(0.34,mist.color.a+delta*0.028)


# ---------- urutan adegan ----------

func _run():
	await get_tree().create_timer(WAIT_BEFORE_FIRST).timeout
	await _talk(GlobalGame.TRAD_JOURNEY_1)
	await get_tree().create_timer(WAIT_BETWEEN).timeout
	await _talk(GlobalGame.TRAD_JOURNEY_2)
	await get_tree().create_timer(WAIT_AFTER).timeout
	# tiba di Desa Beruang bersama Bu Kepiting (musuh di jalan muncul lagi seperti masuk desa biasa)
	GlobalPlayer.clearedEncounters.clear()
	GlobalPlayer.savePosition(Vector2(964,427))
	SceneTransition.change_scene("res://screens/bear-village.tscn")


func _talk(key_):
	var dialog=load("res://common/ui/simpleDialog.tscn").instantiate()
	add_child(dialog)
	GlobalGame.addDialogByKey(dialog,key_)
	dialog.start()
	await dialog.discussionFinished
	dialog.end()
	dialog.queue_free()


# ---------- latar ----------

func _addLayer(node_, speed_, width_):
	add_child(node_)
	layers.append({"node":node_,"speed":speed_,"width":width_})


func _buildSky():
	var bands=12
	var parent=Node2D.new()
	parent.z_index=-100
	add_child(parent)
	for i in bands:
		var t=float(i)/float(bands-1)
		var r=ColorRect.new()
		r.color=SKY_TOP.lerp(SKY_BOTTOM,t)
		r.position=Vector2(0,GROUND_Y*float(i)/float(bands))
		r.size=Vector2(SCREEN.x,GROUND_Y/float(bands)+1.0)
		parent.add_child(r)


func _buildClouds():
	var holder=Node2D.new()
	holder.z_index=-90
	for copy in 2:
		var group=Node2D.new()
		group.position.x=SCREEN.x*copy
		for i in 4:
			var cx=rng.randf_range(10,SCREEN.x-50)
			var cy=rng.randf_range(14,50)
			for k in 3:
				var puff=ColorRect.new()
				puff.color=Color(1,1,1,0.78)
				puff.size=Vector2(rng.randf_range(18,30),rng.randf_range(5,8))
				puff.position=Vector2(cx+k*9,cy-(k%2)*3)
				group.add_child(puff)
		holder.add_child(group)
	_addLayer(holder,SPEED_CLOUDS,SCREEN.x)


func _buildHills():
	var holder=Node2D.new()
	holder.z_index=-80
	for copy in 2:
		var poly=Polygon2D.new()
		poly.color=Color(0.40,0.52,0.62)
		var pts=PackedVector2Array()
		pts.append(Vector2(0,GROUND_Y))
		for i in 33:
			var x=SCREEN.x*float(i)/32.0
			pts.append(Vector2(x,GROUND_Y-34-sin(TAU*2.0*x/SCREEN.x)*14.0-sin(TAU*5.0*x/SCREEN.x)*4.0))
		pts.append(Vector2(SCREEN.x,GROUND_Y))
		poly.polygon=pts
		poly.position.x=SCREEN.x*copy
		holder.add_child(poly)
	_addLayer(holder,SPEED_HILLS,SCREEN.x)


func _buildTrees():
	var holder=Node2D.new()
	holder.z_index=-60
	for copy in 2:
		var group=Node2D.new()
		group.position.x=SCREEN.x*copy
		var x=8.0
		while x<SCREEN.x-6:
			var h=rng.randf_range(22,36)
			var trunk=ColorRect.new()
			trunk.color=Color(0.30,0.20,0.14)
			trunk.size=Vector2(3,h*0.45)
			trunk.position=Vector2(x-1,GROUND_Y-h*0.45)
			group.add_child(trunk)
			var crown=Polygon2D.new()
			crown.color=Color(0.16,0.38,0.24).lerp(Color(0.30,0.50,0.30),rng.randf())
			var pts=PackedVector2Array()
			for i in 10:
				var a=TAU*float(i)/10.0
				pts.append(Vector2(cos(a)*h*0.34,sin(a)*h*0.42))
			crown.polygon=pts
			crown.position=Vector2(x+0.5,GROUND_Y-h*0.62)
			group.add_child(crown)
			x+=rng.randf_range(20,42)
		holder.add_child(group)
	_addLayer(holder,SPEED_TREES,SCREEN.x)


func _buildGround():
	# tanah dan rumput (diam), lalu jalan setapak dan kerikil yang bergulir
	var holder=Node2D.new()
	holder.z_index=-40
	add_child(holder)
	var grass=ColorRect.new()
	grass.color=Color(0.33,0.52,0.30)
	grass.position=Vector2(0,GROUND_Y)
	grass.size=Vector2(SCREEN.x,SCREEN.y-GROUND_Y)
	holder.add_child(grass)
	var path=ColorRect.new()
	path.color=Color(0.62,0.50,0.34)
	path.position=Vector2(0,GROUND_Y+8)
	path.size=Vector2(SCREEN.x,26)
	holder.add_child(path)
	var edge=ColorRect.new()
	edge.color=Color(0.48,0.38,0.26)
	edge.position=Vector2(0,GROUND_Y+8)
	edge.size=Vector2(SCREEN.x,2)
	holder.add_child(edge)

	var pebbles=Node2D.new()
	pebbles.z_index=-39
	for copy in 2:
		var group=Node2D.new()
		group.position.x=SCREEN.x*copy
		for i in 18:
			var p=ColorRect.new()
			p.color=Color(0.50,0.40,0.28) if i%2==0 else Color(0.72,0.62,0.46)
			p.size=Vector2(rng.randf_range(2,4),1)
			p.position=Vector2(rng.randf_range(0,SCREEN.x-4),GROUND_Y+rng.randf_range(12,32))
			group.add_child(p)
		for i in 10:
			var tuft=ColorRect.new()
			tuft.color=Color(0.24,0.44,0.24)
			tuft.size=Vector2(2,3)
			tuft.position=Vector2(rng.randf_range(0,SCREEN.x-4),GROUND_Y+rng.randf_range(38,SCREEN.y-GROUND_Y-4))
			group.add_child(tuft)
		pebbles.add_child(group)
	_addLayer(pebbles,SPEED_GROUND,SCREEN.x)


# ---------- tokoh ----------

func _makeFrames(sheet_, count_, speed_):
	var frames=SpriteFrames.new()
	if frames.has_animation("default"):
		frames.remove_animation("default")
	frames.add_animation("walk")
	frames.set_animation_speed("walk",speed_)
	frames.set_animation_loop("walk",true)
	var tex=load(sheet_)
	for i in count_:
		var atlas=AtlasTexture.new()
		atlas.atlas=tex
		atlas.region=Rect2(i*32,0,32,32)
		frames.add_frame("walk",atlas)
	return frames


func _addWalker(sheet_, count_, speed_, x_, phase_, bob_):
	var holder=Node2D.new()
	holder.position=Vector2(x_,GROUND_Y+14)
	holder.z_index=10
	add_child(holder)
	var shadow=ColorRect.new()
	shadow.color=Color(0,0,0,0.25)
	shadow.size=Vector2(14,3)
	shadow.position=Vector2(-7,11)
	holder.add_child(shadow)
	var sprite=AnimatedSprite2D.new()
	sprite.sprite_frames=_makeFrames(sheet_,count_,speed_)
	sprite.position=Vector2(0,-4)
	holder.add_child(sprite)
	sprite.play("walk")
	if bob_:
		walkers.append({"sprite":sprite,"phase":phase_})


func _buildWalkers():
	# urutan dari belakang ke depan: Pak Tabib, Ranbyus, Bu Kepiting (yang memimpin jalan)
	_addWalker(TABIB_SHEET,TABIB_FRAMES,4.0,104.0,0.0,true)
	_addWalker(HERO_SHEET,HERO_FRAMES,10.0,148.0,0.0,false)
	_addWalker(SELLER_SHEET,SELLER_FRAMES,5.0,192.0,1.7,true)


# ---------- kabut dan teks ----------

func _buildMist():
	var layer=CanvasLayer.new()
	layer.layer=20
	add_child(layer)
	mist=ColorRect.new()
	mist.color=Color(0.78,0.88,1.0,0.0)
	mist.size=SCREEN
	mist.mouse_filter=Control.MOUSE_FILTER_IGNORE
	layer.add_child(mist)


func _buildCaption():
	var layer=CanvasLayer.new()
	layer.layer=30
	add_child(layer)
	var label=Label.new()
	label.theme=load("res://common/themes/default.tres")
	label.text=GlobalGame.getTraductionById(GlobalGame.TRAD_JOURNEY_CAPTION)
	label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	label.size=Vector2(SCREEN.x,16)
	label.position=Vector2(0,12)
	label.add_theme_color_override("font_color",Color(1,1,1))
	label.add_theme_color_override("font_outline_color",Color(0.13,0.125,0.2))
	label.add_theme_constant_override("outline_size",4)
	label.modulate.a=0.0
	layer.add_child(label)
	var t=label.create_tween()
	t.tween_property(label,"modulate:a",1.0,0.6)
	t.tween_interval(3.2)
	t.tween_property(label,"modulate:a",0.0,0.8)
