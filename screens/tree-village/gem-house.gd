extends "res://common/class/scene.gd"

var shopItemClass=preload("res://common/class/shopItem_class.gd")

const STEP_FIRSTTIME='first_time'
const STEP_SHOULD_FIND_GORMONSTAR='shouldFindGormonStar'
const STEP_HAS_FOUND_GORMONSTAR='hasFoundGormonStar'

const STARS_NEEDED=5
const STARS_REWARD_GEMS=10

# efek yang dijalankan setelah dialog selesai (dialog disusun saat pemain menekan E)
var giveToolsAfterDialog=false
var payStarsAfterDialog=false


func _ready():
	setPlayerPath("playerAndControl")
	loadPosition()
	getPlayer().zoomDown()
	getPlayer().loadCameraLimits($cameraRef)


func prepareDialog():
	var TRAD_GEMKEEPER=GlobalGame.getTraductionById(GlobalGame.TRAD_WORD_GEMKEEPER)
	var hero=GlobalGame.getHeroName()

	$simpleDialog.multiDialogList=[]
	giveToolsAfterDialog=false
	payStarsAfterDialog=false

	var step=GlobalScenes.getParamForSceneOr(scene_file_path,"step",STEP_FIRSTTIME)

	if step==STEP_FIRSTTIME:

		var discussionList=GlobalGame.getTraductionById(GlobalGame.TRAD_TREEVILLAGE_GEMHOUSE_START)

		$simpleDialog.addDiscussion(TRAD_GEMKEEPER,discussionList[0])
		$simpleDialog.addDiscussion(hero,discussionList[1])
		$simpleDialog.addDiscussion(TRAD_GEMKEEPER,discussionList[2])
		$simpleDialog.addDiscussion(hero,discussionList[3])
		$simpleDialog.addDiscussion(TRAD_GEMKEEPER,discussionList[4])
		$simpleDialog.addDiscussion(hero,discussionList[5])

		giveToolsAfterDialog=true
		GlobalScenes.saveParamForScene(scene_file_path,"step",STEP_SHOULD_FIND_GORMONSTAR)

	elif step==STEP_SHOULD_FIND_GORMONSTAR:

		var discussionList=GlobalGame.getTraductionById(GlobalGame.TRAD_TREEVILLAGE_GEMHOUSE_PENDING)

		$simpleDialog.addDiscussion(TRAD_GEMKEEPER,discussionList[0])

		var nbGormonStarFounded=GlobalPlayer.countItem(GlobalItems.ID.GORDMON_STAR)

		if nbGormonStarFounded < STARS_NEEDED:
			$simpleDialog.addDiscussion(hero,discussionList[1])
		else:
			$simpleDialog.addDiscussion(hero,discussionList[2])
			$simpleDialog.addDiscussion(TRAD_GEMKEEPER,discussionList[3])
			payStarsAfterDialog=true

	elif step==STEP_HAS_FOUND_GORMONSTAR:
		var discussionList=GlobalGame.getTraductionById(GlobalGame.TRAD_TREEVILLAGE_GEMHOUSE_END)
		$simpleDialog.addDiscussion(TRAD_GEMKEEPER,discussionList[0])


func _on_door_playerOpenedDoor():
	GlobalPlayer.savePosition(Vector2(651,115))
	SceneTransition.change_scene("res://screens/tree-village.tscn")


func giveToPlayerSpadeAndMap():
	GlobalPlayer.addItem(GlobalItems.ID.SPADE)
	GlobalPlayer.addItem(GlobalItems.ID.GORMON_STAR_MAP)
	getPlayer().reloadInvetory()


func payStars():
	for i in range(STARS_NEEDED):
		GlobalPlayer.removeItem(GlobalItems.ID.GORDMON_STAR)
	GlobalPlayer.addGems(STARS_REWARD_GEMS)
	GlobalScenes.saveParamForScene(scene_file_path,"step",STEP_HAS_FOUND_GORMONSTAR)
	getPlayer().reloadGems()
	getPlayer().reloadInvetory()


func _on_simpleDialog_discussionFinished():
	$simpleDialog.end()

	if giveToolsAfterDialog:
		giveToPlayerSpadeAndMap()
		giveToolsAfterDialog=false
	if payStarsAfterDialog:
		payStars()
		payStarsAfterDialog=false

	getPlayer().enableNavigation()


# pemain menekan E di dekat Penjaga Permata
func _on_discussionArea_playerOpenedDoor():
	prepareDialog()
	$simpleDialog.start()
	getPlayer().disableNavigation()
