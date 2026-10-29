extends Node2D

# Mesin cutscene sinematik (320x180). Semua latar, cahaya, partikel, kamera, dan dialog dibuat lewat kode
# memakai sprite asli game. Bab-bab cerita ada di epicEnding.gd (extends skrip ini).
# Cara pakai di bab: await go("gordon",Vector2(200,140),1.2); await say("gordon","teks"); await cam_to(pos,zoom,detik)

const THEME=preload("res://common/themes/default.tres")
const SIGIL=preload("res://screens/ending/assets/ritual-sigil.png")
const HEAL=preload("res://screens/ending/assets/healing-glow.png")
const W=320
const H=180
const BAR_H=15
const CPS=38.0

const PL="res://common/characters/player/"
const TV="res://screens/tree-village/assets/"
const EA="res://screens/ending/assets/"
const DK="res://screens/ancient-dungeon/darkus/"
# anim: [file, lebarFrame, tinggiFrame, frameAwal, jumlah, fps, loop]
const SPR={
	"gordon":{"fh":32,"anims":{
		"idle":[PL+"Player-idle.png",32,32,0,4,4.0,true],
		"walk":[PL+"Player-walking-right.png",32,32,0,8,12.0,true],
		"talk":[PL+"Player-talking.png",32,32,0,6,6.0,true],
		"climb":[PL+"Player-climbing.png",32,32,0,4,6.0,true]}},
	# v9.18: skala 0.75 (setinggi Bunda, ~33 px di layar)
	# v9.14: sprite Darkus baru (jalan, duduk, bangun, terbaring) dari tools/make_darkus_cutscene_sprites.py
	"darkus":{"fh":46,"scale":0.75,"anims":{
		"idle":[DK+"darkus-idle-npc.png",47,46,0,4,2.5,true],
		"walk":[DK+"darkus-walk-npc.png",47,46,0,8,11.0,true],
		"sit":[DK+"darkus-sit-npc.png",47,46,0,4,2.5,true],
		"situp":[DK+"darkus-situp-npc.png",47,46,0,2,2.0,false],
		"lie":[DK+"darkus-lie-npc.png",47,46,0,2,1.4,true]}},
	"tabib":{"fh":32,"anims":{
		"idle":[TV+"tabib/tabib-idle.png",32,32,0,6,4.0,true],
		"climb":[TV+"tabib/tabib-climbing.png",32,32,0,4,6.0,true]}},
	"bunda":{"fh":64,"scale":0.55,"anims":{"idle":["res://common/characters/mom/Mom-idle.png",64,64,0,5,5.0,true]}},
	"bear":{"fh":32,"anims":{"idle":["res://screens/bear-village/assets/bear/bear-idle.png",32,32,0,5,5.0,true]}},
	"ibu":{"fh":32,"anims":{"idle":["res://screens/crabs-village/characters/crab-seller/crab-seller-idle.png",32,32,0,5,5.0,true]}},
	"adek":{"fh":282,"scale":0.11,"anims":{"idle":[TV+"adek-idle-wide.png",320,282,0,4,4.0,true]}},
	"adekbed":{"fh":282,"scale":0.11,"anims":{
		"idle":[TV+"adek-wakeup.png",320,282,0,2,1.6,true],
		"wake":[TV+"adek-wakeup.png",320,282,0,8,6.0,false]}},
	"warga1":{"fh":32,"anims":{
		"idle":[EA+"warga-1.png",32,32,0,4,4.0,true],
		"walk":[EA+"warga-1.png",32,32,4,6,12.0,true],
		"cheer":[EA+"warga-1.png",32,32,10,4,8.0,true]}},
	"warga2":{"fh":32,"anims":{
		"idle":[EA+"warga-2.png",32,32,0,4,4.0,true],
		"walk":[EA+"warga-2.png",32,32,4,6,12.0,true],
		"cheer":[EA+"warga-2.png",32,32,10,4,8.0,true]}},
	"warga3":{"fh":32,"anims":{
		"idle":[EA+"warga-3.png",32,32,0,4,4.0,true],
		"walk":[EA+"warga-3.png",32,32,4,6,12.0,true],
		"cheer":[EA+"warga-3.png",32,32,10,4,8.0,true]}},
	"warga4":{"fh":32,"anims":{
		"idle":[EA+"warga-4.png",32,32,0,4,4.0,true],
		"walk":[EA+"warga-4.png",32,32,4,6,12.0,true],
		"cheer":[EA+"warga-4.png",32,32,10,4,8.0,true]}},
	"warga5":{"fh":32,"anims":{
		"idle":[EA+"warga-5.png",32,32,0,4,4.0,true],
		"walk":[EA+"warga-5.png",32,32,4,6,12.0,true],
		"cheer":[EA+"warga-5.png",32,32,10,4,8.0,true]}}
}
const NAMES={
	"gordon":["RANBYUS",Color("#8fd0ff")],"darkus":["DARKUS",Color("#d2a8ff")],"tabib":["PAK TABIB",Color("#9be39b")],
	"bunda":["BUNDA",Color("#ffb3c1")],"adek":["ADEK",Color("#ffe58a")],"bear":["KEPALA DESA BERUANG",Color("#e6b98a")],
	"ibu":["IBU TOKO KEPITING",Color("#ff9f8a")],"warga":["WARGA DESA",Color("#cfe3ff")],"":["",Color.WHITE],
	"wayan":["PAK WAYAN",Color("#e8c987")],"made":["BU MADE",Color("#ff9aa8")],"kadek":["KADEK",Color("#8fc4ff")],
	"nyoman":["NENEK NYOMAN",Color("#d2b4ff")],"putu":["PUTU",Color("#ffe58a")]
}

signal advanced
var world: Node2D
var cam: Camera2D
var ui: CanvasLayer
var bar_t: ColorRect
var bar_b: ColorRect
var fade_rect: ColorRect
var flash_rect: ColorRect
var vignette: TextureRect
var box: Panel
var name_lbl: Label
var text_lbl: Label
var arrow: Label
var cap_lbl: Label
var cap_bg: ColorRect
# v9.29: nama pemain (kakak) yang diketik saat mulai permainan; tulisan "Ranbyus" di naskah diganti otomatis
var hero_name := "Ranbyus"
var actors := {}
var layers := []
var _waiting := false
var _typing := false
var _skip_type := false
var _esc_time := -10.0
var _finished := false
var _t := 0.0

func _ready():
	hero_name=GlobalGame.getHeroName()
	_build()
	await _run()
	await _finish()

func _run():
	pass

# ---------------------------------------------------------------- dasar
func _build():
	world=Node2D.new(); world.y_sort_enabled=true; add_child(world)
	cam=Camera2D.new(); cam.position=Vector2(160,90); add_child(cam); cam.make_current()
	ui=CanvasLayer.new(); ui.layer=50; add_child(ui)
	vignette=TextureRect.new(); vignette.size=Vector2(W,H); vignette.stretch_mode=TextureRect.STRETCH_SCALE; vignette.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var g=Gradient.new(); g.colors=PackedColorArray([Color(0,0,0,0),Color(0,0,0,0.0),Color(0,0,0,0.62)]); g.offsets=PackedFloat32Array([0.0,0.55,1.0])
	var gt=GradientTexture2D.new(); gt.gradient=g; gt.fill=GradientTexture2D.FILL_RADIAL; gt.fill_from=Vector2(0.5,0.5); gt.fill_to=Vector2(1.0,0.9); gt.width=128; gt.height=72
	vignette.texture=gt; ui.add_child(vignette)
	flash_rect=_ui_rect(Color(1,1,1,0)); fade_rect=_ui_rect(Color(0,0,0,1))
	bar_t=_ui_rect(Color.BLACK); bar_t.size=Vector2(W,BAR_H); bar_t.position=Vector2(0,-BAR_H)
	bar_b=_ui_rect(Color.BLACK); bar_b.size=Vector2(W,BAR_H); bar_b.position=Vector2(0,H)
	box=Panel.new(); box.position=Vector2(10,H-BAR_H-47); box.size=Vector2(W-20,44); box.visible=false
	var sb=StyleBoxFlat.new(); sb.bg_color=Color(0.05,0.06,0.1,0.9); sb.border_color=Color(0.88,0.76,0.48,0.9); sb.set_border_width_all(1); sb.set_corner_radius_all(3)
	box.add_theme_stylebox_override("panel",sb); ui.add_child(box)
	name_lbl=_label(8,2,8,Color.WHITE); box.add_child(name_lbl)
	text_lbl=_label(8,13,7,Color("#f4f0e6")); text_lbl.size=Vector2(W-40,28); text_lbl.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; box.add_child(text_lbl)
	arrow=_label(W-34,32,7,Color("#f6d785")); arrow.text="v"; arrow.visible=false; box.add_child(arrow)
	# v9.29: naskah narasi di ATAS layar (di bawah bar sinema atas), bukan di bawah menutupi tokoh
	cap_lbl=_label(20,BAR_H+4,8,Color("#f6e7c1")); cap_lbl.size=Vector2(W-40,30); cap_lbl.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	cap_lbl.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; cap_lbl.modulate.a=0.0; ui.add_child(cap_lbl)
	cap_bg=ColorRect.new(); cap_bg.color=Color(0.02,0.02,0.05,0.62); cap_bg.mouse_filter=Control.MOUSE_FILTER_IGNORE
	cap_bg.show_behind_parent=true; cap_bg.position=Vector2(-10,-3); cap_bg.size=Vector2(W-20,36); cap_lbl.add_child(cap_bg)

func _ui_rect(c):
	var r=ColorRect.new(); r.color=c; r.size=Vector2(W,H); r.mouse_filter=Control.MOUSE_FILTER_IGNORE; ui.add_child(r); return r

func _label(x,y,fs,c):
	var l=Label.new(); l.theme=THEME; l.position=Vector2(x,y); l.add_theme_font_size_override("font_size",fs)
	l.add_theme_color_override("font_color",c); l.add_theme_color_override("font_outline_color",Color(0,0,0,0.85)); l.add_theme_constant_override("outline_size",2)
	l.mouse_filter=Control.MOUSE_FILTER_IGNORE; return l

func _process(delta):
	_t+=delta
	for l in layers:
		l[0].position.x=cam.position.x*(1.0-l[1])

func wait(sec):
	await get_tree().create_timer(sec).timeout

func _unhandled_input(e):
	if e.is_action_pressed("ui_cancel"):
		if _t-_esc_time<2.0:
			_finish_now()
		else:
			_esc_time=_t
			caption("Tekan ESC sekali lagi untuk melewati cutscene",1.6)
		get_viewport().set_input_as_handled()
		return
	if e.is_action_pressed("interact") or e.is_action_pressed("ui_accept") or (e is InputEventMouseButton and e.pressed) or (e is InputEventScreenTouch and e.pressed):
		if _typing: _skip_type=true
		elif _waiting: advanced.emit()
		get_viewport().set_input_as_handled()

func _finish_now():
	if _finished: return
	_finished=true
	Engine.time_scale=1.0
	GlobalScenes.saveParamForScene("story","epic_from_home",false)
	GlobalScenes.saveParamForScene("story","final_ending_started",true)
	GlobalScenes.saveParamForScene("story","epic_ending_played",true)
	SceneTransition.change_scene("res://screens/game/endgame.tscn")

func _finish():
	await fade(1.0,1.2)
	_finish_now()

# ---------------------------------------------------------------- sinema
func bars(on,sec=0.8):
	var t=create_tween().set_parallel(true)
	t.tween_property(bar_t,"position:y",0.0 if on else -BAR_H,sec).set_trans(Tween.TRANS_SINE)
	t.tween_property(bar_b,"position:y",float(H-BAR_H) if on else float(H),sec).set_trans(Tween.TRANS_SINE)
	await t.finished

func fade(a,sec=0.8,col=Color.BLACK):
	fade_rect.color=Color(col.r,col.g,col.b,fade_rect.color.a)
	var t=create_tween(); t.tween_property(fade_rect,"color:a",a,sec); await t.finished

func flash(col=Color.WHITE,sec=0.5,peak=0.85):
	flash_rect.color=Color(col.r,col.g,col.b,peak)
	create_tween().tween_property(flash_rect,"color:a",0.0,sec)

func cam_to(pos,zoom=1.0,sec=1.0):
	var t=create_tween().set_parallel(true)
	t.tween_property(cam,"position",pos,sec).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_property(cam,"zoom",Vector2(zoom,zoom),sec).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await t.finished

func cam_snap(pos,zoom=1.0):
	cam.position=pos; cam.zoom=Vector2(zoom,zoom)

func shake(power=3.0,sec=0.5):
	var t=create_tween(); var n=int(sec/0.03)
	for i in n:
		var k=power*(1.0-float(i)/n)
		t.tween_property(cam,"offset",Vector2(randf_range(-k,k),randf_range(-k,k)),0.03)
	t.tween_property(cam,"offset",Vector2.ZERO,0.03)

func pulse_vignette(times=3):
	for i in times:
		var t=create_tween(); t.tween_property(vignette,"modulate:a",0.35,0.18); t.tween_property(vignette,"modulate:a",1.0,0.42)
		await t.finished

# ganti "Ranbyus" di naskah dengan nama pemain
func _nm(text):
	return str(text).replace("Ranbyus",hero_name)

# Kecilkan huruf bertahap sampai teks muat di max_h, supaya tidak ada teks yang terpotong.
# Mengembalikan tinggi teks yang dipakai (label ikut diubah ukurannya).
func _fit_label(lbl,max_w,max_h,sizes):
	var h=0.0
	for fs in sizes:
		lbl.add_theme_font_size_override("font_size",fs)
		lbl.size=Vector2(max_w,8)
		h=float(lbl.get_line_count())*float(lbl.get_line_height())+3.0
		if h<=max_h:
			break
	lbl.size=Vector2(max_w,h)
	return h

func caption(text,sec=3.0):
	text=_nm(text)
	cap_lbl.text=text
	var ch=_fit_label(cap_lbl,W-40,56.0,[8,7,6])
	cap_lbl.position=Vector2(20,BAR_H+4)
	cap_bg.position=Vector2(-10,-3); cap_bg.size=Vector2(W-20,ch+6.0)
	var t=create_tween(); t.tween_property(cap_lbl,"modulate:a",1.0,0.5); t.tween_interval(sec); t.tween_property(cap_lbl,"modulate:a",0.0,0.6)
	await t.finished

func title(text,sub="",sec=3.0):
	var l=_label(0,70,16,Color("#f7d68b")); l.size=Vector2(W,24); l.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; l.text=_nm(text); l.modulate.a=0.0; ui.add_child(l)
	var s=_label(0,96,8,Color("#e9e2d0")); s.size=Vector2(W,12); s.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; s.text=_nm(sub); s.modulate.a=0.0; ui.add_child(s)
	var t=create_tween().set_parallel(true)
	t.tween_property(l,"modulate:a",1.0,1.0); t.tween_property(s,"modulate:a",1.0,1.6)
	await t.finished
	await wait(sec)
	var t2=create_tween().set_parallel(true); t2.tween_property(l,"modulate:a",0.0,0.9); t2.tween_property(s,"modulate:a",0.0,0.9)
	await t2.finished
	l.queue_free(); s.queue_free()

# dialog dengan mesin ketik; menunggu E / Enter / klik
func say(who,text,speaker=""):
	var key=speaker if speaker!="" else who
	var info=NAMES.get(key,NAMES[""])
	text=_nm(text)
	# nama pembicara: tokoh utama memakai nama pemain, bukan "RANBYUS"
	name_lbl.text=hero_name.to_upper() if key=="gordon" else info[0]
	name_lbl.add_theme_color_override("font_color",info[1])
	text_lbl.text=text
	# v9.29: kotak dialog menyesuaikan panjang teks (huruf dikecilkan / kotak dinaikkan) agar tidak terpotong
	var th=_fit_label(text_lbl,W-40,28.0,[7,6])
	var bh=max(44.0,13.0+th+5.0)
	box.size.y=bh; box.position.y=H-BAR_H-3.0-bh; arrow.position.y=bh-12.0
	text_lbl.visible_characters=0; box.visible=true; arrow.visible=false
	var talker=actors.get(who)
	if talker!=null: _play(talker.get_node("spr"),"talk")
	_typing=true; _skip_type=false
	var shown=0.0
	while shown<text.length() and !_skip_type:
		await get_tree().process_frame
		shown+=get_process_delta_time()*CPS; text_lbl.visible_characters=int(shown)
	text_lbl.visible_characters=-1; _typing=false; _skip_type=false
	if talker!=null: _play(talker.get_node("spr"),"idle")
	arrow.visible=true; _waiting=true
	await advanced
	_waiting=false; arrow.visible=false

func hide_box():
	box.visible=false

# ---------------------------------------------------------------- aktor
func add_actor(id,kind,pos,flip=false,tint=Color.WHITE,scl=1.0):
	var info=SPR[kind]; var n=Node2D.new(); n.position=pos; world.add_child(n)
	var sh=Sprite2D.new(); sh.texture=_radial(); sh.scale=Vector2(0.5,0.16)*(info.get("scale",1.0)*scl*max(1.0,info.fh/32.0)); sh.modulate=Color(0,0,0,0.45); sh.position=Vector2(0,1); sh.z_index=-1; n.add_child(sh)
	var spr=AnimatedSprite2D.new(); spr.name="spr"; spr.sprite_frames=_frames(info.anims); n.add_child(spr)
	var s=info.get("scale",1.0)*scl; n.set_meta("bs",s); spr.scale=Vector2(s,s); spr.offset=Vector2(0,-info.fh/2.0); spr.flip_h=flip; spr.modulate=tint
	n.set_meta("kind",kind); actors[id]=n; spr.play("idle"); return n

func _frames(anims):
	var f=SpriteFrames.new(); f.remove_animation("default")
	for k in anims:
		var a=anims[k]; var tex=load(a[0]); f.add_animation(k); f.set_animation_speed(k,a[5]); f.set_animation_loop(k,a[6])
		for i in a[4]:
			var at=AtlasTexture.new(); at.atlas=tex; at.region=Rect2((a[3]+i)*a[1],0,a[1],a[2]); f.add_frame(k,at)
	return f

func _play(spr,anim):
	if spr.sprite_frames.has_animation(anim): spr.play(anim)
	elif anim!="idle": spr.play("idle")

func A(id): return actors[id]
func face(id,left): actors[id].get_node("spr").flip_h=left
func anim(id,nm): _play(actors[id].get_node("spr"),nm)

# berjalan dengan langkah naik-turun; mengembalikan tween (bisa dipakai paralel)
func go(id,to,sec,anim_name="walk"):
	var a=actors[id]; var spr=a.get_node("spr")
	if abs(to.x-a.position.x)>1.0: spr.flip_h=to.x<a.position.x
	_play(spr,anim_name)
	var t=a.create_tween(); t.tween_property(a,"position",to,sec).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	var b=spr.create_tween().set_loops()
	b.tween_property(spr,"position:y",-1.6,0.11); b.tween_property(spr,"position:y",0.0,0.11)
	t.finished.connect(_end_walk.bind(spr,b))
	return t

func _end_walk(spr,b):
	b.kill(); spr.position.y=0.0; _play(spr,"idle")

func hop(id,height=6.0,times=2):
	var spr=actors[id].get_node("spr"); var t=spr.create_tween()
	for i in times:
		t.tween_property(spr,"position:y",-height,0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		t.tween_property(spr,"position:y",0.0,0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	return t

func emote(id,txt,col=Color("#ffe35a")):
	var sp=actors[id].get_node("spr")
	var l=_label(-6,sp.offset.y*2.0*sp.scale.y-9,10,col); l.text=txt; l.z_index=100; actors[id].add_child(l)
	var t=create_tween(); t.tween_property(l,"position:y",l.position.y-5,0.25).set_trans(Tween.TRANS_BACK); t.tween_interval(0.9); t.tween_property(l,"modulate:a",0.0,0.3); t.tween_callback(l.queue_free)

# ---------------------------------------------------------------- pelukan & emosi (v9.13)
# Adek melompat ke arah target: node bergerak lurus, sprite membentuk busur (bayangan tetap di tanah).
func leap(id,to,sec,height=20.0):
	var a=actors[id]; var spr=a.get_node("spr")
	if abs(to.x-a.position.x)>1.0: spr.flip_h=to.x<a.position.x
	var t=a.create_tween()
	t.tween_method(_leap_step.bind(a,a.position,to,height),0.0,1.0,sec)
	return t

func _leap_step(p,node,from,to,height):
	node.position=from.lerp(to,p)
	node.get_node("spr").position.y=-sin(p*PI)*height

# Menempelkan tokoh (yang memeluk) di dada tokoh lain; lift = tinggi tubuh yang terangkat.
func hug_hold(id,target,lift=6.0):
	var a=actors[id]; var b=actors[target]
	var left=a.position.x<b.position.x
	a.position=Vector2(b.position.x+(-5.0 if left else 5.0),b.position.y+1.0)
	a.get_node("spr").flip_h=!left
	a.get_node("spr").position.y=-lift

# memipihkan / meregangkan sprite (sx, sy relatif terhadap ukuran normal), kaki tetap di tanah
func squash(id,sx,sy,sec=0.15):
	var a=actors[id]; var spr=a.get_node("spr")
	var bs=a.get_meta("bs",1.0)
	var t=spr.create_tween()
	t.tween_property(spr,"scale",Vector2(bs*sx,bs*sy),sec).set_trans(Tween.TRANS_SINE)
	return t

# bergoyang pelan (dipakai saat berpelukan); unsway() menghentikannya
func sway(id,deg=1.6,period=1.5):
	var a=actors[id]; var spr=a.get_node("spr")
	unsway(id)
	var t=spr.create_tween().set_loops()
	t.tween_property(spr,"rotation_degrees",deg,period/2.0).set_trans(Tween.TRANS_SINE)
	t.tween_property(spr,"rotation_degrees",-deg,period/2.0).set_trans(Tween.TRANS_SINE)
	a.set_meta("sway",t)

func unsway(id):
	var a=actors[id]
	if a.has_meta("sway"):
		a.get_meta("sway").kill()
		a.remove_meta("sway")
	a.get_node("spr").rotation_degrees=0.0

# air mata haru: tetesan biru kecil jatuh dari mata selama sec detik
func tears(id,sec=2.6):
	var a=actors[id]; var spr=a.get_node("spr")
	var fh=SPR[a.get_meta("kind")].fh*spr.scale.y
	var p=puff(a,Vector2(0,-fh*0.6+spr.position.y),Vector2(4.5,0.5),10,0.9,Vector2(0,1),12,6,Color(0.65,0.85,1.0,0.95),Vector2(0,55),1.5)
	p.get_tree().create_timer(sec).timeout.connect(_free_node.bind(p))
	return p

func _free_node(n):
	if is_instance_valid(n): n.queue_free()

# hati kecil melayang naik lalu memudar
func hearts(pos,count=6,spread=16.0):
	for i in count:
		var h=Node2D.new(); h.position=pos+Vector2(randf_range(-spread,spread),randf_range(-4.0,4.0)); h.z_index=90; world.add_child(h)
		var col=Color(1,0.45,0.62) if i%2==0 else Color(1,0.64,0.76)
		var s=randf_range(0.8,1.3)
		disc(h,Vector2(-1.5*s,0),1.6*s,col,8); disc(h,Vector2(1.5*s,0),1.6*s,col,8)
		poly(h,[Vector2(-3.1*s,0.6*s),Vector2(3.1*s,0.6*s),Vector2(0,4.4*s)],col)
		h.modulate.a=0.0
		var t=h.create_tween(); t.tween_interval(randf_range(0.0,0.7))
		t.tween_property(h,"modulate:a",1.0,0.2)
		t.parallel().tween_property(h,"position:y",h.position.y-randf_range(22.0,38.0),1.6)
		t.parallel().tween_property(h,"position:x",h.position.x+randf_range(-6.0,6.0),1.6)
		t.tween_property(h,"modulate:a",0.0,0.5)
		t.tween_callback(h.queue_free)

# ---------------------------------------------------------------- latar & efek
func reset_world():
	for c in world.get_children(): c.queue_free()
	actors.clear(); layers.clear(); cam.offset=Vector2.ZERO; cam_snap(Vector2(160,90)); vignette.modulate.a=1.0

func layer(factor,parent=null):
	var n=Node2D.new(); (parent if parent!=null else world).add_child(n); layers.append([n,factor]); n.y_sort_enabled=false; return n

func rect(parent,x,y,w,h,col):
	var r=ColorRect.new(); r.position=Vector2(x,y); r.size=Vector2(w,h); r.color=col; r.mouse_filter=Control.MOUSE_FILTER_IGNORE; parent.add_child(r); return r

func poly(parent,pts,col):
	var p=Polygon2D.new(); p.polygon=PackedVector2Array(pts); p.color=col; parent.add_child(p); return p

func disc(parent,c,r,col,n=16):
	var pts=[]
	for i in n: pts.append(c+Vector2(cos(TAU*i/n),sin(TAU*i/n))*r)
	return poly(parent,pts,col)

func sky(parent,top,bottom,x=-260,y=-140,w=840,h=420):
	var gr=Gradient.new(); gr.colors=PackedColorArray([top,bottom]); gr.offsets=PackedFloat32Array([0.0,1.0])
	var gt=GradientTexture2D.new(); gt.gradient=gr; gt.fill=GradientTexture2D.FILL_LINEAR; gt.fill_from=Vector2(0,0); gt.fill_to=Vector2(0,1); gt.width=4; gt.height=64
	var tr=TextureRect.new(); tr.texture=gt; tr.stretch_mode=TextureRect.STRETCH_SCALE; tr.position=Vector2(x,y); tr.size=Vector2(w,h); parent.add_child(tr); return tr

func _radial():
	var gr=Gradient.new(); gr.colors=PackedColorArray([Color(1,1,1,1),Color(1,1,1,0)]); gr.offsets=PackedFloat32Array([0.0,1.0])
	var gt=GradientTexture2D.new(); gt.gradient=gr; gt.fill=GradientTexture2D.FILL_RADIAL; gt.fill_from=Vector2(0.5,0.5); gt.fill_to=Vector2(1.0,0.5); gt.width=64; gt.height=64
	return gt

# cahaya tambahan (additive); flicker=true untuk obor/api
func glow(parent,pos,radius,col,flicker=false):
	var s=Sprite2D.new(); s.texture=_radial(); s.position=pos; s.scale=Vector2(radius,radius)/32.0; s.modulate=col; s.z_index=60
	var m=CanvasItemMaterial.new(); m.blend_mode=CanvasItemMaterial.BLEND_MODE_ADD; s.material=m; parent.add_child(s)
	if flicker:
		var t=s.create_tween().set_loops(); var base=s.scale
		t.tween_property(s,"scale",base*1.12,randf_range(0.12,0.25)); t.tween_property(s,"scale",base*0.9,randf_range(0.12,0.25))
	return s

func beam(parent,x,top,bottom,w_top,w_bottom,col):
	var p=poly(parent,[Vector2(x-w_top/2.0,top),Vector2(x+w_top/2.0,top),Vector2(x+w_bottom/2.0,bottom),Vector2(x-w_bottom/2.0,bottom)],col)
	var m=CanvasItemMaterial.new(); m.blend_mode=CanvasItemMaterial.BLEND_MODE_ADD; p.material=m; p.z_index=55; return p

# partikel kotak kecil. dir: arah, spread: derajat, one_shot: ledakan sekali
func puff(parent,pos,ext,amount,life,dir,spread,speed,col,grav=Vector2.ZERO,size=2.0,one_shot=false):
	var p=CPUParticles2D.new(); p.position=pos; p.amount=amount; p.lifetime=life; p.one_shot=one_shot; p.explosiveness=0.9 if one_shot else 0.0
	p.emission_shape=CPUParticles2D.EMISSION_SHAPE_RECTANGLE; p.emission_rect_extents=ext; p.direction=dir; p.spread=spread
	p.initial_velocity_min=speed*0.5; p.initial_velocity_max=speed; p.gravity=grav; p.scale_amount_min=size*0.6; p.scale_amount_max=size
	var g=Gradient.new(); g.colors=PackedColorArray([Color(col.r,col.g,col.b,0.0),col,Color(col.r,col.g,col.b,0.0)]); g.offsets=PackedFloat32Array([0.0,0.25,1.0]); p.color_ramp=g
	p.z_index=70; parent.add_child(p); p.emitting=true; return p
