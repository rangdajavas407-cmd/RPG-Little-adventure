extends "res://common/class/scene.gd"


var shopItemClass=preload("res://common/class/shopItem_class.gd")



func _ready():
	setPlayerPath("playerAndControl")
	loadPosition()
	getPlayer().loadCameraLimits($cameraRef)

	var stage=GlobalGame.getStoryStage()
	var shopItems=[
		shopItemClass.new(GlobalItems.ID.NAILS,6),
		shopItemClass.new(GlobalItems.ID.HP_POTION,8),
		shopItemClass.new(GlobalItems.ID.MANA_POTION,8),
		shopItemClass.new(GlobalItems.ID.LAKLAK,15)
	]

	# obat adek tidak dijual: harus Buah Suwarga dari Ancient Dungeon (kata Pak Tabib)
	if stage >= GlobalGame.STAGE_MEDICINE and stage < GlobalGame.STAGE_DONE:
		$simpleDialog.addDiscussion(GlobalGame.getTraductionById(GlobalGame.TRAD_WORD_CRABSELLER),GlobalGame.getTraductionById(GlobalGame.TRAD_CRABVILLAGE_SHOP_MED))
	else:
		$simpleDialog.addDiscussion(GlobalGame.getTraductionById(GlobalGame.TRAD_WORD_CRABSELLER),GlobalGame.getTraductionById(GlobalGame.TRAD_CRABVILLAGE_SHOP))

	$shopList.setShopItemList(shopItems)

	# v7: Anak Desa sudah mengantar Ranbyus dan Pak Tabib sampai pintu -> Bu Kepiting bercerita
	if _infoPending():
		_playInfoScene()


# ---------- v7: Bu Kepiting (Ibu Toko) memberi petunjuk dan mengantar ke Desa Beruang ----------

func _infoPending():
	return GlobalGame.getStoryStage()==GlobalGame.STAGE_MEDICINE \
		and GlobalGame.getTabibQuest()==GlobalGame.TQ_HOME_DONE \
		and int(GlobalScenes.getParamForSceneOr("story","cv_guided",0))==1


# v7.2: Anak Desa tidak berhenti di luar. Dia ikut masuk, mengantar sampai ke Bu Kepiting,
# memperkenalkan tamunya, lalu pamit dan keluar untuk main.
const WelcomeBoyScene=preload("res://screens/crabs-village/characters/welcome-boy.tscn")
const BOY_STAND_POS=Vector2(150,92)    # berdiri di samping Ranbyus saat memperkenalkan
const BOY_ENTER_POS=Vector2(150,150)   # muncul tepat di dalam pintu


func _playInfoScene():
	getPlayer().disableNavigation()
	var boy=WelcomeBoyScene.instantiate()
	add_child(boy)
	boy.global_position=BOY_ENTER_POS
	await cs_wait(0.7)
	# Ranbyus dan Anak Desa berjalan bersama ke depan meja Bu Kepiting
	cs_walk_npc(boy,BOY_STAND_POS,1.4)
	await cs_move_hero(Vector2(122,90),1.4)
	await cs_talk(GlobalGame.TRAD_CRAB_SHOP_INTRO)
	# Anak Desa pamit, berjalan keluar lewat pintu, lalu menghilang
	await cs_walk_npc(boy,$door.global_position+Vector2(0,-10),1.5)
	await cs_fade(boy,0.0,0.2)
	boy.queue_free()
	await cs_wait(0.4)
	await cs_talk(GlobalGame.TRAD_CRAB_SHOP_INFO)
	# petunjuk sudah diterima: tersimpan, jadi kalau permainan dimuat ulang Bu Kepiting tinggal mengantar
	GlobalGame.setTabibQuest(GlobalGame.TQ_GUIDED)
	await _leaveForBear()


# Bu Kepiting keluar dari tokonya bersama Ranbyus, lalu adegan perjalanan ke Desa Beruang diputar
func _leaveForBear():
	var doorPos=$door.global_position
	cs_walk_npc($seller,doorPos+Vector2(-10,-24),2.3)
	await cs_move_hero(doorPos+Vector2(6,-28),2.1)
	await cs_wait(0.5)
	SceneTransition.change_scene("res://screens/journey.tscn")


func _on_simpleDialog_discussionFinished():
	$simpleDialog.end()
	$shopList.showWindow()
	pass # Replace with function body.


func _on_sellerTalk_playerOpenedDoor():
	if GlobalGame.getStoryStage()==GlobalGame.STAGE_MEDICINE and GlobalGame.getTabibQuest()==GlobalGame.TQ_GUIDED:
		# permainan dimuat ulang di tengah alur: Bu Kepiting mengulang tawaran mengantar
		getPlayer().disableNavigation()
		await cs_talk(GlobalGame.TRAD_CRAB_ESCORT_AGAIN)
		await _leaveForBear()
		return
	$simpleDialog.start()
	
	getPlayer().disableNavigation()



func _on_door_playerOpenedDoor():
	GlobalPlayer.savePosition(Vector2(45,171))
	SceneTransition.change_scene("res://screens/crabs-village.tscn")

