extends "res://common/class/scene.gd"

const VillageEncounters=preload("res://common/class/village_encounters.gd")
const EnemyClass=preload("res://common/class/enemy_class.gd")

# 5 musuh khusus leveling di pantai (muncul lagi tiap kali masuk desa) + 2 bandit setelah semuanya kalah
const BEACH_ENEMIES=[
	{"key":"cv_crab","enemy":EnemyClass.BEACH_CRAB,"pos":Vector2(260,250)},
	{"key":"cv_jelly","enemy":EnemyClass.JELLYFISH,"pos":Vector2(470,310)},
	{"key":"cv_urchin","enemy":EnemyClass.URCHIN,"pos":Vector2(660,350)},
	{"key":"cv_seaweed","enemy":EnemyClass.SEAWEED,"pos":Vector2(880,210)},
	{"key":"cv_gull","enemy":EnemyClass.SEAGULL,"pos":Vector2(960,400)}
]
const BANDITS={"key":"cv_bandits","enemy":EnemyClass.BANDITS,"pos":Vector2(610,120),"size":Vector2(76,30)}

var encounters=null


func _ready():
	setPlayerPath("Node2D/playerAndControl")
	loadPosition()
	getPlayer().loadCameraLimits($cameraRef)
	spawnHealShrine(Vector2(116,176),78,28)   # altar penyembuh: maks HP 78 / MP 28

	encounters=VillageEncounters.new(self,"res://screens/crabs-village.tscn")
	# v7: saat Anak Desa mengantar Ranbyus dan Pak Tabib ke Bu Kepiting, monster pantai tidak muncul
	# (supaya adegan tidak terpotong pertarungan); mereka kembali setelah adegan selesai.
	if !_guidePending():
		encounters.spawn(BEACH_ENEMIES)
	# (dua bandit tidak berdiri diam: mereka berjalan menghampiri pemain, lihat _banditsApproach)

	# Vera menemani sampai desa ini lalu berpamitan (kalau masih ikut)
	await playVeraFarewell()
	spawnTabibFollowerIfNeeded()
	if _guidePending():
		await _guideToShop()
		return
	await _storyBeats()


# ---------- v7: Anak Desa mengantar ke Bu Kepiting (toko) ----------
# Tahap: Tabib sudah memeriksa Adek di rumah (TQ_HOME_DONE) dan Ranbyus belum pernah diantar.
func _guidePending():
	return GlobalGame.getStoryStage()==GlobalGame.STAGE_MEDICINE \
		and GlobalGame.getTabibQuest()==GlobalGame.TQ_HOME_DONE \
		and int(GlobalScenes.getParamForSceneOr("story","cv_guided",0))!=1


func _guideToShop():
	# ditandai di awal supaya kalau permainan dimuat ulang tidak mengulang adegan dari nol
	GlobalScenes.saveParamForScene("story","cv_guided",1)
	getPlayer().disableNavigation()
	var boy=$Node2D/"welcome-boy"
	var playerPos=getPlayer().getPlayerPosition()
	await cs_wait(0.7)
	# Anak Desa berlari kecil menghampiri Ranbyus dan Pak Tabib
	await boy.walk_to_global(playerPos+Vector2(26,-6),1.4)
	await cs_talk(GlobalGame.TRAD_CRAB_GUIDE_1)

	# Anak Desa memimpin jalan ke pintu toko, Ranbyus menyusul (Tabib mengikuti di belakang)
	var doorFront=Vector2(48,170)
	boy.walk_to_global(doorFront+Vector2(26,-2),1.9)
	await cs_wait(0.35)
	await cs_move_hero(doorFront+Vector2(-2,2),1.9)
	await cs_wait(0.3)
	await cs_talk(GlobalGame.TRAD_CRAB_GUIDE_2)
	# v7.2: Anak Desa ikut masuk bersama Ranbyus (adegan lanjut di dalam toko, lihat shop.gd)
	await cs_wait(0.2)
	SceneTransition.change_scene("res://screens/crabs-village/shop.tscn")


# ---------- alur desa: petunjuk, bandit, hadiah busur ----------

func _storyBeats():
	var done=encounters.countDefeated(BEACH_ENEMIES)
	var banditsDone=encounters.isDefeated(BANDITS.key)
	var bowGiven=int(GlobalScenes.getParamForSceneOr("story","cv_bow_given",0))==1

	if banditsDone and !bowGiven:
		await _bowReward()
		return
	if done>=BEACH_ENEMIES.size() and !banditsDone:
		await _banditsApproach()
		return
	if bowGiven:
		return
	if done==0:
		if int(GlobalScenes.getParamForSceneOr("story","cv_tip_seen",0))!=1:
			GlobalScenes.saveParamForScene("story","cv_tip_seen",1)
			_notify(GlobalGame.getTraductionById(GlobalGame.TRAD_CRAB_TIP))
	elif int(GlobalScenes.getParamForSceneOr("story","cv_progress_shown",0))!=done:
		GlobalScenes.saveParamForScene("story","cv_progress_shown",done)
		_notify(GlobalGame.getTraductionById(GlobalGame.TRAD_CRAB_PROGRESS) % done)


# Dua bandit dari desa pohon muncul dari kejauhan dan berlari menghampiri pemain (Vera sudah pergi),
# mengepung dari dua sisi, lalu pertarungan 2 lawan 1 dimulai.
const BanditScript=preload("res://common/characters/bandit.gd")

func _banditsApproach():
	getPlayer().disableNavigation()
	var playerPos=getPlayer().getPlayerPosition()
	# semua hewan pantai kalah -> bandit muncul dan menyegat jalan
	_notify("Bandit menyegat jalanmu!","danger")
	await get_tree().create_timer(1.0).timeout

	var red=Node2D.new()
	red.set_script(BanditScript)
	red.variant="bandit1"
	red.z_index=10
	add_child(red)
	red.global_position=playerPos+Vector2(230,-50)
	var blue=Node2D.new()
	blue.set_script(BanditScript)
	blue.variant="bandit2"
	blue.z_index=10
	add_child(blue)
	blue.global_position=playerPos+Vector2(250,50)

	# berlari menghampiri dan berhenti di depan pemain
	var runRed=red.walkTo(playerPos+Vector2(46,-8),1.9)
	blue.walkTo(playerPos+Vector2(40,20),2.1)
	await runRed.finished
	await get_tree().create_timer(0.35).timeout

	if int(GlobalScenes.getParamForSceneOr("story","cv_bandits_seen",0))!=1:
		GlobalScenes.saveParamForScene("story","cv_bandits_seen",1)
		var dialog=load("res://common/ui/simpleDialog.tscn").instantiate()
		add_child(dialog)
		GlobalGame.addDialogByKey(dialog,GlobalGame.TRAD_BANDIT_BACK)
		dialog.start()
		await dialog.discussionFinished
		dialog.end()
		dialog.queue_free()

	red.queue_free()
	blue.queue_free()
	encounters.startBattle(BANDITS.key, BANDITS.enemy, playerPos+Vector2(44,6))


# Anak Desa berlari menghampiri pemain dan memberi Busur Kayu
func _bowReward():
	GlobalScenes.saveParamForScene("story","cv_bow_given",1)
	await get_tree().create_timer(0.6).timeout
	getPlayer().disableNavigation()
	var boy=$Node2D/"welcome-boy"
	var home=boy.position
	var playerPos=getPlayer().getPlayerPosition()
	# Anak desa berjalan dengan langkah animasi, bukan meluncur di atas pasir.
	await boy.walk_to_global(playerPos+Vector2(-26,6),1.85)
	var dialog=load("res://common/ui/simpleDialog.tscn").instantiate()
	add_child(dialog)
	GlobalGame.addDialogByKey(dialog,GlobalGame.TRAD_BOW_REWARD)
	dialog.start()
	await dialog.discussionFinished
	dialog.end()
	dialog.queue_free()
	GlobalPlayer.addItem(GlobalItems.ID.WOODEN_BOW)
	getPlayer().reloadInvetory()
	_notify(GlobalGame.getTraductionById(GlobalGame.TRAD_BOW_RECEIVED),"reward")
	await boy.walk_to_global(boy.get_parent().to_global(home),1.75)
	getPlayer().enableNavigation()


func _talk(key_):
	var dialog=load("res://common/ui/simpleDialog.tscn").instantiate()
	add_child(dialog)
	GlobalGame.addDialogByKey(dialog,key_)
	getPlayer().disableNavigation()
	dialog.start()
	await dialog.discussionFinished
	dialog.end()
	dialog.queue_free()
	getPlayer().enableNavigation()


func _notify(text_, kind_="info", title_=""):
	notify(text_,kind_,title_)


func _on_welcomeboy_talk():
	# isi dialog menyesuaikan tahap cerita
	if GlobalGame.getStoryStage() >= GlobalGame.STAGE_MEDICINE:
		var tq=GlobalGame.getTabibQuest()
		if tq==GlobalGame.TQ_HOME_DONE:
			GlobalGame.addDialogByKey($simpleDialog,GlobalGame.TRAD_CRAB_GUIDE_REMIND)
		elif tq>GlobalGame.TQ_HOME_DONE:
			GlobalGame.addDialogByKey($simpleDialog,GlobalGame.TRAD_CRABVILLAGE_AFTER)
		else:
			GlobalGame.addDialogByKey($simpleDialog,GlobalGame.TRAD_CRABVILLAGE_MED)
	else:
		GlobalGame.addDialogByKey($simpleDialog,GlobalGame.TRAD_CRABVILLAGE_WELL)
	$simpleDialog.start()
	getPlayer().disableNavigation()


func _on_simpleDialog_discussionFinished():
	$simpleDialog.end()
	getPlayer().enableNavigation()


func _on_goToMacroMap_playerOpenedDoor():
	GlobalPlayer.savePosition(Vector2(427,61))
	SceneTransition.change_scene("res://screens/macro-map.tscn")


func _on_shop_entered():
	SceneTransition.change_scene("res://screens/crabs-village/shop.tscn")


func _on_game1_entered():
	SceneTransition.change_scene("res://screens/crabs-village/game1-room.tscn")


func _on_game2_entered():
	SceneTransition.change_scene("res://screens/crabs-village/game2-room.tscn")


func _on_game3_entered():
	SceneTransition.change_scene("res://screens/crabs-village/game3-room.tscn")
