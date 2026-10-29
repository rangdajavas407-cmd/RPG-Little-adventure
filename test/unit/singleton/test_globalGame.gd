extends GutTest

var Game=load("res://common/singletons/globalGame.gd")

func test_getFilteredSaveList():
	
	#Arrange
	var fileList=[
		"mika_1.save",
		"otherFile.txt",
		"other_systemFile.sh"
	]
	
	var game=Game.new()
	var filterSaveList=game.getFilteredSaveList(fileList)
	
	assert_eq(["mika_1.save"],filterSaveList,"we should have only mika_1")


# ---------- v7: alur Pak Tabib (param "tq" di GlobalScenes) ----------

func _clearStoryParams():
	for key in ["tq","stage"]:
		GlobalScenes.scenesData.erase(GlobalScenes.getKey("story",key))

func after_each():
	_clearStoryParams()

func test_tabibQuest_setAndGet():
	_clearStoryParams()
	var game=Game.new()
	game.setTabibQuest(game.TQ_HOME_DONE)
	assert_eq(game.getTabibQuest(),game.TQ_HOME_DONE,"tahap quest tersimpan")
	game.setTabibQuest(game.TQ_WAIT)
	assert_eq(game.getTabibQuest(),game.TQ_WAIT,"tahap quest bisa diubah")
	game.free()

func test_tabibQuest_orderOfStages():
	var game=Game.new()
	assert_true(game.TQ_NONE<game.TQ_JOINED,"ikut sebelum periksa")
	assert_true(game.TQ_JOINED<game.TQ_HOME_DONE,"periksa sebelum ke desa kepiting")
	assert_true(game.TQ_HOME_DONE<game.TQ_GUIDED,"diantar sebelum desa beruang")
	assert_true(game.TQ_GUIDED<game.TQ_CHIEF,"desa beruang sebelum petunjuk dungeon")
	assert_true(game.TQ_CHIEF<game.TQ_WAIT,"petunjuk sebelum menunggu di jalan masuk")
	assert_true(game.TQ_WAIT<game.TQ_RETURN,"menunggu sebelum ikut pulang")
	game.free()

func test_tabibFollowing_onlyDuringMedicineStage():
	var game=Game.new()
	game.setStoryStage(game.STAGE_MEDICINE)
	for q in [game.TQ_JOINED,game.TQ_HOME_DONE,game.TQ_GUIDED,game.TQ_CHIEF,game.TQ_RETURN]:
		game.setTabibQuest(q)
		assert_true(game.isTabibFollowing(),"Tabib mengikuti pada tahap %d" % q)
	for q in [game.TQ_NONE,game.TQ_WAIT]:
		game.setTabibQuest(q)
		assert_false(game.isTabibFollowing(),"Tabib tidak mengikuti pada tahap %d" % q)
	game.setTabibQuest(game.TQ_RETURN)
	game.setStoryStage(game.STAGE_DONE)
	assert_false(game.isTabibFollowing(),"setelah tamat Tabib kembali ke desa")
	game.free()

func test_tabibDialogs_exist_andWellFormed():
	var game=Game.new()
	var keys=[
		game.TRAD_TABIB_FIRST,game.TRAD_TABIB_AGAIN,game.TRAD_TABIB_HAVE,
		game.TRAD_HOME_EXAM_1,game.TRAD_HOME_EXAM_2,game.TRAD_HOME_EXAM_3,
		game.TRAD_HOME_MOM_MED_3,game.TRAD_HOME_ADEK_GIVE_TABIB,
		game.TRAD_CRAB_GUIDE_1,game.TRAD_CRAB_GUIDE_2,game.TRAD_CRAB_GUIDE_REMIND,
		game.TRAD_CRABVILLAGE_MED,game.TRAD_CRABVILLAGE_AFTER,
		game.TRAD_CRAB_SHOP_INTRO,game.TRAD_CRAB_SHOP_INFO,game.TRAD_CRAB_ESCORT_AGAIN,
		game.TRAD_JOURNEY_1,game.TRAD_JOURNEY_2,
		game.TRAD_BEAR_ARRIVE,game.TRAD_BEAR_DOOR,game.TRAD_BEAR_CHIEF,game.TRAD_BEAR_CHIEF_LOCKED,game.TRAD_BEAR_CHIEF_OPEN,
		game.TRAD_TABIB_ROAD
	]
	for key in keys:
		assert_true(game.traductionsID.has(key),"dialog %s ada" % key)
		var pages=game.traductionsID[key]
		assert_true(pages is Array and pages.size()>0,"dialog %s tidak kosong" % key)
		for page in pages:
			assert_eq(page.size(),2,"tiap halaman = [pembicara, [baris]] (%s)" % key)
			assert_true(page[1] is Array and page[1].size()>0,"halaman punya baris (%s)" % key)
			var speaker=str(page[0])
			assert_true(speaker=="" or game.SPEAKER_KEYS.has(speaker) or speaker=="@hero","pembicara dikenal: %s (%s)" % [speaker,key])
	for tip in [game.TRAD_TABIB_JOIN_TIP,game.TRAD_HOME_EXAM_TIP,game.TRAD_BEAR_CHIEF_TIP,game.TRAD_TABIB_ROAD_TIP,game.TRAD_TABIB_HAVE_JOIN,game.TRAD_JOURNEY_CAPTION]:
		assert_true(game.traductionsID.has(tip) and game.traductionsID[tip] is String,"teks %s ada" % tip)
	game.free()
