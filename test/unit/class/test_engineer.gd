extends GutTest

const HeroClass=preload("res://common/class/hero_class.gd")
const EngineerRules=preload("res://common/class/engineer_rules.gd")
const EnemyClass=preload("res://common/class/enemy_class.gd")
const attackClass=preload("res://common/class/item/attack_class.gd")
var Player=load("res://common/singletons/globalPlayer.gd")

func test_advanceChoicesAreAssassinAndEngineer():
	assert_eq([HeroClass.ASSASSIN,HeroClass.ENGINEER], HeroClass.ADVANCE_CHOICES)
	assert_false(HeroClass.CHOICES.has(HeroClass.ENGINEER))

func test_advanceNeedsFourDungeonEnemies():
	assert_eq(["dg_ular","dg_poci","dg_leak","dg_zombie"], HeroClass.ADVANCE_KEYS)

func test_engineerWeaponIsSciFiWrench():
	assert_eq(GlobalItems.ID.SCIFI_WRENCH, HeroClass.getWeaponId(HeroClass.ENGINEER))
	assert_eq("Sci-Fi Wrench", GlobalItems.getItem(GlobalItems.ID.SCIFI_WRENCH).name)

func test_everyClassWeaponHasThreeSkills():
	for class_ in HeroClass.ORDER:
		var weapon=GlobalItems.getItem(HeroClass.getWeaponId(class_))
		assert_eq(3, weapon.actionList.size(), class_+" punya 3 skill")

func test_wrenchSkills():
	var skills=GlobalItems.getItem(GlobalItems.ID.SCIFI_WRENCH).actionList
	assert_eq("Pukulan Kunci", skills[0].name)
	assert_eq("Teknik Mesin", skills[1].name)
	assert_true(skills[1].isGadget())
	assert_eq(attackClass.CONFUSE, skills[2].status)
	assert_gt(skills[2].statusChance, 0.0)
	assert_lt(skills[2].statusChance, 1.0)
	assert_eq("", HeroClass.getProjectilePath(HeroClass.ENGINEER, "attack_advanced", attackClass.GADGET))

func test_assassinUltimateCanCauseBleeding():
	var skills=GlobalItems.getItem(GlobalItems.ID.SHADOW_DAGGER).actionList
	assert_eq(attackClass.BLEED, skills[2].status)
	assert_gt(skills[2].statusChance, 0.0)

func test_assassinV8IsStrongerThanOtherUltimates():
	var skills=GlobalItems.getItem(GlobalItems.ID.SHADOW_DAGGER).actionList
	assert_eq(14, skills[0].damage)
	assert_eq(30, skills[1].damage)
	assert_eq(85, skills[2].damage)
	assert_gte(skills[2].statusChance, 0.8)
	assert_eq(0.30, HeroClass.getCritBonus(HeroClass.ASSASSIN))
	var knightUltimate=GlobalItems.getItem(GlobalItems.ID.KNIGHT_SWORD).actionList[2]
	assert_gt(skills[2].damage, knightUltimate.damage)

func test_tebasKilatGivesDodgeStance():
	var skills=GlobalItems.getItem(GlobalItems.ID.SHADOW_DAGGER).actionList
	assert_false(skills[0].hasDodgeStance())
	assert_true(skills[1].hasDodgeStance(), "skill 2 Asasin = Siaga Bayangan")
	assert_false(skills[2].hasDodgeStance())
	assert_eq(attackClass.DODGE, skills[1].stance)
	# senjata class lain tidak punya sikap elak
	for attack in GlobalItems.getItem(GlobalItems.ID.KNIGHT_SWORD).actionList:
		assert_false(attack.hasDodgeStance())

func test_satanHasDyingSpeechAndDarkusEntersScene():
	var satan=EnemyClass.getEnemy(EnemyClass.SATAN)
	assert_true(satan.has("dyingText"))
	assert_true(satan.has("lingerText"))
	assert_eq(EnemyClass.DARKUS_BOSS, satan.possess)
	var darkus=EnemyClass.getEnemy(EnemyClass.DARKUS_BOSS)
	for key in ["enterText","enterSpeech","possessSpeech","preText","preSprite"]:
		assert_true(darkus.has(key), key)

func test_wolfAndTigerCanCauseBleeding():
	assert_gt(EnemyClass.getEnemy(EnemyClass.WOLF).bleed, 0.0)
	assert_gt(EnemyClass.getEnemy(EnemyClass.TIGER).bleed, 0.0)

func test_boxDamageRanges():
	var rng=RandomNumberGenerator.new()
	rng.seed=7
	for i in 300:
		assert_between(EngineerRules.rollBoxDamage(rng), 17, 25)
		assert_between(EngineerRules.rollSelfDamage(rng), 1, 3)

func test_turretIsFragileAndHitsLikeVera():
	assert_eq(35, EngineerRules.TURRET_HP)
	assert_eq(6, EngineerRules.TURRET_DAMAGE_MIN)
	assert_eq(9, EngineerRules.TURRET_DAMAGE_MAX)

func test_chooseAdvanceClassGivesWeapon():
	var player=Player.new()
	player.setPlayerClass(HeroClass.NOVICE)
	player.chooseClass(HeroClass.KNIGHT)
	assert_false(player.hasAdvancedClass())
	assert_true(player.chooseClass(HeroClass.ENGINEER))
	assert_true(player.hasAdvancedClass())
	assert_eq(GlobalItems.ID.SCIFI_WRENCH, player.getActiveWeaponId())

func test_zombieAndSheetsExist():
	assert_eq("Zombie Warga Desa", EnemyClass.getEnemy(EnemyClass.ZOMBIE).name)
	for part in ["idle","attack","damage","die"]:
		assert_true(FileAccess.file_exists("res://common/fighters/enemies/zombie-"+part+".png"), part)
	for part in ["idle","damage","attack-simple","attack-advanced","attack-special"]:
		assert_true(FileAccess.file_exists("res://common/fighters/classes/engineer-"+part+".png"), part)
