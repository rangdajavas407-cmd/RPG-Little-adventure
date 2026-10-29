extends Control

var saveFileList = []
@onready var expleButton = get_node("exples/Button")

func _ready():
	$exples.visible = false
	$Title.text = GlobalGame.getTraductionById(GlobalGame.TRAD_BUTTON_LOADGAME)
	$Retour.text = GlobalGame.getTraductionById(GlobalGame.TRAD_BUTTON_RETOUR)
	saveFileList = GlobalGame.getList()
	var buttonBox = get_node("scroll/VBox")
	if saveFileList.is_empty():
		var emptyLabel = Label.new()
		emptyLabel.name = "EmptySaveMessage"
		emptyLabel.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		emptyLabel.custom_minimum_size = Vector2(170, 44)
		emptyLabel.position = Vector2(0, 0)
		match GlobalGame.getLang():
			GlobalGame.EN:
				emptyLabel.text = "No saved games yet. Start a new game first."
			GlobalGame.MS:
				emptyLabel.text = "Belum ada permainan disimpan. Mulakan permainan baharu dahulu."
			_:
				emptyLabel.text = "Belum ada data tersimpan. Mulai permainan baru terlebih dahulu."
		buttonBox.add_child(emptyLabel)
	else:
		for saveFileLoop in saveFileList:
			var newButton = expleButton.duplicate()
			newButton.text = saveFileLoop
			buttonBox.add_child(newButton)
			newButton.pressed.connect(_on_press_fileToLoad.bind(saveFileLoop))
			newButton.grab_focus()

func _on_press_fileToLoad(fileSave):
	GlobalGame.loadFile(fileSave)
	var targetScene = GlobalGame.getSceneToLoad()
	if targetScene != null and targetScene != "" and ResourceLoader.exists(targetScene):
		SceneTransition.change_scene(targetScene)
	else:
		push_warning("Data simpanan tidak mempunyai scene yang sah: " + str(fileSave))

func _on_Retour_pressed():
	SceneTransition.change_scene("res://screens/game/menu.tscn")
