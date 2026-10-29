extends Node2D

# Bandit untuk adegan di desa pohon. variant_: "bandit1" (bandana merah) / "bandit2" (bandana biru)
# Dipakai:  var b=Node2D.new(); b.set_script(BanditScript); b.variant="bandit2"; parent.add_child(b)

var variant="bandit1"
var sprite=null
var shadow=null


func _ready():
	var sheet=load("res://common/characters/bandit/"+variant+"-idle.png")
	var frames=SpriteFrames.new()
	if frames.has_animation("default"):
		frames.remove_animation("default")
	frames.add_animation("idle")
	frames.set_animation_speed("idle",5.0)
	frames.set_animation_loop("idle",true)
	for i in int(sheet.get_width()/32):
		var tex=AtlasTexture.new()
		tex.atlas=sheet
		tex.region=Rect2(i*32,0,32,32)
		frames.add_frame("idle",tex)
	shadow=ColorRect.new()
	shadow.color=Color(0,0,0,0.25)
	shadow.size=Vector2(14,3)
	shadow.position=Vector2(-7,11)
	add_child(shadow)
	sprite=AnimatedSprite2D.new()
	sprite.sprite_frames=frames
	add_child(sprite)
	sprite.play("idle")


func face(left_):
	if sprite!=null:
		sprite.flip_h=left_


# mengayunkan senjata ke arah target (menghantam sumur)
func strike(toward_):
	var dir=1.0 if toward_.x>global_position.x else -1.0
	face(dir<0)
	var origin=position
	var tween=create_tween()
	tween.tween_property(self,"position",origin+Vector2(5*dir,0),0.08)
	tween.tween_property(self,"position",origin,0.12)
	return tween


# berjalan menghampiri suatu titik sambil menghadap tujuan (naik-turun kecil seperti berlari)
func walkTo(to_, seconds_):
	face(to_.x<global_position.x)
	var bob=sprite.create_tween().set_loops()
	bob.tween_property(sprite,"offset:y",-3.0,0.1)
	bob.tween_property(sprite,"offset:y",0.0,0.1)
	var tween=create_tween()
	tween.tween_property(self,"global_position",to_,seconds_).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_callback(bob.kill)
	tween.tween_callback(func(): sprite.offset=Vector2.ZERO)
	return tween


# lari menjauh sambil memudar
func flee(to_, seconds_):
	face(to_.x<global_position.x)
	var tween=create_tween()
	tween.tween_property(self,"global_position",to_,seconds_).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(self,"modulate:a",0.0,seconds_*0.9)
	return tween
