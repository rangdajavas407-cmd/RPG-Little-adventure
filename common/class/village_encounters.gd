extends RefCounted

# Musuh yang berdiri di dalam desa (desa kepiting & desa beruang). Menyentuhnya memulai
# pertarungan lalu kembali ke desa. Kunci diawali "cv_" (desa kepiting) / "bv_" (desa beruang)
# agar kekalahannya tersimpan di file save (lihat spiderFight.gd).

const EncounterScript=preload("res://common/areas/encounter.gd")

var scene=null
var returnScene=""
var spawned={}


func _init(scene_, returnScene_):
	scene=scene_
	returnScene=returnScene_


# list_: [{"key","enemy","pos"}]. Musuh yang sudah kalah pada kunjungan ini tidak dimunculkan lagi.
func spawn(list_):
	for data in list_:
		if GlobalPlayer.clearedEncounters.has(data.key):
			continue
		spawnOne(data)


func spawnOne(data_):
	var encounter=Area2D.new()
	encounter.set_script(EncounterScript)
	encounter.setup(data_.key,data_.enemy,"vertical",data_.get("size",Vector2(44,28)))
	encounter.position=data_.pos
	encounter.triggered.connect(_on_triggered)
	scene.add_child(encounter)
	spawned[data_.key]=encounter
	return encounter


func isDefeated(key_):
	return GlobalScenes.getParamForSceneOr("village",key_,false)==true


func allDefeated(list_):
	for data in list_:
		if !isDefeated(data.key):
			return false
	return true


func countDefeated(list_):
	var n=0
	for data in list_:
		if isDefeated(data.key):
			n+=1
	return n


func _on_triggered(encounter_):
	startBattle(encounter_.key, encounter_.enemyId, encounter_.global_position)


# mulai pertarungan (dari sentuhan musuh, atau dari adegan musuh yang menghampiri pemain)
func startBattle(key_, enemyId_, enemyPos_):
	var playerPos=scene.getPlayer().getPlayerPosition()
	# setelah bertarung pemain muncul sedikit menjauh dari musuh agar tidak langsung memicu lagi
	var away=(playerPos-enemyPos_)
	if away.length()<1.0:
		away=Vector2(0,1)
	var back=playerPos+away.normalized()*44.0
	GlobalPlayer.battleEnemy=enemyId_
	GlobalPlayer.battleEncounterKey=key_
	GlobalPlayer.battleReturnScene=returnScene
	GlobalPlayer.battleWinPosition=back
	GlobalPlayer.battleLosePosition=back
	GlobalPlayer.savePosition(playerPos)
	SceneTransition.change_scene("res://screens/macro-map/spiderFight.tscn")
