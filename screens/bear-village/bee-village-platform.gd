extends Node2D

var honeyReceived=0
var dialogStillDisplayed=false

@onready var cheatGround=get_node("cheat-ground")

func getPlayer():
	return $"bear-platform"

# Called when the node enters the scene tree for the first time.
func _ready():
	
	cheatGround.position.y=500
	
	dialogStillDisplayed=GlobalScenes.getParamForSceneOr(scene_file_path,'dialogStillDisplayed',false)
	
	$gameOver.visible=false
	getPlayer().loadCameraLimits($cameraRef)
	getPlayer().enableCamera()
	
	$startDialog.addDiscussion(GlobalGame.getTraductionById(GlobalGame.TRAD_WORD_APICULTEUR),GlobalGame.getTraductionById(GlobalGame.TRAD_BEARVILLAGE_BEEPLATFORM_START))
	if !dialogStillDisplayed:
		$startDialog.start()
		
		disableNavigation()
	else:
		enableNavigation()
	
	var winLines=GlobalGame.getTraductionById(GlobalGame.TRAD_BEARVILLAGE_BEEPLATFORM_WIN).duplicate()
	# bantuan kedua -> ada hadiah madu tambahan
	if GlobalGame.willBeeBonusFollow("bv_bees_done"):
		winLines.append_array(GlobalGame.getTraductionById(GlobalGame.TRAD_BEE_BONUS))
	$winDialog.addDiscussion(GlobalGame.getTraductionById(GlobalGame.TRAD_WORD_APICULTEUR),winLines)

	_buildHud()
	

# ---- petunjuk langkah demi langkah di layar ----
const DefaultTheme=preload("res://common/themes/default.tres")
var stepLabel=null
var countLabel=null

func _buildHud():
	var layer=CanvasLayer.new()
	layer.layer=20
	add_child(layer)
	countLabel=_makeHudLabel(layer,Vector2(0,4),10,Color(1,0.92,0.6))
	stepLabel=_makeHudLabel(layer,Vector2(0,16),8,Color(1,1,1))
	_updateHud()

func _makeHudLabel(layer_, pos_, size_, color_):
	var label=Label.new()
	label.theme=DefaultTheme
	label.position=pos_
	label.size=Vector2(320,12)
	label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size",size_)
	label.add_theme_color_override("font_color",color_)
	label.add_theme_color_override("font_outline_color",Color(0.13,0.125,0.2))
	label.add_theme_constant_override("outline_size",4)
	layer_.add_child(label)
	return label

func _updateHud():
	if countLabel==null:
		return
	countLabel.text="Madu diantar: "+str(honeyReceived)+" / 3"
	if getPlayer().isFilled():
		stepLabel.text="LANGKAH 2: bawa ember ke Peternak Lebah (beruang di KIRI) dan sentuh dia"
	else:
		stepLabel.text="LANGKAH 1: pergi ke KANAN, sentuh ember madu di sarang lebah"

func _process(_delta):
	_updateHud()

func enableNavigation():
	$navigation.enable()
	$navigation.enableButton()

func disableNavigation():
	$navigation.disable()
	


func playerPickedHoney(honey_):
	honey_.queue_free()
	getPlayer().fill()


func _on_honey_playerPickHoney(obj_):
	playerPickedHoney(obj_)



func _on_honey2_playerPickHoney(obj_):
	playerPickedHoney(obj_)


func _on_honey3_playerPickHoney(obj_):
	playerPickedHoney(obj_)


func _on_exitDoor_playerOpenedDoor():
	goBackToVillage()	


func _on_bearAsking_playerOpenedDoor():
	if getPlayer().isFilled():
		honeyReceived+=1
		
		get_node("bearAsking/honney"+str(honeyReceived)).visible=true
		getPlayer().is_empty()
		
		if honeyReceived >= 3:
			$winDialog.start()
			$navigation.disable()
		


func _on_startDialog_discussionFinished():
	$startDialog.end()
	enableNavigation()
	GlobalScenes.saveParamForScene(scene_file_path,"dialogStillDisplayed",true)



func _on_winDialog_discussionFinished():
	$winDialog.end()
	GlobalPlayer.addGems(4)
	# tercatat di panel TUJUAN desa beruang
	GlobalScenes.saveParamForScene("story","bv_honey_done",1)
	GlobalGame.giveBeeBonusIfReady()
	goBackToVillage()	
	
func goBackToVillage():
	GlobalPlayer.savePosition(Vector2(341,419))
	SceneTransition.change_scene("res://screens/bear-village.tscn")





func _on_Button_button_down():
	$gameOver.visible=false
	$gameOver/Camera2D.enabled=false
	get_tree().reload_current_scene()


func _on_switcharea_enableCheatCode():
	cheatGround.position.y=0
	pass # Replace with function body.


func _on_fall_body_exited(body):
	if body.is_in_group("Player"):
		$gameOver.visible=true
		$gameOver/Camera2D.enabled=true
		$gameOver/Camera2D.make_current()


func _on_fall_body_entered(body):
	if body.is_in_group("Player"):
		$gameOver.visible=true
		$gameOver/Camera2D.enabled=true
		$gameOver/Camera2D.make_current()
