extends RefCounted

# Membangun SpriteFrames musuh dari lembar PNG di common/fighters/enemies/
# (idle 4 frame, attack 5, damage 4, die 5; tiap frame persegi, umumnya 64x64;
# sheet yang lebih besar, mis. attack Rumput Laut 96x96, ikut tinggi sheet-nya).
# Nama animasi sama dengan laba-laba: idle / attack-1 / damage / die.

const PATH="res://common/fighters/enemies/"

static func build(id_, withMorph_=false):
	var frames=SpriteFrames.new()
	if frames.has_animation("default"):
		frames.remove_animation("default")
	_add(frames,"idle",id_+"-idle.png",5.0,true)
	# Darkus memakai sprite sheet 8-frame khusus saat masuk cutscene.
	if id_ == "darkus":
		_add(frames,"walk",id_+"-walk.png",8.0,true)
	_add(frames,"attack-1",id_+"-attack.png",9.0,false)
	_add(frames,"damage",id_+"-damage.png",10.0,false)
	_add(frames,"die",id_+"-die.png",6.0,false)
	# animasi berubah wujud (mis. Darkus dirasuki Satan): file id-morph.png, tidak diulang
	if withMorph_:
		_add(frames,"morph",id_+"-morph.png",3.5,false)
	return frames

static func _add(frames_, anim_, file_, speed_, loop_):
	var sheet=load(PATH+file_)
	frames_.add_animation(anim_)
	frames_.set_animation_speed(anim_,speed_)
	frames_.set_animation_loop(anim_,loop_)
	var cell=sheet.get_height()
	var count=int(sheet.get_width()/cell)
	for i in count:
		var tex=AtlasTexture.new()
		tex.atlas=sheet
		tex.region=Rect2(i*cell,0,cell,cell)
		frames_.add_frame(anim_,tex)

# satu frame idle untuk musuh yang berdiri di peta
static func idleTexture(id_):
	var sheet=load(PATH+id_+"-idle.png")
	var tex=AtlasTexture.new()
	tex.atlas=sheet
	var cell=sheet.get_height()
	tex.region=Rect2(0,0,cell,cell)
	return tex
