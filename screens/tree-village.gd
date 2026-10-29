extends "res://common/class/scene.gd"

var groundFounded=null


func debug():
	GlobalPlayer.addItem(GlobalItems.ID.NAILS)
	GlobalPlayer.addItem(GlobalItems.ID.HONEY)
	GlobalPlayer.addItem(GlobalItems.ID.BUCKET)
	GlobalPlayer.addItem(GlobalItems.ID.GORMON_STAR_MAP)
	GlobalPlayer.addItem(GlobalItems.ID.SPADE)
	
	#$YSort/well.repair()
	#$YSort/craftsman.visible=false

	GlobalPlayer.setLife(80)
	getPlayer().reloadLife()

	GlobalPlayer.addItem(GlobalItems.ID.HEALTH_POTION_10)

func _ready():
	
	setPlayerPath("Node2D/playerAndControl")
	loadPosition()
	getPlayer().loadCameraLimits($cameraRef)
	spawnHealShrine(Vector2(862,250),75,25)   # altar penyembuh: maks HP 75 / MP 25

	#debug()

	if true==GlobalScenes.getParamForSceneOr(scene_file_path,'ground.isDiscovered',false):
		$ground.enableDiscovered()
	
	if true==GlobalScenes.getParamForSceneOr(scene_file_path,'ground2.isDiscovered',false):
		$ground2.enableDiscovered()
	
	if true==GlobalScenes.getParamForSceneOr(scene_file_path,'ground3.isDiscovered',false):
		$ground3.enableDiscovered()
	
	if true==GlobalScenes.getParamForSceneOr(scene_file_path,'ground4.isDiscovered',false):
		$ground4.enableDiscovered()
	
	if true==GlobalScenes.getParamForSceneOr(scene_file_path,'ground5.isDiscovered',false):
		$ground5.enableDiscovered()

	# sumur yang sudah diperbaiki tetap utuh saat permainan dimuat / kembali ke desa
	if GlobalGame.getStoryStage() >= GlobalGame.STAGE_MEDICINE:
		$Node2D/well.setRepaired()
		_spawnTabib()

	if _banditEventPending():
		_setupBanditEvent()
	elif GlobalGame.isVeraWithPlayer():
		getPlayer().spawnCompanion()



# ===================== Adegan bandit di sumur + Vera =====================
# Setelah intro di rumah selesai, bandit sedang merusak sumur. Ranbyus mencoba mengusir mereka,
# kalah karena mereka berdua, lalu Vera datang menolong dan memberi Tongkat Kayu.

const BanditScript=preload("res://common/characters/bandit.gd")
const CompanionScript=preload("res://common/characters/companion.gd")

const BANDIT1_POS=Vector2(988,198)
const BANDIT2_POS=Vector2(1024,206)
const HERO_STAND=Vector2(944,202)
const TRIGGER_POS=Vector2(852,190)

var cutscene=false
var banditNodes=[]
var triggerArea=null


func _banditEventPending():
	if GlobalGame.getStoryStage()!=GlobalGame.STAGE_WELL or GlobalGame.isBanditEventDone():
		return false
	# baru muncul setelah intro di rumah selesai
	return int(GlobalScenes.getParamForSceneOr("story","intro_gift",0))==1


func _setupBanditEvent():
	# dua bandit sedang menghancurkan sumur
	var b1=Node2D.new()
	b1.set_script(BanditScript)
	b1.variant="bandit1"
	b1.position=BANDIT1_POS
	$Node2D.add_child(b1)
	var b2=Node2D.new()
	b2.set_script(BanditScript)
	b2.variant="bandit2"
	b2.position=BANDIT2_POS
	$Node2D.add_child(b2)
	banditNodes=[b1,b2]
	_banditSmashLoop()

	# Pak Tukang bersembunyi: belum bisa diajak bicara sebelum bandit pergi
	$Node2D/well/craftsman/talk.interactionEnabled=false

	# pemicu adegan: pemain mendekati sumur
	triggerArea=Area2D.new()
	var shape=CollisionShape2D.new()
	var rect=RectangleShape2D.new()
	rect.size=Vector2(20,170)
	shape.shape=rect
	triggerArea.add_child(shape)
	triggerArea.position=TRIGGER_POS
	add_child(triggerArea)
	triggerArea.body_entered.connect(_on_banditTrigger_entered)

	notify("Bandit merusak sumur desa!","danger")


# bandit bergantian memukul sumur selama adegan belum dimulai
func _banditSmashLoop():
	while !cutscene and is_inside_tree() and banditNodes.size()==2 and is_instance_valid(banditNodes[0]):
		banditNodes[0].strike(Vector2(960,150))
		await get_tree().create_timer(0.7).timeout
		if cutscene or !is_instance_valid(banditNodes[1]):
			break
		banditNodes[1].strike(Vector2(960,150))
		await get_tree().create_timer(0.9).timeout


func _on_banditTrigger_entered(body_):
	if cutscene or !body_.is_in_group("Player"):
		return
	triggerArea.queue_free()
	_playBanditEvent()


func _talk(key_):
	GlobalGame.addDialogByKey($simpleDialog,key_)
	$simpleDialog.start()
	await $simpleDialog.discussionFinished
	$simpleDialog.end()


func _wait(seconds_):
	await get_tree().create_timer(seconds_).timeout


func _flash(node_):
	node_.modulate=Color(3,3,3)
	node_.create_tween().tween_property(node_,"modulate",Color.WHITE,0.25)


func _shakeCamera(strength_=3.0):
	var camera=getPlayer().getPlayerBody().get_node("Camera2D")
	var tween=create_tween()
	for i in 6:
		tween.tween_property(camera,"offset",Vector2(randf_range(-strength_,strength_),randf_range(-strength_,strength_)),0.03)
	tween.tween_property(camera,"offset",Vector2.ZERO,0.03)


func _moveHero(to_, seconds_, anim_="walk-right"):
	var body=getPlayer().getPlayerBody()
	body.forcedAnimation=anim_
	body.get_node("AnimatedSprite2D").flip_h=to_.x<body.global_position.x
	var tween=create_tween()
	tween.tween_property(body,"global_position",to_,seconds_)
	await tween.finished
	body.forcedAnimation=""


# Efek sihir pixel-art: lingkaran rune berdenyut, orb melesat, kilatan dan dorongan target.
func _veraMagicStrike(vera, target):
	if !is_instance_valid(vera) or !is_instance_valid(target):
		return
	var origin=vera.global_position+Vector2(0,-10)
	var destination=target.global_position+Vector2(0,-8)
	var rune=Node2D.new()
	rune.z_index=55
	$Node2D.add_child(rune)
	rune.global_position=origin
	for ring_i in 2:
		var ring=Line2D.new()
		ring.width=2.0 if ring_i==0 else 1.0
		ring.default_color=Color(0.55,0.72,1.0,0.95) if ring_i==0 else Color(0.82,0.48,1.0,0.8)
		ring.closed=true
		var radius=7.0+ring_i*5.0
		for i in 25:
			var angle=TAU*float(i)/24.0
			ring.add_point(Vector2(cos(angle)*radius,sin(angle)*radius))
		rune.add_child(ring)
		ring.rotation = 0.0
	var charge=rune.create_tween()
	charge.tween_property(rune,"scale",Vector2(1.65,1.65),0.16)
	charge.tween_property(rune,"modulate:a",0.0,0.12)
	var orb=ColorRect.new()
	orb.size=Vector2(10,10)
	orb.color=Color(0.62,0.55,1.0,1.0)
	orb.z_index=58
	$Node2D.add_child(orb)
	orb.global_position=origin-Vector2(5,5)
	var shot=orb.create_tween()
	shot.tween_property(orb,"global_position",destination-Vector2(5,5),0.24).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await shot.finished
	if is_instance_valid(orb): orb.queue_free()
	if is_instance_valid(rune): rune.queue_free()
	if is_instance_valid(target):
		_flash(target)
		var impact=Node2D.new()
		impact.z_index=60
		$Node2D.add_child(impact)
		impact.global_position=destination
		for i in 8:
			var spark=ColorRect.new()
			spark.size=Vector2(3,3)
			spark.color=Color(0.72,0.6,1.0,1.0) if i%2==0 else Color(0.55,0.85,1.0,1.0)
			spark.position=Vector2(-1.5,-1.5)
			impact.add_child(spark)
			var angle=TAU*float(i)/8.0
			var tw=spark.create_tween()
			tw.tween_property(spark,"position",Vector2(cos(angle)*18.0,sin(angle)*15.0),0.22)
			tw.parallel().tween_property(spark,"modulate:a",0.0,0.22)
		var away=(target.global_position-vera.global_position).normalized()
		target.create_tween().tween_property(target,"global_position",target.global_position+away*30.0,0.25)
		await _wait(0.12)
		impact.queue_free()

func _playBanditEvent():
	cutscene=true
	getPlayer().disableNavigation()
	var body=getPlayer().getPlayerBody()
	var heroSprite=body.get_node("AnimatedSprite2D")

	# 1) Ranbyus menghampiri bandit, percakapan
	await _moveHero(HERO_STAND,1.4)
	banditNodes[0].face(true)
	banditNodes[1].face(true)
	await _wait(0.3)
	await _talk(GlobalGame.TRAD_BANDIT_SCENE_1)

	# 2) Ranbyus menyerang tapi dikeroyok dua bandit
	await _moveHero(BANDIT1_POS+Vector2(-18,0),0.35)
	_flash(banditNodes[0])
	await banditNodes[0].strike(body.global_position).finished
	await _wait(0.1)
	for i in 3:
		var attacker=banditNodes[i%2]
		await attacker.strike(body.global_position).finished
		_flash(heroSprite)
		_shakeCamera(3.0)
		body.global_position+=Vector2(-6,2)
		GlobalPlayer.damage(int(GlobalPlayer.getMaxLife()*0.2))
		getPlayer().reloadLife()
		await _wait(0.15)
	# Ranbyus tersungkur
	GlobalPlayer.setLife(max(1,int(GlobalPlayer.getMaxLife()*0.1)))
	getPlayer().reloadLife()
	heroSprite.modulate=Color(1,0.7,0.7)
	var fall=create_tween()
	fall.tween_property(heroSprite,"rotation_degrees",80.0,0.3)
	await fall.finished
	await _wait(0.4)
	await _talk(GlobalGame.TRAD_BANDIT_SCENE_2)

	# 3) Vera muncul dari kiri atas
	var vera=Node2D.new()
	vera.set_script(CompanionScript)
	$Node2D.add_child(vera)
	# Vera selalu digambar di atas bandit & karakter lain (y-sort bisa menutupinya),
	# dan mendarat di kiri atas Ranbyus, jauh dari bandit yang berdiri di kanan
	vera.z_index=40
	var landing=body.global_position+Vector2(-30,-30)
	await vera.arrive(landing+Vector2(-60,-130), landing, 1.7).finished
	vera.face(false)
	await _talk(GlobalGame.TRAD_BANDIT_SCENE_3)

	# Vera mengumpulkan energi, lalu melepaskan proyektil sihir ungu-biru ke kedua bandit.
	# Efek lokal ini lebih jelas daripada flash layar penuh dan tidak menutupi adegan.
	for b in banditNodes:
		if !is_instance_valid(b):
			continue
		await _veraMagicStrike(vera, b)
	_shakeCamera(4.0)
	await _wait(0.18)
	await _talk(GlobalGame.TRAD_BANDIT_SCENE_4)
	var fleeA=banditNodes[0].flee(Vector2(1190,230),1.3)
	banditNodes[1].flee(Vector2(1160,270),1.5)
	await fleeA.finished
	for b in banditNodes:
		b.queue_free()
	banditNodes=[]

	# 4) Vera menolong Ranbyus
	var rise=create_tween()
	rise.tween_property(heroSprite,"rotation_degrees",0.0,0.3)
	heroSprite.modulate=Color.WHITE
	GlobalPlayer.setLife(GlobalPlayer.getMaxLife())
	GlobalPlayer.setMana(GlobalPlayer.getMaxMana())
	getPlayer().reloadLife()
	await _wait(0.4)
	await _talk(GlobalGame.TRAD_BANDIT_SCENE_5)

	# tongkat kayu + Vera ikut sebagai pendamping
	GlobalPlayer.addItem(GlobalItems.ID.WOODEN_STAFF)
	getPlayer().reloadInvetory()
	GlobalGame.setBanditEventDone()
	GlobalGame.setVeraState(GlobalGame.VERA_WITH)
	notify(GlobalGame.getTraductionById(GlobalGame.TRAD_VERA_STAFF),"reward")
	var veraPos=vera.global_position
	vera.queue_free()
	getPlayer().spawnCompanion(veraPos)

	$Node2D/well/craftsman/talk.interactionEnabled=true
	cutscene=false
	getPlayer().enableNavigation()
	await _wait(2.5)
	notify(GlobalGame.getTraductionById(GlobalGame.TRAD_VERA_JOINED),"story")

# --- dialog Pak Tukang (disusun saat pemain menekan E, sesuai tahap cerita) ---

var dialogKind=""        # "tukang" = bicara dengan Pak Tukang, "cheer" = adegan sumur selesai
var repairAfterDialog=false
var _wellRepairHandled=false
var _wellCheerStarted=false

func hasAllWellParts():
	return GlobalPlayer.hasItem(GlobalItems.ID.NAILS) and GlobalPlayer.hasItem(GlobalItems.ID.HONEY) and GlobalPlayer.hasItem(GlobalItems.ID.BUCKET)

func hasSomeWellParts():
	return GlobalPlayer.hasItem(GlobalItems.ID.NAILS) or GlobalPlayer.hasItem(GlobalItems.ID.HONEY) or GlobalPlayer.hasItem(GlobalItems.ID.BUCKET)

func prepareCraftsmanDialog():
	dialogKind="tukang"
	repairAfterDialog=false
	var stage=GlobalGame.getStoryStage()

	if stage >= GlobalGame.STAGE_DONE:
		GlobalGame.addDialogByKey($simpleDialog,GlobalGame.TRAD_WELL_DONE)
	elif stage >= GlobalGame.STAGE_MEDICINE:
		if GlobalGame.hasCure():
			GlobalGame.addDialogByKey($simpleDialog,GlobalGame.TRAD_WELL_HAVE_MED)
		else:
			GlobalGame.addDialogByKey($simpleDialog,GlobalGame.TRAD_WELL_AFTER)
	elif hasAllWellParts():
		GlobalGame.addDialogByKey($simpleDialog,GlobalGame.TRAD_WELL_READY)
		repairAfterDialog=true
	elif hasSomeWellParts():
		GlobalGame.addDialogByKey($simpleDialog,GlobalGame.TRAD_WELL_PENDING)
		# daftar bahan yang masih kurang
		var missing=[]
		if !GlobalPlayer.hasItem(GlobalItems.ID.NAILS):
			missing.append("- "+GlobalItems.getItem(GlobalItems.ID.NAILS).name)
		if !GlobalPlayer.hasItem(GlobalItems.ID.HONEY):
			missing.append("- "+GlobalItems.getItem(GlobalItems.ID.HONEY).name)
		if !GlobalPlayer.hasItem(GlobalItems.ID.BUCKET):
			missing.append("- "+GlobalItems.getItem(GlobalItems.ID.BUCKET).name)
		$simpleDialog.addDiscussion(GlobalGame.getHeroName(),missing)
	else:
		GlobalGame.addDialogByKey($simpleDialog,GlobalGame.TRAD_WELL_START)


func _on_shop_playerEntered():
	GlobalPlayer.savePosition(Vector2(48,73))
	SceneTransition.change_scene("res://screens/tree-village/shop.tscn")


func _on_gordonhome_playerEntered():
	GlobalPlayer.savePosition(Vector2(55,84))
	SceneTransition.change_scene("res://screens/tree-village/gordon-home.tscn")

func _on_gemhouse_playerEntered():
	GlobalPlayer.savePosition(Vector2(48,73))
	SceneTransition.change_scene("res://screens/tree-village/gem-house.tscn")
	pass # Replace with function body.


func _on_goOutFromTreeVillage_playerOpenedDoor():
	GlobalPlayer.savePosition(Vector2(293,608))
	SceneTransition.change_scene("res://screens/macro-map.tscn")
	pass # Replace with function body.




func _on_playerAndControl_endClimbing():
	$Node2D.y_sort_enabled=true



func _on_playerAndControl_startClimbing():
	$Node2D.y_sort_enabled=false




func _on_playerAndControl_digging():
	if groundFounded!=null:
		groundFounded.play()
		print("play ground")
	pass # Replace with function body.

func _on_playerAndControl_endDigging():
	if groundFounded!=null:
		groundFounded.stop()
	pass # Replace with function body.

#--- grounds
func processGormonStarFounded(grounded_):
	notify(GlobalGame.getTraductionById(GlobalGame.TRAD_TREEVILLAGE_STARFOUND),"reward")
	GlobalPlayer.addItemEvenIfExist(GlobalItems.ID.GORDMON_STAR)
	$Node2D/playerAndControl.reloadInvetory()
	
	GlobalScenes.saveParamForScene(scene_file_path,grounded_+".isDiscovered",true)
	
	get_node(grounded_).queue_free()
	

func processGroundedLeft():
	groundFounded.stop()
	groundFounded=null

#ground
func _on_ground_isDiscovered():
	processGormonStarFounded("ground")
	
func _on_ground_rightGroundFounded():
	groundFounded=$ground

func _on_ground_rightGroundFoundedLeft():
	processGroundedLeft()

#ground2
func _on_ground2_isDiscovered():
	processGormonStarFounded("ground2")

func _on_ground2_rightGroundFounded():
	groundFounded=$ground2

func _on_ground2_rightGroundFoundedLeft():
	processGroundedLeft()

#ground3
func _on_ground3_isDiscovered():
	processGormonStarFounded("ground3")

func _on_ground3_rightGroundFounded():
	groundFounded=$ground3

func _on_ground3_rightGroundFoundedLeft():
	processGroundedLeft()

#ground4
func _on_ground4_isDiscovered():
	processGormonStarFounded("ground4")

func _on_ground4_rightGroundFounded():
	groundFounded=$ground4

func _on_ground4_rightGroundFoundedLeft():
	processGroundedLeft()

#ground5
func _on_ground5_isDiscovered():
	processGormonStarFounded("ground5")

func _on_ground5_rightGroundFounded():
	groundFounded=$ground5

func _on_ground5_rightGroundFoundedLeft():
	processGroundedLeft()


func _on_simpleDialog_discussionFinished():
	if cutscene:
		# adegan bandit mengatur dialognya sendiri
		return
	$simpleDialog.end()
	getPlayer().enableNavigation()

	if dialogKind=="tukang" and repairAfterDialog:
		repairAfterDialog=false
		# bahan diserahkan ke Pak Tukang lalu sumur mulai diperbaiki
		GlobalPlayer.removeItem(GlobalItems.ID.NAILS)
		GlobalPlayer.removeItem(GlobalItems.ID.HONEY)
		GlobalPlayer.removeItem(GlobalItems.ID.BUCKET)
		$Node2D/playerAndControl.reloadInvetory()
		$Node2D/well.repair()

	if dialogKind=="cheer":
		_wellCheerStarted=true
	if dialogKind=="tabib_join":
		_tabibJoins()
	dialogKind=""


# ===================== Pak Tabib =====================
# Muncul di jalan desa setelah sumur pulih. Memberi tahu bahwa adek hanya bisa disembuhkan
# Buah Suwarga dari Ancient Dungeon. Ubah TABIB_POS kalau posisinya terlalu dekat dekorasi lain.
const TABIB_POS=Vector2(780,224)
var tabib=null

func _spawnTabib():
	if tabib!=null or GlobalGame.getStoryStage() < GlobalGame.STAGE_MEDICINE:
		return
	# v7: setelah ikut Ranbyus, Tabib berjalan di belakang pemain (non-petarung) sampai jalan masuk dungeon.
	if GlobalGame.isTabibFollowing():
		spawnTabibFollowerIfNeeded()
		return
	# Tabib menunggu di jalan masuk dungeon (belum pulang): tidak ada di desa
	if GlobalGame.getStoryStage() < GlobalGame.STAGE_DONE and GlobalGame.getTabibQuest()==GlobalGame.TQ_WAIT:
		return
	tabib=load("res://screens/tree-village/assets/tabib.tscn").instantiate()
	$Node2D.add_child(tabib)
	tabib.position=TABIB_POS
	tabib.talk.connect(_on_tabib_talk)

func _on_tabib_talk():
	dialogKind="tabib"
	repairAfterDialog=false
	var key
	if GlobalGame.getStoryStage() >= GlobalGame.STAGE_DONE:
		key=GlobalGame.TRAD_TABIB_DONE
	elif GlobalGame.hasCure():
		key=GlobalGame.TRAD_TABIB_HAVE
	else:
		# pertemuan pertama: Tabib minta diantar ke rumah, lalu ikut Ranbyus (lihat _tabibJoins)
		GlobalGame.addTalkCount("tabib")
		key=GlobalGame.TRAD_TABIB_FIRST
		dialogKind="tabib_join"
	GlobalGame.addDialogByKey($simpleDialog,key)
	$simpleDialog.start()
	getPlayer().disableNavigation()


# Pak Tabib bergabung: berhenti jadi NPC diam di jalan desa, lalu berjalan di belakang Ranbyus menuju rumah.
func _tabibJoins():
	if GlobalGame.getTabibQuest()!=GlobalGame.TQ_NONE:
		return
	GlobalGame.setTabibQuest(GlobalGame.TQ_JOINED)
	var startPos=null
	if tabib!=null and is_instance_valid(tabib):
		startPos=tabib.global_position
		tabib.queue_free()
		tabib=null
	getPlayer().spawnTabib(startPos)
	notify(GlobalGame.getTraductionById(GlobalGame.TRAD_TABIB_JOIN_TIP),"story")


func _on_well_talk():
	prepareCraftsmanDialog()
	$simpleDialog.start()
	getPlayer().disableNavigation()


func _on_well_repaired():
	# Guard: animation_finished/animation_looped bisa terpanggil lebih dari sekali.
	if _wellRepairHandled or GlobalGame.getStoryStage() >= GlobalGame.STAGE_MEDICINE:
		return
	_wellRepairHandled=true
	# tahap 1 selesai: sumur pulih, lanjut mencari obat untuk adek
	GlobalGame.setStoryStage(GlobalGame.STAGE_MEDICINE)
	_spawnTabib()
	notify(GlobalGame.getTraductionById(GlobalGame.TRAD_WELL_REPAIRED),"success")
	if !_wellCheerStarted:
		_wellCheerStarted=true
		dialogKind="cheer"
		GlobalGame.addDialogByKey($simpleDialog,GlobalGame.TRAD_WELL_CHEER)
		$simpleDialog.start()
		getPlayer().disableNavigation()


func _on_gotBackToMenu_button_down():
	SceneTransition.change_scene("res://screens/game/menu.tscn")
