extends "res://common/class/scene.gd"


var shopItemClass=preload("res://common/class/shopItem_class.gd")



func _ready():
	setPlayerPath("playerAndControl")
	loadPosition()
	getPlayer().loadCameraLimits($cameraRef)

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


func _on_sellerTalk_playerOpenedDoor():
	$simpleDialog.start()
	
	getPlayer().disableNavigation()
	
	


func _on_door_playerOpenedDoor():
	GlobalPlayer.savePosition(Vector2(833,458))
	SceneTransition.change_scene("res://screens/bear-village.tscn")


func _on_simpleDialog_discussionFinished():
	$simpleDialog.end()
	$shopList.showWindow()
