extends Node2D

var playerPath=null

# toast ringkas (lihat common/ui/notification.gd). Dipasang di CanvasLayer agar selalu di layar,
# tidak ikut bergeser bersama kamera.
var _toast=null

func notify(text_, kind_="info", title_=""):
	if _toast==null or !is_instance_valid(_toast):
		var layer=CanvasLayer.new()
		layer.layer=90
		add_child(layer)
		_toast=load("res://common/ui/notification.tscn").instantiate()
		layer.add_child(_toast)
	_toast.display(text_,kind_,title_)

# Altar api hijau penyembuh (lihat common/areas/healShrine.gd). Dipasang satu parent dengan pemain
# supaya urutan gambar (y-sort) dan koordinatnya sama dengan posisi pemain.
const HealShrine=preload("res://common/areas/healShrine.gd")

func spawnHealShrine(pos_, lifeCap_, manaCap_):
	var shrine=Node2D.new()
	shrine.set_script(HealShrine)
	shrine.position=pos_
	shrine.setup(self,lifeCap_,manaCap_)
	getPlayer().get_parent().add_child(shrine)
	return shrine

func setPlayerPath(playerPath_):
	playerPath=playerPath_

func loadPosition():
	if(GlobalPlayer.shouldLoadPosition()):
		getPlayer().position=GlobalPlayer.loadPosition()
		print("load position")
	else:
		print("not load pisition")
		
func getPlayer():
	return get_node(playerPath)


func _on_playerAndControl_quit():
	# Tombol Keluar benar-benar menutup game setelah konfirmasi HUD.
	get_tree().quit()
	

func _on_playerAndControl_save():
	GlobalGame.saveWithPosition(scene_file_path,getPlayer().getPlayerPosition());
	


# Vera menemani sampai desa berikutnya (kepiting / beruang) lalu berpamitan dan pergi.
# Dipanggil dari _ready desa; memakai kotak dialog sendiri sehingga tidak mengganggu dialog desa.
func playVeraFarewell():
	if !GlobalGame.isVeraWithPlayer():
		return
	getPlayer().spawnCompanion()
	getPlayer().disableNavigation()
	# sprite pamit (pose melayang dari gambar kiriman) dipakai selama adegan perpisahan
	if getPlayer().companion!=null:
		getPlayer().companion.useByeSkin()
	await get_tree().create_timer(0.9).timeout

	var dialog=load("res://common/ui/simpleDialog.tscn").instantiate()
	add_child(dialog)
	GlobalGame.addDialogByKey(dialog,GlobalGame.TRAD_VERA_BYE)
	dialog.start()
	await dialog.discussionFinished
	dialog.end()
	dialog.queue_free()

	# Vera terbang pergi: berbalik, mengecil di kejauhan, lalu menghilang
	var vera=getPlayer().companion
	if vera!=null and is_instance_valid(vera):
		var leave=vera.bye(vera.global_position+Vector2(120,-140),2.2)
		await leave.finished
		getPlayer().removeCompanion()
	GlobalGame.setVeraState(GlobalGame.VERA_GONE)
	getPlayer().enableNavigation()


# =====================================================================
# Helper adegan (v7). Dipakai adegan Tabib / Bu Kepiting / Desa Beruang.
# Awalan cs_ = cutscene, supaya tidak bentrok dengan _talk / _moveHero milik tiap scene.
# =====================================================================

func cs_wait(seconds_):
	await get_tree().create_timer(seconds_).timeout


# dialog berformat addDialogByKey, memakai kotak dialog sendiri (tidak mengganggu $simpleDialog scene).
# Navigasi dibiarkan MATI setelah selesai; pemanggil mengaktifkannya lagi di akhir adegan.
func cs_talk(key_):
	var dialog=load("res://common/ui/simpleDialog.tscn").instantiate()
	add_child(dialog)
	GlobalGame.addDialogByKey(dialog,key_)
	getPlayer().disableNavigation()
	dialog.start()
	await dialog.discussionFinished
	dialog.end()
	dialog.queue_free()


# pemain berjalan otomatis ke titik dunia (animasi jalan dipaksa)
func cs_move_hero(to_, seconds_, anim_="walk-right"):
	var body=getPlayer().getPlayerBody()
	body.forcedAnimation=anim_
	body.get_node("AnimatedSprite2D").flip_h=to_.x<body.global_position.x
	var tween=create_tween()
	tween.tween_property(body,"global_position",to_,seconds_).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tween.finished
	body.forcedAnimation=""


# NPC Node2D / StaticBody2D yang punya anak AnimatedSprite2D berjalan dengan langkah kecil
func cs_walk_npc(node_, to_, seconds_):
	if !is_instance_valid(node_):
		return
	if node_.has_method("walk_to_global"):
		await node_.walk_to_global(to_,seconds_)
		return
	var sprite=node_.get_node_or_null("AnimatedSprite2D")
	if sprite!=null and abs(to_.x-node_.global_position.x)>1.0:
		sprite.flip_h=to_.x<node_.global_position.x
	var bob=null
	if sprite!=null:
		bob=create_tween().set_loops()
		bob.tween_property(sprite,"offset:y",-1.6,0.13)
		bob.tween_property(sprite,"offset:y",0.6,0.13)
	var tween=create_tween()
	tween.tween_property(node_,"global_position",to_,seconds_).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tween.finished
	if bob!=null:
		bob.kill()
		sprite.offset=Vector2.ZERO


# Animasi Tabib memanjat tangga/pohon. Mendukung NPC Tabib biasa maupun pendamping follower.
func cs_climb_tabib(node_, to_, seconds_=2.0):
	if !is_instance_valid(node_):
		return
	if node_.has_method("climb_to_global"):
		await node_.climb_to_global(to_,seconds_)
	elif node_.has_method("climbTo"):
		await node_.climbTo(to_,seconds_)
	else:
		var sprite=node_.get_node_or_null("AnimatedSprite2D")
		var bob=null
		if sprite!=null:
			bob=create_tween().set_loops()
			bob.tween_property(sprite,"offset:y",-1.8,0.16)
			bob.tween_property(sprite,"offset:y",0.4,0.16)
		var move=create_tween()
		move.tween_property(node_,"global_position",to_,max(seconds_,0.1)).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		await move.finished
		if bob!=null:
			bob.kill()
		if sprite!=null:
			sprite.offset=Vector2.ZERO


# v7.2: NPC mengetuk pintu. Badan maju-mundur sedikit tiap ketukan + tulisan "Tok!" melayang.
func cs_knock(node_, times_=3):
	if !is_instance_valid(node_):
		return
	var basePos=node_.position
	for i in times_:
		cs_pop_mark(node_,"Tok!",Color(1,0.95,0.7),0.5)
		var tween=create_tween()
		tween.tween_property(node_,"position:y",basePos.y-2.0,0.07)
		tween.tween_property(node_,"position:y",basePos.y,0.07)
		await tween.finished
		await cs_wait(0.28)
	node_.position=basePos


# v7.2: ubah transparansi sebuah node (muncul / hilang di ambang pintu)
func cs_fade(node_, alpha_, seconds_=0.3):
	if !is_instance_valid(node_):
		return
	var tween=create_tween()
	tween.tween_property(node_,"modulate:a",alpha_,seconds_)
	await tween.finished


# tanda seru / tanya melayang di atas sebuah node (adegan bingung / teringat)
func cs_pop_mark(node_, text_, color_=Color(1,0.9,0.35), seconds_=1.1):
	var label=Label.new()
	label.text=text_
	label.top_level=true
	label.z_index=100
	label.add_theme_color_override("font_color",color_)
	label.add_theme_color_override("font_outline_color",Color(0.13,0.125,0.2))
	label.add_theme_constant_override("outline_size",4)
	add_child(label)
	label.global_position=node_.global_position+Vector2(-3,-38)
	var t=label.create_tween()
	t.tween_property(label,"position:y",label.position.y-7,seconds_*0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(label,"modulate:a",0.0,seconds_*0.4)
	t.tween_callback(label.queue_free)


# Pak Tabib ikut Ranbyus (non-petarung) kalau tahap quest-nya memang begitu
func spawnTabibFollowerIfNeeded():
	if GlobalGame.isTabibFollowing():
		return getPlayer().spawnTabib()
	return null
