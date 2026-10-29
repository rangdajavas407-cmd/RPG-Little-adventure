extends "res://common/class/scene.gd"

const DefaultTheme=preload("res://common/themes/default.tres")
const POTION_TEX=preload("res://common/items/magicpotion/hp-potion-big.png")
const BIKA_TEX=preload("res://common/items/food/bika-ambon-eat-0.png")

# hadiah awal: 1 Ramuan HP dari adek, 3 Bika Ambon dari Bunda
const INTRO_BIKA_COUNT=3

# jenis dialog yang sedang berjalan: "mom", "adek", "give" (memberi obat), ""
var dialogKind=""


func _ready():
	setPlayerPath("Node2D/playerAndControl")
	loadPosition()
	getPlayer().zoomDown()
	getPlayer().loadCameraLimits($cameraRef)

	# Dialog disusun saat pemain menekan E di dekat Bunda atau ranjang adek.

	# intro: Ranbyus bertanya pada Bunda -> adek memanggil -> ramuan HP -> Bunda memberi bika
	if GlobalGame.getStoryStage()==GlobalGame.STAGE_WELL:
		var phase=_introPhase()
		if phase==0:
			_startIntro()
		elif phase==1:
			_showCallMark($Node2D/adekTalk)
		elif phase==2 and _momHasCalled():
			_showCallMark($Node2D/mom/talk)

	# v7: Pak Tabib ikut masuk dan memeriksa Adek (sekali, lalu Tabib terus menemani Ranbyus)
	if GlobalGame.getStoryStage()==GlobalGame.STAGE_MEDICINE and GlobalGame.getTabibQuest()==GlobalGame.TQ_JOINED:
		_playExamScene()
	else:
		spawnTabibFollowerIfNeeded()


# ---------- Intro ----------
# fase: 0 belum mulai, 1 adek memanggil (pemain harus menemuinya),
#       2 ramuan sudah diterima (Bunda memanggil saat pemain mau keluar), 3 selesai

func _introPhase():
	if int(GlobalScenes.getParamForSceneOr("story","intro_gift",0))==1:
		return 3
	return int(GlobalScenes.getParamForSceneOr("story","intro_phase",0))

func _setIntroPhase(phase_):
	GlobalScenes.saveParamForScene("story","intro_phase",phase_)

func _momHasCalled():
	return int(GlobalScenes.getParamForSceneOr("story","intro_called",0))==1

func _inIntro():
	return GlobalGame.getStoryStage()==GlobalGame.STAGE_WELL and _introPhase()<3

func _startIntro():
	getPlayer().disableNavigation()
	await get_tree().create_timer(0.9).timeout
	dialogKind="intro_open"
	GlobalGame.addDialogByKey($simpleDialog,GlobalGame.TRAD_INTRO_OPEN)
	_startDialog()

# tanda "!" melayang di atas orang yang memanggil pemain
var callMark=null

func _showCallMark(node_):
	_hideCallMark()
	var label=Label.new()
	label.theme=DefaultTheme
	label.text="!"
	label.top_level=true
	label.z_index=100
	label.add_theme_color_override("font_color",Color(1,0.9,0.35))
	label.add_theme_color_override("font_outline_color",Color(0.13,0.125,0.2))
	label.add_theme_constant_override("outline_size",4)
	add_child(label)
	label.global_position=node_.global_position+Vector2(-2,-54)
	var t=label.create_tween().set_loops()
	t.tween_property(label,"position:y",label.position.y-3,0.4)
	t.tween_property(label,"position:y",label.position.y,0.4)
	callMark=label

func _hideCallMark():
	if callMark!=null and is_instance_valid(callMark):
		callMark.queue_free()
	callMark=null

func _introAfterOpen():
	# adek mendengar percakapan dan memanggil Kakak
	await get_tree().create_timer(0.4).timeout
	dialogKind="intro_call"
	GlobalGame.addDialogByKey($simpleDialog,GlobalGame.TRAD_INTRO_ADEK_CALL)
	_startDialog()

func _introAfterCall():
	_setIntroPhase(1)
	_showTip(GlobalGame.getTraductionById(GlobalGame.TRAD_INTRO_TIP_ADEK))
	_showCallMark($Node2D/adekTalk)
	getPlayer().enableNavigation()

func _introAfterAdek():
	_hideCallMark()
	await _giveGift(GlobalItems.ID.HP_POTION,1,POTION_TEX,0.38,$Node2D/adekTalk.global_position,null,"Ramuan HP")
	_setIntroPhase(2)
	getPlayer().enableNavigation()

func _introAfterMomCall():
	GlobalScenes.saveParamForScene("story","intro_called",1)
	_showTip(GlobalGame.getTraductionById(GlobalGame.TRAD_INTRO_TIP_MOM))
	_showCallMark($Node2D/mom/talk)
	getPlayer().enableNavigation()

func _introAfterMom():
	_hideCallMark()
	# Bunda "memasak": goyang sambil mengeluarkan uap, lalu bika ambon melayang ke pemain
	await _cookingEffect($Node2D/mom)
	await _giveGift(GlobalItems.ID.BIKA_AMBON,INTRO_BIKA_COUNT,BIKA_TEX,0.2,$Node2D/mom.global_position,null,"Bika Ambon")
	_setIntroPhase(3)
	GlobalScenes.saveParamForScene("story","intro_gift",1)
	_showTip(GlobalGame.getTraductionById(GlobalGame.TRAD_INTRO_TIP))
	getPlayer().enableNavigation()

# posisi dunia -> posisi layar (untuk efek di CanvasLayer)
func _toScreen(worldPos_):
	return get_viewport().get_canvas_transform()*worldPos_

func _giveGift(itemId_,count_,texture_,scale_,fromWorld_,unused_,label_):
	var layer=CanvasLayer.new()
	layer.layer=110
	add_child(layer)

	var from=_toScreen(fromWorld_)+Vector2(0,-8)
	var to=_toScreen(getPlayer().getPlayerPosition())+Vector2(0,-14)

	var sprite=Sprite2D.new()
	sprite.texture=texture_
	sprite.position=from
	sprite.scale=Vector2.ZERO
	layer.add_child(sprite)

	# muncul (membesar) lalu melayang melengkung ke arah pemain
	var pop=create_tween()
	pop.tween_property(sprite,"scale",Vector2(scale_,scale_)*1.4,0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	pop.tween_property(sprite,"scale",Vector2(scale_,scale_),0.1)
	await pop.finished
	await get_tree().create_timer(0.25).timeout

	var mid=(from+to)/2+Vector2(0,-26)
	var fly=create_tween()
	fly.tween_property(sprite,"position",mid,0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	fly.tween_property(sprite,"position",to,0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	fly.parallel().tween_property(sprite,"rotation",TAU,0.6)
	await fly.finished

	# masuk ke tas: item bertambah + kilau + teks "+N"
	for i in count_:
		GlobalPlayer.addItemEvenIfExist(itemId_)
	$Node2D/playerAndControl.reloadInvetory()
	_sparkles(layer,to,8)
	_floatText(layer,"+"+str(count_)+" "+label_,Color(1,0.9,0.5),to+Vector2(-30,-16))
	var shrink=create_tween()
	shrink.tween_property(sprite,"scale",Vector2.ZERO,0.2)
	await shrink.finished
	await get_tree().create_timer(1.0).timeout
	layer.queue_free()

func _cookingEffect(node_):
	var layer=CanvasLayer.new()
	layer.layer=110
	add_child(layer)
	var base=node_.scale
	var origin=_toScreen(node_.global_position)+Vector2(0,-16)
	for i in 3:
		var squash=create_tween()
		squash.tween_property(node_,"scale",Vector2(base.x*1.12,base.y*0.88),0.12)
		squash.tween_property(node_,"scale",Vector2(base.x*0.94,base.y*1.08),0.12)
		squash.tween_property(node_,"scale",base,0.1)
		for p in 3:
			var puff=ColorRect.new()
			puff.size=Vector2(3,3)
			puff.color=Color(1,1,1,0.85)
			puff.position=origin+Vector2(randf_range(-8,8),0)
			layer.add_child(puff)
			var rise=create_tween()
			rise.tween_property(puff,"position:y",puff.position.y-18,0.55)
			rise.parallel().tween_property(puff,"modulate:a",0.0,0.55)
			rise.tween_callback(puff.queue_free)
		await get_tree().create_timer(0.38).timeout
	layer.queue_free()

func _sparkles(layer_,pos_,count_):
	for i in count_:
		var s=ColorRect.new()
		s.size=Vector2(3,3)
		s.pivot_offset=Vector2(1.5,1.5)
		s.rotation=deg_to_rad(45)
		s.color=Color(1,0.95,0.6) if i%2==0 else Color(0.8,0.7,1)
		s.position=pos_
		layer_.add_child(s)
		var angle=TAU*float(i)/count_
		var target=pos_+Vector2(cos(angle),sin(angle))*randf_range(14,26)
		var t=create_tween()
		t.tween_property(s,"position",target,0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		t.parallel().tween_property(s,"modulate:a",0.0,0.5).set_delay(0.2)
		t.tween_callback(s.queue_free)

func _floatText(layer_,text_,color_,pos_):
	var label=Label.new()
	label.theme=DefaultTheme
	label.text=text_
	label.add_theme_color_override("font_color",color_)
	label.add_theme_color_override("font_outline_color",Color(0.13,0.125,0.2))
	label.add_theme_constant_override("outline_size",4)
	label.position=pos_
	layer_.add_child(label)
	var t=create_tween()
	t.tween_property(label,"position:y",pos_.y-12,0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(label,"modulate:a",0.0,0.4).set_delay(1.0)
	t.tween_callback(label.queue_free)

func _showTip(text_):
	var layer=CanvasLayer.new()
	layer.layer=110
	add_child(layer)
	var label=Label.new()
	label.theme=DefaultTheme
	label.text=text_
	label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size=Vector2(280,0)
	label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_outline_color",Color(0.13,0.125,0.2))
	label.add_theme_constant_override("outline_size",4)
	label.position=Vector2(20,140)
	layer.add_child(label)
	var t=create_tween()
	t.tween_interval(4.0)
	t.tween_property(label,"modulate:a",0.0,0.6)
	t.tween_callback(layer.queue_free)


# ---------- v7: Tabib memeriksa Adek ----------
# Alur: Tabib masuk -> Bunda mempersilakan -> pemindaian dingin di ranjang -> Tabib bingung
#       -> Ranbyus dan Tabib sama-sama teringat Buah Suwarga -> menuju Desa Kepiting.

func _coldScan(center_, pulses_=3):
	var rune=Node2D.new()
	rune.z_index=60
	add_child(rune)
	rune.global_position=center_
	rune.scale=Vector2(0.35,0.35)
	rune.modulate.a=0.0
	for ring_i in 2:
		var ring=Line2D.new()
		ring.width=1.6 if ring_i==0 else 1.0
		ring.default_color=Color(0.55,0.85,1.0,0.95) if ring_i==0 else Color(0.85,0.95,1.0,0.8)
		ring.closed=true
		var radius=13.0+ring_i*7.0
		for i in 25:
			var angle=TAU*float(i)/24.0
			ring.add_point(Vector2(cos(angle)*radius,sin(angle)*radius*0.55))
		rune.add_child(ring)
	for k in pulses_:
		var pulse=rune.create_tween()
		pulse.tween_property(rune,"modulate:a",0.95,0.18)
		pulse.parallel().tween_property(rune,"scale",Vector2(1.15,1.15),0.55).set_trans(Tween.TRANS_SINE)
		pulse.tween_property(rune,"modulate:a",0.0,0.22)
		pulse.tween_property(rune,"scale",Vector2(0.35,0.35),0.01)
		await pulse.finished
	rune.queue_free()


# serpihan es biru-putih naik dari ranjang (racun dingin)
func _iceSparkles(center_, count_=14):
	for i in count_:
		var s=ColorRect.new()
		s.size=Vector2(2,2)
		s.color=Color(0.7,0.92,1.0) if i%2==0 else Color(1,1,1)
		s.z_index=61
		add_child(s)
		s.global_position=center_+Vector2(randf_range(-22,22),randf_range(-6,8))
		var t=s.create_tween()
		t.tween_property(s,"position:y",s.position.y-randf_range(12,26),randf_range(0.7,1.2))
		t.parallel().tween_property(s,"modulate:a",0.0,1.0).set_delay(0.2)
		t.tween_callback(s.queue_free)
		await get_tree().create_timer(0.08).timeout


# Adek menggigil: ranjang bergetar halus
func _shiverBed(seconds_):
	var bed=$Node2D/bed2
	var base=bed.position
	var t=create_tween()
	var steps=int(seconds_/0.06)
	for i in steps:
		t.tween_property(bed,"position",base+Vector2(randf_range(-0.7,0.7),0),0.06)
	t.tween_property(bed,"position",base,0.06)


func _shakeCameraSmall(strength_=2.0):
	var camera=getPlayer().getPlayerBody().get_node("Camera2D")
	var t=create_tween()
	for i in 5:
		t.tween_property(camera,"offset",Vector2(randf_range(-strength_,strength_),randf_range(-strength_,strength_)),0.03)
	t.tween_property(camera,"offset",Vector2.ZERO,0.03)


func _playExamScene():
	getPlayer().disableNavigation()
	var body=getPlayer().getPlayerBody()
	var tabib=load("res://screens/tree-village/assets/tabib.tscn").instantiate()
	$Node2D.add_child(tabib)
	tabib.get_node("talk").interactionEnabled=false
	var bedPos=$Node2D/bed2/bed.global_position
	var bedSide=$Node2D/adekTalk.global_position
	var heroStand=bedSide+Vector2(-42,12)
	var tabibStand=bedSide+Vector2(-18,-2)

	# 1) Tabib masuk lewat pintu, Ranbyus mengantar ke sisi ranjang
	tabib.global_position=$door.global_position+Vector2(8,-12)
	await cs_wait(0.8)
	tabib.walk_to_global(tabibStand,2.3)
	await cs_move_hero(heroStand,2.0)
	await cs_wait(0.45)
	tabib.get_node("AnimatedSprite2D").flip_h=false
	await cs_talk(GlobalGame.TRAD_HOME_EXAM_1)

	# 2) pemeriksaan: lingkaran dingin berdenyut, serpihan es, Adek menggigil
	var sprite=tabib.get_node("AnimatedSprite2D")
	var lean=create_tween().set_loops(3)
	lean.tween_property(sprite,"scale",Vector2(1.05,0.95),0.35)
	lean.tween_property(sprite,"scale",Vector2.ONE,0.35)
	_shiverBed(2.6)
	_iceSparkles(bedPos,16)
	await _coldScan(bedPos+Vector2(0,-4),3)
	await cs_wait(0.3)
	await cs_talk(GlobalGame.TRAD_HOME_EXAM_2)

	# 3) Tabib bingung: mondar-mandir sambil menggaruk kepala, tanda tanya bermunculan
	cs_pop_mark(tabib,"?",Color(0.7,0.9,1.0),1.3)
	await tabib.walk_to_global(tabibStand+Vector2(-16,8),0.8)
	cs_pop_mark(tabib,"??",Color(0.7,0.9,1.0),1.3)
	await tabib.walk_to_global(tabibStand+Vector2(8,10),0.9)
	cs_pop_mark(tabib,"?",Color(0.7,0.9,1.0),1.3)
	await tabib.walk_to_global(tabibStand,0.7)
	await cs_wait(0.5)

	# 4) keduanya teringat Buah Suwarga di saat yang sama
	cs_pop_mark(tabib,"!",Color(1,0.9,0.35),1.2)
	cs_pop_mark(body,"!",Color(1,0.9,0.35),1.2)
	_flash(sprite)
	_shakeCameraSmall(2.0)
	await cs_wait(0.9)
	await cs_talk(GlobalGame.TRAD_HOME_EXAM_3)

	# 5) selesai: Tabib ikut Ranbyus menuju Desa Kepiting
	var startPos=tabib.global_position
	tabib.queue_free()
	getPlayer().spawnTabib(startPos)
	GlobalGame.setTabibQuest(GlobalGame.TQ_HOME_DONE)
	_showTip(GlobalGame.getTraductionById(GlobalGame.TRAD_HOME_EXAM_TIP))
	getPlayer().enableNavigation()


func _flash(node_):
	node_.modulate=Color(3,3,3)
	node_.create_tween().tween_property(node_,"modulate",Color.WHITE,0.25)


# ---------- Bunda ----------

func _prepareMomDialog():
	dialogKind="mom"
	var stage=GlobalGame.getStoryStage()
	var talks=GlobalGame.getTalkCount("mom_"+str(stage))
	var key

	if stage >= GlobalGame.STAGE_DONE:
		key=GlobalGame.TRAD_HOME_MOM_DONE
	elif stage >= GlobalGame.STAGE_MEDICINE:
		if GlobalGame.hasCure():
			key=GlobalGame.TRAD_HOME_MOM_MED_HAVE
		elif GlobalGame.getTabibQuest()>=GlobalGame.TQ_HOME_DONE:
			key=GlobalGame.TRAD_HOME_MOM_MED_3
		elif talks==0:
			key=GlobalGame.TRAD_HOME_MOM_MED_1
		else:
			key=GlobalGame.TRAD_HOME_MOM_MED_2
	else:
		if GlobalPlayer.hasItem(GlobalItems.ID.NAILS) and GlobalPlayer.hasItem(GlobalItems.ID.HONEY) and GlobalPlayer.hasItem(GlobalItems.ID.BUCKET):
			key=GlobalGame.TRAD_HOME_MOM_WELL_READY
		elif talks==0:
			key=GlobalGame.TRAD_HOME_MOM_WELL_1
		else:
			key=GlobalGame.TRAD_HOME_MOM_WELL_2

	GlobalGame.addTalkCount("mom_"+str(stage))
	GlobalGame.addDialogByKey($simpleDialog,key)


# ---------- Adek ----------

func _prepareAdekDialog():
	dialogKind="adek"
	var stage=GlobalGame.getStoryStage()
	var talks=GlobalGame.getTalkCount("adek_"+str(stage))
	var key

	if stage >= GlobalGame.STAGE_DONE:
		key=GlobalGame.TRAD_HOME_ADEK_DONE
	elif stage >= GlobalGame.STAGE_MEDICINE:
		if GlobalGame.hasCure():
			# obat diberikan -> cerita tamat setelah dialog ini
			key=GlobalGame.TRAD_HOME_ADEK_GIVE
			if GlobalGame.getTabibQuest()==GlobalGame.TQ_RETURN:
				key=GlobalGame.TRAD_HOME_ADEK_GIVE_TABIB
			dialogKind="give"
		elif talks==0:
			key=GlobalGame.TRAD_HOME_ADEK_MED_1
		else:
			key=GlobalGame.TRAD_HOME_ADEK_MED_2
	else:
		# selang-seling dua dialog agar tidak membosankan
		key=GlobalGame.TRAD_HOME_ADEK_WELL_1 if talks%2==0 else GlobalGame.TRAD_HOME_ADEK_WELL_2

	GlobalGame.addTalkCount("adek_"+str(stage))
	GlobalGame.addDialogByKey($simpleDialog,key)


func _startDialog():
	$simpleDialog.start()
	getPlayer().disableNavigation()


func _on_door_playerOpenedDoor():
	if _inIntro():
		# belum boleh keluar: adek / Bunda masih memanggil
		if _introPhase()==1:
			_showTip(GlobalGame.getTraductionById(GlobalGame.TRAD_INTRO_TIP_ADEK))
		elif !_momHasCalled():
			dialogKind="intro_momcall"
			GlobalGame.addDialogByKey($simpleDialog,GlobalGame.TRAD_INTRO_MOM_CALL)
			_startDialog()
		else:
			_showTip(GlobalGame.getTraductionById(GlobalGame.TRAD_INTRO_TIP_MOM))
		return
	GlobalPlayer.savePosition(Vector2(436,160))
	SceneTransition.change_scene("res://screens/tree-village.tscn")


func _on_mom_talk():
	if _inIntro() and _introPhase()==1:
		dialogKind="mom"
		GlobalGame.addDialogByKey($simpleDialog,GlobalGame.TRAD_INTRO_MOM_WAIT)
	elif _inIntro() and _introPhase()==2:
		dialogKind="intro_mom"
		GlobalGame.addDialogByKey($simpleDialog,GlobalGame.TRAD_INTRO_MOM)
	else:
		_prepareMomDialog()
	_startDialog()


func _on_adekTalk_playerOpenedDoor():
	if _inIntro() and _introPhase()==1:
		dialogKind="intro_adek"
		GlobalGame.addDialogByKey($simpleDialog,GlobalGame.TRAD_INTRO_ADEK)
	else:
		_prepareAdekDialog()
	_startDialog()


func _on_simpleDialog_discussionFinished():
	$simpleDialog.end()
	var kind=dialogKind
	dialogKind=""

	if kind=="intro_open":
		_introAfterOpen()
		return
	if kind=="intro_call":
		_introAfterCall()
		return
	if kind=="intro_adek":
		_introAfterAdek()
		return
	if kind=="intro_momcall":
		_introAfterMomCall()
		return
	if kind=="intro_mom":
		_introAfterMom()
		return

	if kind=="give":
		# buah dimakan adek -> tamat
		GlobalGame.consumeCure()
		GlobalGame.setStoryStage(GlobalGame.STAGE_DONE)
		$Node2D/playerAndControl.reloadInvetory()
		# v9.12: hanya ada satu ending (epilog sinematik). Dari rumah, mulai dari bab Pak Tabib merawat Adek.
		GlobalScenes.saveParamForScene("story","epic_from_home",true)
		SceneTransition.change_scene("res://screens/ending/epicEnding.tscn")
	else:
		getPlayer().enableNavigation()


func _on_playerAndControl_pressAccept():
	$simpleDialog.next()


# ---------- Layar tamat ----------

# (tidak dipakai lagi sejak v9.12, ending sekarang di screens/ending/epic/)
func _showEnding():
	getPlayer().disableNavigation()

	# Epilog sinematik: setiap halaman adalah satu beat cerita, bukan blok teks panjang.
	var layer=CanvasLayer.new()
	layer.layer=100
	add_child(layer)

	var bg=ColorRect.new()
	bg.color=Color(0.035,0.045,0.10,0.0)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(bg)

	var content=Control.new()
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(content)

	var chapter=Label.new()
	chapter.theme=DefaultTheme
	chapter.position=Vector2(14,8)
	chapter.size=Vector2(292,22)
	chapter.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	chapter.add_theme_color_override("font_color",Color(0.82,0.88,1.0))
	chapter.add_theme_color_override("font_outline_color",Color(0,0,0,1))
	chapter.add_theme_constant_override("outline_size",3)
	content.add_child(chapter)

	var portrait=TextureRect.new()
	portrait.position=Vector2(68,30)
	portrait.size=Vector2(180,145)
	portrait.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.mouse_filter=Control.MOUSE_FILTER_IGNORE
	content.add_child(portrait)

	var panel=PanelContainer.new()
	panel.position=Vector2(12,178)
	panel.size=Vector2(296,112)
	panel.theme=DefaultTheme
	content.add_child(panel)
	var stack=VBoxContainer.new()
	stack.add_theme_constant_override("separation",4)
	panel.add_child(stack)
	var speaker=Label.new()
	speaker.theme=DefaultTheme
	speaker.add_theme_color_override("font_color",Color(0.75,0.91,1.0))
	stack.add_child(speaker)
	var body=Label.new()
	body.theme=DefaultTheme
	body.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	body.size_flags_vertical=Control.SIZE_EXPAND_FILL
	body.add_theme_color_override("font_outline_color",Color(0,0,0,1))
	body.add_theme_constant_override("outline_size",2)
	stack.add_child(body)
	var next=Button.new()
	next.theme=DefaultTheme
	next.position=Vector2(190,294)
	next.size=Vector2(112,22)
	content.add_child(next)

	var adekSheet=load("res://screens/tree-village/assets/adek-ending.png")
	var frameWidth=float(adekSheet.get_width())/4.0
	var frames=[]
	for i in 4:
		var atlas=AtlasTexture.new()
		atlas.atlas=adekSheet
		atlas.region=Rect2(frameWidth*i,0,frameWidth,adekSheet.get_height())
		frames.append(atlas)

	var pages=[
		["NARASI", "Satan telah dikalahkan. Darkus terjatuh ke lantai dungeon, napasnya berat… lalu perlahan membuka mata.", 0],
		["DARKUS", "Apa yang terjadi...? Aku ingat suaraku sendiri, tetapi tubuhku tidak mau menurut. Satan… dia merasuki tubuhku.", 2],
		["DARKUS", "Aku hampir lupa tujuan kita. Adek sedang kritis! Kita harus menemukan Buah Suwarga sekarang!", 0],
		["NARASI", "Di ruang terdalam, cahaya keemasan berdenyut dari Buah Suwarga. Ranbyus dan Darkus mengambilnya dengan hati-hati.", 3],
		["NARASI", "Mereka bergegas keluar dari dungeon. Tak ada waktu untuk dirayakan—setiap langkah membawa mereka lebih dekat kepada Adek.", 0],
		["PAK TABIB", "Buah Suwarga! Cepat, kita pulang ke Desa Pohon. Aku akan menyiapkan racikan penyembuhnya.", 2],
		["NARASI", "Ranbyus, Darkus, Pak Tabib, Kepala Desa Beruang, dan Bu Kepiting menempuh perjalanan pulang bersama.", 0],
		["NARASI", "Begitu mereka tiba, warga Desa Pohon berlarian menyambut rombongan. Lega dan bahagia, mereka memberi jalan menuju rumah Ranbyus.", 3],
		["PAK TABIB", "Semua mundur sedikit, ya. Aku akan menggunakan Buah Suwarga. Ranbyus, tetaplah di sisi adikmu.", 2],
		["NARASI", "Cahaya hangat menyelimuti Adek. Pak Tabib merawatnya, sementara Ranbyus menggenggam tangannya dan berdoa dalam diam.", 0],
		["ADEK", "Kak...? Aku… sudah tidak sakit lagi?", 0],
		["RANBYUS", "Iya, Dek. Kakak sudah pulang. Kakak janji akan menjagamu, dan Kakak menepatinya.", 2],
		["NARASI", "Adek bangkit dari kasur lalu berlari keluar rumah. Semua orang ikut keluar, tertawa lega saat melihatnya kembali ceria.", 3],
		["ADEK", "Kak, makasih sudah berjuang sejauh ini buat Adek. Adek tahu Kakak tidak pernah menyerah.", 1],
		["DARKUS", "Ada satu hal yang harus kalian tahu. Orang tuaku memiliki darah keturunan Leviathan. Sejak lahir, kutukan itu melekat padaku.", 2],
		["DARKUS", "Makhluk-makhluk jahat selalu mengincar tubuhku. Satan bukan yang pertama mencoba mengambil alih diriku… dan mungkin bukan yang terakhir.", 0],
		["NARASI", "Hari itu, Desa Pohon kembali dipenuhi tawa. Namun rahasia garis keturunan Leviathan masih menyimpan bahaya di masa depan.", 3],
		["TAMAT", "Janji untuk Adek telah ditepati. Terima kasih sudah bermain!", 1]
	]
	# v9.10: Adek bangun dari kasur (8 frame, frame terakhir = pose idle) lalu menyambung ke sprite idle
	var wakeSheet=load("res://screens/tree-village/assets/adek-wakeup.png")
	var wakeFrames=[]
	for i in 8:
		var wakeAtlas=AtlasTexture.new()
		wakeAtlas.atlas=wakeSheet
		wakeAtlas.region=Rect2(320*i,0,320,282)
		wakeFrames.append(wakeAtlas)
	var wakeState={"tween":null}

	var pageIndex=0
	var updatePage: Callable
	updatePage=func():
		var page=pages[pageIndex]
		chapter.text="EPILOG  ·  %02d / %02d" % [pageIndex+1,pages.size()]
		speaker.text=page[0]
		body.text=page[1]
		var frameIndex=int(page[2])
		portrait.texture=frames[frameIndex]
		portrait.modulate=Color.WHITE
		portrait.position=Vector2(68,30)
		if wakeState["tween"]!=null and wakeState["tween"].is_running():
			wakeState["tween"].kill()
		if pageIndex==9:
			# Adek masih tertidur di kasur saat Tabib merawatnya
			portrait.texture=wakeFrames[0]
		elif pageIndex==10:
			# Adek terbangun: berbaring -> membuka mata -> duduk -> menggeliat -> turun -> pose idle
			portrait.texture=wakeFrames[0]
			var wakeTween=create_tween()
			for wi in range(1,wakeFrames.size()):
				wakeTween.tween_interval(0.55 if wi<4 else 0.38)
				wakeTween.tween_callback(func(): portrait.texture=wakeFrames[wi])
			wakeState["tween"]=wakeTween
		if pageIndex==12:
			portrait.position.x=-100
			var runTween=create_tween()
			runTween.tween_property(portrait,"position:x",250.0,2.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			portrait.texture=frames[1]
			portrait.modulate=Color(1.08,1.08,1.08,1.0)
			chapter.text="DESA POHON  ·  SEMUA BERSUKACITA"
		next.text="Lanjut  ▶" if pageIndex<pages.size()-1 else "Kembali ke Menu"

	var advancePage: Callable
	advancePage=func():
		if pageIndex>=pages.size()-1:
			_on_endingBackToMenu()
			return
		pageIndex+=1
		updatePage.call()
	next.pressed.connect(advancePage)

	var fadeTween=create_tween()
	fadeTween.tween_property(bg,"color:a",0.94,0.8)
	fadeTween.tween_property(content,"modulate:a",1.0,0.45)
	content.modulate.a=0.0
	await fadeTween.finished
	updatePage.call()
	
func _on_endingBackToMenu():
	GlobalGame.gotoMenu()
