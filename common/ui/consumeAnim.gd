extends CanvasLayer

# Animasi singkat saat memakai item: minum Ramuan HP atau makan Bika Ambon.
# Dipakai dari HUD (menu inventaris), pertarungan, dan cutscene.
#   var anim=ConsumeAnim.new(); anim.setup(itemId, GlobalPlayer.lastUseResult)
#   add_child(anim); await anim.finished

signal finished

const DefaultTheme=preload("res://common/themes/default.tres")
const GHOST=[
	preload("res://common/ui/consume/ghost-1.png"),
	preload("res://common/ui/consume/ghost-2.png"),
	preload("res://common/ui/consume/ghost-3.png"),
	preload("res://common/ui/consume/ghost-4.png"),
	preload("res://common/ui/consume/ghost-5.png"),
	preload("res://common/ui/consume/ghost-6.png")
]
# 5 pose makan (hantu memegang ransum -> membuka -> menggigit -> mengunyah -> puas)
const EAT=[
	preload("res://common/ui/consume/eat-1.png"),
	preload("res://common/ui/consume/eat-2.png"),
	preload("res://common/ui/consume/eat-3.png"),
	preload("res://common/ui/consume/eat-4.png"),
	preload("res://common/ui/consume/eat-5.png")
]
const POTION=preload("res://common/items/magicpotion/hp-potion-big.png")
const MANA_POTION=preload("res://common/items/magicpotion/mana-potion-big.png")

const GHOST_POS=Vector2(112,98)
const COLOR_HP=Color(0.45,1,0.55)
const COLOR_MP=Color(0.45,0.7,1)
const COLOR_BUFF=Color(1,0.7,0.3)
const COLOR_OUTLINE=Color(0.13,0.125,0.2)

var itemId=-1
var result={}

var dim
var ghost
var food
var root


func setup(itemId_,result_):
	itemId=itemId_
	result=result_


func _ready():
	layer=120
	process_mode=Node.PROCESS_MODE_ALWAYS
	root=Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter=Control.MOUSE_FILTER_STOP # blokir tombol selama animasi
	add_child(root)

	dim=ColorRect.new()
	dim.color=Color(0.05,0.04,0.1,0.0)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter=Control.MOUSE_FILTER_IGNORE
	root.add_child(dim)

	ghost=Sprite2D.new()
	ghost.texture=GHOST[0]
	ghost.position=GHOST_POS
	ghost.scale=Vector2(0.9,0.9)
	ghost.modulate.a=0.0
	root.add_child(ghost)

	await _play()
	emit_signal("finished")
	queue_free()


# gambar ramuan sesuai item yang diminum
func _potionTexture():
	if itemId==GlobalItems.ID.MANA_POTION:
		return MANA_POTION
	if itemId==GlobalItems.ID.JAMU_OJO_LALI:
		return GlobalItems.getItem(itemId).getTexture()
	return POTION

# ikon kecil (22px) diperbesar supaya sebesar botol ramuan besar saat diminum
func _potionScale():
	var tex=_potionTexture()
	return float(POTION.get_height())/float(tex.get_height())


func _isFood():
	return GlobalItems.getItem(itemId).type==item_class.TYPE.FOOD


func _wait(seconds_):
	return get_tree().create_timer(seconds_,true).timeout


func _pose(index_):
	ghost.texture=GHOST[index_]


func _play():
	if _isFood():
		ghost.texture=EAT[0]
	var t=create_tween()
	t.tween_property(dim,"color:a",0.62,0.25)
	t.parallel().tween_property(ghost,"modulate:a",1.0,0.25)
	await t.finished

	if _isFood():
		await _eat()
	else:
		await _drink()

	if !_isFood():
		_pose(3)
	_sparkles(GHOST_POS+Vector2(0,-8),8)
	await _showResult()
	await _wait(0.5)

	var out=create_tween()
	out.tween_property(root,"modulate:a",0.0,0.3)
	await out.finished


# ---------- minum ramuan ----------

func _drink():
	food=Sprite2D.new()
	food.texture=_potionTexture()
	var k=_potionScale()
	food.scale=Vector2(0.1,0.1)*k
	food.position=Vector2(215,98)
	root.add_child(food)

	# ramuan muncul dan melayang ke tangan
	var t=create_tween()
	t.tween_property(food,"scale",Vector2(0.55,0.55)*k,0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await t.finished
	await _wait(0.2)
	var t2=create_tween()
	t2.tween_property(food,"position",GHOST_POS+Vector2(34,-4),0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	await t2.finished

	# minum: pose minum, botol miring ke wajah
	_pose(2)
	var t3=create_tween()
	t3.tween_property(food,"rotation",deg_to_rad(-55),0.3)
	t3.parallel().tween_property(food,"position",GHOST_POS+Vector2(14,-24),0.3)
	await t3.finished

	for i in 4:
		_bubble(GHOST_POS+Vector2(16,-34))
		var gulp=create_tween()
		gulp.tween_property(ghost,"scale",Vector2(0.9,0.84),0.1)
		gulp.tween_property(ghost,"scale",Vector2(0.9,0.9),0.1)
		await _wait(0.28)

	var t4=create_tween()
	t4.tween_property(food,"modulate:a",0.0,0.25)
	await t4.finished
	food.queue_free()
	_pose(4)
	await _wait(0.25)


# ---------- makan (bika, laklak, kue putu, dst.) ----------

func _eatPose(index_):
	ghost.texture=EAT[index_]


func _eat():
	# hantu muncul memegang ransum
	_eatPose(0)
	await _wait(0.45)

	# makanan yang dimakan muncul kecil di dekat tangan lalu masuk ke mulut
	food=Sprite2D.new()
	food.texture=GlobalItems.getItem(itemId).getTexture()
	food.scale=Vector2(0.1,0.1)
	food.position=GHOST_POS+Vector2(0,14)
	root.add_child(food)
	var pop=create_tween()
	pop.tween_property(food,"scale",Vector2(1.6,1.6),0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await pop.finished

	# ransum dibuka
	_eatPose(1)
	_sparkles(GHOST_POS+Vector2(0,10),5)
	await _wait(0.5)

	# gigitan: makanan naik ke mulut dan mengecil
	_eatPose(2)
	var lift=create_tween()
	lift.tween_property(food,"position",GHOST_POS+Vector2(0,-6),0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	lift.tween_property(food,"scale",Vector2(0.2,0.2),0.25)
	await lift.finished
	food.queue_free()
	_crumbs(GHOST_POS+Vector2(-4,-4),8)

	# mengunyah: pose 3 & 4 bergantian sambil bergoyang
	for chew in 4:
		_eatPose(3 if chew%2==0 else 2)
		var c=create_tween()
		c.tween_property(ghost,"scale",Vector2(0.95,0.84),0.08)
		c.tween_property(ghost,"scale",Vector2(0.9,0.9),0.08)
		await _wait(0.2)

	# puas
	_eatPose(4)
	await _wait(0.4)


# ---------- hasil +HP / +Mana ----------

func _showResult():
	var lines=[]
	if result.get("life",0) > 0:
		lines.append(["+"+str(result.life)+" HP",COLOR_HP])
	if result.get("mana",0) > 0:
		lines.append(["+"+str(result.mana)+" MP",COLOR_MP])
	if result.get("attackBuff",0) > 0:
		lines.append(["ATK ++ "+str(result.attackBuff)+" ronde",COLOR_BUFF])
	if result.get("effectBuff",0) > 0:
		lines.append(["EFEK ++ "+str(result.effectBuff)+" ronde",COLOR_BUFF])
	if result.get("shieldBuff",0) > 0:
		lines.append(["PERISAI "+str(result.get("shieldPercent",0))+"% "+str(result.shieldBuff)+" ronde",COLOR_BUFF])
	var y=GHOST_POS.y-60
	for line in lines:
		var label=_label(line[0],line[1])
		label.position=Vector2(190,y)
		root.add_child(label)
		var t=create_tween()
		t.tween_property(label,"position:y",y-10,0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		y+=14
		await _wait(0.25)
	await _wait(0.6)


func _label(text_,color_):
	var label=Label.new()
	label.theme=DefaultTheme
	label.text=text_
	label.add_theme_color_override("font_color",color_)
	label.add_theme_color_override("font_outline_color",COLOR_OUTLINE)
	label.add_theme_constant_override("outline_size",4)
	label.add_theme_font_size_override("font_size",16)
	return label


# ---------- efek kecil ----------

func _bubble(pos_):
	var b=ColorRect.new()
	b.size=Vector2(3,3)
	b.color=Color(0.8,0.7,1.0,0.9)
	b.position=pos_+Vector2(randf_range(-6,6),0)
	root.add_child(b)
	var t=create_tween()
	t.tween_property(b,"position:y",b.position.y-18,0.6)
	t.parallel().tween_property(b,"modulate:a",0.0,0.6)
	t.tween_callback(b.queue_free)


func _crumbs(pos_,count_):
	for i in count_:
		var c=ColorRect.new()
		c.size=Vector2(2,2)
		c.color=Color(1.0,0.85,0.2) if i%2==0 else Color(0.9,0.6,0.1)
		c.position=pos_
		root.add_child(c)
		var target=pos_+Vector2(randf_range(-16,10),randf_range(8,26))
		var t=create_tween()
		t.tween_property(c,"position",target,0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		t.parallel().tween_property(c,"modulate:a",0.0,0.45).set_delay(0.15)
		t.tween_callback(c.queue_free)


func _sparkles(pos_,count_):
	for i in count_:
		var s=ColorRect.new()
		s.size=Vector2(3,3)
		s.pivot_offset=Vector2(1.5,1.5)
		s.rotation=deg_to_rad(45)
		s.color=Color(1,0.95,0.6) if i%2==0 else Color(0.8,0.7,1)
		s.position=pos_
		root.add_child(s)
		var angle=TAU*float(i)/count_
		var target=pos_+Vector2(cos(angle),sin(angle))*randf_range(28,44)
		var t=create_tween()
		t.tween_property(s,"position",target,0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		t.parallel().tween_property(s,"modulate:a",0.0,0.5).set_delay(0.2)
		t.tween_callback(s.queue_free)
