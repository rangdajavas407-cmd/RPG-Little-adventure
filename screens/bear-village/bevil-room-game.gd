extends "res://common/class/scene.gd"

# Mini game mengusir lebah. Kalahkan SEMUA lebah dengan menekan tombol serang saat lebah dekat.

const DefaultTheme=preload("res://common/themes/default.tres")
const BEE_DAMAGE=6

var nbBeeKilled=0
var maxNbBeeToKill=0
var killedBees={}
var finished=false

var playerSavedLife=0

var counterLabel=null
var hintLabel=null


func debug():
	GlobalPlayer.addItem(GlobalPlayer.getClassWeaponId())
	GlobalPlayer.setEquipment(GlobalPlayer.getClassWeaponId())



func _ready():
	#debug()
	
	playerSavedLife=GlobalPlayer.getLife()

	_ensureWeapon()

	setPlayerPath("playerAndControl")
	loadPosition()
		
	setupGame()
	
	getPlayer().loadCameraLimits($cameraRef)

	$playerAndControl.enableNavigation()
	_buildHud()


# serang hanya bisa kalau memegang senjata: pasang otomatis senjata yang dimiliki
func _ensureWeapon():
	if GlobalPlayer.hasWeaponEquipped():
		return
	var weaponId=GlobalPlayer.getActiveWeaponId()
	if weaponId>=0:
		GlobalPlayer.setEquipment(weaponId)


func setupGame():
	for node in get_children():
		if node.is_in_group("Enemy"):
			node.setPlayer(getPlayer())
			
			maxNbBeeToKill+=1


# petunjuk cara main + penghitung lebah di layar
func _buildHud():
	var layer=CanvasLayer.new()
	layer.layer=20
	add_child(layer)

	counterLabel=Label.new()
	counterLabel.theme=DefaultTheme
	counterLabel.add_theme_font_size_override("font_size",10)
	counterLabel.add_theme_color_override("font_color",Color(1,0.92,0.7))
	counterLabel.add_theme_color_override("font_outline_color",Color(0.13,0.125,0.2))
	counterLabel.add_theme_constant_override("outline_size",4)
	counterLabel.position=Vector2(6,4)
	layer.add_child(counterLabel)
	_updateCounter()

	hintLabel=Label.new()
	hintLabel.theme=DefaultTheme
	hintLabel.text="CARA MAIN\nGerakkan karakter dekati lebah.\nTekan SERANG (Spasi / Enter / tombol A)\nsaat lebah ada di depanmu untuk memukulnya.\nKalahkan semua lebah untuk menang!"
	hintLabel.add_theme_font_size_override("font_size",8)
	hintLabel.add_theme_color_override("font_color",Color(1,1,1))
	hintLabel.add_theme_color_override("font_outline_color",Color(0.13,0.125,0.2))
	hintLabel.add_theme_constant_override("outline_size",4)
	hintLabel.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	hintLabel.size=Vector2(320,60)
	hintLabel.position=Vector2(0,118)
	layer.add_child(hintLabel)
	var tween=create_tween()
	tween.tween_interval(9.0)
	tween.tween_property(hintLabel,"modulate:a",0.0,1.0)
	tween.tween_callback(hintLabel.queue_free)

	if !GlobalPlayer.hasWeaponEquipped():
		hintLabel.text="Kamu belum punya senjata!\nBuka Menu > Inventaris > Pasang senjata dulu."


func _updateCounter():
	if counterLabel!=null:
		counterLabel.text="Lebah: "+str(maxNbBeeToKill-nbBeeKilled)+" tersisa"


func _on_playerAndControl_hit(enemy_):
	# satu lebah hanya dihitung sekali walau terkena beberapa kali dalam satu frame
	if finished or !is_instance_valid(enemy_) or killedBees.has(enemy_.get_instance_id()):
		return
	killedBees[enemy_.get_instance_id()]=true
	enemy_.queue_free()
	GlobalPlayer.addXp(2)
	nbBeeKilled+=1
	$playerAndControl.reloadXp()
	_updateCounter()
	
	if nbBeeKilled>=maxNbBeeToKill:
		win()
	

func win():
	if finished:
		return
	finished=true
	SceneTransition.change_scene("res://screens/bear-village/bevil-room-end.tscn")
	

func _on_playerAndControl_damagedBy(enemy_):
	if finished:
		return
	
	enemy_.goBack()
	
	GlobalPlayer.damage(BEE_DAMAGE)
	getPlayer().reloadLife()

	if( GlobalPlayer.getLife() <= 0):
		finished=true
		GlobalPlayer.setLife(playerSavedLife)
		
		GlobalPlayer.savePosition(Vector2(120,300))
		SceneTransition.change_scene("res://screens/bear-village.tscn")



func _on_winDialog_discussionFinished():
	GlobalPlayer.addGems(4)
	
	GlobalPlayer.savePosition(Vector2(120,300))
	SceneTransition.change_scene("res://screens/bear-village.tscn")
