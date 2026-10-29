extends Node

# Adegan ritual setelah Bhuta Kala gugur di pertempuran (Ancient Dungeon).
# Pemain keluar dari pertempuran dan kembali ke ruang Bhuta Kala. Sigil tergambar di lantai,
# dupa dan lilin menyala, lalu Satan bangkit dari lingkaran dan pemain dipaksa bertarung lagi.
#
# Dipasang oleh dungeon.gd:
#   var ritual=RitualCutscene.new(); ritual.setup(self)
#   ritual.buildSet(true)    # adegan: sigil belum tergambar
#   await ritual.play()      # selesai -> signal finished -> pertarungan melawan Satan dimulai
# Kalau pemain kalah lalu kembali ke dungeon, dungeon.gd memanggil ritual.buildSet(false)
# agar sigil dan perlengkapannya langsung terpasang dan menyala redup.

signal finished

const SigilScript=preload("res://screens/ancient-dungeon/ritualSigil.gd")
const PropScript=preload("res://screens/ancient-dungeon/ritualProp.gd")
const EnemySprites=preload("res://common/fighters/enemySprites.gd")
const DefaultTheme=preload("res://common/themes/default.tres")

# pusat sigil di lantai ruang Bhuta Kala, dan titik tempat Bhuta Kala / Satan berdiri
const SIGIL_CENTER=Vector2(864,86)
const SATAN_FEET=Vector2(864,80)

const BAR_TOP=12.0
const BAR_BOTTOM=38.0

const COLOR_NARRATOR=Color(0.93,0.94,1.0)
const COLOR_SATAN=Color(1.0,0.45,0.4)
const COLOR_DARK_ROOM=Color(0.30,0.24,0.40)

var dungeon=null
var sigil=null
var props=[]
var satan=null
var cam=null
var ui=null
var barTop=null
var barBottom=null
var label=null
var flash=null
var fade=null


func setup(dungeon_):
	dungeon=dungeon_


#--- pemasangan sigil dan perlengkapan ritual di lantai

# animated_=true: semuanya belum ada (akan muncul di adegan). false: sudah terpasang dan menyala redup.
func buildSet(animated_):
	# sigil dipasang tepat di atas lantai dan di bawah dinding
	var wallsIndex=dungeon.get_node("walls").get_index()
	sigil=Node2D.new()
	sigil.set_script(SigilScript)
	sigil.position=SIGIL_CENTER
	dungeon.add_child(sigil)
	dungeon.move_child(sigil,wallsIndex)

	# dupa di tiap ujung bintang, lilin hitam di antaranya, pedupaan di sisi utara (belakang)
	var sorted=dungeon.get_node("sorted")
	for i in 5:
		_addProp(sorted,"dupa",SIGIL_CENTER+SigilScript.ringPoint(i,1.16))
		if i==2:
			_addProp(sorted,"pedupaan",SIGIL_CENTER+SigilScript.ringPoint(i,1.16,0.5))
		else:
			_addProp(sorted,"lilin",SIGIL_CENTER+SigilScript.ringPoint(i,1.16,0.5))

	if animated_:
		sigil.reveal=0.0
		sigil.energy=0.0
		for p in props:
			p.appear=0.0
			p.lit=0.0
	else:
		sigil.reveal=1.0
		sigil.energy=0.35
		for p in props:
			p.appear=1.0
			p.lit=1.0


func _addProp(parent_,kind_,pos_):
	var node=Node2D.new()
	node.set_script(PropScript)
	node.setup(kind_)
	node.position=pos_
	parent_.add_child(node)
	props.append(node)
	return node


#--- adegan

func play():
	var player=dungeon.getPlayer()
	player.disableNavigation()
	_hideGameUi(player)
	_buildUi()
	await _wait(0.8)

	_makeCamera(player)
	var barsIn=create_tween()
	barsIn.tween_property(barTop,"position:y",0.0,0.6)
	barsIn.parallel().tween_property(barBottom,"position:y",_screenSize().y-BAR_BOTTOM,0.6)
	await _panCamera(SIGIL_CENTER+Vector2(0,16),1.3)

	# 1. asap hitam sisa Bhuta Kala
	_smokeBurst(SATAN_FEET,12)
	await _say("Asap hitam sisa tubuh Bhuta Kala merayap ke lantai... dan tidak mau lenyap.",COLOR_NARRATOR,1.4)

	# 2. sigil tergambar, ruangan menggelap
	var dim=dungeon.get_node_or_null("darkness")
	if dim!=null:
		var dimTween=create_tween()
		dimTween.tween_property(dim,"color",COLOR_DARK_ROOM,2.6)
	var sigilTween=create_tween()
	sigilTween.tween_property(sigil,"reveal",1.0,3.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	sigilTween.parallel().tween_property(sigil,"energy",0.3,3.6)
	_shake(0.7,3.4)
	await _say("Tanah bergetar. Garis-garis merah menyala sendiri, menggambar sigil di lantai!",COLOR_NARRATOR,1.6)

	# 3. dupa dan lilin menyala satu per satu
	var index=0
	for p in props:
		var grow=create_tween()
		grow.tween_property(p,"appear",1.0,0.35).set_delay(0.15*index)
		grow.tween_property(p,"lit",1.0,0.6).set_delay(0.1)
		index+=1
	await _say("Dupa-dupa menancap sendiri dan menyala. Bau hangus menusuk hidung...",COLOR_NARRATOR,1.6)
	# Sisipan close-up singkat membuat adegan terasa seperti kamera film, bukan satu bidikan panjang.
	if props.size() > 0:
		await _panCamera(props[0].global_position + Vector2(0, 10), 0.48)
		await _wait(0.18)
		await _panCamera(SIGIL_CENTER + Vector2(0, 16), 0.55)

	# 4. bisikan dari bawah lantai
	var charge=create_tween()
	charge.tween_property(sigil,"energy",0.85,3.2)
	_shake(1.4,3.0)
	await _say("Bisikan merayap dari bawah lantai: 'Nyawa penjaga sudah dibayar... bukalah pintunya!'",COLOR_NARRATOR,1.8)

	# 5. puncak ritual: tiang cahaya, kilat, Satan bangkit
	var climax=create_tween()
	climax.tween_property(sigil,"energy",1.0,0.8)
	climax.parallel().tween_property(sigil,"beam",1.0,0.9).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await _wait(0.9)
	_flash(Color(1.0,0.75,0.6),0.95,0.6)
	_shake(3.0,1.4)
	_smokeBurst(SATAN_FEET,18)
	await _summonSatan()
	await _wait(0.25)
	var beamOut=create_tween()
	beamOut.tween_property(sigil,"beam",0.0,1.0)
	await _wait(1.3)
	await _say("Satan: 'Hahaha... akhirnya pintu itu terbuka. Sudah lama aku menunggu!'",COLOR_SATAN,1.4)

	# 6. Satan menantang, pemain tidak bisa kabur
	await _say("Satan: 'Bhuta Kala sudah menukar nyawanya denganku. Sekarang giliranmu!'",COLOR_SATAN,1.4)
	for p in props:
		if p.kind=="dupa" or p.kind=="lilin":
			var out=create_tween()
			out.tween_property(p,"lit",0.0,0.4)
	_flash(Color(0.8,0.1,0.1),0.5,0.5)
	_shake(2.0,0.6)
	dungeon.notify("Satan menghadangmu! Tidak ada jalan kabur!","danger")
	await _say("Lorong di belakangmu runtuh menutup. Tidak ada jalan lari!",COLOR_NARRATOR,1.2)

	# 7. layar menggelap, pertarungan dimulai oleh dungeon.gd
	var toBlack=create_tween()
	toBlack.tween_property(fade,"color:a",1.0,0.6)
	await toBlack.finished
	finished.emit()


#--- bantuan adegan

# Gerakan napas kecil pada karakter yang sedang diam supaya sprite tidak terasa beku.
func _addIdleBreath(sprite_):
	if sprite_ == null or !is_instance_valid(sprite_):
		return
	var breath = sprite_.create_tween().set_loops()
	breath.tween_property(sprite_, "offset:y", -1.0, 0.62).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	breath.tween_property(sprite_, "offset:y", 0.0, 0.62).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _screenSize():
	return get_viewport().get_visible_rect().size


func _wait(seconds_):
	return get_tree().create_timer(seconds_).timeout


# UI sinematik: bar hitam atas-bawah, teks narasi di bar bawah, lapisan kilat, dan lapisan fade hitam
func _buildUi():
	var size=_screenSize()
	ui=CanvasLayer.new()
	ui.layer=80
	add_child(ui)

	barTop=ColorRect.new()
	barTop.color=Color(0,0,0,1)
	barTop.size=Vector2(size.x,BAR_TOP)
	barTop.position=Vector2(0,-BAR_TOP)
	barTop.mouse_filter=Control.MOUSE_FILTER_IGNORE
	ui.add_child(barTop)

	barBottom=ColorRect.new()
	barBottom.color=Color(0,0,0,1)
	barBottom.size=Vector2(size.x,BAR_BOTTOM)
	barBottom.position=Vector2(0,size.y)
	barBottom.mouse_filter=Control.MOUSE_FILTER_IGNORE
	ui.add_child(barBottom)

	label=Label.new()
	label.theme=DefaultTheme
	label.size=Vector2(size.x-24,BAR_BOTTOM-4)
	label.position=Vector2(12,size.y-BAR_BOTTOM+2)
	label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size",7)
	label.add_theme_color_override("font_outline_color",Color(0,0,0,1))
	label.add_theme_constant_override("outline_size",3)
	label.mouse_filter=Control.MOUSE_FILTER_IGNORE
	label.text=""
	ui.add_child(label)

	flash=ColorRect.new()
	flash.color=Color(1,1,1,0)
	flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	flash.mouse_filter=Control.MOUSE_FILTER_IGNORE
	ui.add_child(flash)

	fade=ColorRect.new()
	fade.color=Color(0.02,0.0,0.03,0)
	fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fade.mouse_filter=Control.MOUSE_FILTER_STOP   # blokir sentuhan selama adegan
	ui.add_child(fade)


# HUD dan kontrol sentuh disembunyikan selama adegan
func _hideGameUi(player_):
	for nodeName in ["HUD","navigation"]:
		var node=player_.get_node_or_null(nodeName)
		if node!=null:
			node.visible=false


# kamera sinematik: mulai dari posisi kamera pemain, batasnya sama dengan kamera pemain
func _makeCamera(player_):
	var playerCam=player_.getPlayerBody().get_node("Camera2D")
	cam=Camera2D.new()
	cam.position=playerCam.get_screen_center_position()
	cam.limit_left=playerCam.limit_left
	cam.limit_top=playerCam.limit_top
	cam.limit_right=playerCam.limit_right
	cam.limit_bottom=playerCam.limit_bottom
	dungeon.add_child(cam)
	cam.enabled=true
	cam.make_current()


func _panCamera(target_,secs_):
	var t=create_tween()
	t.tween_property(cam,"position",target_,secs_).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await t.finished


# teks narasi muncul huruf demi huruf di bar bawah, lalu ditahan sebentar
func _say(text_,color_,hold_):
	label.text=text_
	label.add_theme_color_override("font_color",color_)
	if !GlobalPlayer.isDialogAnimationEnabled():
		label.visible_ratio=1.0
	else:
		label.visible_ratio=0.0
		var t=create_tween()
		t.tween_property(label,"visible_ratio",1.0,0.025*text_.length()+0.1)
		await t.finished
	await _wait(hold_)


# kamera bergetar; dipanggil tanpa await supaya berjalan bersamaan dengan adegan
func _shake(strength_,secs_):
	var elapsed=0.0
	while elapsed<secs_ and cam!=null and is_instance_valid(cam):
		cam.offset=Vector2(randf_range(-strength_,strength_),randf_range(-strength_,strength_))
		await get_tree().process_frame
		elapsed+=get_process_delta_time()
	if cam!=null and is_instance_valid(cam):
		cam.offset=Vector2.ZERO


func _flash(color_,alpha_,secs_):
	flash.color=Color(color_.r,color_.g,color_.b,alpha_)
	var t=create_tween()
	t.tween_property(flash,"color:a",0.0,secs_)


# gumpalan asap hitam naik dari lantai (ColorRect kecil yang membesar dan memudar)
func _smokePuff(pos_,color_,size_,rise_,secs_):
	var puff=ColorRect.new()
	puff.color=color_
	puff.size=Vector2(size_,size_)
	puff.pivot_offset=Vector2(size_,size_)*0.5
	puff.position=pos_-Vector2(size_,size_)*0.5
	puff.z_index=30
	puff.mouse_filter=Control.MOUSE_FILTER_IGNORE
	dungeon.add_child(puff)
	var t=puff.create_tween()
	t.tween_property(puff,"position",puff.position+Vector2(randf_range(-14.0,14.0),-rise_),secs_)
	t.parallel().tween_property(puff,"modulate:a",0.0,secs_)
	t.parallel().tween_property(puff,"scale",Vector2(2.4,2.4),secs_)
	t.tween_callback(puff.queue_free)


func _smokeBurst(center_,count_):
	for i in count_:
		var offset=Vector2(randf_range(-22.0,22.0),randf_range(-6.0,8.0))
		var shade=randf_range(0.05,0.2)
		_smokePuff(center_+offset,Color(shade,shade*0.8,shade*1.2,0.85),randf_range(5.0,9.0),randf_range(18.0,44.0),randf_range(1.2,2.2))


# Satan naik dari tengah sigil: muncul perlahan sambil terangkat dari lantai
func _summonSatan():
	satan=AnimatedSprite2D.new()
	satan.sprite_frames=EnemySprites.build("satan")
	# sprite 64x64, kaki di sekitar baris 60: dipasang 22 piksel di atas titik pijak (sama seperti musuh di lorong)
	satan.position=SATAN_FEET+Vector2(0,-22.0+14.0)
	satan.scale=Vector2(0.85,0.85)
	satan.modulate=Color(1,1,1,0)
	dungeon.get_node("sorted").add_child(satan)
	satan.play("idle")
	var t=create_tween()
	t.tween_property(satan,"modulate:a",1.0,1.4)
	t.parallel().tween_property(satan,"position:y",SATAN_FEET.y-22.0,1.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(satan,"scale",Vector2(1,1),1.4)
