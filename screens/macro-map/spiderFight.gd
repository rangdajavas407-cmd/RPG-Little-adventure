extends Node2D

# Pertarungan di jalan antar desa, desa, dan dungeon. Musuh dipilih lewat GlobalPlayer.battleEnemy:
# id musuh tunggal dari enemy_class.gd, atau id grup (mis. "bandits") untuk 2 musuh sekaligus
# dalam satu layar dengan giliran serang dan pilih target. Nama file dipertahankan
# agar scene dan peta lama tetap terhubung.

const FightRules=preload("res://common/class/fight_rules.gd")
const DefaultTheme=preload("res://common/themes/default.tres")
const LifeBarScene=preload("res://common/ui/lifeBar.tscn")
const COLOR_MANA_BAR=Color(0.35, 0.62, 1.0)
const ConsumeAnim=preload("res://common/ui/consumeAnim.gd")
const HeroClass=preload("res://common/class/hero_class.gd")
const ClassSelect=preload("res://screens/game/classSelect.gd")
const EnemyClass=preload("res://common/class/enemy_class.gd")
const EnemySprites=preload("res://common/fighters/enemySprites.gd")
const EngineerRules=preload("res://common/class/engineer_rules.gd")
const GadgetScript=preload("res://common/fighters/gadget.gd")
const attack_class=preload("res://common/class/item/attack_class.gd")
const SummonRules=preload("res://common/class/summon_rules.gd")
const SummonScript=preload("res://common/fighters/summon.gd")

const VERA_FRAMES=[
	"res://common/characters/vera/vera-0.png",
	"res://common/characters/vera/vera-1.png",
	"res://common/characters/vera/vera-2.png",
	"res://common/characters/vera/vera-3.png"
]

const SECOND_ENEMY_SCENE="res://common/fighters/spider1.tscn"
# posisi musuh di layar: satu musuh di tengah kanan, dua musuh bersusun miring
const ENEMY_POS_SINGLE=[Vector2(199.115,51.272)]
const ENEMY_POS_PAIR=[Vector2(166,34),Vector2(232,68)]
const VERA_MAX_LIFE=40
# peluang musuh menyerang Vera (lebih sering di dua pertarungan pertama bersamanya)
const VERA_TARGET_EARLY=0.5
const VERA_TARGET_LATER=0.3

const VICTORY_MANA=5
const MESSAGE_DELAY=0.8
const POISON_DAMAGE=3
const POISON_TURNS=3
# pendarahan: pemain 3 damage x 3 giliran, musuh 7 damage x 3 giliran (Asasin diperkuat di v8)
const BLEED_TURNS=3
const PLAYER_BLEED_DAMAGE=3
const ENEMY_BLEED_DAMAGE=7
const COLOR_BLEED=Color(1,0.35,0.35)
const SHIELD_REDUCTION=0.75     # perisai Ksatria menahan 25%
const DEFEND_REDUCTION=0.5      # Bertahan menahan 50% lagi
const GHOST_PHYSICAL_MULTIPLIER=0.5
const VERA_DAMAGE_MIN=6
const VERA_DAMAGE_MAX=9
const ATTACK_BUFF_MULT=1.5      # Serangan++ dari Jamu Ojo Lali
# Soto: Efek++ menambah peluang semua efek khusus (berdarah, bingung, elak, balas) selama dua ronde
const EFFECT_BUFF_BONUS=0.35
# Asasin: setelah Tebas Kilat (skill 2) giliran musuh berikutnya bisa dielak; kadang serangannya dibalikkan
const SHADOW_DODGE_CHANCE=0.5
const SHADOW_COUNTER_CHANCE=0.4
const SHADOW_COUNTER_DAMAGE=10
# tempat pemain berdiri di ruang Bhuta Kala saat adegan ritual (selatan sigil)
const RITUAL_PLAYER_POSITION=Vector2(864,152)

var HERO_NAME="Kakak"

const COLOR_DAMAGE=Color(1, 0.95, 0.85)
const COLOR_CRITICAL=Color(1, 0.82, 0.4)
const COLOR_HEAL=Color(0.45, 1, 0.55)
const COLOR_POISON=Color(0.6, 1, 0.45)
const COLOR_OUTLINE=Color(0.13, 0.125, 0.2)

const UP="UP"
const DOWN="DOWN"

# tiap musuh: {id, data, node, bar, life, maxLife, name, charging, enraged, turns}
var enemies=[]

var positionToGoUp
var positionToGoDown

var playerSavedLife=0
var playerSavedMana=0
var transitioningToCutscene=false

var poisonTurns=0
var defending=false

# Serangan++ (Jamu Ojo Lali): sisa ronde. Ronde saat jamu diminum tidak dihitung.
var attackBuffRounds=0
var buffSkipTick=false
# Efek++ (Soto): sisa ronde. Dikurangi di akhir giliran musuh; ronde saat soto dimakan tidak dihitung.
var effectBuffRounds=0
var effectSkipTick=false
# Perisai Kelapa: damage masuk berkurang (shieldReduction) selama satu giliran musuh berikutnya
var shieldBuffRounds=0
var shieldReduction=0.0
# Siaga Bayangan (Asasin): aktif sampai giliran musuh berikutnya selesai
var shadowStance=false

var veraNode=null
var veraLife=VERA_MAX_LIFE
var veraBar=null
var veraBattleNumber=0
var veraHurtHinted=false

# Engineer: Kotak Mekanik (skill 2). boxState = none / box / turret
var boxState=EngineerRules.NONE
var boxNode=null
var secondTurretNode=null
var turretLife=0
var secondTurretLife=0
var playerBleedTurns=0

# v9.30: makhluk panggilan (Dukun: Mumi/Lampor/Randa, Exorcist: Banaspati, Alkemis: Golem/Mecha).
# null = tidak ada; selain itu {kind, node, life, maxLife, data}. Hanya satu makhluk dalam satu waktu.
var summon=null
# Exorcist (Jimat Pengusir): Barrier menahan satu serangan penuh; Perisai Suci memotong damage satu giliran musuh
var barrierHits=0
var barrierNode=null
var holyShieldRounds=0
var holyShieldNode=null

var rng=RandomNumberGenerator.new()


func _ready():
	rng.randomize()
	HERO_NAME=GlobalGame.getHeroName()

	_setupEnemies()

	playerSavedLife=GlobalPlayer.getLife()
	playerSavedMana=GlobalPlayer.getMana()
	$lifePlayer.init(HERO_NAME, GlobalPlayer.getLife(), GlobalPlayer.getMaxLife())
	_setupManaBar()

	positionToGoUp=Vector2( GlobalPlayer.getPosition().x,260)
	positionToGoDown=Vector2( GlobalPlayer.getPosition().x,420)

	$gamepad.defend.connect(_on_gamepad_defend)
	$gamepad.useItemOnVera.connect(_on_gamepad_useItemOnVera)
	_spawnVera()

	if enemies.size()>1:
		$gamepad.showMessage(_groupIntro())
	else:
		$gamepad.showMessage(enemies[0].data.appear)
	await _wait(MESSAGE_DELAY)
	_playerTurn()


# satu atau dua musuh, lengkap dengan sprite dan bar nyawa masing-masing
func _setupEnemies():
	var ids=EnemyClass.getGroup(GlobalPlayer.battleEnemy)
	var positions=ENEMY_POS_SINGLE if ids.size()==1 else ENEMY_POS_PAIR
	for i in ids.size():
		var data=EnemyClass.getEnemy(ids[i])
		var node
		var bar
		if i==0:
			node=$spider1
			bar=$lifeSpider
		else:
			node=load(SECOND_ENEMY_SCENE).instantiate()
			add_child(node)
			bar=LifeBarScene.instantiate()
			add_child(bar)
			bar.offset_left=210.0
			bar.offset_top=32.0
			bar.offset_right=314.0
			bar.offset_bottom=56.0
		node.position=positions[i]
		# laba-laba memakai sprite bawaan scene; musuh lain memakai lembar sprite-nya sendiri
		if data.sprite!="":
			node.get_node("AnimatedSprite2D").sprite_frames=EnemySprites.build(data.sprite)
		node.playIdle()
		var title=data.name
		if ids.size()>1 and ids[0]==ids[1]:
			title+=" "+["A","B"][i]
		bar.init(title, data.life, data.life)
		enemies.append({"id":ids[i],"data":data,"node":node,"bar":bar,"life":data.life,"maxLife":data.life,
			"name":title,"charging":false,"enraged":false,"turns":0,"suicided":false,"confused":false,"bleedTurns":0,"poisonTurns":0,"slowTurns":0,"frozen":false,
			"home":node.position,"busy":false,"animDone":true})
		_startIdleMotion(node,data)

func _groupIntro():
	var group=GlobalPlayer.battleEnemy
	if EnemyClass.isGroup(group) and EnemyClass.GROUPS[group].has("appear"):
		return EnemyClass.GROUPS[group].appear
	var names=[]
	for e in enemies:
		names.append(e.name)
	return " & ".join(names)+" menghadang!"

func _living():
	var list=[]
	for e in enemies:
		if e.life>0:
			list.append(e)
	return list

func _aimAt(e_):
	# proyektil Pemanah / Penyihir terbang ke arah musuh yang dipilih
	$player.targetPosition=e_.node.global_position+Vector2(32,36)

# pilih sasaran: otomatis kalau tinggal satu musuh, kalau dua tampil menu target (null = batal)
func _pickTarget():
	var living=_living()
	if living.size()==1:
		return living[0]
	var labels=[]
	var indexes=[]
	for i in enemies.size():
		if enemies[i].life>0:
			labels.append(enemies[i].name+"  "+str(enemies[i].life)+"/"+str(enemies[i].maxLife))
			indexes.append(i)
	$gamepad.showMessage(_trad(GlobalGame.TRAD_FIGHT_TARGET))
	$gamepad.showEnemyTargets(labels, indexes)
	var picked=await $gamepad.targetPicked
	if picked<0:
		return null
	return enemies[picked]


# bar mana (biru) tepat di bawah bar HP; angkanya mengikuti GlobalPlayer.getMana()
var manaBar=null
var shownMana=-1

func _setupManaBar():
	manaBar=LifeBarScene.instantiate()
	add_child(manaBar)
	manaBar.offset_left=6.0
	manaBar.offset_top=32.0
	manaBar.offset_right=110.0
	manaBar.offset_bottom=56.0
	manaBar.init("MP", GlobalPlayer.getMana(), GlobalPlayer.getMaxMana(), COLOR_MANA_BAR)
	shownMana=GlobalPlayer.getMana()

func _process(_delta):
	# semua perubahan mana (serangan sihir, ramuan, Sage, kemenangan) langsung tampil di bar
	if manaBar!=null and shownMana!=GlobalPlayer.getMana():
		shownMana=GlobalPlayer.getMana()
		manaBar.updateValue(shownMana)


func _playerTurn():
	# Sage memulihkan sedikit MP tiap giliran
	var regen=HeroClass.getTurnManaRegen(GlobalPlayer.getPlayerClass())
	if regen>0:
		GlobalPlayer.addMana(regen)
	$gamepad.veraHealable=_veraHealable()
	$gamepad.gadgetState=boxState
	$gamepad.summonAlive=_summonActive()
	var chooseText=_trad(GlobalGame.TRAD_FIGHT_CHOOSE) % HERO_NAME
	if attackBuffRounds>0:
		chooseText+="  [Serangan++ "+str(attackBuffRounds)+" ronde]"
	if effectBuffRounds>0:
		chooseText+="  [Efek++ "+str(effectBuffRounds)+" ronde]"
	$gamepad.showMessage(chooseText)
	$gamepad.showActions()


#--- aksi pemain

func _on_gamepad_attack(attack_):
	defending=false
	var heroClass=GlobalPlayer.getPlayerClass()

	# skill alat Engineer: Kotak Mekanik / Turet (tidak memilih sasaran)
	if attack_.isGadget():
		await _useGadget(attack_)
		return

	# skill panggil (Dukun / Exorcist / Alkemis): memanggil satu makhluk, tidak memilih sasaran
	if attack_.isSummon():
		await _useSummon(attack_)
		return

	# melawan 2 musuh: pilih sasaran dulu (batal = kembali ke menu)
	var target=await _pickTarget()
	if target==null:
		_playerTurn()
		return
	_aimAt(target)

	GlobalPlayer.useMana(attack_.manaCost)
	$gamepad.showMessage(_trad(GlobalGame.TRAD_FIGHT_PLAYER_ATTACK) % [HERO_NAME, attack_.name])
	var assassinOrigin=$player.position
	var assassin=_isAssassin()
	if assassin:
		# Asasin menerjang ke arah musuh sambil meninggalkan bayangan sisa
		_assassinDash(attack_, target, assassinOrigin)
	$player.playAttack(attack_.animation, attack_.kind)
	await $player.attackFinished
	if assassin:
		_assassinBack(assassinOrigin)

	# musuh lincah bisa menghindar
	if target.data.evade>0.0 and rng.randf()<target.data.evade:
		_popText(target.node, _trad(GlobalGame.TRAD_FIGHT_MISS), COLOR_DAMAGE)
		$gamepad.showMessage(_trad(GlobalGame.TRAD_FIGHT_EVADE) % target.name)
		await _wait(MESSAGE_DELAY)
		_afterPlayerAction()
		return

	var base=float(attack_.damage)*FightRules.PLAYER_DAMAGE_BOOST
	var note=""
	var spirit=HeroClass.getSpiritBonus(heroClass)
	# Exorcist: jimat suci bonus terhadap SEMUA musuh, bukan hanya hantu/iblis.
	if spirit>1.0 and attack_.isMagic():
		base*=spirit
		note=_trad(GlobalGame.TRAD_FIGHT_SPIRIT)
	elif target.data.kind=="ghost" and !attack_.isMagic():
		# hantu kebal serangan fisik: hanya sihir yang menembusnya
		base*=GHOST_PHYSICAL_MULTIPLIER
		note=_trad(GlobalGame.TRAD_FIGHT_RESIST)
	if attackBuffRounds>0:
		base*=ATTACK_BUFF_MULT
		_popText($player, "ATK++", COLOR_CRITICAL)
	var roll=FightRules.rollDamage(base, rng, true, HeroClass.getCritBonus(heroClass))

	if roll.critical:
		$gamepad.showMessage(_trad(GlobalGame.TRAD_FIGHT_CRITICAL))
	if assassin:
		_assassinSlashEffect(attack_, target, roll.critical)
	await _hitEnemy(target, roll.damage, roll.critical)

	# serangan Sage ikut memulihkan HP
	if attack_.heal>0:
		GlobalPlayer.setLife(min(GlobalPlayer.getLife()+attack_.heal, GlobalPlayer.getMaxLife()))
		_popText($player, "+"+str(attack_.heal), COLOR_HEAL)
		$lifePlayer.updateValue(GlobalPlayer.getLife())

	# efek tambahan serangan: bingung (Engineer) / pendarahan (Asasin)
	if attack_.status!="" and target.life>0:
		await _applyAttackStatus(attack_, target)

	# Tabung Reaksi (Alkemis): Blizzard (beku) atau Racun
	if attack_.special==attack_class.SPECIAL_TUBE and target.life>0:
		await _applyTubeEffect(target)

	# Jimat Pengusir (Exorcist): kadang memunculkan Barrier atau Perisai Suci
	if attack_.special==attack_class.SPECIAL_BARRIER:
		await _tryBarrier()

	if note!="" and target.life>0:
		$gamepad.showMessage(note)
		await _wait(MESSAGE_DELAY)

	# Tebas Kilat: Asasin siaga, serangan musuh berikutnya bisa dielak
	if attack_.hasDodgeStance():
		_enterShadowStance()
	_afterPlayerAction()


# giliran Vera (kalau ada) lalu giliran musuh
func _afterPlayerAction():
	if transitioningToCutscene:
		return
	_tickAttackBuff()
	if _living().is_empty():
		_victory()
		return
	await _veraAssist()
	await _turretFire()
	await _summonAct()
	if _living().is_empty():
		_victory()
		return
	# Bhuta Kala: nyawa tinggal 70 -> serangan pengorbanan, lalu Satan dipanggil
	if await _bossPhases():
		return
	if _living().is_empty():
		_victory()
	else:
		_enemyTurn()


# Serangan++ berkurang satu ronde tiap aksi pemain selesai (kecuali aksi minum jamunya sendiri)
func _tickAttackBuff():
	if buffSkipTick:
		buffSkipTick=false
		return
	if attackBuffRounds>0:
		attackBuffRounds-=1
		if attackBuffRounds==0:
			_toast("Efek Jamu Ojo Lali habis","story")


func _on_gamepad_defend():
	defending=true
	$gamepad.showMessage(_trad(GlobalGame.TRAD_FIGHT_DEFEND_TEXT) % HERO_NAME)
	await _wait(MESSAGE_DELAY)
	_afterPlayerAction()


func _on_gamepad_usePotion():
	await _consume(GlobalPlayer.getBattlePotionId(), _trad(GlobalGame.TRAD_FIGHT_POTION_USED) % HERO_NAME)

func _on_gamepad_useFood():
	await _consume(GlobalItems.ID.BIKA_AMBON, _trad(GlobalGame.TRAD_FIGHT_FOOD_USED) % HERO_NAME)

# dari menu Inventaris: ramuan / makanan apa pun
func _on_gamepad_useItemById(itemId_):
	var itemName=GlobalItems.getItem(itemId_).name
	await _consume(itemId_, _trad(GlobalGame.TRAD_FIGHT_ITEM_USED) % [HERO_NAME, itemName])

# minum ramuan / makan di tengah pertarungan (memakai giliran)
func _consume(itemId_, message_):
	defending=false
	var result=GlobalPlayer.useItem(itemId_,true).duplicate()
	if result.is_empty():
		_playerTurn()
		return
	if result.get("attackBuff",0)>0:
		attackBuffRounds=int(result.attackBuff)
		buffSkipTick=true
	if result.get("effectBuff",0)>0:
		effectBuffRounds=int(result.effectBuff)
		effectSkipTick=true
		_toast("Efek++ %d ronde" % effectBuffRounds,"story")
	if result.get("shieldBuff",0)>0:
		shieldBuffRounds=int(result.shieldBuff)
		shieldReduction=FightRules.rollCoconutShield(rng)
		result["shieldPercent"]=int(round(shieldReduction*100.0))
		_toast("Perisai Kelapa: damage -%d%% (1 ronde)" % result.shieldPercent,"story")
	$gamepad.showMessage(message_)
	var anim=ConsumeAnim.new()
	anim.setup(itemId_, result)
	add_child(anim)
	await anim.finished
	if result.life > 0:
		_popText($player, "+"+str(result.life), COLOR_HEAL)
	$lifePlayer.updateValue(GlobalPlayer.getLife())
	await _wait(MESSAGE_DELAY)
	_afterPlayerAction()

func _on_gamepad_leave():
	var fleeChance=1.0
	for e in _living():
		fleeChance=min(fleeChance,e.data.flee)
	if rng.randf() < fleeChance:
		$gamepad.showMessage(_trad(GlobalGame.TRAD_FIGHT_FLEE_OK))
		await _wait(MESSAGE_DELAY)
		_recordBossFail()
		_gotoMap(false)
	else:
		defending=false
		$gamepad.showMessage(_trad(GlobalGame.TRAD_FIGHT_FLEE_FAIL))
		await _wait(MESSAGE_DELAY)
		_afterPlayerAction()


#--- bantuan Vera

func _spawnVera():
	if !GlobalGame.isVeraWithPlayer():
		return
	var frames=SpriteFrames.new()
	if frames.has_animation("default"):
		frames.remove_animation("default")
	frames.add_animation("idle")
	frames.set_animation_speed("idle",4.0)
	frames.set_animation_loop("idle",true)
	for path in VERA_FRAMES:
		frames.add_frame("idle",load(path))
	# pertarungan ke-1 dan ke-2 bersama Vera: menyembuhkannya diberi hadiah Kue Putu
	veraBattleNumber=int(GlobalScenes.getParamForSceneOr("story","vera_battles",0))+1
	GlobalScenes.saveParamForScene("story","vera_battles",veraBattleNumber)
	veraLife=VERA_MAX_LIFE
	veraBar=LifeBarScene.instantiate()
	add_child(veraBar)
	veraBar.offset_left=112.0
	veraBar.offset_top=6.0
	veraBar.offset_right=216.0
	veraBar.offset_bottom=30.0
	veraBar.scale=Vector2(0.9,1.0)
	veraBar.init("Vera", veraLife, VERA_MAX_LIFE)
	veraNode=AnimatedSprite2D.new()
	veraNode.sprite_frames=frames
	veraNode.position=$player.position+Vector2(-30,-26)
	add_child(veraNode)
	veraNode.play("idle")
	var bob=veraNode.create_tween().set_loops()
	bob.tween_property(veraNode,"offset:y",-3.0,0.5)
	bob.tween_property(veraNode,"offset:y",3.0,0.5)

func _veraHealable():
	return veraNode!=null and is_instance_valid(veraNode) and veraLife<VERA_MAX_LIFE

# memakai ramuan / makanan penyembuh pada Vera (memakai giliran)
func _on_gamepad_useItemOnVera(itemId_):
	defending=false
	var heal=0
	var bonus=HeroClass.getConsumeBonus(GlobalPlayer.getPlayerClass())
	for action in GlobalItems.getItem(itemId_).actionList:
		if action.action=="increaseLife":
			heal+=int(round(action.value*bonus))
	GlobalPlayer.removeItem(itemId_)
	var wasDown=veraLife<=0
	veraLife=min(VERA_MAX_LIFE, veraLife+heal)
	veraBar.updateValue(veraLife)
	if wasDown:
		veraNode.modulate=Color.WHITE
	_popTextAt(veraNode.position+Vector2(0,-22), "+"+str(heal), COLOR_HEAL)
	veraNode.modulate=Color(0.6,1.5,0.7)
	veraNode.create_tween().tween_property(veraNode,"modulate",Color.WHITE,0.4)
	$gamepad.showMessage(_trad(GlobalGame.TRAD_FIGHT_VERA_HEALED) % HERO_NAME)
	await _wait(MESSAGE_DELAY)

	# hadiah: sembuhkan Vera di pertarungan ke-1 atau ke-2 -> satu Kue Putu (sekali saja)
	if veraBattleNumber<=2 and int(GlobalScenes.getParamForSceneOr("story","vera_putu_given",0))!=1:
		GlobalScenes.saveParamForScene("story","vera_putu_given",1)
		GlobalPlayer.addItemEvenIfExist(GlobalItems.ID.KUE_PUTU)
		$gamepad.showMessage(_trad(GlobalGame.TRAD_FIGHT_VERA_THANKS))
		await _wait(MESSAGE_DELAY*1.6)
	_afterPlayerAction()

func _veraAssist():
	if veraNode==null or !is_instance_valid(veraNode) or veraLife<=0:
		return
	var living=_living()
	if living.is_empty():
		return
	var target=living[rng.randi_range(0,living.size()-1)]
	$gamepad.showMessage(_trad(GlobalGame.TRAD_FIGHT_VERA))
	# bola sihir gelap melesat ke musuh
	var bolt=ColorRect.new()
	bolt.size=Vector2(6,6)
	bolt.color=Color(0.85,0.1,0.25)
	bolt.z_index=50
	add_child(bolt)
	bolt.global_position=veraNode.global_position
	var tween=bolt.create_tween()
	tween.tween_property(bolt,"global_position",target.node.global_position+Vector2(30,34),0.3)
	await tween.finished
	bolt.queue_free()
	await _hitEnemy(target, rng.randi_range(VERA_DAMAGE_MIN,VERA_DAMAGE_MAX), false)


#--- giliran musuh (tiap musuh yang masih hidup menyerang bergantian)

func _enemyTurn():
	# musuh yang berdarah kehilangan nyawa di awal gilirannya
	for e in enemies:
		if e.life>0 and e.bleedTurns>0:
			e.bleedTurns-=1
			$gamepad.showMessage("%s berdarah!" % e.name)
			await _hitEnemy(e, ENEMY_BLEED_DAMAGE, false)
			await _wait(MESSAGE_DELAY*0.5)
	# musuh keracunan (Racun Santet / Lampor / Tabung Reaksi) kehilangan nyawa di awal gilirannya
	for e in enemies:
		if e.life>0 and e.get("poisonTurns",0)>0:
			e.poisonTurns-=1
			$gamepad.showMessage("%s keracunan!" % e.name)
			_popText(e.node, "RACUN", COLOR_POISON)
			await _hitEnemy(e, SummonRules.ENEMY_POISON_DAMAGE, false)
			await _wait(MESSAGE_DELAY*0.5)
	if _living().is_empty():
		_victory()
		return

	# salinan daftar: musuh yang baru muncul di tengah giliran (mis. Darkus) baru beraksi di giliran berikutnya
	for e in enemies.duplicate():
		if e.life<=0:
			continue
		var playerDown=await _enemyAct(e)
		if playerDown:
			_defeat()
			return

	defending=false
	_leaveShadowStance()
	_expireHolyShield()

	# ledakan Kotak Mekanik bisa menumbangkan musuh terakhir di giliran musuh
	if _living().is_empty():
		_victory()
		return

	# racun menggerogoti di akhir giliran
	if poisonTurns>0:
		poisonTurns-=1
		GlobalPlayer.damage(POISON_DAMAGE)
		$gamepad.showMessage(_trad(GlobalGame.TRAD_FIGHT_POISON_TICK) % HERO_NAME)
		_popText($player, str(POISON_DAMAGE), COLOR_POISON)
		$lifePlayer.updateValue(GlobalPlayer.getLife())
		await _wait(MESSAGE_DELAY)
		if GlobalPlayer.getLife() <= 0:
			_defeat()
			return

	# pendarahan menggerogoti pemain
	if playerBleedTurns>0:
		playerBleedTurns-=1
		GlobalPlayer.damage(PLAYER_BLEED_DAMAGE)
		$gamepad.showMessage("%s berdarah!" % HERO_NAME)
		_popText($player, str(PLAYER_BLEED_DAMAGE), COLOR_BLEED)
		$lifePlayer.updateValue(GlobalPlayer.getLife())
		await _wait(MESSAGE_DELAY)
		if GlobalPlayer.getLife() <= 0:
			_defeat()
			return

	_tickShieldBuff()
	_tickEffectBuff()
	_playerTurn()


# satu musuh beraksi. Mengembalikan true kalau pemain tumbang.
func _enemyAct(e_):
	var data=e_.data
	e_.turns+=1
	var mult=1.0

	# musuh bingung (kena Hantaman Berat): lewat satu giliran
	if e_.confused:
		e_.confused=false
		$gamepad.showMessage("%s masih bingung dan tidak bisa menyerang!" % e_.name)
		var wobble=e_.node.create_tween()
		wobble.tween_property(e_.node,"rotation",0.25,0.12)
		wobble.tween_property(e_.node,"rotation",-0.25,0.2)
		wobble.tween_property(e_.node,"rotation",0.0,0.12)
		await _wait(MESSAGE_DELAY*1.3)
		return false

	# musuh membeku (Blizzard Tabung Reaksi): lewat satu giliran
	if e_.get("frozen",false):
		e_.frozen=false
		$gamepad.showMessage("%s membeku dan tidak bisa bergerak!" % e_.name)
		await _wait(MESSAGE_DELAY*1.3)
		e_.node.modulate=Color.WHITE
		return false

	# musuh melambat (Mumi): sering kehilangan giliran selama beberapa ronde
	if e_.get("slowTurns",0)>0:
		e_.slowTurns-=1
		if rng.randf()<SummonRules.SLOW_SKIP_CHANCE:
			$gamepad.showMessage("%s bergerak lamban dan kehilangan gilirannya!" % e_.name)
			await _wait(MESSAGE_DELAY*1.3)
			return false

	# musuh kuat mengumpulkan tenaga, lalu menyerang jauh lebih sakit
	if data.charge>0:
		if e_.charging:
			e_.charging=false
			mult*=data.chargeMul
		elif e_.turns%data.charge==0:
			e_.charging=true
			$gamepad.showMessage(_trad(GlobalGame.TRAD_FIGHT_CHARGE) % e_.name)
			var pulse=e_.node.create_tween()
			pulse.tween_property(e_.node,"modulate",Color(1.6,0.7,0.7),0.3)
			pulse.tween_property(e_.node,"modulate",Color.WHITE,0.3)
			_tremble(e_, MESSAGE_DELAY*1.4)
			await _wait(MESSAGE_DELAY*1.4)
			return false

	# mengamuk saat nyawa tinggal sedikit
	if data.has("enrageBelow") and e_.life<=e_.maxLife*data.enrageBelow:
		if !e_.enraged:
			e_.enraged=true
			$gamepad.showMessage(_trad(GlobalGame.TRAD_FIGHT_ENRAGE) % e_.name)
			await _wait(MESSAGE_DELAY)
		mult*=data.enrageMul

	for hit in data.hits:
		$gamepad.showMessage(data.attack)

		# tentukan sasaran dulu supaya musuh bisa bergerak ke arah yang benar
		var veraChance=VERA_TARGET_EARLY if veraBattleNumber<=2 else VERA_TARGET_LATER
		# makhluk panggilan: Randa memancing SEMUA serangan (taunt), makhluk lain kadang jadi sasaran
		var toSummon=_summonActive() and (SummonRules.isTaunt(summon.kind) or rng.randf()<float(summon.data.target))
		var toVera=!toSummon and veraNode!=null and veraLife>0 and rng.randf()<veraChance
		# Engineer: musuh bisa menyerang Kotak Mekanik, bukan pemain
		var toBox=!toVera and !toSummon and boxState==EngineerRules.BOX and boxNode!=null and rng.randf()<EngineerRules.BOX_TARGET_CHANCE
		# turet juga bisa diserang (nyawanya rapuh)
		var toTurret=!toVera and !toSummon and boxState==EngineerRules.TURRET and boxNode!=null and rng.randf()<EngineerRules.TURRET_TARGET_CHANCE
		var missed=!toVera and !toBox and !toTurret and !toSummon and rng.randf()<data.miss
		var targetPos=veraNode.position if toVera else $player.position
		if toBox or toTurret:
			targetPos=boxNode.position-Vector2(32,36)
		if toSummon:
			targetPos=summon.node.position-Vector2(32,36)
		var heavy=mult>1.2 or _attackStyle(data)=="slam"

		# bersiap (menunduk / mundur / naik) lalu menerjang sampai kena sasaran
		await _enemyApproach(e_, targetPos, missed, mult)

		# musuh menyerang makhluk panggilan
		if toSummon:
			_impactBurst(summon.node.position, _burstColor(data), 6)
			_enemyReturn(e_)
			await _enemyHitsSummon(e_, mult)
			await _enemyWaitReturn(e_)
			continue

		# musuh menghantam Kotak Mekanik: kotak meledak
		if toBox:
			await _boxExplodes(e_)
			if GlobalPlayer.getLife() <= 0:
				return true
			continue

		if toTurret:
			_impactBurst(boxNode.position, _burstColor(data), 6)
			_enemyReturn(e_)
			await _enemyHitsTurret(e_, mult)
			await _enemyWaitReturn(e_)
			continue

		# kadang musuh menyerang Vera, bukan pemain
		if toVera:
			_impactBurst(targetPos+Vector2(30,34), _burstColor(data), 6)
			_enemyReturn(e_)
			await _enemyHitsVera(e_, mult)
			await _enemyWaitReturn(e_)
			continue

		if missed:
			# pemain melompat menghindar, musuh meluncur lewat lalu kembali
			_playerDodge()
			_enemyReturn(e_)
			_popText($player, _trad(GlobalGame.TRAD_FIGHT_MISS), COLOR_DAMAGE)
			$gamepad.showMessage(data.miss_text)
			await _wait(MESSAGE_DELAY)
			await _enemyWaitReturn(e_)
			continue

		# Siaga Bayangan (Asasin): serangan bisa dielak, kadang dibalikkan ke penyerang
		if shadowStance and rng.randf()<_effectChance(SHADOW_DODGE_CHANCE):
			await _shadowDodge(e_)
			if e_.life<=0:
				return false
			continue

		# Barrier (Exorcist) menahan satu serangan penuh
		if barrierHits>0:
			barrierHits-=1
			await _barrierBlocks(e_)
			continue

		var roll=FightRules.rollDamage(data.damage*mult, rng, false)
		var damage=roll.damage
		if holyShieldRounds>0:
			damage=FightRules.applyShield(damage,SummonRules.HOLY_SHIELD_REDUCTION)
		if GlobalPlayer.hasShieldReady():
			damage=int(round(damage*SHIELD_REDUCTION))
		if defending:
			damage=int(round(damage*DEFEND_REDUCTION))
		if shieldBuffRounds>0:
			damage=FightRules.applyShield(damage,shieldReduction)
		damage=max(1,damage)

		# tepat saat musuh menghantam: percikan, pemain terpental, layar bergetar kalau berat
		var knock=(targetPos-e_.home).normalized()*(9.0 if heavy else 6.0)
		_impactBurst($player.position+Vector2(32,36), _burstColor(data), 9 if heavy else 6)
		GlobalPlayer.damage(damage)
		$player.playDamage()
		_hitEffect($player, heavy, knock)
		_popText($player, str(damage), COLOR_DAMAGE)
		$lifePlayer.updateValue(GlobalPlayer.getLife())
		_enemyReturn(e_)
		await $player.damageFinished
		await _enemyWaitReturn(e_)

		if GlobalPlayer.getLife() <= 0:
			return true

		# efek khusus musuh
		if data.poison>0.0 and poisonTurns==0 and rng.randf()<data.poison:
			poisonTurns=POISON_TURNS
			$gamepad.showMessage(_trad(GlobalGame.TRAD_FIGHT_POISONED) % HERO_NAME)
			await _wait(MESSAGE_DELAY)
		var bleedChance=data.get("bleed",0.0)
		if bleedChance>0.0 and playerBleedTurns==0 and rng.randf()<bleedChance:
			playerBleedTurns=BLEED_TURNS
			$gamepad.showMessage("%s terluka dan mulai berdarah!" % HERO_NAME)
			_popText($player, "BERDARAH", COLOR_BLEED)
			await _wait(MESSAGE_DELAY)
		if data.drain>0 and GlobalPlayer.getMana()>0:
			GlobalPlayer.useMana(data.drain)
			$gamepad.showMessage(_trad(GlobalGame.TRAD_FIGHT_DRAIN) % HERO_NAME)
			_popText($player, "-"+str(data.drain)+" MP", Color(0.6,0.8,1))
			await _wait(MESSAGE_DELAY)
	return false


func _enemyHitsVera(e_, mult_):
	$gamepad.showMessage(_trad(GlobalGame.TRAD_FIGHT_VERA_HIT) % e_.name)
	var damage=max(1,int(round(FightRules.rollDamage(e_.data.damage*mult_, rng, false).damage*0.8)))
	veraLife=max(0,veraLife-damage)
	veraBar.updateValue(veraLife)
	_popTextAt(veraNode.position+Vector2(0,-22), str(damage), COLOR_DAMAGE)
	veraNode.modulate=Color(3,3,3)
	veraNode.create_tween().tween_property(veraNode,"modulate",Color.WHITE,0.25)
	await _wait(MESSAGE_DELAY)
	if veraLife<=0:
		veraNode.modulate=Color(0.5,0.5,0.55,0.7)
		$gamepad.showMessage(_trad(GlobalGame.TRAD_FIGHT_VERA_DOWN))
		await _wait(MESSAGE_DELAY)
	elif !veraHurtHinted and veraBattleNumber<=2:
		veraHurtHinted=true
		$gamepad.showMessage(_trad(GlobalGame.TRAD_FIGHT_VERA_HURT))
		await _wait(MESSAGE_DELAY*1.5)


#--- Engineer: Kotak Mekanik (skill 2) dan Turet

# skill 2 (Teknik Mesin): kotak belum ada -> pasang kotak; kotak ada -> ubah jadi Turet
func _useGadget(attack_):
	if boxState==EngineerRules.TURRET:
		if secondTurretNode==null or !is_instance_valid(secondTurretNode):
			GlobalPlayer.useMana(attack_.manaCost)
			await _deploySecondTurret()
			_afterPlayerAction()
		else:
			$gamepad.showMessage("Dua Turet sudah terpasang. Maksimal 2 Turet.")
			await _wait(MESSAGE_DELAY*1.4)
			_playerTurn()
		return

	var upgrading=boxState==EngineerRules.BOX
	GlobalPlayer.useMana(attack_.manaCost)
	$gamepad.showMessage("%s memakai %s!" % [HERO_NAME, attack_.name])
	$player.playAttack(attack_.animation, attack_.kind)
	await $player.attackFinished

	if upgrading:
		await _transformTurret()
	else:
		await _deployBox()
	await _wait(MESSAGE_DELAY*0.6)
	_afterPlayerAction()

func _deployBox():
	boxNode=Node2D.new()
	boxNode.set_script(GadgetScript)
	add_child(boxNode)
	var rest=$player.position+Vector2(68,-24)
	boxNode.position=rest+Vector2(0,-44)
	boxNode.modulate.a=0.0
	boxState=EngineerRules.BOX
	$gamepad.showMessage("Kotak Mekanik terpasang! Kalau musuh menyerangnya, kotak meledak.")
	var tween=boxNode.create_tween()
	tween.tween_property(boxNode,"modulate:a",1.0,0.12)
	tween.parallel().tween_property(boxNode,"position",rest,0.28).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	await tween.finished
	_impactBurst(boxNode.position+Vector2(0,6), Color(0.6,0.95,1), 6)

func _transformTurret():
	boxState=EngineerRules.TURRET
	turretLife=EngineerRules.TURRET_HP
	boxNode.setMode("turret")
	boxNode.setHealth(turretLife, EngineerRules.TURRET_HP)
	var living=_living()
	if !living.is_empty():
		boxNode.aimAt(living[0].node.global_position+Vector2(30,34))
	_impactBurst(boxNode.position, Color(0.4,0.95,1), 10)
	_popTextAt(boxNode.position+Vector2(0,-22), "TURET", Color(0.5,0.95,1), true)
	$gamepad.showMessage("Kotak berubah jadi Turet (nyawa %d)! Ia menembak sekali tiap giliranmu." % turretLife)
	var pulse=boxNode.create_tween()
	pulse.tween_property(boxNode,"scale",Vector2(1.35,0.8),0.1)
	pulse.tween_property(boxNode,"scale",Vector2.ONE,0.15)
	await pulse.finished

# Turet kedua: bisa dipasang sekali lagi setelah Turet pertama aktif.
func _deploySecondTurret():
	secondTurretNode=Node2D.new()
	secondTurretNode.set_script(GadgetScript)
	add_child(secondTurretNode)
	secondTurretNode.position=boxNode.position+Vector2(-34,-18)
	secondTurretNode.setMode("turret")
	secondTurretLife=EngineerRules.TURRET_HP
	secondTurretNode.setHealth(secondTurretLife,EngineerRules.TURRET_HP)
	secondTurretNode.modulate.a=0.0
	var tween=secondTurretNode.create_tween()
	tween.tween_property(secondTurretNode,"modulate:a",1.0,0.18)
	await tween.finished
	_impactBurst(secondTurretNode.position,Color(0.4,0.95,1),10)
	$gamepad.showMessage("Turet kedua terpasang! Kedua Turet menembak setiap giliran.")

# Turet menembak satu musuh hidup setelah aksi pemain (damage setara Vera)
func _turretFire():
	if boxState!=EngineerRules.TURRET or boxNode==null or !is_instance_valid(boxNode):
		return
	var living=_living()
	if living.is_empty():
		return
	var target=living[rng.randi_range(0,living.size()-1)]
	var aim=target.node.global_position+Vector2(30,34)
	boxNode.aimAt(aim)
	boxNode.kick()
	$gamepad.showMessage("Turet menembak %s!" % target.name)
	var bolt=ColorRect.new()
	bolt.size=Vector2(6,3)
	bolt.color=Color(0.45,0.95,1)
	bolt.z_index=50
	add_child(bolt)
	bolt.global_position=boxNode.global_position+Vector2(0,-6)
	bolt.rotation=(aim-bolt.global_position).angle()
	var tween=bolt.create_tween()
	tween.tween_property(bolt,"global_position",aim,0.22)
	await tween.finished
	bolt.queue_free()
	_impactBurst(aim, Color(0.45,0.95,1), 6)
	await _hitEnemy(target, FightRules.boosted(EngineerRules.rollTurretDamage(rng)), false)
	if secondTurretNode!=null and is_instance_valid(secondTurretNode) and secondTurretLife>0 and !_living().is_empty():
		var target2=_living()[rng.randi_range(0,_living().size()-1)]
		var aim2=target2.node.global_position+Vector2(30,34)
		secondTurretNode.aimAt(aim2)
		secondTurretNode.kick()
		var bolt2=ColorRect.new()
		bolt2.size=Vector2(6,3)
		bolt2.color=Color(0.45,0.95,1)
		bolt2.z_index=50
		add_child(bolt2)
		bolt2.global_position=secondTurretNode.global_position+Vector2(0,-6)
		bolt2.rotation=(aim2-bolt2.global_position).angle()
		var tween2=bolt2.create_tween()
		tween2.tween_property(bolt2,"global_position",aim2,0.22)
		await tween2.finished
		bolt2.queue_free()
		_impactBurst(aim2,Color(0.45,0.95,1),6)
		await _hitEnemy(target2,FightRules.boosted(EngineerRules.rollTurretDamage(rng)),false)

# musuh menyerang Turet: nyawa turet berkurang, hancur kalau habis
func _enemyHitsTurret(e_, mult_):
	var useSecond=secondTurretNode!=null and is_instance_valid(secondTurretNode) and secondTurretLife>0 and rng.randf()<0.5
	var targetNode=secondTurretNode if useSecond else boxNode
	$gamepad.showMessage("%s menyerang Turet!" % e_.name)
	var damage=max(1,int(round(FightRules.rollDamage(e_.data.damage*mult_, rng, false).damage*EngineerRules.TURRET_HIT_MULT)))
	if useSecond:
		secondTurretLife=max(0,secondTurretLife-damage)
		targetNode.setHealth(secondTurretLife,EngineerRules.TURRET_HP)
	else:
		turretLife=max(0,turretLife-damage)
		targetNode.setHealth(turretLife, EngineerRules.TURRET_HP)
	_popTextAt(targetNode.position+Vector2(0,-22), str(damage), COLOR_DAMAGE)
	targetNode.modulate=Color(3,3,3)
	targetNode.create_tween().tween_property(targetNode,"modulate",Color.WHITE,0.25)
	await _wait(MESSAGE_DELAY)
	if useSecond and secondTurretLife<=0:
		_impactBurst(secondTurretNode.position,Color(1,0.6,0.25),10)
		secondTurretNode.queue_free()
		secondTurretNode=null
		secondTurretLife=0
		$gamepad.showMessage("Turet kedua hancur!")
	elif !useSecond and turretLife<=0:
		await _dismantleTurret()

func _dismantleTurret():
	if secondTurretNode!=null and is_instance_valid(secondTurretNode) and secondTurretLife>0:
		boxNode.queue_free()
		boxNode=secondTurretNode
		secondTurretNode=null
		turretLife=secondTurretLife
		secondTurretLife=0
		$gamepad.showMessage("Turet pertama hancur; Turet kedua masih aktif.")
		await _wait(MESSAGE_DELAY)
		return
	boxState=EngineerRules.NONE
	$gamepad.showMessage("Semua Turet hancur! Pasang Kotak Mekanik lagi dengan Teknik Mesin.")
	if boxNode!=null and is_instance_valid(boxNode):
		_impactBurst(boxNode.position, Color(1,0.6,0.25), 10)
		var node=boxNode
		boxNode=null
		var tween=node.create_tween()
		tween.tween_property(node,"modulate:a",0.0,0.3)
		tween.tween_callback(node.queue_free)
	await _wait(MESSAGE_DELAY)

# efek tambahan serangan pemain: peluang membuat musuh bingung / berdarah
func _applyAttackStatus(attack_, target_):
	if rng.randf()>=_effectChance(attack_.statusChance):
		return
	if attack_.status==attack_class.CONFUSE:
		target_.confused=true
		_popText(target_.node, "BINGUNG", Color(1,0.9,0.4))
		$gamepad.showMessage("%s kebingungan! Ia akan melewatkan serangannya." % target_.name)
	elif attack_.status==attack_class.POISON:
		target_.poisonTurns=SummonRules.ENEMY_POISON_TURNS
		_popText(target_.node, "RACUN", COLOR_POISON)
		_impactBurst(target_.node.position+Vector2(32,40), COLOR_POISON, 8)
		$gamepad.showMessage("%s keracunan santet!" % target_.name)
	elif attack_.status==attack_class.BLEED:
		target_.bleedTurns=BLEED_TURNS
		_popText(target_.node, "BERDARAH", COLOR_BLEED)
		_impactBurst(target_.node.position+Vector2(32,40), COLOR_BLEED, 9)
		$gamepad.showMessage("%s terluka dan berdarah!" % target_.name)
	else:
		return
	await _wait(MESSAGE_DELAY)

# ---------- Efek++ (Soto) ----------

# peluang efek khusus setelah bonus Efek++ (maksimal 100%)
func _effectChance(base_):
	if effectBuffRounds>0:
		return min(1.0, base_+EFFECT_BUFF_BONUS)
	return base_

# dipanggil di akhir tiap giliran musuh: Perisai Kelapa hanya berlaku untuk satu giliran musuh
func _tickShieldBuff():
	if shieldBuffRounds>0:
		shieldBuffRounds-=1
		if shieldBuffRounds==0:
			shieldReduction=0.0
			_toast("Perisai Kelapa habis","story")


# dipanggil di akhir tiap giliran musuh
func _tickEffectBuff():
	if effectSkipTick:
		effectSkipTick=false
		return
	if effectBuffRounds>0:
		effectBuffRounds-=1
		if effectBuffRounds==0:
			_toast("Efek Soto habis","story")


# ---------- Asasin: animasi serangan, Siaga Bayangan, elak & balas ----------

func _isAssassin():
	return $player.skin==HeroClass.ASSASSIN

# bayangan sisa dari frame sprite pemain yang sedang tampil
func _afterimage(color_, secs_=0.3):
	var src=$player/AnimatedSprite2D
	if src.sprite_frames==null or !src.sprite_frames.has_animation(src.animation):
		return
	var tex=src.sprite_frames.get_frame_texture(src.animation, src.frame)
	if tex==null:
		return
	var ghost=Sprite2D.new()
	ghost.texture=tex
	ghost.position=$player.position
	ghost.flip_h=src.flip_h
	ghost.modulate=color_
	ghost.z_index=4
	add_child(ghost)
	var tw=ghost.create_tween()
	tw.tween_property(ghost,"modulate:a",0.0,secs_)
	tw.tween_callback(ghost.queue_free)

# jarak terjang tiap serangan: makin berat makin jauh, makin banyak bayangan
func _assassinDash(attack_, target_, origin_):
	var enemyCenter=target_.node.position+Vector2(32,40)
	var reach=24.0
	var ghosts=2
	var tint=Color(0.8,0.85,1.0,0.5)
	match attack_.animation:
		"attack_advanced":
			reach=42.0
			ghosts=3
		"attack_special":
			reach=60.0
			ghosts=5
			tint=Color(0.6,0.25,0.95,0.6)
	var toward=enemyCenter-origin_
	var dist=max(0.0, toward.length()-34.0)
	var dest=origin_+toward.normalized()*min(reach,dist)
	var tw=$player.create_tween()
	tw.tween_property($player,"position",dest,0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	for i in ghosts:
		_afterimage(tint, 0.3)
		await _wait(0.14/float(ghosts))

# kembali ke tempat semula (cepat, dengan bayangan)
func _assassinBack(origin_):
	_afterimage(Color(0.8,0.85,1.0,0.4), 0.2)
	var tw=$player.create_tween()
	tw.tween_property($player,"position",origin_,0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)

# satu garis tebasan di titik tertentu; muncul memanjang lalu memudar
func _slash(center_, angle_, length_, color_, thick_=2.0, delay_=0.0):
	var bar=ColorRect.new()
	bar.color=color_
	bar.size=Vector2(length_,thick_)
	bar.pivot_offset=bar.size/2.0
	bar.rotation=angle_
	bar.position=center_-bar.size/2.0
	bar.scale=Vector2(0.1,1.0)
	bar.z_index=12
	bar.visible=false
	add_child(bar)
	var tw=bar.create_tween()
	if delay_>0.0:
		tw.tween_interval(delay_)
	tw.tween_callback(bar.show)
	tw.tween_property(bar,"scale:x",1.0,0.07).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(bar,"modulate:a",0.0,0.2)
	tw.tween_callback(bar.queue_free)

# tebasan di tubuh musuh sesuai serangan: Tusukan (1 garis), Tebas Kilat (silang), Serangan Bayangan (3 garis + ledakan bayangan)
func _assassinSlashEffect(attack_, target_, critical_):
	var c=target_.node.position+Vector2(32,38)
	match attack_.animation:
		"attack_special":
			_slash(c,-0.7,58,Color(1.0,0.25,0.35),3.0)
			_slash(c,0.7,58,Color(0.75,0.3,1.0),3.0,0.07)
			_slash(c,0.0,64,Color(1,1,1),2.0,0.14)
			_impactBurst(c,Color(0.45,0.1,0.7),12)
			_impactBurst(c,Color(1.0,0.2,0.3),10)
			_shakeScreen()
		"attack_advanced":
			_slash(c,-0.6,42,Color(0.8,0.92,1.0),2.0)
			_slash(c,0.6,42,Color(0.8,0.92,1.0),2.0,0.06)
			_impactBurst(c,Color(0.8,0.92,1.0),8)
		_:
			_slash(c,-0.5,28,Color(1,1,1),2.0)
			_impactBurst(c,Color(1,1,1),4)
	if critical_:
		_slash(c,1.57,46,Color(1.0,0.85,0.35),2.0,0.1)

# Tebas Kilat selesai: Asasin menyatu dengan bayangan (siaga mengelak di giliran musuh berikutnya)
func _enterShadowStance():
	shadowStance=true
	_toast("Siaga Bayangan! Serangan musuh bisa dielak","story")
	$player.modulate=Color(0.75,0.65,1.25)
	_afterimage(Color(0.6,0.35,1.0,0.6), 0.5)

func _leaveShadowStance():
	if !shadowStance:
		return
	shadowStance=false
	$player.modulate=Color.WHITE

# pemain lenyap ke dalam bayangan, serangan musuh lewat tanpa kena; kadang langsung dibalas
func _shadowDodge(e_):
	var origin=$player.position
	_afterimage(Color(0.6,0.35,1.0,0.7), 0.45)
	var vanish=$player.create_tween()
	vanish.tween_property($player,"position",origin+Vector2(-30,-12),0.08)
	vanish.parallel().tween_property($player,"modulate:a",0.2,0.08)
	vanish.tween_interval(0.3)
	vanish.tween_property($player,"position",origin,0.12)
	vanish.parallel().tween_property($player,"modulate",Color(0.75,0.65,1.25),0.12)
	_enemyReturn(e_)
	_popText($player, "ELAK!", Color(0.75,0.6,1.0), true)
	$gamepad.showMessage("%s lenyap ke dalam bayangan! Serangan %s tidak kena." % [HERO_NAME, e_.name])
	await _wait(MESSAGE_DELAY)
	await _enemyWaitReturn(e_)
	if rng.randf()<_effectChance(SHADOW_COUNTER_CHANCE):
		await _shadowCounter(e_)

# serangan musuh dibalikkan: Asasin muncul di sisi musuh lalu menebas (damage tetap)
func _shadowCounter(e_):
	var origin=$player.position
	var c=e_.node.position+Vector2(32,38)
	$gamepad.showMessage("%s membalikkan serangan! %s kena %d damage!" % [HERO_NAME, e_.name, FightRules.boosted(SHADOW_COUNTER_DAMAGE)])
	_toast("Serangan dibalikkan!","story")
	_afterimage(Color(0.6,0.35,1.0,0.6), 0.3)
	var toward=c-origin
	var dest=origin+toward.normalized()*max(0.0,toward.length()-34.0)
	var go=$player.create_tween()
	go.tween_property($player,"position",dest,0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_afterimage(Color(0.8,0.85,1.0,0.5), 0.25)
	await go.finished
	_slash(c,-0.6,44,Color(1.0,0.35,0.5),3.0)
	_slash(c,0.6,44,Color(0.8,0.4,1.0),3.0,0.06)
	_impactBurst(c,Color(1.0,0.35,0.5),10)
	_shakeScreen()
	await _hitEnemy(e_, FightRules.boosted(SHADOW_COUNTER_DAMAGE), false)
	_assassinBack(origin)
	await _wait(0.2)

# musuh menghantam Kotak Mekanik: musuh kena 17-25, pemain kena 1-3
func _boxExplodes(e_):
	# tunggu animasi serang musuh selesai supaya tidak terpotong animasi terluka
	while !e_.animDone:
		await get_tree().process_frame
	var center=boxNode.position
	var enemyDamage=FightRules.boosted(EngineerRules.rollBoxDamage(rng))
	var selfDamage=EngineerRules.rollSelfDamage(rng)
	_impactBurst(center, Color(1,0.62,0.2), 12)
	_impactBurst(center, Color(0.45,0.95,1), 8)
	_shakeScreen()
	boxNode.queue_free()
	boxNode=null
	boxState=EngineerRules.NONE
	$gamepad.showMessage("Kotak Mekanik meledak! %s kena %d, kamu kena %d." % [e_.name, enemyDamage, selfDamage])

	GlobalPlayer.damage(selfDamage)
	$player.playDamage()
	_popText($player, str(selfDamage), COLOR_DAMAGE)
	$lifePlayer.updateValue(GlobalPlayer.getLife())

	await _hitEnemy(e_, enemyDamage, false)
	if e_.life>0:
		await _enemyReturn(e_)
	else:
		e_.busy=false
	await _wait(MESSAGE_DELAY*0.5)


# ---------- v9.30: makhluk panggilan (Dukun / Exorcist / Alkemis) ----------

func _summonActive():
	return summon!=null and summon.node!=null and is_instance_valid(summon.node) and summon.life>0

func _summonColor(kind_):
	match kind_:
		SummonRules.MUMMY:
			return Color(0.92,0.86,0.68)
		SummonRules.LAMPOR:
			return Color(0.4,1.0,0.55)
		SummonRules.RANDA:
			return Color(0.9,0.2,0.3)
		SummonRules.BANASPATI:
			return Color(1.0,0.55,0.15)
		SummonRules.GOLEM:
			return Color(0.7,0.68,0.62)
	return Color(0.45,0.95,1.0)

# skill panggil (v9.31, GACHA): makhluk diundi acak dari daftar skill, tanpa menu pilih. Bayar MP, animasi serang,
# makhluk muncul. Hanya satu makhluk dalam satu waktu.
func _useSummon(attack_):
	if _summonActive():
		$gamepad.showMessage("%s masih bertarung. Hanya satu makhluk dalam satu waktu." % summon.data.name)
		await _wait(MESSAGE_DELAY*1.4)
		_playerTurn()
		return
	var kind=SummonRules.roll(attack_.special,rng)
	if kind=="":
		_playerTurn()
		return
	GlobalPlayer.useMana(attack_.manaCost)
	$gamepad.showMessage("%s memakai %s!" % [HERO_NAME, attack_.name])
	$player.playAttack(attack_.animation, attack_.kind)
	await $player.attackFinished
	await _spawnSummon(kind)
	await _wait(MESSAGE_DELAY*0.6)
	_afterPlayerAction()

func _spawnSummon(kind_):
	var data=SummonRules.getData(kind_)
	var node=Node2D.new()
	node.set_script(SummonScript)
	add_child(node)
	node.setKind(kind_)
	node.setHealth(int(data.life),int(data.life))
	var rest=$player.position+Vector2(70,-20)
	node.position=rest+Vector2(0,-46)
	node.modulate.a=0.0
	summon={"kind":kind_,"node":node,"life":int(data.life),"maxLife":int(data.life),"data":data}
	$gamepad.showMessage(data.appear)
	var tween=node.create_tween()
	tween.tween_property(node,"modulate:a",1.0,0.15)
	tween.parallel().tween_property(node,"position",rest,0.3).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	await tween.finished
	_impactBurst(node.position,_summonColor(kind_),12)
	_shakeScreen()
	_popTextAt(node.position+Vector2(0,-26),data.name.to_upper(),_summonColor(kind_),true)
	if SummonRules.isTaunt(kind_):
		_toast("%s memancing semua serangan musuh!" % data.name,"story")
	# panggilan memulihkan HP pemain (Dukun: 47)
	var heal=int(data.heal)
	if heal>0:
		var before=GlobalPlayer.getLife()
		GlobalPlayer.setLife(mini(before+heal,GlobalPlayer.getMaxLife()))
		var gained=GlobalPlayer.getLife()-before
		if gained>0:
			_popText($player,"+"+str(gained),COLOR_HEAL)
			$lifePlayer.updateValue(GlobalPlayer.getLife())
			$gamepad.showMessage("%s pulih %d HP!" % [HERO_NAME,gained])
	await _wait(MESSAGE_DELAY)

# makhluk menyerang satu musuh hidup setelah aksi pemain (damage tetap, tanpa pengali)
func _summonAct():
	if !_summonActive():
		return
	var living=_living()
	if living.is_empty():
		return
	var data=summon.data
	var node=summon.node
	var target=living[rng.randi_range(0,living.size()-1)]
	if data.effect==SummonRules.EFFECT_DRAIN:
		await _summonDrain(target)
		return
	var home=node.position
	var center=target.node.position+Vector2(32,38)
	$gamepad.showMessage(data.attack)
	node.kick()
	if summon.kind==SummonRules.MECHA:
		# meriam Mecha: peluru melesat ke musuh
		var bolt=ColorRect.new()
		bolt.size=Vector2(7,3)
		bolt.color=Color(0.45,0.95,1)
		bolt.z_index=50
		add_child(bolt)
		bolt.global_position=node.global_position+Vector2(16,-2)
		var aim=target.node.global_position+Vector2(30,34)
		bolt.rotation=(aim-bolt.global_position).angle()
		var shot=bolt.create_tween()
		shot.tween_property(bolt,"global_position",aim,0.22)
		await shot.finished
		bolt.queue_free()
		_impactBurst(center,Color(0.45,0.95,1),8)
	else:
		# menerjang ke arah musuh lalu kembali
		var toward=center-home
		var dest=home+toward.normalized()*minf(36.0,maxf(0.0,toward.length()-34.0))
		var go=node.create_tween()
		go.tween_property(node,"position",dest,0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		await go.finished
		_impactBurst(center,_summonColor(summon.kind),7)
	await _hitEnemy(target,int(data.damage),false)
	if is_instance_valid(node):
		var back=node.create_tween()
		back.tween_property(node,"position",home,0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	if target.life>0:
		await _summonEffect(target,data)
	await _wait(0.15)

# efek tambahan serangan makhluk: Mumi = slow, Lampor = racun
func _summonEffect(target_, data_):
	if data_.effect!=SummonRules.EFFECT_SLOW and data_.effect!=SummonRules.EFFECT_POISON:
		return
	if rng.randf()>=_effectChance(float(data_.effectChance)):
		return
	if data_.effect==SummonRules.EFFECT_SLOW:
		target_.slowTurns=SummonRules.SLOW_TURNS
		_popText(target_.node,"LAMBAN",Color(0.65,0.78,1.0))
		$gamepad.showMessage("%s terlilit perban dan melambat!" % target_.name)
	else:
		target_.poisonTurns=SummonRules.ENEMY_POISON_TURNS
		_popText(target_.node,"RACUN",COLOR_POISON)
		_impactBurst(target_.node.position+Vector2(32,40),COLOR_POISON,8)
		$gamepad.showMessage("%s keracunan api Lampor!" % target_.name)
	await _wait(MESSAGE_DELAY)

# Banaspati: menyedot tenaga musuh (jadi damage), dikirim ke pemain sebagai MP; MP penuh -> sisanya jadi HP
func _summonDrain(target_):
	var data=summon.data
	var node=summon.node
	var amount=int(data.drain)
	$gamepad.showMessage(data.attack)
	node.kick()
	var center=target_.node.position+Vector2(32,38)
	_energyFlow(center,node.position,Color(1.0,0.55,0.15),10,0.35)
	await _wait(0.3)
	_energyFlow(node.position,$player.position+Vector2(32,30),Color(0.55,0.8,1.0),8,0.3)
	await _hitEnemy(target_,amount,false)
	var room=GlobalPlayer.getMaxMana()-GlobalPlayer.getMana()
	var toMana=mini(amount,room)
	var overflow=amount-toMana
	if toMana>0:
		GlobalPlayer.addMana(toMana)
		_popText($player,"+%d MP" % toMana,Color(0.6,0.8,1.0))
	if overflow>0:
		var before=GlobalPlayer.getLife()
		GlobalPlayer.setLife(mini(before+overflow,GlobalPlayer.getMaxLife()))
		var gained=GlobalPlayer.getLife()-before
		if gained>0:
			_popTextAt($player.getHeadPosition()+Vector2(0,-14),"+"+str(gained),COLOR_HEAL)
			$lifePlayer.updateValue(GlobalPlayer.getLife())
	await _wait(MESSAGE_DELAY*0.5)

# percikan energi mengalir dari satu titik ke titik lain
func _energyFlow(from_, to_, color_, count_, dur_):
	for i in count_:
		var spark=ColorRect.new()
		spark.size=Vector2(3,3)
		spark.color=color_
		spark.z_index=40
		spark.position=from_
		add_child(spark)
		var ctrl=(from_+to_)/2.0+Vector2(rng.randf_range(-18,18),rng.randf_range(-26,-6))
		var tw=spark.create_tween()
		tw.tween_interval(rng.randf()*0.15)
		tw.tween_method(func(t): spark.position=from_.lerp(ctrl,t).lerp(ctrl.lerp(to_,t),t), 0.0, 1.0, dur_)
		tw.tween_callback(spark.queue_free)

# musuh menyerang makhluk panggilan: nyawanya berkurang, lenyap kalau habis
func _enemyHitsSummon(e_, mult_):
	var node=summon.node
	var data=summon.data
	$gamepad.showMessage("%s menyerang %s!" % [e_.name, data.name])
	var damage=max(1,int(round(FightRules.rollDamage(e_.data.damage*mult_, rng, false).damage*SummonRules.HIT_MULT)))
	summon.life=max(0,summon.life-damage)
	node.setHealth(summon.life,summon.maxLife)
	_popTextAt(node.position+Vector2(0,-28), str(damage), COLOR_DAMAGE)
	node.modulate=Color(3,3,3)
	node.create_tween().tween_property(node,"modulate",Color.WHITE,0.25)
	await _wait(MESSAGE_DELAY)
	if summon.life<=0:
		_impactBurst(node.position,_summonColor(summon.kind),12)
		node.queue_free()
		summon=null
		$gamepad.showMessage("%s tumbang! Kamu bisa memanggil makhluk lagi." % data.name)
		await _wait(MESSAGE_DELAY)

# ---------- v9.30: Tabung Reaksi (Alkemis) ----------

# peluang efek: separuh Blizzard (musuh beku satu giliran + sedikit damage), separuh Racun
func _applyTubeEffect(target_):
	if rng.randf()>=_effectChance(SummonRules.TUBE_EFFECT_CHANCE):
		return
	var center=target_.node.position+Vector2(32,38)
	if rng.randf()<0.5:
		_popText(target_.node,"BLIZZARD",Color(0.65,0.92,1.0),true)
		_impactBurst(center,Color(0.75,0.95,1.0),14)
		_impactBurst(center,Color(1,1,1),8)
		$gamepad.showMessage("Tabung pecah menjadi Blizzard! %s membeku!" % target_.name)
		target_.frozen=true
		await _hitEnemy(target_,SummonRules.TUBE_BLIZZARD_BONUS_DAMAGE,false)
		if target_.life>0:
			await _wait(0.25)
			target_.node.modulate=Color(0.6,0.85,1.35)
		else:
			target_.frozen=false
	else:
		_popText(target_.node,"RACUN",COLOR_POISON,true)
		_impactBurst(center,COLOR_POISON,12)
		target_.poisonTurns=SummonRules.ENEMY_POISON_TURNS
		$gamepad.showMessage("Tabung pecah mengeluarkan racun! %s keracunan!" % target_.name)
	await _wait(MESSAGE_DELAY)

# ---------- v9.30: Barrier / Perisai Suci (Jimat Pengusir, Exorcist) ----------

func _tryBarrier():
	if rng.randf()>=_effectChance(SummonRules.BARRIER_CHANCE):
		return
	if rng.randf()<SummonRules.BARRIER_SHARE:
		if barrierHits>0:
			return
		barrierHits=1
		barrierNode=_makeAura(false)
		_popText($player,"BARRIER",Color(0.8,0.95,1.0),true)
		$gamepad.showMessage("Jimat memunculkan Barrier! Satu serangan musuh akan ditahan penuh.")
	else:
		if holyShieldNode!=null and is_instance_valid(holyShieldNode):
			holyShieldNode.queue_free()
		holyShieldRounds=1
		holyShieldNode=_makeAura(true)
		_popText($player,"PERISAI",Color(1.0,0.9,0.5),true)
		$gamepad.showMessage("Jimat memunculkan Perisai Suci! Damage giliran musuh berikutnya -%d%%." % int(SummonRules.HOLY_SHIELD_REDUCTION*100.0))
	await _wait(MESSAGE_DELAY)

# gelembung (Barrier) atau perisai emas (Perisai Suci) di dekat pemain
func _makeAura(shield_):
	var poly=Polygon2D.new()
	var points=PackedVector2Array()
	if shield_:
		points=PackedVector2Array([Vector2(0,-14),Vector2(10,-8),Vector2(10,6),Vector2(0,16),Vector2(-10,6),Vector2(-10,-8)])
		poly.color=Color(1.0,0.9,0.45,0.6)
		poly.position=$player.position+Vector2(54,34)
	else:
		for i in 28:
			points.append(Vector2(cos(TAU*float(i)/28.0)*26.0,sin(TAU*float(i)/28.0)*32.0))
		poly.color=Color(0.75,0.95,1.0,0.3)
		poly.position=$player.position+Vector2(32,36)
	poly.polygon=points
	poly.z_index=6
	add_child(poly)
	var pulse=poly.create_tween().set_loops()
	pulse.tween_property(poly,"modulate:a",0.55,0.5)
	pulse.tween_property(poly,"modulate:a",1.0,0.5)
	return poly

# serangan musuh membentur Barrier: damage dan efek khusus musuh dibatalkan
func _barrierBlocks(e_):
	_enemyReturn(e_)
	if barrierNode!=null and is_instance_valid(barrierNode):
		_impactBurst(barrierNode.position,Color(0.8,0.95,1.0),10)
		barrierNode.queue_free()
	barrierNode=null
	_popText($player,"TERTAHAN",Color(0.8,0.95,1.0),true)
	$gamepad.showMessage("Barrier menahan serangan %s lalu pecah!" % e_.name)
	await _wait(MESSAGE_DELAY)
	await _enemyWaitReturn(e_)

# Perisai Suci hanya berlaku untuk satu giliran musuh
func _expireHolyShield():
	if holyShieldRounds<=0:
		return
	holyShieldRounds=0
	if holyShieldNode!=null and is_instance_valid(holyShieldNode):
		holyShieldNode.queue_free()
	holyShieldNode=null

#--- fin du combat

func _victory():
	if transitioningToCutscene:
		return
	# semua musuh sudah tumbang (animasi mati diputar saat masing-masing kalah)
	var xp=0
	var gems=0
	var drops=[]
	for e in enemies:
		xp+=e.data.xp
		gems+=rng.randi_range(e.data.gemsMin, e.data.gemsMax)
		drops.append_array(EnemyClass.getDrops(e.id))
	GlobalPlayer.addXp(xp)
	GlobalPlayer.addMana(VICTORY_MANA)
	GlobalPlayer.addGems(gems)
	$gamepad.showMessage(_trad(GlobalGame.TRAD_FIGHT_VICTORY) % [xp, gems])
	await _wait(MESSAGE_DELAY*2)

	# hadiah barang (mini boss)
	if !drops.is_empty():
		var names=[]
		for id in drops:
			GlobalPlayer.addItemEvenIfExist(id)
			var itemName=GlobalItems.getItem(id).name
			if !names.has(itemName):
				names.append(itemName)
		$gamepad.showMessage(_trad(GlobalGame.TRAD_FIGHT_DROP) % ", ".join(names))
		await _wait(MESSAGE_DELAY*2)

	_markDefeated()
	# Cadangan: kalau pilihan Segel Kelas dibatalkan sebelum ritual, ditawarkan lagi di sini.
	await _offerBossClassDrop()
	_gotoMap(true)

# Drop khusus Bhuta Kala (eksklusif, tidak dijual). Diberikan tepat saat Bhuta Kala gugur, SEBELUM ritual /
# cutscene Satan. Satu kali; kalau dibatalkan tetap ditawarkan lagi nanti.
# v9.30: pilihan tergantung percobaan: ke-1 = Exorcist / Alkemis / Dukun, ke-2 = Dukun / Exorcist, ke-3+ = Dukun saja.
func _offerBossClassDrop():
	if GlobalPlayer.battleEncounterKey!="dg_boss" or GlobalScenes.getParamForSceneOr("dungeon",HeroClass.BOSS_DROP_KEY,false):
		return
	var attempt=HeroClass.getBossAttempt()
	var choices=HeroClass.getBossDropChoices(attempt)
	var names=[]
	for class_ in choices:
		names.append(HeroClass.getName(class_))
	var text="Bhuta Kala menjatuhkan Segel Kelas! Pilih "+" atau ".join(names)+"."
	if attempt==2:
		text="Bhuta Kala jatuh di percobaan kedua. Segel Kelas yang tersisa: "+" atau ".join(names)+"."
	elif attempt>2:
		text="Setelah berulang kali mengulang, hanya Segel Kelas "+names[0]+" yang tersisa."
	$gamepad.showMessage(text)
	await _wait(MESSAGE_DELAY*2)
	await _pickBossDropClass(choices)

func _pickBossDropClass(choices_):
	var layer=CanvasLayer.new()
	layer.layer=80
	add_child(layer)
	var select=ClassSelect.new()
	select.classList=choices_.duplicate()
	layer.add_child(select)
	var picked=await _waitForClassChoice(select)
	layer.queue_free()
	if picked=="":
		return
	var sacrifice=""
	if !GlobalPlayer.ownsClass(picked) and GlobalPlayer.getOwnedClasses().size()>=GlobalPlayer.MAX_OWNED_CLASSES:
		sacrifice=await _pickClassToReplace()
		if sacrifice=="":
			$gamepad.showMessage("Pemilihan class dibatalkan. Segel Kelas tetap tersedia.")
			return
	if GlobalPlayer.chooseClass(picked,sacrifice):
		GlobalScenes.saveParamForScene("dungeon",HeroClass.BOSS_DROP_KEY,true)
		$gamepad.showMessage("Class %s terbuka! Senjata khas masuk inventaris." % HeroClass.getName(picked))
		await _wait(MESSAGE_DELAY*2)

func _pickClassToReplace():
	var owned=GlobalPlayer.getOwnedClasses()
	if owned.is_empty():
		return ""
	var layer=CanvasLayer.new()
	layer.layer=81
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
	layer.queue_free()
	return result["class"]

func _waitForClassChoice(select_):
	var result={"class":"","done":false}
	select_.chosen.connect(func(class_):
		result["class"]=class_
		result["done"]=true)
	select_.cancelled.connect(func(): result["done"]=true)
	while !result["done"]:
		await get_tree().process_frame
	return result["class"]

# catat kemenangan: dungeon dan desa tersimpan di save; musuh di jalan hilang selama perjalanan ini
func _markDefeated():
	var key=GlobalPlayer.battleEncounterKey
	if key=="":
		return
	if key.begins_with("dg_"):
		GlobalScenes.saveParamForScene("dungeon",key,true)
	elif key.begins_with("cv_") or key.begins_with("bv_"):
		GlobalScenes.saveParamForScene("village",key,true)
		GlobalPlayer.clearedEncounters.append(key)
	else:
		GlobalPlayer.clearedEncounters.append(key)

# Bhuta Kala (bukan Satan): kalah atau kabur = satu percobaan gagal, pilihan Segel Kelas berikutnya menyempit
func _recordBossFail():
	if GlobalPlayer.battleEncounterKey=="dg_boss" and GlobalPlayer.battleEnemy==EnemyClass.BOSS:
		HeroClass.recordBossFail()

func _defeat():
	_recordBossFail()
	$gamepad.showMessage(_trad(GlobalGame.TRAD_FIGHT_DEFEAT) % HERO_NAME)
	var tween=$player.create_tween()
	tween.tween_property($player, "modulate:a", 0.0, MESSAGE_DELAY)
	await _wait(MESSAGE_DELAY*2)
	# kalah: HP & MP dikembalikan seperti sebelum bertarung, lalu mundur di peta
	GlobalPlayer.setLife(playerSavedLife)
	GlobalPlayer.setMana(playerSavedMana)
	_gotoMap(false)

# menang: lewat ke seberang musuh; kabur / kalah: mundur ke sisi semula
func _gotoMap(crossed_):
	var target=GlobalPlayer.battleWinPosition if crossed_ else GlobalPlayer.battleLosePosition
	if target==null:
		var goUp=(GlobalPlayer.getSide()==UP)!=crossed_
		target=positionToGoUp if goUp else positionToGoDown
	GlobalPlayer.savePosition(target)
	# kembali ke scene asal pertarungan (peta dunia atau Ancient Dungeon), lalu direset
	var returnScene=GlobalPlayer.battleReturnScene
	GlobalPlayer.battleReturnScene=GlobalPlayer.DEFAULT_BATTLE_RETURN
	SceneTransition.change_scene(returnScene)


#--- animasi serangan musuh: bersiap -> menerjang -> kena -> kembali

const ATTACK_TRAVEL_MAX=92.0
const ATTACK_STOP_GAP=40.0

# gaya gerak tiap musuh: hop = melompat (pocong), swoop = melayang menukik (hantu & terbang),
# strike = menggulung lalu mematuk (ular), slam = mengangkat lalu menghantam (bos), dash = menerjang
func _attackStyle(data_):
	match data_.sprite:
		"poci":
			return "hop"
		"kunti","leak","flameleak","bat","cavebat","wasp","seagull","jellyfish":
			return "swoop"
		"snake","nightsnake":
			return "strike"
		"boss","satan","darkus_iblis","darkus":
			return "slam"
	if data_.kind=="ghost":
		return "swoop"
	return "dash"

func _burstColor(data_):
	match data_.kind:
		"ghost":
			return Color(0.75,0.85,1.0)
		"demon":
			return Color(1.0,0.45,0.35)
	return Color(1.0,0.92,0.6)

# hantu & hewan terbang mengambang pelan saat menunggu giliran; pocong sedikit mengayun
func _startIdleMotion(node_, data_):
	var sprite=node_.get_node("AnimatedSprite2D")
	var style=_attackStyle(data_)
	var amp=0.0
	var secs=0.9
	if style=="swoop":
		amp=3.0
	elif style=="hop":
		amp=1.5
		secs=0.6
	elif data_.kind=="demon":
		amp=1.5
		secs=1.1
	if amp==0.0:
		return
	if sprite.has_meta("idleBob"):
		var oldBob=sprite.get_meta("idleBob")
		if oldBob!=null and oldBob.is_valid():
			oldBob.kill()
	sprite.offset=Vector2.ZERO
	var bob=sprite.create_tween().set_loops()
	sprite.set_meta("idleBob",bob)
	bob.tween_property(sprite,"offset:y",-amp,secs).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	bob.tween_property(sprite,"offset:y",amp,secs).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

# skala di sekitar titik pijak (tengah-bawah sprite 64x64) supaya sprite tidak melenceng
func _squash(sprite_, sx_, sy_):
	sprite_.scale=Vector2(sx_,sy_)
	sprite_.position=Vector2(32.0*(1.0-sx_),64.0*(1.0-sy_))

func _moveTween(node_, from_, to_, dur_, arc_, trans_, ease_):
	var tw=node_.create_tween()
	tw.tween_method(func(p): node_.position=from_.lerp(to_,p)+Vector2(0.0,-sin(p*PI)*arc_), 0.0, 1.0, dur_).set_trans(trans_).set_ease(ease_)
	return tw

func _squashTween(sprite_, from_, to_, dur_):
	var tw=sprite_.create_tween()
	tw.tween_method(func(v): _squash(sprite_,v.x,v.y), from_, to_, dur_).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	return tw

# bagian pertama serangan: bersiap lalu menerjang. Selesai tepat saat musuh mengenai sasaran.
func _enemyApproach(e_, targetPos_, missed_, mult_):
	var node=e_.node
	var sprite=node.get_node("AnimatedSprite2D")
	var home=e_.home
	var style=_attackStyle(e_.data)
	var heavy=mult_>1.2

	var toward=targetPos_-home
	if toward.length()<1.0:
		toward=Vector2.LEFT
	var dir=toward.normalized()
	var reach=clamp(toward.length()-ATTACK_STOP_GAP,28.0,ATTACK_TRAVEL_MAX)
	if missed_:
		reach*=1.12

	# windup (detik), terjang (detik), mundur sebelum terjang, naik, tinggi lompatan, bentuk saat bersiap
	var windup=0.22
	var lunge=0.11
	var back=10.0
	var rise=0.0
	var arc=0.0
	var crouch=Vector2(1.1,0.88)
	var stretch=Vector2(0.92,1.08)
	var trans=Tween.TRANS_CUBIC
	match style:
		"hop":
			windup=0.2
			lunge=0.34
			back=4.0
			arc=24.0
			crouch=Vector2(1.14,0.8)
			stretch=Vector2(0.9,1.14)
			trans=Tween.TRANS_SINE
		"swoop":
			windup=0.3
			lunge=0.28
			back=14.0
			rise=12.0
			crouch=Vector2(0.94,1.06)
			stretch=Vector2(1.1,0.92)
			trans=Tween.TRANS_SINE
		"strike":
			windup=0.32
			lunge=0.07
			back=18.0
			crouch=Vector2(0.86,1.12)
			stretch=Vector2(1.18,0.86)
			trans=Tween.TRANS_EXPO
		"slam":
			windup=0.4
			lunge=0.1
			back=6.0
			rise=18.0
			crouch=Vector2(0.94,1.1)
			stretch=Vector2(1.08,0.94)
	if heavy:
		# serangan penuh tenaga: bersiap lebih lama dan lebih jauh
		windup*=1.5
		back*=1.5
		rise+=6.0

	e_.busy=true
	e_.animDone=false
	var windupPos=home-dir*back+Vector2(0.0,-rise)
	var hitPos=home+dir*reach

	var wt=_moveTween(node,home,windupPos,windup,0.0,Tween.TRANS_QUAD,Tween.EASE_OUT)
	_squashTween(sprite,Vector2.ONE,crouch,windup)
	if style=="swoop":
		node.create_tween().tween_property(node,"modulate:a",0.75,windup)
	await wt.finished

	# mulai animasi serang tepat saat menerjang agar ayunannya pas dengan benturan
	node.attackFinished.connect(func(): e_.animDone=true, CONNECT_ONE_SHOT)
	node.playAttack("attack-1")
	_squashTween(sprite,crouch,stretch,lunge)
	var lt=_moveTween(node,windupPos,hitPos,lunge,arc,trans,Tween.EASE_IN)
	await lt.finished

	# benturan: sedikit menekan, lalu layar bergetar kalau serangan berat
	_squash(sprite,1.0+(1.0-stretch.x)*0.6,1.0-(stretch.y-1.0)*0.6)
	if style=="slam" or heavy:
		_shakeScreen()

# bagian kedua: musuh mundur ke tempat semula. Tidak perlu di-await; pakai _enemyWaitReturn.
func _enemyReturn(e_):
	var node=e_.node
	var sprite=node.get_node("AnimatedSprite2D")
	var style=_attackStyle(e_.data)
	var dur=0.34 if style=="swoop" else 0.28
	var tw=_moveTween(node,node.position,e_.home,dur,0.0,Tween.TRANS_QUAD,Tween.EASE_OUT)
	_squashTween(sprite,sprite.scale,Vector2.ONE,dur)
	if style=="swoop":
		node.create_tween().tween_property(node,"modulate:a",1.0,dur)
	await tw.finished
	# tunggu animasi serangnya selesai juga supaya tidak terpotong
	while !e_.animDone:
		await get_tree().process_frame
	_squash(sprite,1.0,1.0)
	node.position=e_.home
	node.modulate.a=1.0
	e_.busy=false

func _enemyWaitReturn(e_):
	while e_.busy:
		await get_tree().process_frame

# musuh gemetar saat mengumpulkan tenaga
func _tremble(e_, secs_):
	var node=e_.node
	var home=e_.home
	var tw=node.create_tween()
	var steps=int(secs_/0.05)
	for i in steps:
		var amp=1.0+2.0*float(i)/float(steps)
		tw.tween_property(node,"position",home+Vector2(rng.randf_range(-amp,amp),rng.randf_range(-amp,amp)*0.5),0.05)
	tw.tween_property(node,"position",home,0.05)

# pemain melompat kecil ke belakang saat serangan musuh meleset
func _playerDodge():
	var origin=$player.position
	var tw=$player.create_tween()
	tw.tween_property($player,"position",origin+Vector2(-14,-8),0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property($player,"position",origin,0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

# percikan kecil di titik benturan
func _impactBurst(center_, color_, count_=7):
	for i in count_:
		var spark=ColorRect.new()
		spark.color=color_
		spark.size=Vector2(3,3)
		spark.z_index=9
		spark.position=center_
		add_child(spark)
		var ang=TAU*float(i)/float(count_)+rng.randf()*0.5
		var dist=rng.randf_range(10.0,24.0)
		var tw=spark.create_tween()
		tw.tween_property(spark,"position",center_+Vector2(cos(ang),sin(ang))*dist,0.26).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.parallel().tween_property(spark,"modulate:a",0.0,0.26)
		tw.tween_callback(spark.queue_free)


#--- effets

func _wait(seconds_):
	return get_tree().create_timer(seconds_).timeout

# musuh terkena serangan: animasi, angka damage, bar nyawa; kalau habis langsung tumbang
func _hitEnemy(e_, damage_, critical_):
	var newLife=max(0, e_.life-damage_)
	# bos dengan fase pengorbanan tidak bisa dibunuh langsung: nyawanya berhenti di batas fase
	if e_.data.has("suicideAt") and !e_.suicided and newLife<=e_.data.suicideAt:
		newLife=e_.data.suicideAt
	e_.life=newLife
	e_.node.playDamage()
	_hitEffect(e_.node, critical_)
	_popText(e_.node, str(damage_), COLOR_CRITICAL if critical_ else COLOR_DAMAGE, critical_)
	e_.bar.updateValue(e_.life)
	await e_.node.damageFinished
	if e_.life<=0:
		await _killEnemy(e_)

func _killEnemy(e_):
	if e_.data.has("possess") and !e_.data.has("dyingText"):
		$gamepad.showMessage(e_.name+" tumbang!")
	elif enemies.size()>1:
		$gamepad.showMessage(_trad(GlobalGame.TRAD_FIGHT_ENEMY_DOWN) % e_.name)
	# Satan: meraung tidak terima kalah dulu, baru runtuh
	if e_.data.has("dyingText"):
		await _dyingThroes(e_)
	e_.node.playDie()
	await e_.node.dieFinished
	e_.node.visible=false
	if e_.data.has("dieText"):
		$gamepad.showMessage(e_.data.dieText)
		await _wait(MESSAGE_DELAY*2)
	# Satan kalah: akhiri battle sepenuhnya. Adegan perasukan Darkus dimainkan
	# sebagai cutscene mandiri setelah kembali ke dungeon, lalu battle baru dimulai.
	if e_.data.has("possess"):
		if e_.id == EnemyClass.SATAN:
			await _leaveForPossessionCutscene(e_)
		else:
			await _spawnNext(e_, e_.data.possess, e_.data.possessText)

# toast ringkas di atas layar untuk momen penting pertarungan
var _toastNode=null

func _toast(text_, kind_="danger", title_=""):
	if _toastNode==null or !is_instance_valid(_toastNode):
		var layer=CanvasLayer.new()
		layer.layer=90
		add_child(layer)
		_toastNode=load("res://common/ui/notification.tscn").instantiate()
		layer.add_child(_toastNode)
	_toastNode.display(text_,kind_,title_)

# musuh baru menggantikan musuh sebelumnya di tempat dan bar nyawa yang sama
func _spawnNext(from_, nextId_, text_):
	var data=EnemyClass.getEnemy(nextId_)
	var node=from_.node
	var bar=from_.bar
	if nextId_==EnemyClass.SATAN:
		_toast("Satan dipanggil!","danger")
	if !data.has("preSprite"):
		$gamepad.showMessage(text_)
		await _wait(MESSAGE_DELAY*1.6)
	var sprite=node.get_node("AnimatedSprite2D")
	node.modulate=Color(1,1,1,0)
	node.visible=true
	if data.has("preSprite"):
		# Darkus berlari masuk, dirasuki asap Satan, lalu berubah wujud
		await _possessDarkus(from_, data, text_)
	else:
		sprite.sprite_frames=EnemySprites.build(data.sprite)
		node.playIdle()
		var fadeIn=node.create_tween()
		fadeIn.tween_property(node,"modulate",Color.WHITE,0.8)
	bar.init(data.name, data.life, data.life)
	enemies.append({"id":nextId_,"data":data,"node":node,"bar":bar,"life":data.life,"maxLife":data.life,
		"name":data.name,"charging":false,"enraged":false,"turns":0,"suicided":false,"confused":false,"bleedTurns":0,"poisonTurns":0,"slowTurns":0,"frozen":false,
		"home":node.position,"busy":false,"animDone":true})
	_startIdleMotion(node,data)
	await _wait(MESSAGE_DELAY)
	$gamepad.showMessage(data.appear)
	await _wait(MESSAGE_DELAY*1.6)

# ---------- adegan: Satan sekarat -> Darkus berlari masuk -> dirasuki -> berubah wujud ----------

# Satan meraung tidak terima kalah: tubuh berdenyut merah, gemetar makin kencang, layar bergetar
func _dyingThroes(e_):
	var node=e_.node
	var home=node.position
	$gamepad.showMessage(e_.data.dyingText)
	_toast("Satan murka!","danger")
	await _wait(MESSAGE_DELAY*1.2)
	for i in 14:
		var amp=1.5+float(i)*0.45
		node.position=home+Vector2(rng.randf_range(-amp,amp),rng.randf_range(-amp,amp)*0.5)
		node.modulate=Color(2.6,0.3,0.3) if i%2==0 else Color(1.4,1.0,1.0)
		if i%3==0:
			_shakeScreen()
			_impactBurst(home+Vector2(32,36), Color(1.0,0.3,0.2), 7)
		await _wait(0.1)
	node.position=home
	node.modulate=Color.WHITE
	if e_.data.has("dyingText2"):
		$gamepad.showMessage(e_.data.dyingText2)
		_smokeRise(home+Vector2(32,50), 16)
		await _wait(MESSAGE_DELAY*1.6)

# asap hitam naik pelan dari satu titik lalu menghilang
func _smokeRise(center_, count_):
	for i in count_:
		var puff=ColorRect.new()
		var sz=rng.randi_range(3,6)
		puff.size=Vector2(sz,sz)
		puff.color=Color(0.05,0.0,0.08).lerp(Color(0.5,0.05,0.1), rng.randf()*0.6)
		puff.z_index=9
		puff.position=center_+Vector2(rng.randf_range(-16,16),rng.randf_range(-6,10))
		add_child(puff)
		var tw=puff.create_tween()
		tw.tween_interval(rng.randf()*0.5)
		tw.tween_property(puff,"position",puff.position+Vector2(rng.randf_range(-14,14),-rng.randf_range(26,52)),rng.randf_range(0.9,1.5)).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tw.parallel().tween_property(puff,"modulate:a",0.0,1.2).set_delay(0.3)
		tw.tween_callback(puff.queue_free)

# arus asap hitam melengkung dari satu titik menuju titik lain (dipakai saat Satan merasuki Darkus)
func _smokeFlow(from_, to_, count_, dur_):
	for i in count_:
		var puff=ColorRect.new()
		var sz=rng.randi_range(2,5)
		puff.size=Vector2(sz,sz)
		puff.color=Color(0.05,0.0,0.08).lerp(Color(0.9,0.1,0.15), rng.randf()*0.7)
		puff.z_index=9
		puff.position=from_
		add_child(puff)
		var ctrl=(from_+to_)/2.0+Vector2(rng.randf_range(-34,34),rng.randf_range(-50,-12))
		var tw=puff.create_tween()
		tw.tween_interval(rng.randf()*0.5)
		tw.tween_method(func(t): puff.position=from_.lerp(ctrl,t).lerp(ctrl.lerp(to_,t),t), 0.0, 1.0, dur_).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		tw.tween_callback(puff.queue_free)

# gemetar di tempat (dipakai Darkus yang sedang dirasuki)
func _shiver(node_, secs_, strong_=2.0):
	var home=node_.position
	var steps=int(secs_/0.04)
	for i in steps:
		var amp=strong_*(0.5+float(i)/float(steps))
		node_.position=home+Vector2(rng.randf_range(-amp,amp),rng.randf_range(-amp,amp)*0.6)
		await _wait(0.04)
	node_.position=home

# satu langkah lari Darkus: maju sambil melompat-lompat kecil, sesekali debu di kakinya
func _runStep(p_, node_, from_, to_):
	node_.position=from_.lerp(to_,p_)+Vector2(0.0,-absf(sin(p_*PI*7.0))*5.0)
	if rng.randf()<0.25:
		_impactBurst(node_.position+Vector2(32,62), Color(0.75,0.7,0.6), 1)

# Darkus muncul: berlari masuk dari kiri layar, sadar ada yang tidak beres, dirasuki asap Satan,
# terangkat ke tempat musuh, lalu berubah wujud menjadi Darkus (Dirasuki Satan)
func _possessDarkus(from_, data_, possessText_):
	var node=from_.node
	var bar=from_.bar
	var sprite=node.get_node("AnimatedSprite2D")
	var home=from_.home
	var satanCenter=home+Vector2(32,40)
	var satanEcho=null

	# 1. Asap Satan masih bertahan setelah tubuhnya runtuh; arena hening sejenak.
	if EnemyClass.getEnemy(EnemyClass.SATAN).has("lingerText"):
		$gamepad.showMessage(EnemyClass.getEnemy(EnemyClass.SATAN).lingerText)
	_smokeRise(satanCenter, 22)
	_shakeScreen()
	await _wait(MESSAGE_DELAY*1.8)

	# 2. Darkus datang dari lorong, bukan muncul mendadak di tengah arena.
	var startPos=Vector2(-92,home.y+16)
	var stopPos=Vector2(148,home.y+4)
	node.position=startPos
	node.modulate=Color.WHITE
	node.visible=true
	if sprite.has_meta("idleBob"):
		var oldBob=sprite.get_meta("idleBob")
		if oldBob!=null and oldBob.is_valid():
			oldBob.kill()
	sprite.offset=Vector2.ZERO
	sprite.sprite_frames=EnemySprites.build(data_.preSprite)
	node.playIdle()
	$gamepad.showMessage(data_.enterText)
	_toast("Darkus datang!","story")
	var run=node.create_tween()
	run.tween_method(_runStep.bind(node,startPos,stopPos), 0.0, 1.0, 1.7).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await run.finished
	node.position=stopPos
	await _wait(0.45)
	$gamepad.showMessage(data_.enterSpeech)
	await _wait(MESSAGE_DELAY*2.2)

	# 3. Satan muncul kembali sebagai bayangan energi. Ia mengenali Darkus.
	satanEcho=AnimatedSprite2D.new()
	satanEcho.sprite_frames=EnemySprites.build("satan")
	satanEcho.position=home
	satanEcho.scale=Vector2(0.82,0.82)
	satanEcho.modulate=Color(1.0,0.28,0.24,0.0)
	satanEcho.z_index=8
	add_child(satanEcho)
	satanEcho.play("idle")
	var echoIn=satanEcho.create_tween()
	echoIn.tween_property(satanEcho,"modulate",Color(1.4,0.35,0.3,0.92),0.65)
	echoIn.parallel().tween_property(satanEcho,"scale",Vector2(1.0,1.0),0.65)
	_smokeRise(satanCenter,16)
	await echoIn.finished
	$gamepad.showMessage(possessText_)
	_toast("Satan mengincar Darkus!","danger")
	await _wait(MESSAGE_DELAY*1.5)

	# 4. Darkus terangkat dari lantai dan terseret paksa ke arah Satan.
	_shakeScreen()
	_impactBurst(stopPos+Vector2(32,58),Color(0.75,0.08,0.16),10)
	var pull=_moveTween(node,stopPos,home+Vector2(0,-20),1.15,42.0,Tween.TRANS_CUBIC,Tween.EASE_IN)
	var pullTint=node.create_tween()
	pullTint.tween_property(node,"modulate",Color(1.8,0.45,0.42),0.65)
	pullTint.tween_property(node,"modulate",Color(1.0,0.22,0.2),0.5)
	for i in 3:
		_smokeFlow(stopPos+Vector2(24,34),home+Vector2(32,38),12,0.75)
		await _wait(0.22)
	await pull.finished
	node.position=home+Vector2(0,-20)
	_impactBurst(home+Vector2(32,36),Color(0.95,0.12,0.18),16)
	_shakeScreen()
	await _shiver(node,0.85,4.0)

	# 5. Tubuh Satan pecah menjadi asap dan seluruh asap menerobos masuk ke Darkus.
	$gamepad.showMessage(data_.possessSpeech)
	var echoFade=satanEcho.create_tween()
	echoFade.tween_property(satanEcho,"modulate:a",0.0,0.75)
	echoFade.parallel().tween_property(satanEcho,"scale",Vector2(0.25,0.25),0.75).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	_smokeFlow(home+Vector2(32,30),node.position+Vector2(32,34),48,0.9)
	_smokeRise(home+Vector2(32,30),20)
	await echoFade.finished
	satanEcho.queue_free()
	_impactBurst(node.position+Vector2(32,36),Color(0.95,0.05,0.16),22)
	node.modulate=Color(1.8,0.2,0.25)
	await _shiver(node,1.15,4.5)

	# 6. Darkus berubah menjadi wadah Satan; fase boss kedua dimulai setelah morph selesai.
	node.position=home
	$gamepad.showMessage(data_.preText)
	sprite.sprite_frames=EnemySprites.build(data_.sprite,true)
	sprite.play("morph")
	_shakeScreen()
	await sprite.animation_finished
	node.playIdle()
	_impactBurst(home+Vector2(32,36),Color(1.0,0.18,0.16),18)
	_shakeScreen()
	var flash=node.create_tween()
	flash.tween_property(node,"modulate",Color(2.6,0.45,0.45),0.15)
	flash.tween_property(node,"modulate",Color.WHITE,0.55)
	await flash.finished

# Satan dikalahkan: keluar dari battle agar ritual perasukan bukan animasi di arena pertarungan.
func _leaveForPossessionCutscene(e_):
	transitioningToCutscene = true
	$gamepad.showMessage("Satan: 'TIDAK! Aku tidak mungkin kalah...!'")
	_toast("Satan runtuh!","danger")
	await _wait(MESSAGE_DELAY * 1.5)
	# Hadiah Satan diberikan di sini; encounter boss baru ditandai selesai setelah Darkus kalah.
	GlobalPlayer.addXp(e_.data.xp)
	GlobalPlayer.addGems(rng.randi_range(e_.data.gemsMin, e_.data.gemsMax))
	GlobalScenes.saveParamForScene("dungeon", "dg_ritual", true)
	GlobalPlayer.possessionCutscenePending = true
	GlobalPlayer.ritualCutscenePending = false
	GlobalPlayer.savePosition(RITUAL_PLAYER_POSITION)
	GlobalPlayer.battleReturnScene = "res://screens/ancient-dungeon/dungeon.tscn"
	SceneTransition.change_scene(GlobalPlayer.battleReturnScene)
	GlobalPlayer.battleReturnScene = GlobalPlayer.DEFAULT_BATTLE_RETURN

# cek fase bos setelah aksi pemain. Mengembalikan true kalau pemain tumbang atau pertempuran berakhir
# (Bhuta Kala gugur: pemain keluar ke adegan ritual).
func _bossPhases():
	for e in enemies:
		if e.life>0 and e.data.has("suicideAt") and !e.suicided and e.life<=e.data.suicideAt:
			return await _bossSuicide(e)
	return false

# serangan pengorbanan: pemain kena damage tetap, bos hancur, lalu memanggil musuh berikutnya
func _bossSuicide(e_):
	e_.suicided=true
	defending=false
	$gamepad.showMessage(e_.data.suicideText)
	await _wait(MESSAGE_DELAY*2)
	if e_.data.has("ritualText"):
		$gamepad.showMessage(e_.data.ritualText)
	var pulse=e_.node.create_tween()
	pulse.tween_property(e_.node,"modulate",Color(2.0,0.4,0.4),0.35)
	pulse.tween_property(e_.node,"modulate",Color.WHITE,0.25)
	pulse.tween_property(e_.node,"modulate",Color(2.0,0.4,0.4),0.25)
	await _wait(MESSAGE_DELAY*2)
	e_.node.playAttack("attack-1")
	await e_.node.attackFinished

	var damage=int(e_.data.suicideDamage)
	GlobalPlayer.damage(damage)
	$player.playDamage()
	_hitEffect($player, true)
	_popText($player, str(damage), COLOR_CRITICAL, true)
	$lifePlayer.updateValue(GlobalPlayer.getLife())
	await $player.damageFinished
	if GlobalPlayer.getLife()<=0:
		_defeat()
		return true

	# bos hancur oleh serangannya sendiri
	e_.life=0
	e_.bar.updateValue(0)
	e_.node.modulate=Color.WHITE
	e_.node.playDie()
	await e_.node.dieFinished
	e_.node.visible=false
	if e_.data.has("summon"):
		await _leaveForRitual(e_)
		# pemain sudah meninggalkan pertempuran: tidak ada giliran lagi di sini
		return true
	return false

# Bhuta Kala gugur: pertempuran berakhir di sini. Pemain kembali ke dungeon, di sana adegan ritual
# (sigil, dupa, dll.) diputar, lalu Satan muncul dan pemain dipaksa bertarung lagi (lihat dungeon.gd).
func _leaveForRitual(e_):
	$gamepad.showMessage(e_.data.summonText)
	_toast("Ritual pemanggilan dimulai!","danger")
	await _wait(MESSAGE_DELAY*2)

	# hadiah Bhuta Kala dibayar sekarang karena pertempurannya selesai
	var xp=e_.data.xp
	var gems=rng.randi_range(e_.data.gemsMin, e_.data.gemsMax)
	GlobalPlayer.addXp(xp)
	GlobalPlayer.addGems(gems)
	$gamepad.showMessage(_trad(GlobalGame.TRAD_FIGHT_VICTORY) % [xp, gems])
	await _wait(MESSAGE_DELAY*2)

	# v9.24: Segel Kelas (Exorcist / Alkemis) dijatuhkan sekarang, sebelum ritual dan cutscene Satan
	await _offerBossClassDrop()

	# ritual tercatat di save: kalau pemain kalah lawan Satan, ruang bos tetap berisi sigil dan Satan
	GlobalScenes.saveParamForScene("dungeon","dg_ritual",true)
	GlobalPlayer.ritualCutscenePending=true
	# pemain dikembalikan ke selatan sigil, tempat adegan ritual disaksikan
	GlobalPlayer.savePosition(RITUAL_PLAYER_POSITION)
	var returnScene=GlobalPlayer.battleReturnScene
	GlobalPlayer.battleReturnScene=GlobalPlayer.DEFAULT_BATTLE_RETURN
	SceneTransition.change_scene(returnScene)


# kilatan putih + getar kecil; kalau knock_ diisi, petarung terpental lalu kembali
func _hitEffect(fighter_:Node2D, strong_, knock_=Vector2.ZERO):
	var origin=fighter_.position
	var amplitude=4 if strong_ else 2
	var tween=fighter_.create_tween()
	fighter_.modulate=Color(3, 3, 3)
	tween.tween_property(fighter_, "modulate", Color.WHITE, 0.2)
	if knock_!=Vector2.ZERO:
		var kb=fighter_.create_tween()
		kb.tween_property(fighter_, "position", origin+knock_, 0.06).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		kb.tween_property(fighter_, "position", origin, 0.24).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	else:
		for i in 4:
			var side=1 if i%2==0 else -1
			tween.parallel().tween_property(fighter_, "position", origin+Vector2(amplitude*side, 0), 0.04).set_delay(i*0.04)
		tween.tween_property(fighter_, "position", origin, 0.04)
	if strong_:
		_shakeScreen()

func _shakeScreen():
	var tween=create_tween()
	for i in 6:
		tween.tween_property(self, "position", Vector2(rng.randi_range(-3, 3), rng.randi_range(-2, 2)), 0.03)
	tween.tween_property(self, "position", Vector2.ZERO, 0.03)

# nombor (atau teks) yang muncul di atas petarung
func _popText(fighter_:Node2D, text_, color_, big_=false):
	_popTextAt(fighter_.getHeadPosition(), text_, color_, big_)

func _popTextAt(position_, text_, color_, big_=false):
	var label=Label.new()
	label.theme=DefaultTheme
	label.text=text_
	label.z_index=10
	label.add_theme_color_override("font_color", color_)
	label.add_theme_color_override("font_outline_color", COLOR_OUTLINE)
	label.add_theme_constant_override("outline_size", 4)
	label.add_theme_font_size_override("font_size", 24 if big_ else 16)
	add_child(label)
	label.reset_size()
	label.position=position_-Vector2(label.size.x/2, label.size.y)
	var tween=label.create_tween()
	tween.tween_property(label, "position:y", label.position.y-14, 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.3).set_delay(0.5)
	tween.tween_callback(label.queue_free)

func _trad(id_):
	return GlobalGame.getTraductionById(id_)
