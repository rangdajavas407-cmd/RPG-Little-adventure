extends Resource

# Membangun SpriteFrames petarung (64x64 per frame) sesuai SENJATA yang dipegang pemain:
#
#   Pedang Kayu       -> karakter utama memegang pedang kayu
#   Tongkat Kayu      -> karakter utama memegang tongkat kayu
#   Busur Kayu        -> karakter utama memegang busur kayu (tools/make_bow_skin.py)
#   senjata khas class -> tampilan class (Ksatria, Pemanah, dst.) lengkap dengan perlengkapannya
#
#   $AnimatedSprite2D.sprite_frames=ClassSprites.buildForWeapon(GlobalPlayer.getPlayerClass(), GlobalPlayer.getActiveWeaponId())
#
# Sheet karakter utama dengan tongkat dibuat oleh tools/make_hero_skins.py.

const HeroClass=preload("res://common/class/hero_class.gd")

# nama animasi : [file, jumlah frame, fps, loop]  (sheet tampilan class, di common/fighters/classes/)
const SHEETS={
	"idle":["idle",4,5.0,true],
	"damage":["damage",7,6.0,false],
	"attack_simple":["attack-simple",5,8.0,false],
	"attack_advanced":["attack-advanced",7,8.0,false],
	"attack_special":["attack-special",7,8.0,false]
}

# sheet karakter utama, per senjata: nama animasi : [path lengkap, fps, loop]
const HERO_PATH="res://common/fighters/hero/"
const ORIGINAL_PATH="res://common/fighters/player/"
const HERO_SHEETS={
	"sword":{
		# pose diam & kena damage memegang pedang (dibuat dari sprite asli, lihat README, bagian v9.25)
		"idle":[HERO_PATH+"sword-idle.png",5.0,true],
		"damage":[HERO_PATH+"sword-damage.png",6.0,false],
		"attack_simple":[ORIGINAL_PATH+"player-attack1.png",8.0,false],
		"attack_advanced":[ORIGINAL_PATH+"player-attack2.png",8.0,false],
		"attack_special":[HERO_PATH+"sword-attack-special.png",8.0,false]
	},
	"bow":{
		"idle":[HERO_PATH+"bow-idle.png",5.0,true],
		"damage":[HERO_PATH+"bow-damage.png",6.0,false],
		"attack_simple":[HERO_PATH+"bow-attack-simple.png",8.0,false],
		"attack_advanced":[HERO_PATH+"bow-attack-advanced.png",8.0,false],
		"attack_special":[HERO_PATH+"bow-attack-special.png",8.0,false]
	},
	"staff":{
		"idle":[HERO_PATH+"staff-idle.png",5.0,true],
		"damage":[HERO_PATH+"staff-damage.png",6.0,false],
		"attack_simple":[HERO_PATH+"staff-attack-simple.png",8.0,false],
		"attack_advanced":[HERO_PATH+"staff-attack-advanced.png",8.0,false],
		"attack_special":[HERO_PATH+"staff-attack-special.png",8.0,false]
	}
}

const FRAME_SIZE=64

# tampilan yang dipakai untuk senjata itu: class pemain (senjata khasnya) atau HeroClass.HERO
static func getSkin(class_, weaponId_):
	if HeroClass.isValid(class_) and weaponId_==HeroClass.getWeaponId(class_):
		return class_
	return HeroClass.HERO

static func buildForWeapon(class_, weaponId_):
	var skin=getSkin(class_,weaponId_)
	if skin!=HeroClass.HERO:
		return build(skin)
	var sheetKey="sword"
	if weaponId_==GlobalItems.ID.WOODEN_STAFF:
		sheetKey="staff"
	elif weaponId_==GlobalItems.ID.WOODEN_BOW:
		sheetKey="bow"
	var sheets=HERO_SHEETS[sheetKey]
	var frames=_emptyFrames()
	for animation in sheets.keys():
		var data=sheets[animation]
		var texture=load(data[0])
		_addAnimation(frames,animation,texture,int(texture.get_width()/FRAME_SIZE),data[1],data[2])
	return frames

# tampilan class lengkap dengan perlengkapannya (juga dipakai layar pilih class)
static func build(class_):
	if !HeroClass.isValid(class_):
		class_=HeroClass.DEFAULT
	var frames=_emptyFrames()
	for animation in SHEETS.keys():
		var data=SHEETS[animation]
		var texture=load(HeroClass.FRAMES_PATH+class_+"-"+data[0]+".png")
		_addAnimation(frames,animation,texture,data[1],data[2],data[3])
	return frames

static func _emptyFrames():
	var frames=SpriteFrames.new()
	if frames.has_animation("default"):
		frames.remove_animation("default")
	return frames

static func _addAnimation(frames_, animation_, texture_, count_, fps_, loop_):
	frames_.add_animation(animation_)
	frames_.set_animation_speed(animation_,fps_)
	frames_.set_animation_loop(animation_,loop_)
	for i in count_:
		var atlas=AtlasTexture.new()
		atlas.atlas=texture_
		atlas.region=Rect2(i*FRAME_SIZE,0,FRAME_SIZE,FRAME_SIZE)
		frames_.add_frame(animation_,atlas)
