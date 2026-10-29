extends CanvasLayer

const TextFit=preload("res://common/ui/textFit.gd")

signal equipItem(item_)
signal useItem(item)

signal openInventory
signal closeInventory

var itemList=[]

var itemClass=preload("res://common/class/item_class.gd")
var exampleItem

var patternItem=null

var itemSelected=null

func _ready():
	getWindow().visible=false
	getSideInfo().visible=false
	$window2.visible=false
	
	var exampleItemTmp=getGrid().get_node("item")
	exampleItem=exampleItemTmp.duplicate()
	exampleItemTmp.queue_free()
	
	getWindow().get_node("title").text=GlobalGame.getTraductionById(GlobalGame.TRAD_UI_INVENTORY)
	getEquipButton().text=GlobalGame.getTraductionById(GlobalGame.TRAD_UI_EQUIP)
	getDisplayButton().text=GlobalGame.getTraductionById(GlobalGame.TRAD_UI_DISPLAY)
	getUseButton().text=GlobalGame.getTraductionById(GlobalGame.TRAD_UI_USE)
	


func emitOpenInventory():
	emit_signal("openInventory")
	
func emitCloseInventory():
	emit_signal("closeInventory")

#access
func getWindow():
	return $window
	
func getGrid():
	return $window/HBoxContainer/GridContainer

func getSideInfo():
	return $window/HBoxContainer/sideInfo

func getEquipButton():
	return getSideInfo().get_node("equipButton")
	
func getDisplayButton():
	return getSideInfo().get_node("displayButton")

func getUseButton():
	return getSideInfo().get_node("useButton")


func setItemList(itemList_):
	itemList=itemList_
	pass
	
func hideWindow():
	getWindow().visible=false
	emitCloseInventory()
	
func showWindow():
	getWindow().visible=true
	
	getSideInfo().visible=false
	
	for itemToReset in getGrid().get_children():
		getGrid().remove_child(itemToReset)
		itemToReset.queue_free()
	
	patternItem=exampleItem.duplicate()

	# item sejenis digabung (jumlahnya tampil di judul) dan diurutkan: senjata, alat, ramuan, makanan, barang, peta
	for item in GlobalItems.sortedUniqueIds(itemList):
		var realItem=GlobalItems.getItem(item)
		var newItem=patternItem.duplicate()
		newItem.setImage(realItem.getTexture())
		newItem.connect("button_down", Callable(self, "_on_pressed_selected").bind(item))
	
		getGrid().add_child(newItem)
	
	# focus sur le premier objet pour la navigation clavier / manette
	if getGrid().get_child_count() > 0:
		getGrid().get_child(0).grab_focus()
	else:
		getWindow().get_node("closeButton").grab_focus()

func _on_pressed_selected(item_):
	var realItem=GlobalItems.getItem(item_)
	getSideInfo().visible=true
	var title=realItem.name
	var count=itemList.count(item_)
	if count>1:
		title+="  x"+str(count)
	if GlobalPlayer.getEquipment()==item_:
		title+="  (dipakai)"
	TextFit.fit(getSideInfo().get_node("title"),title,124)
	getSideInfo().get_node("description").text=realItem.description

	itemSelected=item_

	var equipButton=getEquipButton()
	if not equipButton.button_down.is_connected(_on_pressed_equip):
		equipButton.button_down.connect(_on_pressed_equip)

	var displayButton=getDisplayButton()
	if not displayButton.button_down.is_connected(_on_pressed_display):
		displayButton.button_down.connect(_on_pressed_display)

	var useButton=getUseButton()
	if not useButton.button_down.is_connected(_on_pressed_use):
		useButton.button_down.connect(_on_pressed_use)

	# senjata hanya bisa dipasang kalau cocok dengan class pemain
	if (realItem.type==itemClass.TYPE.TOOL or realItem.type==itemClass.TYPE.WEAPON) and GlobalPlayer.canEquip(item_):
		equipButton.visible=true
	else:
		equipButton.visible=false
		
	if realItem.type==itemClass.TYPE.MAP:
		displayButton.visible=true
	else:
		displayButton.visible=false
	
	if realItem.type==itemClass.TYPE.MAGICPOTION or realItem.type==itemClass.TYPE.FOOD:
		useButton.visible=true
	else:
		useButton.visible=false
	

		
func _on_pressed_equip():
	GlobalPlayer.setEquipment(itemSelected)
	emit_signal("equipItem",itemSelected)
	getWindow().visible=false
	emitCloseInventory()

func _on_pressed_display():
	#display map zoomed
	$window2.visible=true
	$window2/closeButton2.grab_focus()
	$window2/TextureRect.texture=load("res://common/items/maps/gormonstar-map-zoom.png")

func _on_pressed_use():
	GlobalPlayer.useItem(itemSelected)
	emit_signal("useItem",itemSelected)
	getWindow().visible=false
	emitCloseInventory()

func _on_closeButton_pressed():
	getWindow().visible=false
	emitCloseInventory()


func _on_closeButton2_pressed():
	$window2.visible=false
	emitCloseInventory()
