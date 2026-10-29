extends Node

const HeroClass=preload("res://common/class/hero_class.gd")

var simpleFieldToSaveList=["gems","xp","life","maxLife","mana","maxMana","nickname","playerClass","equipment","weaponId","itemsList","side","ownedClasses"]
var stringFieldList=["nickname","playerClass"]
var arrayFieldList=["itemsList","ownedClasses"]
var nullFieldList=["equipment"]

var position=null
var itemsList=[]

var gems=0
var xp=0
var life=100
var maxLife=100
var mana=40
var maxMana=40
# hasil pemakaian item terakhir {"life":n,"mana":n} (kosong = tidak terpakai)
var lastUseResult={}
var nickname=null
# class pemain: "novice" (belum memilih) / knight / archer / wizard (save lama tanpa class = knight)
var playerClass="knight"
# Class yang sudah dimiliki pemain; maksimum empat. Disimpan bersama save.
var ownedClasses=[]
const MAX_OWNED_CLASSES=4
var equipment=null
# senjata terakhir yang dipasang (dipakai saat bertarung). -1 = belum ada.
# Dipisah dari equipment karena equipment juga dipakai untuk alat (mis. sekop).
var weaponId=-1

var side="DOWN"


# --- data pertarungan yang sedang berlangsung (tidak disimpan ke file save) ---
# musuh yang dilawan (id dari enemy_class.gd), dan posisi di peta setelah menang / mundur
var battleEnemy="spider"
var battleWinPosition=null
var battleLosePosition=null
# id encounter di peta yang sedang dilawan (supaya hilang setelah dikalahkan)
var battleEncounterKey=""
# true = Bhuta Kala baru gugur: dungeon memutar adegan ritual lalu memaksa pertarungan melawan Satan
var ritualCutscenePending=false
# true = Satan kalah; cutscene ritual perasukan Darkus diputar di dungeon, di luar battle
var possessionCutscenePending=false
# scene yang dimuat setelah pertarungan selesai (peta dunia, atau Ancient Dungeon).
# Direset ke peta dunia oleh spiderFight.gd setelah dipakai.
const DEFAULT_BATTLE_RETURN="res://screens/macro-map.tscn"
var battleReturnScene="res://screens/macro-map.tscn"
# encounter yang sudah dikalahkan selama perjalanan antar desa saat ini (di-reset tiap masuk desa)
var clearedEncounters=[]

var touchEnabled=true
var dialogAnimationEnabled=true

func setSide(side_):
	side=side_

func getSide():
	return side
	
func enableTouch():
	touchEnabled=true

func disableTouch():
	touchEnabled=false

func isTouchEnabled():
	return touchEnabled


func enableDialogAnimation():
	dialogAnimationEnabled=true

func disableDialogAnimation():
	dialogAnimationEnabled=false

func isDialogAnimationEnabled():
	return dialogAnimationEnabled

#---nickname
func setNickname(nickname_):
	nickname=nickname_

func getNickname():
	return nickname

#---class
func getPlayerClass():
	return playerClass

# dipanggil sekali saat permainan baru: atur statistik awal + senjata awal.
# Permainan baru memakai HeroClass.NOVICE (Petualang): belum punya class, hanya Pedang Kayu
# dan tampilan karakter utama. Class sungguhan dipilih nanti lewat Darkus di depan Ancient
# Dungeon (chooseClass), yang juga memberi senjata khas class + perisai Ksatria.
# Tongkat Kayu didapat dari Vera, Busur Kayu dari Anak Desa.
func setPlayerClass(class_):
	if class_!=HeroClass.NOVICE and !HeroClass.isValid(class_):
		class_=HeroClass.DEFAULT
	playerClass=class_
	if HeroClass.isValid(class_) and !ownedClasses.has(class_):
		ownedClasses.append(class_)
	var info=HeroClass.getInfo(class_)
	maxLife=info.life
	life=maxLife
	maxMana=info.mana
	mana=maxMana
	addItem(GlobalItems.ID.WOOD_SWORD)
	setEquipment(GlobalItems.ID.WOOD_SWORD)

# true kalau pemain sudah memilih class (save lama: class dipilih saat permainan dimulai)
func hasChosenClass():
	return HeroClass.hasClass(playerClass)

# Dipanggil Darkus: pemain memilih class di depan Ancient Dungeon.
# HP/MP maksimum mengikuti class (lalu terisi penuh), senjata khas class langsung dipasang.
# XP, permata, dan item lain tetap. Mengembalikan false kalau class tidak valid.
func chooseClass(class_, sacrificeClass_=""):
	if !HeroClass.isValid(class_):
		return false
	_syncOwnedClasses()
	var firstClassChoice=ownedClasses.is_empty()
	# Class baru pada slot penuh wajib menggantikan class yang dipilih pemain.
	if !ownedClasses.has(class_) and ownedClasses.size()>=MAX_OWNED_CLASSES:
		if sacrificeClass_=="" or !ownedClasses.has(sacrificeClass_) or sacrificeClass_==class_:
			return false
		ownedClasses.erase(sacrificeClass_)
		# Senjata khas class yang dikorbankan ikut dilepas dari inventaris
		# (Ksatria: pedang + perisai). Senjata kayu dan item umum tetap.
		var removedItems=[HeroClass.getWeaponId(sacrificeClass_)]
		if sacrificeClass_==HeroClass.KNIGHT:
			removedItems.append(GlobalItems.ID.KNIGHT_SHIELD)
		for removedId in removedItems:
			if removedId<0:
				continue
			while hasItem(removedId):
				removeItem(removedId)
			if weaponId==removedId:
				weaponId=-1
			if equipment==removedId:
				equipment=null
	if !ownedClasses.has(class_):
		ownedClasses.append(class_)
	playerClass=class_
	var info=HeroClass.getInfo(class_)
	maxLife=info.life
	life=maxLife
	maxMana=info.mana
	mana=maxMana
	var classWeapon=HeroClass.getWeaponId(class_)
	if firstClassChoice:
		# Upgrade pertama mengubah senjata kayu sesuai jalur awal, bukan langsung memberi senjata logam.
		match class_:
			HeroClass.KNIGHT:
				classWeapon=GlobalItems.ID.WOOD_SWORD
			HeroClass.WIZARD:
				classWeapon=GlobalItems.ID.WOODEN_STAFF
			HeroClass.ARCHER:
				classWeapon=GlobalItems.ID.WOODEN_BOW
	addItem(classWeapon)
	setEquipment(classWeapon)
	# Class berbayar / lanjutan yang dipilih jadi terbuka permanen; item aksesnya ikut hilang
	if LICENSE_CLASSES.has(class_):
		markClassUnlocked(class_)
	consumeSageLicenseIfUsed()
	return true

func _syncOwnedClasses():
	# Migrasi save lama yang belum memiliki daftar class.
	if ownedClasses.is_empty() and HeroClass.isValid(playerClass):
		ownedClasses.append(playerClass)
	# Bersihkan data lama/duplikat dan tegakkan batas maksimum.
	var clean=[]
	for class_ in ownedClasses:
		if HeroClass.isValid(class_) and !clean.has(class_) and clean.size()<MAX_OWNED_CLASSES:
			clean.append(class_)
	ownedClasses=clean

func getOwnedClasses():
	_syncOwnedClasses()
	return ownedClasses.duplicate()

func ownsClass(class_):
	_syncOwnedClasses()
	return ownedClasses.has(class_)

# Class yang dibuka lewat item akses (Akses Class ...) yang diaktifkan di Darkus.
# Sage dibeli di kios Barong; Asasin / Engineer dibeli kalau yang satunya dipilih Darkus.
# Exorcist dan Alkemis eksklusif (limited): hanya dari drop Segel Kelas Bhuta Kala, tidak dijual.
const LICENSE_CLASSES=[HeroClass.SAGE,HeroClass.ASSASSIN,HeroClass.ENGINEER]

# id item akses untuk sebuah class (-1 = class ini tidak punya item akses)
func getLicenseItemId(class_):
	match class_:
		HeroClass.SAGE:
			return GlobalItems.ID.SAGE_LICENSE
		HeroClass.ASSASSIN:
			return GlobalItems.ID.ASSASSIN_LICENSE
		HeroClass.ENGINEER:
			return GlobalItems.ID.ENGINEER_LICENSE
	return -1

# class sudah terbuka (pernah dipilih / diaktifkan) walau sekarang bukan class aktif
func isClassUnlocked(class_):
	if playerClass==class_:
		return true
	return GlobalScenes.getParamForSceneOr("dungeon",class_+"_unlocked",false)==true

# class terbuka permanen (tersimpan di save) dan item aksesnya hilang
func markClassUnlocked(class_):
	GlobalScenes.saveParamForScene("dungeon",class_+"_unlocked",true)
	consumeSageLicenseIfUsed()

# class yang itemnya dipegang pemain tapi belum diaktifkan di Darkus
func getLicensedClasses():
	var result=[]
	for class_ in LICENSE_CLASSES:
		if hasItem(getLicenseItemId(class_)) and !isClassUnlocked(class_):
			result.append(class_)
	return result

# class Sage sudah terbuka (akses pernah dipakai, atau Sage sudah dipilih)
func isSageUnlocked():
	return isClassUnlocked(HeroClass.SAGE)

# Akses Class Sage dipakai: Sage terbuka permanen (tersimpan di save) dan itemnya hilang
func unlockSage():
	markClassUnlocked(HeroClass.SAGE)

# hapus semua item akses class (Sage / Asasin / Engineer) yang class-nya sudah terbuka (juga membersihkan save lama)
func consumeSageLicenseIfUsed():
	for class_ in LICENSE_CLASSES:
		if isClassUnlocked(class_):
			var itemId=getLicenseItemId(class_)
			while hasItem(itemId):
				removeItem(itemId)

# kosongkan data permainan sebelumnya saat memulai permainan baru
func resetForNewGame():
	ritualCutscenePending=false
	possessionCutscenePending=false
	itemsList=[]
	ownedClasses=[]
	gems=0
	xp=0
	equipment=null
	weaponId=-1
	position=null
	side="DOWN"
	lastUseResult={}

func getClassWeaponId():
	return HeroClass.getWeaponId(playerClass)

#---class lanjutan
# true kalau pemain sudah memilih Asasin / Engineer
func hasAdvancedClass():
	_syncOwnedClasses()
	for class_ in ownedClasses:
		if HeroClass.isAdvanceChoice(class_):
			return true
	return false

# true kalau pemain pernah mendapat Asasin / Engineer (juga kalau salah satunya sudah dikorbankan)
func hasPickedAdvanceClass():
	if hasAdvancedClass():
		return true
	for class_ in HeroClass.ADVANCE_CHOICES:
		if isClassUnlocked(class_):
			return true
	return false

#---equipment
func setEquipment(item_):
	equipment=item_
	if item_!=null and GlobalItems.getItem(item_).type==item_class.TYPE.WEAPON:
		weaponId=int(item_)
		# Memasang senjata khas salah satu class yang dimiliki = pindah ke class itu.
		# Senjata kayu bersifat netral: tidak mengganti class.
		var weaponClass=HeroClass.getClassOfWeapon(weaponId)
		_syncOwnedClasses()
		if weaponClass!="" and weaponClass!=playerClass and ownedClasses.has(weaponClass):
			_switchActiveClass(weaponClass)

# Ganti class aktif tanpa mengisi ulang HP/MP (HP/MP hanya dibatasi oleh maksimum class baru)
func _switchActiveClass(class_):
	if !HeroClass.isValid(class_):
		return
	playerClass=class_
	var info=HeroClass.getInfo(class_)
	maxLife=info.life
	maxMana=info.mana
	life=min(life,maxLife)
	mana=min(mana,maxMana)
	
func getEquipment():
	return equipment
	
func hasEquipment():
	if equipment==null:
		return false
	else:
		return true

# true kalau yang sedang dipegang adalah senjata (bukan sekop / kosong)
func hasWeaponEquipped():
	if equipment==null:
		return false
	return GlobalItems.getItem(equipment).type==item_class.TYPE.WEAPON

# senjata hanya boleh dipasang kalau cocok dengan class
func canEquip(itemId_):
	var item=GlobalItems.getItem(itemId_)
	if item.type==item_class.TYPE.WEAPON:
		if HeroClass.canUseWeapon(playerClass,itemId_):
			return true
		# senjata khas class lain yang juga dimiliki pemain (maksimal 4 class)
		var weaponClass=HeroClass.getClassOfWeapon(itemId_)
		_syncOwnedClasses()
		return weaponClass!="" and ownedClasses.has(weaponClass)
	return item.type==item_class.TYPE.TOOL

# Ksatria baru bisa menahan serangan / Bertahan setelah punya Perisai Ksatria
# (ikut didapat bersama Pedang Ksatria)
func hasShieldReady():
	return HeroClass.hasShield(playerClass) and hasItem(GlobalItems.ID.KNIGHT_SHIELD)

#--life
func setLife(life_):
	life=life_

func getLife():
	return life

func getMaxLife():
	return maxLife
	
func damage(damage_):
	life=max(0, life-damage_)
	
#--mana
func getMana():
	return mana

func getMaxMana():
	return maxMana

func setMana(mana_):
	mana=clampi(mana_,0,maxMana)

func addMana(mana_):
	setMana(mana+mana_)

func useMana(mana_):
	mana=max(0,mana-mana_)

func canUseMana(mana_):
	return mana>=mana_

#--xp
func setXp(xp_):
	xp=xp_

func getXp():
	return xp

func addXp(xp_):
	xp+=xp_

#--position
func savePosition(newPosition_):
	position=newPosition_

func loadPosition():
	var savedPosition=position
	resetPosition()
	return savedPosition
	
func getPosition():
	return position

func resetPosition():
	position=null

func shouldLoadPosition():
	if(position!=null):
		return true
	else:
		return false

#--gems
func addGems(value_):
	putGems(value_)
	
func putGems(value_):
	gems+=value_
	
func spendGems(value_):
	if(value_<=gems):
		gems-=value_
		
func getGemsBalance():
	return gems
	
func canSpendGems(price_):
	if(price_<=gems):
		return true
	return false

#--items
func isConsumable(itemId_):
	var t=GlobalItems.getItem(itemId_).type
	return t==item_class.TYPE.MAGICPOTION or t==item_class.TYPE.FOOD

# item hanya terpakai kalau ada efeknya (tidak boros saat HP/Mana sudah penuh)
# inBattle_: di pertarungan, item dengan efek Serangan++ (Jamu Ojo Lali) atau Efek++ (Soto) selalu bisa dipakai
func canUseItem(itemId_, inBattle_=false):
	if !isConsumable(itemId_) or !hasItem(itemId_):
		return false
	for action in GlobalItems.getItem(itemId_).actionList:
		if action.action=="increaseLife" and life<maxLife:
			return true
		if action.action=="increaseMana" and mana<maxMana:
			return true
		if (action.action=="attackBuff" or action.action=="effectBuff" or action.action=="shieldBuff") and inBattle_:
			return true
	return false

# hasil: {"life":..,"mana":..} + "attackBuff" / "effectBuff" / "shieldBuff": jumlah ronde (hanya kalau dipakai di pertarungan)
func useItem(itemId_, inBattle_=false):
	lastUseResult={}
	if !canUseItem(itemId_, inBattle_):
		return lastUseResult
	var lifeBefore=life
	var manaBefore=mana
	var buffRounds=0
	var effectRounds=0
	var shieldRounds=0
	var bonus=HeroClass.getConsumeBonus(playerClass)
	for action in GlobalItems.getItem(itemId_).actionList:
		if action.action=="increaseLife":
			setLife(min(getLife()+int(round(action.value*bonus)),getMaxLife()))
		elif action.action=="increaseMana":
			addMana(int(round(action.value*bonus)))
		elif action.action=="bonusMana":
			# bonus MP acak (Kelapa: 5-7 di atas MP dasar), value = Vector2i(min,max)
			var manaRng=RandomNumberGenerator.new()
			manaRng.randomize()
			addMana(int(round(manaRng.randi_range(action.value.x,action.value.y)*bonus)))
		elif action.action=="attackBuff" and inBattle_:
			buffRounds=int(action.value)
		elif action.action=="effectBuff" and inBattle_:
			effectRounds=int(action.value)
		elif action.action=="shieldBuff" and inBattle_:
			shieldRounds=int(action.value)
	removeItem(itemId_)
	lastUseResult={"life":life-lifeBefore,"mana":mana-manaBefore}
	if buffRounds>0:
		lastUseResult["attackBuff"]=buffRounds
	if effectRounds>0:
		lastUseResult["effectBuff"]=effectRounds
	if shieldRounds>0:
		lastUseResult["shieldBuff"]=shieldRounds
	return lastUseResult

# ramuan yang dipakai di tombol "Ramuan" saat bertarung (ramuan HP baru dipakai lebih dulu)
func getBattlePotionId():
	if hasItem(GlobalItems.ID.HP_POTION):
		return GlobalItems.ID.HP_POTION
	return GlobalItems.ID.HEALTH_POTION_10

func countBattlePotions():
	return countItem(GlobalItems.ID.HP_POTION)+countItem(GlobalItems.ID.HEALTH_POTION_10)

func hasItem(itemId_):
	return itemsList.has(itemId_)

func addItem(itemId_):
	addItemIfNotExist(itemId_)
	
func addItemIfNotExist(itemId_):
	if !hasItem(itemId_):
		_addItem(itemId_)
		
func addItemEvenIfExist(itemId_):
	_addItem(itemId_)
	
func _addItem(itemId_):
	itemsList.append(itemId_)
	# Pedang Ksatria datang satu paket dengan perisainya
	if itemId_==GlobalItems.ID.KNIGHT_SWORD and !hasItem(GlobalItems.ID.KNIGHT_SHIELD):
		itemsList.append(GlobalItems.ID.KNIGHT_SHIELD)

func getItemsList():
	return itemsList

func countItem(itemId_):
	return itemsList.count(itemId_)

func removeItem(itemId_):
	itemsList.erase(itemId_)


# Senjata yang dipakai saat bertarung = senjata yang terakhir dipasang (Menu > Inventaris > Pasang).
# Save lama tanpa data itu: senjata yang sedang dipegang -> senjata class -> Pedang Kayu -> senjata lain.
# -1 = tidak punya senjata.
func getActiveWeaponId():
	if weaponId>=0 and hasItem(weaponId) and canEquip(weaponId):
		return weaponId
	if hasWeaponEquipped() and hasItem(equipment) and canEquip(equipment):
		return int(equipment)
	if hasItem(getClassWeaponId()):
		return getClassWeaponId()
	if hasItem(GlobalItems.ID.WOOD_SWORD):
		return GlobalItems.ID.WOOD_SWORD
	for itemId in itemsList:
		if GlobalItems.getItem(itemId).type==item_class.TYPE.WEAPON and canEquip(itemId):
			return itemId
	return -1

# Serangan HANYA dari senjata yang sedang dipakai (termasuk yang masih terkunci XP).
# Pegang tongkat -> hanya serangan tongkat; pegang pedang -> hanya serangan pedang.
func getWeaponAttackList():
	var activeId=getActiveWeaponId()
	if activeId<0:
		return []
	return GlobalItems.getItem(activeId).actionList.duplicate()

func isAttackUnlocked(attack_):
	return xp >= attack_.xpMin

func getAttackList():
	return getWeaponAttackList().filter(isAttackUnlocked)

# ID item lama yang sudah digantikan (Ramuan HP versi lama -> Ramuan HP) agar save lama tidak berisi duplikat
func _currentItemId(itemId_):
	if itemId_==GlobalItems.ID.HEALTH_POTION_10:
		return GlobalItems.ID.HP_POTION
	return itemId_

func loadFromSave(data_):
	for field in simpleFieldToSaveList:
		if data_.has(field):
			var valueMixed=data_[field]
			if field=="ownedClasses":
				var classArray=[]
				for classValue in valueMixed:
					if typeof(classValue)==TYPE_STRING and HeroClass.isValid(classValue) and !classArray.has(classValue):
						classArray.append(classValue)
				set(field,classArray.slice(0,MAX_OWNED_CLASSES))
			elif field=="itemsList":
				var intArray=[]
				for valueMixedLoop in valueMixed:
					intArray.append(_currentItemId(int(valueMixedLoop)))
				set(field,intArray)
			
			elif stringFieldList.has(field):
				set(field,str(valueMixed))
			elif nullFieldList.has(field):
				set(field,valueMixed)
			else:
				set(field,int(valueMixed))
			
	position=Vector2(data_.position[0],data_.position[1])
	pass

func convertToSave():
	var saveData=GlobalGame.convertObjectToSave(self,simpleFieldToSaveList)
	
	saveData.position=[position.x,position.y]	

	return saveData
