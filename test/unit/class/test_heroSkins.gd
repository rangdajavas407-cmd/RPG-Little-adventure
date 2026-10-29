extends GutTest

var ClassSprites=load("res://common/fighters/classSprites.gd")
const ANIMATIONS=["idle","damage","attack_simple","attack_advanced","attack_special"]

func test_everyHeroSheetFileExists():
	for weaponSheets in ClassSprites.HERO_SHEETS.values():
		for data in weaponSheets.values():
			assert_true(FileAccess.file_exists(data[0]), data[0])

func test_swordStaffAndBowSkinsHaveEveryAnimation():
	for weaponId in [GlobalItems.ID.WOOD_SWORD, GlobalItems.ID.WOODEN_STAFF, GlobalItems.ID.WOODEN_BOW]:
		var frames=ClassSprites.buildForWeapon("knight", weaponId)
		for animation in ANIMATIONS:
			assert_true(frames.has_animation(animation), animation)
			assert_gt(frames.get_frame_count(animation), 0, animation)

func test_staffSkinDiffersFromSwordSkin():
	var sword=ClassSprites.buildForWeapon("knight", GlobalItems.ID.WOOD_SWORD)
	var staff=ClassSprites.buildForWeapon("knight", GlobalItems.ID.WOODEN_STAFF)
	assert_ne(sword.get_frame_texture("idle",0).atlas.resource_path, staff.get_frame_texture("idle",0).atlas.resource_path)

func test_classWeaponUsesClassSheets():
	var frames=ClassSprites.buildForWeapon("wizard", GlobalItems.ID.MAGIC_STAFF)
	assert_true(frames.get_frame_texture("idle",0).atlas.resource_path.contains("wizard-idle"))

func test_bowSkinDiffersFromSwordSkin():
	var sword=ClassSprites.buildForWeapon("knight", GlobalItems.ID.WOOD_SWORD)
	var bow=ClassSprites.buildForWeapon("knight", GlobalItems.ID.WOODEN_BOW)
	assert_ne(sword.get_frame_texture("idle",0).atlas.resource_path, bow.get_frame_texture("idle",0).atlas.resource_path)
