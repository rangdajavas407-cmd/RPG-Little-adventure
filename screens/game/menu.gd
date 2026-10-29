extends Control

var saveFileList=[]

func _ready():
	refreshUi()
	
	get_node("version").text=GlobalVersion.getVersion()

	$VBoxContainer/btnNew.grab_focus()


func _on_btnNew_button_down():
	#showNewGame()
	#hideLoadGame()
	SceneTransition.change_scene("res://screens/game/menuKeyboard.tscn")
	

func _on_btnLoad_button_down():
	#showLoadGame()
	#hideNewGame()
	SceneTransition.change_scene("res://screens/game/menuLoad.tscn")
	pass # Replace with function body.








func _on_btnID_button_down():
	GlobalGame.setLang(GlobalGame.ID)
	refreshUi()


func _on_btnEN_button_down():
	GlobalGame.setLang(GlobalGame.EN)
	
	refreshUi()
	pass # Replace with function body.

func refreshUi():
	$VBoxContainer/btnNew.text=GlobalGame.getTraductionById(GlobalGame.TRAD_BUTTON_NEWGAME)
	$VBoxContainer/btnLoad.text=GlobalGame.getTraductionById(GlobalGame.TRAD_BUTTON_LOADGAME)
	

func _on_btnMS_button_down():
	GlobalGame.setLang(GlobalGame.MS)
	refreshUi()
