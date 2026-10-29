
extends "res://common/class/scene.gd"

# Bagian dalam Ancient Dungeon: lorong dan ruangan penuh musuh.
# Musuh yang sudah dikalahkan tidak muncul lagi.
# Tata letak lantai/dinding: tools/build_ancient_dungeon_scenes.py

const EncounterScript = preload("res://common/areas/encounter.gd")
const EnemyClass = preload("res://common/class/enemy_class.gd")
const RitualCutscene = preload("res://screens/ancient-dungeon/ritualCutscene.gd")
const PossessionCutscene = preload("res://screens/ancient-dungeon/possessionCutscene.gd")

const SCENE_PATH = "res://screens/ancient-dungeon/dungeon.tscn"
const WIN_DISTANCE = 52

# Bhuta Kala gugur -> ritual pemanggilan Satan. Kunci ini disimpan di save: selama belum menang,
# ruang bos berisi sigil menyala dan Satan (bukan Bhuta Kala lagi), mis. setelah kalah lalu kembali.
const RITUAL_KEY = "dg_ritual"
const BOSS_KEY = "dg_boss"

# Posisi tengah musuh, ukuran pemicu, dan arah lorong.
# Kunci diawali dg_ agar kekalahan tersimpan.
#
# Penyebaran: tiap jenis hantu/hewan khusus dungeon HANYA SATU (Ular Malam, Leak Bara, Pocong,
# Celuluk Es, Kuntilanak), disusun searah jalur dari pintu masuk sampai Bhuta Kala dengan jarak
# antar musuh kurang lebih sama (sekitar 230-350 piksel jalan kaki):
#
#   pintu masuk -> [Ular Malam] R1 -> [Leak Bara] lorong C2 -> [Pocong] R2
#               -> [Celuluk Es] R3 -> [Kuntilanak] lorong C4 -> Bhuta Kala (R4)
#
# Kunci baru (bukan dg_02 dst.) supaya save lama tidak salah menyembunyikan musuh.
const ENCOUNTERS = [
	# ruang besar pertama (R1): penjaga pertama, di tengah ruangan
	{"key":"dg_ular","enemy":EnemyClass.NIGHT_SNAKE,"pos":Vector2(512,1040),"axis":"vertical","size":Vector2(40,26)},

	# ruang besar pertama (R1): Zombie Warga Desa (warga yang tersesat), di sisi timur ruangan.
	# v7.2: dulu berdiri di baris ubin paling bawah (y=1090), sehingga setelah menang dari arah utara
	# pemain dipindahkan 52 piksel ke bawah = masuk ke dalam dinding dan macet. Sekarang di tengah
	# tinggi ruangan (lantai R1: y 896..1119), jadi kedua sisi (utara/selatan) aman.
	{"key":"dg_zombie","enemy":EnemyClass.ZOMBIE,"pos":Vector2(736,1008),"axis":"vertical","size":Vector2(40,26)},

	# lorong barat (C2): Leak menghadang di lorong sempit (tidak bisa dilewati)
	{"key":"dg_leak","enemy":EnemyClass.FLAME_LEAK,"pos":Vector2(320,820),"axis":"vertical","size":Vector2(64,26)},

	# ruang kedua (R2): Pocong di tengah ruangan
	{"key":"dg_poci","enemy":EnemyClass.POCI,"pos":Vector2(448,648),"axis":"vertical","size":Vector2(40,26)},

	# ruang ketiga (R3): Celuluk Es di tengah ruangan
	{"key":"dg_celuluk","enemy":EnemyClass.FROST_IMP,"pos":Vector2(768,528),"axis":"vertical","size":Vector2(40,26)},

	# lorong terakhir (C4): Kuntilanak menjaga jalan ke ruang bos
	{"key":"dg_kunti","enemy":EnemyClass.KUNTI,"pos":Vector2(864,304),"axis":"vertical","size":Vector2(64,26)},

	# Bhuta Kala (mini boss) di ruang terakhir (R4)
	{"key":"dg_boss","enemy":EnemyClass.BOSS,"pos":Vector2(864,76),"axis":"vertical","size":Vector2(120,30)}
]


# v7.2: petak lantai (x0,y0,x1,y1 inklusif, satuan ubin 32 px). HARUS sama dengan AREAS di
# tools/build_ancient_dungeon_scenes.py. Dipakai untuk memastikan posisi pemain setelah
# pertarungan tidak pernah jatuh di dalam dinding.
const TILE = 32
const PLAYER_MARGIN = 10
const FLOOR_AREAS = [
	Vector4i(13, 40, 22, 45),   # R0
	Vector4i(17, 35, 18, 39),   # C1
	Vector4i(8, 28, 27, 34),    # R1
	Vector4i(9, 23, 10, 27),    # C2
	Vector4i(3, 16, 16, 22),    # R2
	Vector4i(17, 18, 20, 19),   # C3
	Vector4i(21, 12, 32, 22),   # R3
	Vector4i(26, 7, 27, 11),    # C4
	Vector4i(18, 1, 35, 6)      # R4
]

var ritual = null
var ritualEncounter = null


func _ready():
	# Darkus sudah kalah -> epilog sinematik (Darkus terbaring, disadarkan, lalu mencari Buah Suwarga).
	# Flag "epic_ending_played" disimpan epicStage hanya saat epilog selesai / dilewati. Flag lama
	# "final_ending_started" tidak dipakai lagi di sini: save lama bisa menyimpannya padahal epilog tidak pernah main.
	if GlobalScenes.getParamForSceneOr("story", "epic_ending_played", false) == false and GlobalScenes.getParamForSceneOr("dungeon", "dg_boss", false) == true:
		call_deferred("_launch_final_story_cutscene")
	setPlayerPath("sorted/playerAndControl")
	loadPosition()
	getPlayer().loadCameraLimits($cameraRef)
	spawnHealShrine(Vector2(612,1384),80,30)   # altar penyembuh di pintu masuk dungeon: maks HP 80 / MP 30
	_spawnEncounters()
	_setupRitual()


func _spawnEncounters():
	for data in ENCOUNTERS:
		if GlobalScenes.getParamForSceneOr("dungeon", data.key, false) == true:
			continue

		var enemyId = data.enemy
		# ritual sudah dimulai: yang menunggu di ruang bos adalah Satan
		if data.key == BOSS_KEY and _ritualStarted():
			enemyId = EnemyClass.SATAN

		var encounter = Area2D.new()
		encounter.set_script(EncounterScript)
		encounter.setup(data.key, enemyId, data.axis, data.size)
		encounter.position = data.pos
		encounter.triggered.connect(_on_encounter_triggered)
		add_child(encounter)
		if data.key == BOSS_KEY:
			ritualEncounter = encounter


func _ritualStarted():
	return GlobalScenes.getParamForSceneOr("dungeon", RITUAL_KEY, false) == true \
		and GlobalScenes.getParamForSceneOr("dungeon", BOSS_KEY, false) != true


# Sigil dan perlengkapan ritual dipasang kalau ritual sudah dimulai. Kalau baru saja keluar dari
# pertempuran Bhuta Kala, adegan ritual diputar lalu pemain dipaksa melawan Satan.
func _setupRitual():
	if !_ritualStarted():
		GlobalPlayer.ritualCutscenePending = false
		return
	ritual = RitualCutscene.new()
	add_child(ritual)
	ritual.setup(self)

	# Setelah Satan kalah, jangan masuk battle lanjutan di arena. Mainkan cutscene
	# ritual/perasukan di dungeon, lalu mulai encounter baru melawan Darkus yang dirasuki.
	if GlobalPlayer.possessionCutscenePending:
		GlobalPlayer.possessionCutscenePending = false
		ritual.buildSet(false)
		if ritualEncounter != null:
			ritualEncounter.visible = false
			ritualEncounter.set_deferred("monitoring", false)
			ritualEncounter.set_deferred("monitorable", false)
		var possession = PossessionCutscene.new()
		add_child(possession)
		possession.setup(self)
		possession.finished.connect(_on_possession_cutscene_finished)
		possession.play()
		return

	if !GlobalPlayer.ritualCutscenePending:
		ritual.buildSet(false)
		return

	GlobalPlayer.ritualCutscenePending = false
	ritual.buildSet(true)
	# Satan yang menunggu disembunyikan dulu; di adegan dia bangkit dari sigil
	if ritualEncounter != null:
		ritualEncounter.visible = false
	ritual.finished.connect(_on_ritual_finished)
	ritual.play()


func _on_ritual_finished():
	if ritualEncounter != null and is_instance_valid(ritualEncounter):
		_on_encounter_triggered(ritualEncounter)

func _on_possession_cutscene_finished():
	# Mulai battle baru setelah layar fade-out: musuh sekarang Darkus (Dirasuki Satan).
	GlobalPlayer.battleEnemy = EnemyClass.DARKUS_BOSS
	GlobalPlayer.battleEncounterKey = BOSS_KEY
	GlobalPlayer.battleReturnScene = SCENE_PATH
	GlobalPlayer.battleWinPosition = Vector2(864, 128)
	GlobalPlayer.battleLosePosition = Vector2(864, 176)
	GlobalPlayer.savePosition(Vector2(864, 152))
	SceneTransition.change_scene("res://screens/macro-map/spiderFight.tscn")


func _tileIsFloor(tile_):
	for a in FLOOR_AREAS:
		if tile_.x >= a.x and tile_.x <= a.z and tile_.y >= a.y and tile_.y <= a.w:
			return true
	return false


# titik aman = keempat sudut "badan" pemain (margin PLAYER_MARGIN) berada di ubin lantai
func _isSafeSpot(pos_):
	for dx in [-PLAYER_MARGIN, PLAYER_MARGIN]:
		for dy in [-PLAYER_MARGIN, PLAYER_MARGIN]:
			var tile = Vector2i(floori((pos_.x + dx) / TILE), floori((pos_.y + dy) / TILE))
			if !_tileIsFloor(tile):
				return false
	return true


# kalau pos_ ada di dinding / terlalu dekat dinding, geser pelan-pelan ke arah musuh (anchor_,
# yang pasti di lantai) sampai ketemu titik aman
func _fitToFloor(pos_, anchor_):
	if _isSafeSpot(pos_):
		return pos_
	for i in range(1, 21):
		var candidate = pos_.lerp(anchor_, i / 20.0)
		if _isSafeSpot(candidate):
			return candidate
	return anchor_


func _on_encounter_triggered(encounter_):
	var playerPos = getPlayer().getPlayerPosition()
	var forward

	if encounter_.axis == "vertical":
		var fromSouth = playerPos.y > encounter_.position.y
		forward = Vector2(0, -WIN_DISTANCE if fromSouth else WIN_DISTANCE)

		GlobalPlayer.battleWinPosition = Vector2(
			encounter_.position.x,
			encounter_.position.y + forward.y
		)
		GlobalPlayer.battleLosePosition = Vector2(
			encounter_.position.x,
			encounter_.position.y - forward.y
		)
	else:
		var fromWest = playerPos.x < encounter_.position.x
		forward = Vector2(
			WIN_DISTANCE if fromWest else -WIN_DISTANCE,
			0
		)

		GlobalPlayer.battleWinPosition = Vector2(
			encounter_.position.x + forward.x,
			encounter_.position.y
		)
		GlobalPlayer.battleLosePosition = Vector2(
			encounter_.position.x - forward.x,
			encounter_.position.y
		)

	# v7.2: pengaman, posisi setelah menang / kalah / kabur tidak boleh di dalam dinding
	GlobalPlayer.battleWinPosition = _fitToFloor(GlobalPlayer.battleWinPosition, encounter_.position)
	GlobalPlayer.battleLosePosition = _fitToFloor(GlobalPlayer.battleLosePosition, encounter_.position)

	GlobalPlayer.battleEnemy = encounter_.enemyId
	GlobalPlayer.battleEncounterKey = encounter_.key
	GlobalPlayer.battleReturnScene = SCENE_PATH
	GlobalPlayer.savePosition(playerPos)

	SceneTransition.change_scene(
		"res://screens/macro-map/spiderFight.tscn"
	)


func _on_exit_playerOpenedDoor():
	# Kembali ke halaman depan, tepat di bawah gerbang
	GlobalPlayer.savePosition(Vector2(320, 182))
	SceneTransition.change_scene("res://screens/ancient-dungeon.tscn")


func _launch_final_story_cutscene():
	# epilog sinematik baru (screens/ending/epic/epicEnding.gd); ESC dua kali untuk melewati.
	# v9.29: SceneTransition.change_scene() menolak panggilan selama transisi sebelumnya masih "sibuk".
	# Begitu pertarungan Darkus selesai, scene dungeon ini baru saja dimuat lewat transisi yang masih
	# memudar, jadi panggilan lama dibuang diam-diam (dan flag sudah terlanjur disimpan) = epilog tidak pernah main.
	# Sekarang menunggu transisi selesai dulu baru memanggil epilog.
	while SceneTransition.isBusy():
		await get_tree().process_frame
	await get_tree().create_timer(0.3).timeout
	SceneTransition.change_scene("res://screens/ending/epicEnding.tscn")
