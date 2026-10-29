extends "res://common/class/scene.gd"

func debug():
	GlobalPlayer.addItem(GlobalPlayer.getClassWeaponId())



const VillageEncounters=preload("res://common/class/village_encounters.gd")
const ObjectivePanel=preload("res://common/ui/objectivePanel.gd")
const EnemyClass=preload("res://common/class/enemy_class.gd")

# musuh desa beruang (muncul lagi tiap kali masuk desa; kalah sekali = gerbang dungeon terbuka)
const BEAR_ENEMIES=[
	{"key":"bv_wasp","enemy":EnemyClass.WASP,"pos":Vector2(520,250)},
	{"key":"bv_wolf","enemy":EnemyClass.WOLF,"pos":Vector2(690,520)},
	{"key":"bv_mushroom","enemy":EnemyClass.MUSHROOM,"pos":Vector2(330,560)}
]

var encounters=null
var objectivePanel=null


func _ready():
	setPlayerPath("Node2D/playerAndControl")
	loadPosition()
	getPlayer().loadCameraLimits($cameraRef)
	spawnHealShrine(Vector2(925,418),80,30)   # altar penyembuh: maks HP 80 / MP 30

	#debug()

	encounters=VillageEncounters.new(self,"res://screens/bear-village.tscn")
	encounters.spawn(BEAR_ENEMIES)

	objectivePanel=ObjectivePanel.new()
	add_child(objectivePanel)
	_updateObjectives()

	# Vera menemani sampai desa ini lalu berpamitan (kalau masih ikut)
	await playVeraFarewell()
	if _escortPending():
		# v7: tiba bersama Bu Kepiting dan Pak Tabib, langsung menuju toko Pak Beruang (Kepala Desa)
		await _arriveWithBuKepiting()
		return
	spawnTabibFollowerIfNeeded()
	_progress()


# ---------- v7: Bu Kepiting mengantar ke Pak Beruang (Kepala Desa Beruang) ----------

const CrabSellerScene=preload("res://screens/crabs-village/characters/crab-seller.tscn")
const BearSellerScene=preload("res://screens/bear-village/assets/bear-seller.tscn")
const SHOP_DOOR_FRONT=Vector2(838,452)
# v7.2: pintu toko = rumah bola (842.9,402.2) + pintu lokal (-1.9,19.3)
const SHOP_DOOR_POS=Vector2(841,421.5)
const IBU_KNOCK_POS=Vector2(842,438)      # Bu Kepiting berdiri persis di depan pintu untuk mengetuk
const HERO_WAIT_POS=Vector2(824,456)      # Ranbyus menunggu sedikit di belakang dan di samping Bu Kepiting
const BERUANG_OUT_POS=Vector2(864,438)    # Pak Beruang berdiri di sisi kanan pintu saat menyambut

func _escortPending():
	return GlobalGame.getStoryStage()==GlobalGame.STAGE_MEDICINE and GlobalGame.getTabibQuest()==GlobalGame.TQ_GUIDED


func _arriveWithBuKepiting():
	getPlayer().disableNavigation()
	var playerPos=getPlayer().getPlayerPosition()
	getPlayer().spawnTabib(playerPos+Vector2(-26,6))
	var ibu=CrabSellerScene.instantiate()
	$Node2D.add_child(ibu)
	ibu.global_position=playerPos+Vector2(-30,-8)
	await cs_wait(0.9)
	await cs_talk(GlobalGame.TRAD_BEAR_ARRIVE)

	# Bu Kepiting memimpin jalan ke depan pintu toko, Ranbyus dan Pak Tabib menyusul
	cs_walk_npc(ibu,IBU_KNOCK_POS,2.6)
	await cs_wait(0.5)
	await cs_move_hero(HERO_WAIT_POS,2.4)
	await cs_wait(0.4)

	# v7.2: Bu Kepiting mengetuk pintu dulu (tidak langsung masuk), lalu Pak Beruang membuka dan keluar
	await cs_knock(ibu,3)
	await cs_wait(0.8)
	var beruang=BearSellerScene.instantiate()
	$Node2D.add_child(beruang)
	beruang.global_position=SHOP_DOOR_POS
	beruang.modulate.a=0.0
	await cs_fade(beruang,1.0,0.25)
	await cs_walk_npc(beruang,BERUANG_OUT_POS,0.9)
	await cs_wait(0.2)
	await cs_talk(GlobalGame.TRAD_BEAR_DOOR)

	# Pak Beruang mempersilakan masuk: dia masuk duluan, disusul Bu Kepiting, lalu Ranbyus dan Pak Tabib
	await cs_walk_npc(beruang,SHOP_DOOR_POS+Vector2(0,6),0.9)
	await cs_fade(beruang,0.0,0.2)
	beruang.queue_free()
	await cs_walk_npc(ibu,SHOP_DOOR_POS+Vector2(0,8),0.9)
	await cs_fade(ibu,0.0,0.2)
	await cs_move_hero(SHOP_DOOR_FRONT,1.2)
	await cs_wait(0.3)
	GlobalPlayer.savePosition(Vector2(120,140))
	SceneTransition.change_scene("res://screens/bear-village/shop.tscn")


func _progress():
	var done=encounters.countDefeated(BEAR_ENEMIES)
	if done>=BEAR_ENEMIES.size():
		if !GlobalGame.isBearVillageCleared():
			GlobalScenes.saveParamForScene("story","bear_cleared",1)
			_notify(GlobalGame.getTraductionById(GlobalGame.TRAD_BEAR_CLEARED),"success")
	elif done==0:
		if int(GlobalScenes.getParamForSceneOr("story","bv_tip_seen",0))!=1:
			GlobalScenes.saveParamForScene("story","bv_tip_seen",1)
			_notify(GlobalGame.getTraductionById(GlobalGame.TRAD_BEAR_TIP))
	elif int(GlobalScenes.getParamForSceneOr("story","bv_progress_shown",0))!=done:
		GlobalScenes.saveParamForScene("story","bv_progress_shown",done)
		_notify(GlobalGame.getTraductionById(GlobalGame.TRAD_BEAR_PROGRESS) % done)
	# status "desa aman" baru tersimpan di atas, jadi segarkan panel TUJUAN sekali lagi
	_updateObjectives()


# Panel TUJUAN: utama = kalahkan 3 musuh desa (membuka gerbang Ancient Dungeon);
# sampingan = membantu Peternak Lebah (usir lebah di rumahnya, lalu ambil 3 ember madu di sarang).
func _updateObjectives():
	var done=encounters.countDefeated(BEAR_ENEMIES)
	var total=BEAR_ENEMIES.size()
	var cleared=GlobalGame.isBearVillageCleared()
	var bees=int(GlobalScenes.getParamForSceneOr("story","bv_bees_done",0))==1
	var honey=int(GlobalScenes.getParamForSceneOr("story","bv_honey_done",0))==1

	# panel kecil: judul + SATU tujuan yang sedang aktif
	var line=""
	if !cleared:
		line="[ ] Kalahkan musuh desa "+str(done)+"/"+str(total)
	elif !bees:
		line="[ ] Usir lebah di rumah peternak"
	elif !honey:
		line="[ ] Ambil 3 ember madu di sarang"
	else:
		line="[x] Desa aman, gerbang dungeon terbuka"
	objectivePanel.setText("TUJUAN\n"+line)


func _notify(text_, kind_="info", title_=""):
	notify(text_,kind_,title_)


func _on_bevilroom_playerEntered():
	SceneTransition.change_scene("res://screens/bear-village/bevil-room.tscn")


func _on_beeroom_playerEntered():
	SceneTransition.change_scene("res://screens/bear-village/bee-village-platform.tscn")


func _on_shop_playerEntered():
	# titik muncul di dalam toko (seperti toko desa pohon); tanpa ini posisi lama ikut terbawa
	# dan karakter bisa muncul di luar ruangan toko
	GlobalPlayer.savePosition(Vector2(120,140))
	SceneTransition.change_scene("res://screens/bear-village/shop.tscn")


func _on_gotToMacro_playerOpenedDoor():
	GlobalPlayer.savePosition(Vector2(168,-82))
	SceneTransition.change_scene("res://screens/macro-map.tscn")
