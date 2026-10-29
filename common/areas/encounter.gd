extends Area2D

# Musuh yang berdiri di jalan peta. Pemain menyentuhnya -> pertarungan dimulai.
# Dibuat lewat kode oleh macro-map.gd:
#   var e=Area2D.new(); e.set_script(EncounterScript); e.setup(key, enemyId, axis); add_child(e)

signal triggered(encounter_)

const EnemySprites=preload("res://common/fighters/enemySprites.gd")
const EnemyClass=preload("res://common/class/enemy_class.gd")

var key=""
var enemyId="bat"
# arah jalan: "vertical" (utara-selatan) atau "horizontal" (barat-timur)
var axis="vertical"
var sprite=null
# ukuran area pemicu; di lorong sempit diperlebar sepanjang lorong agar tidak bisa dilewati
var triggerSize=Vector2(40,26)


func setup(key_, enemyId_, axis_="vertical", triggerSize_=Vector2(40,26)):
	triggerSize=triggerSize_
	key=key_
	enemyId=enemyId_
	axis=axis_


func _ready():
	var shape=CollisionShape2D.new()
	var rect=RectangleShape2D.new()
	rect.size=triggerSize
	shape.shape=rect
	add_child(shape)

	# satu musuh, atau beberapa musuh yang berdiri berdampingan (grup, mis. dua bandit)
	var members=EnemyClass.getGroup(enemyId)
	var label_text=EnemyClass.GROUPS[enemyId].name if EnemyClass.isGroup(enemyId) else EnemyClass.getEnemy(enemyId).name
	for i in members.size():
		var data=EnemyClass.getEnemy(members[i])
		var offset_x=0.0 if members.size()==1 else (-18.0 if i==0 else 18.0)
		var shadow=ColorRect.new()
		shadow.color=Color(0,0,0,0.28)
		shadow.size=Vector2(26,5)
		shadow.position=Vector2(-13+offset_x,6)
		add_child(shadow)

		var member_sprite=AnimatedSprite2D.new()
		member_sprite.sprite_frames=EnemySprites.build(data.sprite if data.sprite!="" else members[i])
		member_sprite.position=Vector2(offset_x,-22)
		add_child(member_sprite)
		member_sprite.play("idle")
		if sprite==null:
			sprite=member_sprite

	# nama musuh kecil di atas kepalanya
	var label=Label.new()
	label.text=label_text
	label.add_theme_font_size_override("font_size",8)
	label.add_theme_color_override("font_color",Color(1,0.92,0.7))
	label.add_theme_color_override("font_outline_color",Color(0.13,0.125,0.2))
	label.add_theme_constant_override("outline_size",3)
	label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	label.size=Vector2(110,10)
	label.position=Vector2(-55,-62)
	label.z_index=5
	# nama panjang diperkecil supaya tidak keluar dari layar
	var labelFont=label.get_theme_font("font")
	var labelSize=8
	while labelSize>5 and labelFont.get_string_size(label_text,HORIZONTAL_ALIGNMENT_LEFT,-1,labelSize).x>96.0:
		labelSize-=1
	label.add_theme_font_size_override("font_size",labelSize)
	label.clip_text=true
	add_child(label)

	body_entered.connect(_on_body_entered)


func _on_body_entered(body_):
	if body_.is_in_group("Player"):
		emit_signal("triggered",self)
