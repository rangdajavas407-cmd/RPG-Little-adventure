extends "res://common/class/scene.gd"

const EncounterScript=preload("res://common/areas/encounter.gd")
const EnemyClass=preload("res://common/class/enemy_class.gd")

# Musuh yang berjaga di jalan antar desa (jalan utara-selatan berpusat di x=304;
# cabang ke desa kepiting di y=48; cabang ke desa beruang di y=-80 ke arah barat).
# Jaring laba-laba di tengah jalan tetap memakai pemicu lama (spider-attack-*, y~337).
# Bhuta Kala dan hantu khusus dungeon ada di Ancient Dungeon, bukan di sini.
#
# Enam musuh jalan disebar menurut perjalanan, jarak antar musuh sekitar 140-180 piksel:
#   desa pohon -> desa kepiting : Kelelawar, Laba-laba, Ular Hijau
#   desa kepiting -> desa beruang: Celuluk, Harimau (di jalan menuju desa beruang)
#   desa beruang -> Ancient Dungeon: Hantu Leak
# Persimpangan (y=48 dan y=-80) dikosongkan supaya pemain tidak diserang saat berbelok.
const ENCOUNTERS=[
	# --- desa pohon -> desa kepiting ---
	{"key":"bat","enemy":EnemyClass.BAT,"pos":Vector2(304,480),"axis":"vertical"},
	# (jaring laba-laba ~ y=337)
	{"key":"snake","enemy":EnemyClass.SNAKE,"pos":Vector2(304,160),"axis":"vertical"},

	# --- desa kepiting -> desa beruang ---
	{"key":"imp","enemy":EnemyClass.IMP,"pos":Vector2(304,-10),"axis":"vertical"},
	# harimau menjaga lorong ke desa beruang (cabang barat, jalan mendatar)
	{"key":"tiger","enemy":EnemyClass.TIGER,"pos":Vector2(215,-80),"axis":"horizontal","size":Vector2(26,44)},

	# --- desa beruang -> Ancient Dungeon ---
	{"key":"leak","enemy":EnemyClass.LEAK,"pos":Vector2(304,-170),"axis":"vertical"}
]
const WIN_DISTANCE=52

var veraTalking=false


func _ready():
	setPlayerPath("playerAndControl")
	loadPosition()
	getPlayer().zoomUp()
	getPlayer().loadCameraLimits($cameraRef)

	_spawnEncounters()
	_buildDungeonRoadWalls()

	if GlobalGame.isVeraWithPlayer():
		getPlayer().spawnCompanion()
		_veraComments()

	_setupTabib()


# ---------- dinding tak terlihat di jalan menuju Ancient Dungeon ----------
# Peta dunia tidak punya collision di jalan utara dan bangunan dungeon, sehingga karakter
# bisa menembus bangunan dan berjalan keluar jalan. Jalan: x 288..320, y -256..-96.
# Pintu masuk (ancient-dungeon-door, y -258) tetap terbuka di tengah bangunan.
const DUNGEON_WALLS=[
	# sisi kiri & kanan jalan
	Rect2(264,-262,24,166),
	Rect2(320,-262,24,166),
	# bangunan dungeon: badan batu kiri, kanan, dan di atas lubang pintu
	Rect2(218,-380,54,118),
	Rect2(337,-380,56,118),
	Rect2(272,-380,65,42),
	# tepi bawah halaman dungeon di kiri/kanan jalan
	Rect2(218,-262,46,10),
	Rect2(344,-262,49,10)
]

func _buildDungeonRoadWalls():
	for rect in DUNGEON_WALLS:
		var body=StaticBody2D.new()
		body.collision_layer=1
		body.collision_mask=0
		var shape=CollisionShape2D.new()
		var box=RectangleShape2D.new()
		box.size=rect.size
		shape.shape=box
		body.add_child(shape)
		body.position=rect.position+rect.size/2.0
		add_child(body)


# ---------- musuh di jalan ----------

func _spawnEncounters():
	for data in ENCOUNTERS:
		if GlobalPlayer.clearedEncounters.has(data.key):
			continue
		var encounter=Area2D.new()
		encounter.set_script(EncounterScript)
		encounter.setup(data.key,data.enemy,data.axis,data.get("size",Vector2(40,26)))
		encounter.position=data.pos
		encounter.triggered.connect(_on_encounter_triggered)
		add_child(encounter)


func _on_encounter_triggered(encounter_):
	var playerPos=getPlayer().getPlayerPosition()
	var forward
	if encounter_.axis=="vertical":
		# pemain dari selatan -> menang berarti lewat ke utara
		var fromSouth=playerPos.y>encounter_.position.y
		forward=Vector2(0,-WIN_DISTANCE if fromSouth else WIN_DISTANCE)
		GlobalPlayer.battleWinPosition=Vector2(encounter_.position.x,encounter_.position.y+forward.y)
		GlobalPlayer.battleLosePosition=Vector2(encounter_.position.x,encounter_.position.y-forward.y)
	else:
		var fromWest=playerPos.x<encounter_.position.x
		forward=Vector2(WIN_DISTANCE if fromWest else -WIN_DISTANCE,0)
		GlobalPlayer.battleWinPosition=Vector2(encounter_.position.x+forward.x,encounter_.position.y)
		GlobalPlayer.battleLosePosition=Vector2(encounter_.position.x-forward.x,encounter_.position.y)
	GlobalPlayer.battleEnemy=encounter_.enemyId
	GlobalPlayer.battleEncounterKey=encounter_.key
	GlobalPlayer.battleReturnScene=GlobalPlayer.DEFAULT_BATTLE_RETURN
	GlobalPlayer.savePosition(playerPos)
	SceneTransition.change_scene("res://screens/macro-map/spiderFight.tscn")


# ---------- v7: Pak Tabib di jalan ----------
# Tabib berjalan di belakang Ranbyus (non-petarung). Setelah Kepala Desa Beruang memberi tahu letak Buah Suwarga,
# Tabib berhenti di JALAN MASUK menuju dungeon (bukan di depan gerbang dungeon) dan menunggu di sana.
# Ubah TABIB_WAIT_POS kalau posisinya menutupi jalan; ROAD_TRIGGER_POS = garis yang memicu adegan berhenti.
const TABIB_WAIT_POS=Vector2(292,-120)
const ROAD_TRIGGER_POS=Vector2(304,-100)
const ROAD_TRIGGER_SIZE=Vector2(44,6)

var waitingTabib=null
var roadSceneStarted=false


func _setupTabib():
	if GlobalGame.getStoryStage()!=GlobalGame.STAGE_MEDICINE:
		return
	if GlobalGame.isTabibFollowing():
		getPlayer().spawnTabib()
		if GlobalGame.getTabibQuest()==GlobalGame.TQ_CHIEF:
			_makeRoadTrigger()
	elif GlobalGame.getTabibQuest()==GlobalGame.TQ_WAIT:
		_spawnWaitingTabib()


func _makeRoadTrigger():
	var area=Area2D.new()
	var shape=CollisionShape2D.new()
	var rect=RectangleShape2D.new()
	rect.size=ROAD_TRIGGER_SIZE
	shape.shape=rect
	area.add_child(shape)
	area.position=ROAD_TRIGGER_POS
	add_child(area)
	area.body_entered.connect(_on_roadTrigger_entered)


func _on_roadTrigger_entered(body_):
	if roadSceneStarted or !body_.is_in_group("Player"):
		return
	if GlobalGame.getTabibQuest()!=GlobalGame.TQ_CHIEF:
		return
	roadSceneStarted=true
	_playRoadScene()


func _spawnWaitingTabib():
	if waitingTabib!=null:
		return
	waitingTabib=load("res://screens/tree-village/assets/tabib.tscn").instantiate()
	add_child(waitingTabib)
	waitingTabib.position=TABIB_WAIT_POS
	waitingTabib.talk.connect(_on_waitingTabib_talk)


# Tabib berjalan mendahului ke tempat menunggu, Ranbyus menyusul, lalu Tabib berpamitan dan tidak ikut masuk
func _playRoadScene():
	getPlayer().disableNavigation()
	var follower=getPlayer().tabibFollower
	if follower!=null and is_instance_valid(follower):
		var walk=follower.walkTo(TABIB_WAIT_POS+Vector2(0,-2),1.7)
		await walk.finished
	await cs_move_hero(TABIB_WAIT_POS+Vector2(20,16),1.1)
	await cs_talk(GlobalGame.TRAD_TABIB_ROAD)
	getPlayer().removeTabib()
	GlobalGame.setTabibQuest(GlobalGame.TQ_WAIT)
	_spawnWaitingTabib()
	notify(GlobalGame.getTraductionById(GlobalGame.TRAD_TABIB_ROAD_TIP),"story")
	getPlayer().enableNavigation()


func _on_waitingTabib_talk():
	getPlayer().disableNavigation()
	if GlobalGame.hasCure():
		# Buah Suwarga sudah di tangan: Tabib ikut pulang bersama Ranbyus
		await cs_talk(GlobalGame.TRAD_TABIB_HAVE)
		var startPos=waitingTabib.global_position
		waitingTabib.queue_free()
		waitingTabib=null
		GlobalGame.setTabibQuest(GlobalGame.TQ_RETURN)
		getPlayer().spawnTabib(startPos)
		notify(GlobalGame.getTraductionById(GlobalGame.TRAD_TABIB_HAVE_JOIN),"story")
	else:
		await cs_talk(GlobalGame.TRAD_TABIB_AGAIN)
	getPlayer().enableNavigation()


# ---------- Vera berkomentar di jalan ----------

func _talk(key_):
	var dialog=load("res://common/ui/simpleDialog.tscn").instantiate()
	add_child(dialog)
	GlobalGame.addDialogByKey(dialog,key_)
	getPlayer().disableNavigation()
	dialog.start()
	await dialog.discussionFinished
	dialog.end()
	dialog.queue_free()
	getPlayer().enableNavigation()


func _veraComments():
	await get_tree().create_timer(0.6).timeout
	if GlobalScenes.getParamForSceneOr("story","vera_map_intro",0)!=1:
		GlobalScenes.saveParamForScene("story","vera_map_intro",1)
		await _talk(GlobalGame.TRAD_VERA_MAP)


# ---------- pintu ke desa ----------

func _enterVillage(scenePath_, position_):
	# musuh di jalan muncul lagi pada perjalanan berikutnya
	GlobalPlayer.clearedEncounters.clear()
	GlobalPlayer.savePosition(position_)
	SceneTransition.change_scene(scenePath_)


func _on_crabvillage_playerOpenedDoor():
	_enterVillage("res://screens/crabs-village.tscn",Vector2(79,168))


func _on_treevillage2_playerOpenedDoor():
	_enterVillage("res://screens/tree-village.tscn",Vector2(900,258))


func _on_bearvillage2_playerOpenedDoor():
	# urutan cerita: desa kepiting dulu (sampai Busur Kayu diterima), baru desa beruang
	if int(GlobalScenes.getParamForSceneOr("story","cv_bow_given",0))!=1:
		getPlayer().getPlayerBody().global_position+=Vector2(30,0)
		await _talk(GlobalGame.TRAD_BEAR_LOCKED)
		return
	_enterVillage("res://screens/bear-village.tscn",Vector2(964,427))


func _on_ancientdungeon_playerOpenedDoor():
	# Ancient Dungeon = map terakhir: gerbangnya terbuka setelah musuh desa beruang dikalahkan
	if !GlobalGame.isBearVillageCleared():
		getPlayer().getPlayerBody().global_position+=Vector2(0,30)
		await _talk(GlobalGame.TRAD_DUNGEON_LOCKED)
		return
	_enterVillage("res://screens/ancient-dungeon.tscn",Vector2(320,430))


# ---------- jaring laba-laba (pemicu lama) ----------

func _startSpiderFight(side_, win_y_, lose_y_):
	var x=getPlayer().getPlayerPosition().x
	GlobalPlayer.savePosition(getPlayer().getPlayerPosition())
	GlobalPlayer.setSide(side_)
	GlobalPlayer.battleEnemy=EnemyClass.SPIDER
	GlobalPlayer.battleEncounterKey=""
	GlobalPlayer.battleReturnScene=GlobalPlayer.DEFAULT_BATTLE_RETURN
	GlobalPlayer.battleWinPosition=Vector2(x,win_y_)
	GlobalPlayer.battleLosePosition=Vector2(x,lose_y_)
	SceneTransition.change_scene("res://screens/macro-map/spiderFight.tscn")


func _on_spiderattackdown_playerOpenedDoor():
	_startSpiderFight("DOWN",260,420)


func _on_spiderattackupa_playerOpenedDoor():
	_startSpiderFight("UP",420,260)
