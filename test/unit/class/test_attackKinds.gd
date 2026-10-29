extends GutTest

var HeroClass=load("res://common/class/hero_class.gd")

func _kinds(itemId_):
	return GlobalItems.getItem(itemId_).actionList.map(func(a): return a.kind)

func test_woodSwordIsPhysicalOnly():
	for kind in _kinds(GlobalItems.ID.WOOD_SWORD):
		assert_eq("physical", kind, "Pedang Kayu hanya serangan fisik")

func test_woodenStaffHasOnePhysicalSwingAndRestMagic():
	var attacks=GlobalItems.getItem(GlobalItems.ID.WOODEN_STAFF).actionList
	assert_eq("Ayunan Tongkat", attacks[0].name)
	assert_eq("physical", attacks[0].kind)
	assert_eq(0, attacks[0].manaCost, "ayunan tidak memakai MP")
	assert_gt(attacks.size(), 1)
	for i in range(1, attacks.size()):
		assert_eq("magic", attacks[i].kind)
		assert_gt(attacks[i].manaCost, 0, "sihir memakai MP")

func test_bowIsRangedAndStaffsAreMagic():
	for kind in _kinds(GlobalItems.ID.HUNTER_BOW):
		assert_eq("ranged", kind)
	for kind in _kinds(GlobalItems.ID.MAGIC_STAFF):
		assert_eq("magic", kind)

func test_physicalAttackFiresNoProjectile():
	assert_eq("", HeroClass.getProjectilePath("wizard", "attack_simple", "physical"))
	assert_eq(0, HeroClass.getLaunchFrames("wizard", "attack_simple", "physical").size())

func test_knightMagicUsesVeraBolt():
	assert_true(HeroClass.getProjectilePath("knight", "attack_simple", "magic").ends_with("projectile-vera.png"))
	assert_gt(HeroClass.getLaunchFrames("knight", "attack_simple", "magic").size(), 0)

func test_casterKeepsOwnProjectileForMagic():
	assert_true(HeroClass.getProjectilePath("exorcist", "attack_simple", "magic").ends_with("projectile-holy.png"))

func test_everyProjectileFileExists():
	for class_ in HeroClass.ORDER:
		for kind in ["magic","ranged"]:
			for anim in ["attack_simple","attack_special"]:
				var path=HeroClass.getProjectilePath(class_, anim, kind)
				assert_true(FileAccess.file_exists(path), path)

func test_walkingRestoresMana():
	var Player=load("res://common/singletons/globalPlayer.gd")
	var player=Player.new()
	player.setPlayerClass("wizard")
	player.setMana(10)
	player.addMana(1)
	assert_eq(11, player.getMana())
