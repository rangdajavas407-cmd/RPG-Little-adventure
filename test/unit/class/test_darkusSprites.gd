extends GutTest

# v9.18: ukuran sheet Darkus harus cocok dengan konstanta pemotongnya (darkusCutsceneSprites.gd).
const DarkusSprites=preload("res://screens/ancient-dungeon/darkus/darkusCutsceneSprites.gd")

func test_walkAndBoundSheetsMatchCell():
	var walk=load(DarkusSprites.WALK_SHEET)
	var bound=load(DarkusSprites.BOUND_SHEET)
	assert_eq(walk.get_width(),DarkusSprites.CELL_W*8)
	assert_eq(walk.get_height(),DarkusSprites.CELL_H)
	assert_eq(bound.get_width(),DarkusSprites.CELL_W*10)
	assert_eq(bound.get_height(),DarkusSprites.CELL_H)

func test_castSheetHasNineFrames():
	var cast=load(DarkusSprites.CAST_SHEET)
	assert_eq(cast.get_width(),DarkusSprites.CAST_W*DarkusSprites.CAST_FRAMES)
	assert_eq(cast.get_height(),DarkusSprites.CAST_H)

func test_walkNpcSheetIsEightFrames():
	var npc=load("res://screens/ancient-dungeon/darkus/darkus-walk-npc.png")
	assert_eq(npc.get_width(),47*8)
	assert_eq(npc.get_height(),46)
