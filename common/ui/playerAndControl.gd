extends Node2D


signal save
signal quit

signal startClimbing
signal endClimbing

signal digging
signal endDigging

signal hit(enemy_)
signal damagedBy(enemy_)

signal pressAccept
signal pressMenu

# Called when the node enters the scene tree for the first time.
const WeaponMapSkin=preload("res://common/characters/weaponMapSkin.gd")
var appliedAttackSkin=-2

func _ready():
	# animasi serang di peta/desa mengikuti senjata yang dipakai (tanpa mengubah player.gd)
	$HUD.equipItem.connect(_refreshAttackSkin)
	$player.pressAccept.connect(_refreshAttackSkin)
	_refreshAttackSkin()

func _refreshAttackSkin(_item=null):
	var equipment=GlobalPlayer.getEquipment()
	var key=-1 if equipment==null else int(equipment)
	if key==appliedAttackSkin:
		return
	appliedAttackSkin=key
	WeaponMapSkin.applyAttackSkin($player/AnimatedSprite2D.sprite_frames,equipment)
	
const CompanionScript=preload("res://common/characters/companion.gd")
var companion=null

# badan pemain (CharacterBody2D) untuk adegan / animasi khusus
func getPlayerBody():
	return $player

# Vera melayang mengikuti pemain. Dipasang sebagai saudara node ini agar urutan gambarnya ikut Y-sort.
func spawnCompanion(startPosition_=null):
	removeCompanion()
	companion=Node2D.new()
	companion.set_script(CompanionScript)
	get_parent().add_child(companion)
	companion.follow($player,startPosition_)
	return companion

func removeCompanion():
	if companion!=null and is_instance_valid(companion):
		companion.queue_free()
	companion=null

# Pak Tabib (v7): pendamping non-petarung yang berjalan di belakang pemain pada tahap quest tertentu.
const TabibFollowerScript=preload("res://common/characters/tabibFollower.gd")
var tabibFollower=null

func spawnTabib(startPosition_=null):
	removeTabib()
	tabibFollower=Node2D.new()
	tabibFollower.set_script(TabibFollowerScript)
	get_parent().add_child(tabibFollower)
	tabibFollower.follow($player,startPosition_)
	return tabibFollower

func removeTabib():
	if tabibFollower!=null and is_instance_valid(tabibFollower):
		tabibFollower.queue_free()
	tabibFollower=null

func getPlayerPosition():
	return $player.global_position

func enableNavigation():
	$navigation.enable()
	$player.enableNavigation()

func disableNavigation():
	$navigation.disable()
	# pemain juga berhenti bergerak/berinteraksi saat dialog atau toko terbuka
	$player.disableNavigation()
	$player.stop()
	
func disableCamera():
	$player.disableCamera()

func reloadGems():
	$HUD.reloadGems()
	
func reloadInvetory():
	$HUD.reloadInventory()
	
func reloadLife():
	$HUD.reloadLife()

func reloadMana():
	$HUD.reloadMana()
	
func reloadXp():
	$HUD.reloadXp()

func zoomDown():
	$player.zoomDown()
	
func zoomUp():
	$player.zoomUp();
	
func loadCameraLimits(cameraRef_):
	$player.loadCameraLimits(cameraRef_)


func _on_shopList_buyItem(item_):
	$HUD.reloadGems()
	$HUD.reloadInventory()
	enableNavigation()


func _on_HUD_save():
	emit_signal("save")
	pass # Replace with function body.


func _on_HUD_quit():
	emit_signal("quit")
	pass # Replace with function body.


func _on_player_startClimbing():
	if tabibFollower!=null and is_instance_valid(tabibFollower):
		tabibFollower.setClimbing(true)
	emit_signal("startClimbing")
	pass # Replace with function body.


func _on_player_endClimbing():
	if tabibFollower!=null and is_instance_valid(tabibFollower):
		tabibFollower.setClimbing(false)
	emit_signal("endClimbing")
	pass # Replace with function body.


func _on_gordonhome_playerLeaveScale():
	$player._on_gordonhome_playerLeaveScale()
	pass # Replace with function body.


func _on_gordonhome_playerOnScale():
	$player._on_gordonhome_playerOnScale()
	pass # Replace with function body.


func _on_gordonhome_playerStartClimbing():
	$player._on_gordonhome_playerStartClimbing()
	pass # Replace with function body.




func _on_navigation_releaseButton():
	if GlobalPlayer.getEquipment()==GlobalItems.ID.SPADE:
		emit_signal("endDigging")
	
func _on_navigation_pushButton():
	if GlobalPlayer.getEquipment()==GlobalItems.ID.SPADE:
		emit_signal("digging")
	


func _on_player_hit(enemy_):
	emit_signal("hit",enemy_)



func _on_player_damagedBy(enemy_):
	emit_signal("damagedBy",enemy_)


func _on_HUD_useItem(item_):
	$HUD.reloadInventory()
	pass # Replace with function body.


func _on_player_pressAccept():
	emit_signal("pressAccept")
	if GlobalPlayer.getEquipment()==GlobalItems.ID.SPADE:
		emit_signal("digging")
	

func _on_player_pressMenu():
	emit_signal("pressMenu")
	pass # Replace with function body.


func _on_HUD_openMenu():
	$navigation.disable()
	$player.disableNavigation()
	
	print("open menu")



func _on_HUD_closeMenu():
	$navigation.enable()
	$player.enableNavigation()
	
	print("close menu")



func _on_player_releaseAccept() -> void:
	if GlobalPlayer.getEquipment()==GlobalItems.ID.SPADE:
		emit_signal("endDigging")
