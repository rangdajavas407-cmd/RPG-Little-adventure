extends GutTest

# v9.30: class Dukun, makhluk panggilan (Mumi / Lampor / Randa / Banaspati / Golem / Mecha),
# skill baru Exorcist & Alkemis, dan pilihan Segel Kelas Bhuta Kala menurut percobaan.

const HeroClass=preload("res://common/class/hero_class.gd")
const SummonRules=preload("res://common/class/summon_rules.gd")
const attackClass=preload("res://common/class/item/attack_class.gd")
var Player=load("res://common/singletons/globalPlayer.gd")

func before_each():
	GlobalScenes.saveParamForScene("dungeon",HeroClass.BOSS_FAIL_KEY,0)

func after_each():
	GlobalScenes.saveParamForScene("dungeon",HeroClass.BOSS_FAIL_KEY,0)

# ---------- Segel Kelas menurut percobaan ----------

func test_firstAttemptOffersExorcistAlchemistAndDukun():
	assert_eq(1, HeroClass.getBossAttempt())
	assert_eq([HeroClass.EXORCIST,HeroClass.ALCHEMIST,HeroClass.DUKUN], HeroClass.getBossDropChoices(1))

func test_secondAttemptOffersOnlyDukunOrExorcist():
	HeroClass.recordBossFail()
	assert_eq(2, HeroClass.getBossAttempt())
	var choices=HeroClass.getBossDropChoices(HeroClass.getBossAttempt())
	assert_eq(2, choices.size())
	assert_true(choices.has(HeroClass.DUKUN))
	assert_true(choices.has(HeroClass.EXORCIST))
	assert_false(choices.has(HeroClass.ALCHEMIST))

func test_repeatedAttemptsOfferOnlyDukun():
	HeroClass.recordBossFail()
	HeroClass.recordBossFail()
	assert_eq(3, HeroClass.getBossAttempt())
	assert_eq([HeroClass.DUKUN], HeroClass.getBossDropChoices(3))
	assert_eq([HeroClass.DUKUN], HeroClass.getBossDropChoices(9))

func test_failCounterSurvivesSaveAsFloat():
	# nilai dari file save JSON terbaca sebagai desimal
	GlobalScenes.saveParamForScene("dungeon",HeroClass.BOSS_FAIL_KEY,2.0)
	assert_eq(3, HeroClass.getBossAttempt())

# ---------- class Dukun ----------

func test_dukunIsValidClassWithStaff():
	assert_true(HeroClass.isValid(HeroClass.DUKUN))
	assert_true(HeroClass.isMagic(HeroClass.DUKUN))
	assert_eq(GlobalItems.ID.DUKUN_STAFF, HeroClass.getWeaponId(HeroClass.DUKUN))
	assert_eq("Dukun", HeroClass.getName(HeroClass.DUKUN))
	assert_false(HeroClass.CHOICES.has(HeroClass.DUKUN), "Dukun hanya dari drop Bhuta Kala")

func test_dukunSheetsAndProjectilesExist():
	for sheet in ["idle","damage","attack-simple","attack-advanced","attack-special"]:
		assert_true(FileAccess.file_exists(HeroClass.FRAMES_PATH+"dukun-"+sheet+".png"), sheet)
	assert_true(FileAccess.file_exists("res://common/items/weapons/hiolo-sesat-dukun.png"))

func test_dukunSpecialIsSummonOfThree():
	var skills=GlobalItems.getItem(GlobalItems.ID.DUKUN_STAFF).actionList
	assert_eq(3, skills.size())
	assert_eq(0, skills[0].manaCost, "skill 1 gratis")
	assert_true(skills[2].isSummon())
	assert_eq(attackClass.SPECIAL_SUMMON_DUKUN, skills[2].special)
	assert_eq([SummonRules.MUMMY,SummonRules.LAMPOR,SummonRules.RANDA], SummonRules.getChoices(skills[2].special))
	assert_eq("", HeroClass.getProjectilePath(HeroClass.DUKUN,"attack_special",attackClass.SUMMON), "tidak ada proyektil")
	assert_eq(0, HeroClass.getLaunchFrames(HeroClass.DUKUN,"attack_special",attackClass.SUMMON).size())

# v9.31: tidak ada menu pilih makhluk; semua skill panggil adalah gacha dari daftar skill-nya
func test_summonRollIsGachaFromSkillList():
	var rng=RandomNumberGenerator.new()
	rng.seed=7
	var dukun={}
	var alchemy={}
	for i in 300:
		var kind=SummonRules.roll(attackClass.SPECIAL_SUMMON_DUKUN,rng)
		assert_true([SummonRules.MUMMY,SummonRules.LAMPOR,SummonRules.RANDA].has(kind),kind)
		dukun[kind]=true
		var kind2=SummonRules.roll(attackClass.SPECIAL_SUMMON_ALCHEMY,rng)
		assert_true([SummonRules.GOLEM,SummonRules.MECHA].has(kind2),kind2)
		alchemy[kind2]=true
	assert_eq(3, dukun.size(), "Mumi, Lampor, dan Randa semuanya bisa keluar")
	assert_eq(2, alchemy.size(), "Golem dan Mecha dua-duanya bisa keluar")

func test_summonRollWithSingleOrUnknownList():
	var rng=RandomNumberGenerator.new()
	assert_eq(SummonRules.BANASPATI, SummonRules.roll(attackClass.SPECIAL_SUMMON_BANASPATI,rng))
	assert_eq("", SummonRules.roll("tidak_ada",rng))

func test_dukunWeaponIsHioloSesat():
	var item=GlobalItems.getItem(GlobalItems.ID.DUKUN_STAFF)
	assert_eq("Hiolo Sesat", item.name)
	assert_true(item.actionList[2].name.contains("Acak"), "nama skill menyebut acak")
	var icon=load("res://common/items/weapons/hiolo-sesat-dukun.png")
	assert_not_null(icon)
	assert_eq(16, icon.get_width(), "ikon senjata 16x16, bukan 500x500")
	assert_eq(16, icon.get_height())

func test_choosingDukunGivesStaffAndStats():
	var player=Player.new()
	player.setPlayerClass(HeroClass.KNIGHT)
	assert_true(player.chooseClass(HeroClass.DUKUN))
	assert_eq(HeroClass.DUKUN, player.getPlayerClass())
	assert_true(player.hasItem(GlobalItems.ID.DUKUN_STAFF))
	assert_eq(HeroClass.getInfo(HeroClass.DUKUN).life, player.getMaxLife())

# ---------- angka makhluk ----------

func test_dukunSummonsAttack20AndHeal47():
	for kind in [SummonRules.MUMMY,SummonRules.LAMPOR,SummonRules.RANDA]:
		var data=SummonRules.getData(kind)
		assert_eq(20, data.damage, kind)
		assert_eq(47, data.heal, kind)

func test_summonSpecialEffects():
	assert_eq(SummonRules.EFFECT_SLOW, SummonRules.getData(SummonRules.MUMMY).effect)
	assert_eq(SummonRules.EFFECT_POISON, SummonRules.getData(SummonRules.LAMPOR).effect)
	assert_true(SummonRules.isTaunt(SummonRules.RANDA))
	assert_eq(1.0, SummonRules.getData(SummonRules.RANDA).target, "Randa memancing semua serangan")
	assert_false(SummonRules.isTaunt(SummonRules.MUMMY))

func test_everySummonHasCompleteData():
	for kind in [SummonRules.MUMMY,SummonRules.LAMPOR,SummonRules.RANDA,SummonRules.BANASPATI,SummonRules.GOLEM,SummonRules.MECHA]:
		var data=SummonRules.getData(kind)
		for key in ["name","tag","desc","damage","heal","life","effect","effectChance","target","appear","attack"]:
			assert_true(data.has(key), kind+" punya "+key)
		assert_gt(data.life, 0, kind)

func test_summonDrawingHandlesEveryKind():
	var node=Node2D.new()
	node.set_script(load("res://common/fighters/summon.gd"))
	add_child_autofree(node)
	for kind in [SummonRules.MUMMY,SummonRules.LAMPOR,SummonRules.RANDA,SummonRules.BANASPATI,SummonRules.GOLEM,SummonRules.MECHA]:
		node.setKind(kind)
		node.setHealth(10,20)
		node.kick()
		assert_eq(kind, node.kind)

# ---------- Exorcist ----------

func test_exorcistSkillOneIsFreeAndMayConjureBarrier():
	var skills=GlobalItems.getItem(GlobalItems.ID.EXORCIST_PAPER).actionList
	assert_eq(0, skills[0].manaCost)
	assert_eq(attackClass.SPECIAL_BARRIER, skills[0].special)
	assert_gt(SummonRules.BARRIER_CHANCE, 0.0)
	assert_lt(SummonRules.BARRIER_CHANCE, 1.0)

func test_exorcistSummonsBanaspatiThatDrains():
	var skills=GlobalItems.getItem(GlobalItems.ID.EXORCIST_PAPER).actionList
	assert_true(skills[1].isSummon())
	assert_eq([SummonRules.BANASPATI], SummonRules.getChoices(skills[1].special))
	var data=SummonRules.getData(SummonRules.BANASPATI)
	assert_eq(SummonRules.EFFECT_DRAIN, data.effect)
	assert_gt(data.drain, 0)
	assert_eq(3, skills.size())

# ---------- Alkemis ----------

func test_alchemistCreatesGolemOrMechaAndThrowsTube():
	var skills=GlobalItems.getItem(GlobalItems.ID.ALCHEMY_FLASK).actionList
	assert_eq(3, skills.size())
	assert_true(skills[1].isSummon())
	assert_eq([SummonRules.GOLEM,SummonRules.MECHA], SummonRules.getChoices(skills[1].special))
	assert_eq(attackClass.SPECIAL_TUBE, skills[2].special)
	assert_true(skills[2].isMagic())
	assert_gt(skills[2].damage, 0)

func test_summonSkillsSkipTargetPicking():
	for itemId in [GlobalItems.ID.DUKUN_STAFF,GlobalItems.ID.EXORCIST_PAPER,GlobalItems.ID.ALCHEMY_FLASK]:
		for attack in GlobalItems.getItem(itemId).actionList:
			if attack.isSummon():
				assert_true(attack.isSelfAction())
				assert_false(attack.isMagic())
				assert_gt(attack.manaCost, 0, "memanggil memakai MP")

func test_poisonStatusExistsForSantet():
	var skills=GlobalItems.getItem(GlobalItems.ID.DUKUN_STAFF).actionList
	assert_eq(attackClass.POISON, skills[1].status)
	assert_gt(skills[1].statusChance, 0.0)
