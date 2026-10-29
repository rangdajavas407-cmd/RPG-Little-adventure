extends "res://common/class/scene.gd"


var shopItemClass=preload("res://common/class/shopItem_class.gd")



# titik muncul normal di dalam toko (dekat pintu)
const SPAWN_POS=Vector2(120,140)


func _ready():
	setPlayerPath("playerAndControl")
	loadPosition()
	getPlayer().zoomDown()
	getPlayer().loadCameraLimits($cameraRef)
	_ensurePlayerInsideRoom()

	var key=GlobalGame.TRAD_BEARVILLAGE_SHOP
	if GlobalGame.getStoryStage() >= GlobalGame.STAGE_MEDICINE:
		key=GlobalGame.TRAD_BEARVILLAGE_SHOP_MED
	$simpleDialog.addDiscussion(GlobalGame.getTraductionById(GlobalGame.TRAD_WORD_BEARSELLER),GlobalGame.getTraductionById(key))

	$shopList.setShopItemList([
		shopItemClass.new(GlobalItems.ID.HONEY,6),
		shopItemClass.new(GlobalItems.ID.HP_POTION,8),
		shopItemClass.new(GlobalItems.ID.MANA_POTION,8),
		shopItemClass.new(GlobalItems.ID.KUE_PUTU,12),
		shopItemClass.new(GlobalItems.ID.BUCKET,3)
		])

	# v7: Bu Kepiting memperkenalkan Ranbyus dan Pak Tabib pada Pak Beruang, Kepala Desa Beruang
	if GlobalGame.getStoryStage()==GlobalGame.STAGE_MEDICINE and GlobalGame.getTabibQuest()==GlobalGame.TQ_GUIDED:
		_playChiefScene()


# ---------- v7: Kepala Desa Beruang memberi tahu letak Buah Suwarga ----------

const CrabSellerScene=preload("res://screens/crabs-village/characters/crab-seller.tscn")

func _playChiefScene():
	getPlayer().disableNavigation()
	# Bu Kepiting masuk dari pintu dan berdiri di dekat Ranbyus
	var ibu=CrabSellerScene.instantiate()
	add_child(ibu)
	ibu.global_position=$door.global_position+Vector2(4,-14)
	await cs_wait(0.8)
	await cs_move_hero(Vector2(100,118),1.1)
	await cs_walk_npc(ibu,Vector2(134,120),1.7)
	await cs_talk(GlobalGame.TRAD_BEAR_CHIEF)
	if GlobalGame.isBearVillageCleared():
		await cs_talk(GlobalGame.TRAD_BEAR_CHIEF_OPEN)
	else:
		await cs_talk(GlobalGame.TRAD_BEAR_CHIEF_LOCKED)
	GlobalGame.setTabibQuest(GlobalGame.TQ_CHIEF)
	notify(GlobalGame.getTraductionById(GlobalGame.TRAD_BEAR_CHIEF_TIP),"story")
	getPlayer().enableNavigation()


func _on_sellerTalk_playerOpenedDoor():
	$simpleDialog.start()
	
	getPlayer().disableNavigation()
	
	


func _on_door_playerOpenedDoor():
	GlobalPlayer.savePosition(Vector2(833,458))
	SceneTransition.change_scene("res://screens/bear-village.tscn")


func _on_simpleDialog_discussionFinished():
	$simpleDialog.end()
	$shopList.showWindow()


# kalau karena sebab apa pun posisi pemain jatuh di luar ruangan toko, kembalikan ke dalam
func _ensurePlayerInsideRoom():
	var body=getPlayer().getPlayerBody()
	var room=Rect2($cameraRef.global_position,$cameraRef.size)
	if !room.grow(-8.0).has_point(body.global_position):
		getPlayer().position=SPAWN_POS
	body.visible=true
