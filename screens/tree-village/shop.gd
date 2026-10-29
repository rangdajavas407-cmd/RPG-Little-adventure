extends "res://common/class/scene.gd"


var shopItemClass=preload("res://common/class/shopItem_class.gd")

func _ready():
	setPlayerPath("playerAndControl")
	loadPosition()
	getPlayer().zoomDown()
	getPlayer().loadCameraLimits($cameraRef)

	var key=GlobalGame.TRAD_TREEVILLAGE_SHOP
	if GlobalGame.getStoryStage() >= GlobalGame.STAGE_MEDICINE:
		key=GlobalGame.TRAD_TREEVILLAGE_SHOP_MED
	GlobalGame.addDialogByKey($simpleDialog,key)
	
	# senjata class kini diberikan Darkus di Ancient Dungeon, bukan dijual di sini
	$shopList.setShopItemList([
		shopItemClass.new(GlobalItems.ID.HP_POTION,8),
		shopItemClass.new(GlobalItems.ID.MANA_POTION,8),
	])

func _on_door_playerOpenedDoor():
	GlobalPlayer.savePosition(Vector2(260,196))
	SceneTransition.change_scene("res://screens/tree-village.tscn")


func _on_discussionDoor_playerOpenedDoor():
	$simpleDialog.start()
	getPlayer().disableNavigation()


func _on_simpleDialog_discussionFinished():
	$simpleDialog.end()
	# navigasi dikembalikan saat daftar toko ditutup (sinyal buyItem)
	$shopList.showWindow()


func _on_discussionArea_playerOpenedDoor():
	$simpleDialog.start()
	getPlayer().disableNavigation()


