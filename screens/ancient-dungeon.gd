extends "res://common/class/scene.gd"

# Halaman depan Ancient Dungeon. Darkus berdiri di depan gerbang dan membukakan class
# (Ksatria / Pemburu / Penyihir). Gerbang baru bisa dimasuki setelah punya class.
# Scene ini ditulis oleh tools/build_ancient_dungeon_scenes.py.

const ClassSelect=preload("res://screens/game/classSelect.gd")
const HeroClass=preload("res://common/class/hero_class.gd")

const ShopItem=preload("res://common/class/shopItem_class.gd")

signal classPicked(class_)

# harga Akses Class (Sage, Asasin, Engineer) di kios Barong
const CLASS_LICENSE_PRICE=80
const CLASS_COCONUT_PRICE=14   # setara laklak (15-16), sedikit lebih murah

var busy=false
var shopList=null


func _ready():
	setPlayerPath("sorted/playerAndControl")
	loadPosition()
	getPlayer().loadCameraLimits($cameraRef)
	_updateDungeonMist()
	_setupShop()


# Kabut di gerbang hanya hilang setelah semua encounter Ancient Dungeon selesai.
# Status sumur tidak memengaruhi kabut dungeon, dan sebaliknya.
func _updateDungeonMist():
	if !has_node("ColdMist"):
		return
	var all_cleared = true
	for key in ["dg_ular", "dg_leak", "dg_poci", "dg_celuluk", "dg_kunti", "dg_boss"]:
		if GlobalScenes.getParamForSceneOr("dungeon", key, false) != true:
			all_cleared = false
			break
	$ColdMist.visible = !all_cleared


# ---------- dialog ----------

func _talk(key_):
	var dialog=load("res://common/ui/simpleDialog.tscn").instantiate()
	add_child(dialog)
	GlobalGame.addDialogByKey(dialog,key_)
	getPlayer().disableNavigation()
	dialog.start()
	await dialog.discussionFinished
	dialog.end()
	dialog.queue_free()
	getPlayer().enableNavigation()


func _chosenKey(class_):
	match class_:
		HeroClass.ARCHER:
			return GlobalGame.TRAD_DARKUS_CHOSEN_ARCHER
		HeroClass.WIZARD:
			return GlobalGame.TRAD_DARKUS_CHOSEN_WIZARD
		HeroClass.ASSASSIN:
			return GlobalGame.TRAD_DARKUS_CHOSEN_ASSASSIN
		HeroClass.ENGINEER:
			return GlobalGame.TRAD_DARKUS_CHOSEN_ENGINEER
		HeroClass.SAGE:
			return GlobalGame.TRAD_DARKUS_CHOSEN_SAGE
	return GlobalGame.TRAD_DARKUS_CHOSEN_KNIGHT


# ---------- kios Barong ----------

func _setupShop():
	shopList=load("res://common/ui/shopList.tscn").instantiate()
	add_child(shopList)
	GlobalPlayer.consumeSageLicenseIfUsed()
	var items=[
		ShopItem.new(GlobalItems.ID.HP_POTION,8),
		ShopItem.new(GlobalItems.ID.MANA_POTION,8),
		# v9.24: kue putu dan laklak tidak dijual di sini; diganti Kelapa (sedikit lebih murah dari laklak 15-16)
		ShopItem.new(GlobalItems.ID.KELAPA,CLASS_COCONUT_PRICE),
		ShopItem.new(GlobalItems.ID.SOTO,24),
		ShopItem.new(GlobalItems.ID.JAMU_OJO_LALI,20),
		ShopItem.new(GlobalItems.ID.SAGE_LICENSE,CLASS_LICENSE_PRICE),
		ShopItem.new(GlobalItems.ID.ASSASSIN_LICENSE,CLASS_LICENSE_PRICE),
		ShopItem.new(GlobalItems.ID.ENGINEER_LICENSE,CLASS_LICENSE_PRICE),
		ShopItem.new(GlobalItems.ID.HONEY,6)
	]
	# Akses class hanya dijual kalau class itu belum terbuka dan belum dibeli.
	# Asasin / Engineer baru dijual setelah pemain memilih salah satunya di Darkus
	# (yang tidak dipilih bisa dibeli di sini dengan harga sama). Exorcist / Alkemis eksklusif dari drop Bhuta Kala, tidak dijual.
	var hiddenLicenses=[]
	for class_ in GlobalPlayer.LICENSE_CLASSES:
		var licenseId=GlobalPlayer.getLicenseItemId(class_)
		if GlobalPlayer.isClassUnlocked(class_) or GlobalPlayer.hasItem(licenseId):
			hiddenLicenses.append(licenseId)
		elif HeroClass.isAdvanceChoice(class_) and !GlobalPlayer.hasPickedAdvanceClass():
			hiddenLicenses.append(licenseId)
	items=items.filter(func(shopItem): return !hiddenLicenses.has(shopItem.item))
	shopList.setShopItemList(items)
	# menutup toko / membeli mengaktifkan kembali gerak pemain
	shopList.buyItem.connect(getPlayer()._on_shopList_buyItem)


func _refreshShop():
	if shopList!=null:
		shopList.queue_free()
	_setupShop()


func _on_barong_talk():
	if busy:
		return
	busy=true
	if GlobalGame.getTalkCount("barong")==0:
		GlobalGame.addTalkCount("barong")
		await _talk(GlobalGame.TRAD_BARONG_INTRO)
	else:
		await _talk(GlobalGame.TRAD_BARONG_AGAIN)
	getPlayer().disableNavigation()
	# daftar dibangun ulang supaya Akses Class yang baru bisa dibeli (mis. setelah memilih di Darkus) muncul
	_refreshShop()
	shopList.showWindow()
	busy=false


# ---------- Darkus ----------

func _on_darkus_talk():
	if busy:
		return
	busy=true
	if GlobalPlayer.hasChosenClass():
		# 4 musuh dungeon (ular, pocong, leak bara, zombie) sudah kalah: tawarkan Asasin / Engineer
		if !GlobalPlayer.hasPickedAdvanceClass() and HeroClass.isAdvanceUnlocked():
			await _talk(GlobalGame.TRAD_DARKUS_ADVANCE)
			await _pickClass(HeroClass.ADVANCE_CHOICES.duplicate(), true)
			busy=false
			return
		# Item Akses Class dari kios Barong: aktifkan kapan saja, tanpa menunggu pemilihan class lagi
		var licensed=GlobalPlayer.getLicensedClasses()
		if !licensed.is_empty():
			await _talk(GlobalGame.TRAD_DARKUS_LICENSE)
			await _pickClass(licensed, true)
			busy=false
			return
		# setelah bos terakhir (Darkus dirasuki Satan) kalah, Darkus sadar kembali
		if true==GlobalScenes.getParamForSceneOr("dungeon","dg_boss",false):
			await _talk(GlobalGame.TRAD_DARKUS_SAVED)
		else:
			await _talk(GlobalGame.TRAD_DARKUS_AFTER)
	else:
		if GlobalGame.getTalkCount("darkus")==0:
			GlobalGame.addTalkCount("darkus")
			await _talk(GlobalGame.TRAD_DARKUS_INTRO)
		await _talk(GlobalGame.TRAD_DARKUS_OFFER)
		await _pickClass()
	busy=false


func _pickClass(choices_=null, advance_=false):
	getPlayer().disableNavigation()
	var layer=CanvasLayer.new()
	layer.layer=50
	add_child(layer)
	var select=ClassSelect.new()
	var availableClasses=HeroClass.CHOICES.duplicate() if choices_==null else choices_
	# Sage baru bisa dipilih setelah akses class dibeli dari kios Barong. Begitu terbuka,
	# item aksesnya hilang dari inventaris dan Sage tetap tersedia.
	if !advance_:
		if GlobalPlayer.hasItem(GlobalItems.ID.SAGE_LICENSE):
			GlobalPlayer.unlockSage()
			getPlayer().reloadInvetory()
		if GlobalPlayer.isSageUnlocked() and !availableClasses.has(HeroClass.SAGE):
			availableClasses.append(HeroClass.SAGE)
	select.classList=availableClasses
	layer.add_child(select)
	select.chosen.connect(func(class_): classPicked.emit(class_))
	select.cancelled.connect(func(): classPicked.emit(""))
	var picked=await classPicked
	layer.queue_free()

	if picked=="":
		await _talk(GlobalGame.TRAD_DARKUS_DECLINE)
		return
	var sacrifice=""
	if !GlobalPlayer.ownsClass(picked) and GlobalPlayer.getOwnedClasses().size()>=GlobalPlayer.MAX_OWNED_CLASSES:
		sacrifice=await _pickClassToReplace()
		if sacrifice=="":
			await _talk(GlobalGame.TRAD_DARKUS_DECLINE)
			return
	if !GlobalPlayer.chooseClass(picked,sacrifice):
		await _talk(GlobalGame.TRAD_DARKUS_DECLINE)
		return
	getPlayer().reloadInvetory()
	getPlayer().reloadLife()
	getPlayer().reloadMana()
	await _talk(_chosenKey(picked))
	if !advance_:
		await _talk(GlobalGame.TRAD_DARKUS_AFTER)


func _pickClassToReplace():
	var owned=GlobalPlayer.getOwnedClasses()
	if owned.is_empty():
		return ""
	var layer=CanvasLayer.new()
	layer.layer=51
	add_child(layer)
	var select=ClassSelect.new()
	select.classList=owned
	select.headerText="GANTI CLASS"
	select.subtitleText="Pilih class yang dikorbankan"
	select.confirmText="Ganti Class"
	layer.add_child(select)
	var result={"class":"","done":false}
	select.chosen.connect(func(class_):
		result["class"]=class_
		result["done"]=true)
	select.cancelled.connect(func(): result["done"]=true)
	while !result["done"]:
		await get_tree().process_frame
	var picked=result["class"]
	layer.queue_free()
	return picked

# ---------- pintu ----------

func _on_gateDoor_playerOpenedDoor():
	if !GlobalPlayer.hasChosenClass():
		# didorong mundur sedikit, lalu Darkus menegur
		getPlayer().getPlayerBody().global_position+=Vector2(0,30)
		if !busy:
			busy=true
			await _talk(GlobalGame.TRAD_DARKUS_GATE)
			busy=false
		return
	GlobalPlayer.savePosition(Vector2(576,1400))
	SceneTransition.change_scene("res://screens/ancient-dungeon/dungeon.tscn")


func _on_exit_playerOpenedDoor():
	# kembali ke peta dunia, di bawah gerbang Ancient Dungeon
	GlobalPlayer.savePosition(Vector2(304,-215))
	SceneTransition.change_scene("res://screens/macro-map.tscn")
