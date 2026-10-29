extends GutTest

var WeaponFx=load("res://common/fighters/weaponFx.gd")
var HeroClass=load("res://common/class/hero_class.gd")

var fx=null

func before_each():
	fx=WeaponFx.new()

func test_everyWeaponHasItsOwnStyle():
	assert_eq("wood_sword", fx.styleOf(GlobalItems.ID.WOOD_SWORD,"physical"))
	assert_eq("knight", fx.styleOf(GlobalItems.ID.KNIGHT_SWORD,"physical"))
	assert_eq("dagger", fx.styleOf(GlobalItems.ID.SHADOW_DAGGER,"physical"))
	assert_eq("wrench", fx.styleOf(GlobalItems.ID.SCIFI_WRENCH,"physical"))
	assert_eq("wizard", fx.styleOf(GlobalItems.ID.MAGIC_STAFF,"magic"))
	assert_eq("alchemy", fx.styleOf(GlobalItems.ID.ALCHEMY_FLASK,"magic"))
	assert_eq("holy", fx.styleOf(GlobalItems.ID.EXORCIST_PAPER,"magic"))
	assert_eq("sage", fx.styleOf(GlobalItems.ID.ORB_SUCI,"magic"))
	assert_eq("dukun", fx.styleOf(GlobalItems.ID.DUKUN_STAFF,"magic"))

func test_bowsUseBowStyleForRangedAttacks():
	assert_eq("bow", fx.styleOf(GlobalItems.ID.HUNTER_BOW,"ranged"))
	assert_eq("bow", fx.styleOf(GlobalItems.ID.WOODEN_BOW,"ranged"))

func test_woodenStaffDependsOnAttackKind():
	assert_eq("staff_hit", fx.styleOf(GlobalItems.ID.WOODEN_STAFF,"physical"))
	assert_eq("vera", fx.styleOf(GlobalItems.ID.WOODEN_STAFF,"magic"))

func test_gadgetSkillHasItsOwnStyle():
	assert_eq("gadget", fx.styleOf(GlobalItems.ID.SCIFI_WRENCH,"gadget"))

func test_levelFollowsAnimationName():
	assert_eq(1, fx.level("attack_simple"))
	assert_eq(2, fx.level("attack_advanced"))
	assert_eq(3, fx.level("attack_special"))

func test_everyStyleHasTwoColors():
	for weaponId in [GlobalItems.ID.WOOD_SWORD, GlobalItems.ID.KNIGHT_SWORD, GlobalItems.ID.SHADOW_DAGGER,
			GlobalItems.ID.SCIFI_WRENCH, GlobalItems.ID.MAGIC_STAFF, GlobalItems.ID.ALCHEMY_FLASK,
			GlobalItems.ID.EXORCIST_PAPER, GlobalItems.ID.ORB_SUCI, GlobalItems.ID.WOODEN_STAFF, GlobalItems.ID.DUKUN_STAFF]:
		for kind in ["physical","magic","ranged","gadget","summon"]:
			for lv in [1,2,3]:
				var c=fx.colors(fx.styleOf(weaponId,kind),lv)
				assert_eq(2, c.size())

func test_specialAttackChangesColorForFlamingStyles():
	for style in ["wood_sword","knight","wizard","alchemy","bow","dukun"]:
		assert_ne(fx.colors(style,1)[0], fx.colors(style,3)[0], style)

func test_hitFramesExistInEveryAttackSheet():
	# jumlah frame sheet serang: simple 5, advanced 7, special 7
	var counts={"attack_simple":5,"attack_advanced":7,"attack_special":7}
	for animation in counts.keys():
		var hit=fx.HIT_FRAME[animation]
		assert_gt(hit, 0, animation)
		assert_lt(hit, counts[animation], animation)

func test_lungeGrowsWithAttackLevel():
	assert_lt(fx.LUNGE[1], fx.LUNGE[2])
	assert_lt(fx.LUNGE[2], fx.LUNGE[3])
