extends GutTest

# v7.2: pemain tidak boleh macet di dinding setelah menang / kalah / kabur dari musuh dungeon
# (bug Zombie Warga Desa: posisi menang jatuh di dalam dinding bawah ruang pertama).

var DungeonScript=load("res://screens/ancient-dungeon/dungeon.gd")
var dungeon=null

func before_each():
	dungeon=autofree(DungeonScript.new())

func _encounter(key_):
	for data in DungeonScript.ENCOUNTERS:
		if data.key==key_:
			return data
	return null

# posisi menang/kalah seperti yang dihitung _on_encounter_triggered, dari sisi selatan atau utara
func _spots(data_, fromSouth_):
	var step=-DungeonScript.WIN_DISTANCE if fromSouth_ else DungeonScript.WIN_DISTANCE
	return [
		Vector2(data_.pos.x, data_.pos.y+step),
		Vector2(data_.pos.x, data_.pos.y-step)
	]

func test_zombieSpotsAreSafeFromBothSides():
	var zombie=_encounter("dg_zombie")
	assert_not_null(zombie)
	assert_true(dungeon._isSafeSpot(zombie.pos), "zombie berdiri di lantai")
	for fromSouth in [true, false]:
		for spot in _spots(zombie, fromSouth):
			assert_true(dungeon._isSafeSpot(spot), "posisi sesudah pertarungan zombie tidak di dinding: %s" % spot)

func test_wallPositionIsDetected():
	# di bawah lantai R1 (y>=1120) adalah dinding
	assert_false(dungeon._isSafeSpot(Vector2(610,1142)))
	assert_true(dungeon._isSafeSpot(Vector2(610,1000)))

func test_fitToFloorRescuesPositionInsideWall():
	var anchor=Vector2(610,1090)
	var fitted=dungeon._fitToFloor(Vector2(610,1142), anchor)
	assert_true(dungeon._isSafeSpot(fitted), "posisi di dinding digeser ke lantai: %s" % fitted)

func test_everyEncounterEndsOnFloor():
	for data in DungeonScript.ENCOUNTERS:
		assert_true(dungeon._isSafeSpot(data.pos), "%s berdiri di lantai" % data.key)
		for fromSouth in [true, false]:
			for spot in _spots(data, fromSouth):
				var fitted=dungeon._fitToFloor(spot, data.pos)
				assert_true(dungeon._isSafeSpot(fitted), "%s -> %s aman" % [data.key, fitted])
