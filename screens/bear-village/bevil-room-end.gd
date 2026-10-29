extends "res://common/class/scene.gd"


func _ready():

	var lines=GlobalGame.getTraductionById(GlobalGame.TRAD_BEARVILLAGE_BEVILROOM_WIN).duplicate()
	# bantuan kedua -> ada hadiah madu tambahan
	if GlobalGame.willBeeBonusFollow("bv_honey_done"):
		lines.append_array(GlobalGame.getTraductionById(GlobalGame.TRAD_BEE_BONUS))
	$winRect/winDialog.addDiscussion( GlobalGame.getTraductionById(GlobalGame.TRAD_WORD_APICULTEUR),lines)
	win()
	

func win():
	$winRect.visible=true
	$winRect/winDialog.start()
	
	$Camera2D.enabled=true
	$Camera2D.make_current()
	
	



func _on_winDialog_discussionFinished():
	GlobalPlayer.addGems(4)
	# tercatat di panel TUJUAN desa beruang
	GlobalScenes.saveParamForScene("story","bv_bees_done",1)
	GlobalGame.giveBeeBonusIfReady()
	
	GlobalPlayer.savePosition(Vector2(120,300))
	SceneTransition.change_scene("res://screens/bear-village.tscn")
