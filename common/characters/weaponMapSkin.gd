extends RefCounted

# Animasi menyerang karakter di peta/desa/mini game mengikuti senjata yang dipakai (tekan Spasi).
#   pedang / belati -> attack1 (animasi bawaan)    tongkat / orb / jimat / tabung -> attack-staff
#   busur           -> attack-bow                    sekop -> menggali
const STAFF_SHEET="res://common/characters/player/player-attack-staff.png"
const BOW_SHEET="res://common/characters/player/player-attack-bow.png"
const SWORD_SHEET="res://common/characters/player/player-attack1.png"

# nama animasi untuk senjata ("" = tidak ada animasi serang).
# Pakai if biasa + int() (bukan match) supaya id yang terbaca dari file save (angka desimal)
# tetap dikenali.
static func animationFor(weaponId_):
	if weaponId_==null:
		return ""
	var id=int(weaponId_)
	if [GlobalItems.ID.WOODEN_STAFF, GlobalItems.ID.MAGIC_STAFF, GlobalItems.ID.ORB_SUCI, GlobalItems.ID.EXORCIST_PAPER, GlobalItems.ID.ALCHEMY_FLASK, GlobalItems.ID.DUKUN_STAFF].has(id):
		return "attack-staff"
	if [GlobalItems.ID.WOODEN_BOW, GlobalItems.ID.HUNTER_BOW].has(id):
		return "attack-bow"
	if [GlobalItems.ID.WOOD_SWORD, GlobalItems.ID.KNIGHT_SWORD, GlobalItems.ID.SHADOW_DAGGER, GlobalItems.ID.SCIFI_WRENCH].has(id):
		return "attack1"
	return ""

# Tukar isi animasi "attack1" (yang diputar player.gd untuk senjata apa pun) dengan gambar
# sesuai senjata: pedang -> pedang, tongkat -> tongkat, busur -> busur. player.gd tidak diubah.
static func applyAttackSkin(frames_, weaponId_):
	if frames_==null or !frames_.has_animation("attack1"):
		return
	var sheet=SWORD_SHEET
	var anim=animationFor(weaponId_)
	if anim=="attack-staff":
		sheet=STAFF_SHEET
	elif anim=="attack-bow":
		sheet=BOW_SHEET
	for i in range(frames_.get_frame_count("attack1")-1,-1,-1):
		frames_.remove_frame("attack1",i)
	_fill(frames_,"attack1",sheet)

# tambahkan animasi tongkat & busur ke SpriteFrames pemain (aman dipanggil berulang)
static func addAnimations(frames_):
	_addFromSheet(frames_,"attack-staff",STAFF_SHEET)
	_addFromSheet(frames_,"attack-bow",BOW_SHEET)

# ganti isi satu animasi (mis. "attack1-right" di mini game lebah) sesuai senjata yang dipakai
static func replaceAttack(frames_, animation_, weaponId_):
	var anim=animationFor(weaponId_)
	if anim=="" or anim=="attack1":
		return
	var sheet=STAFF_SHEET if anim=="attack-staff" else BOW_SHEET
	for i in range(frames_.get_frame_count(animation_)-1,-1,-1):
		frames_.remove_frame(animation_,i)
	_fill(frames_,animation_,sheet)

static func _addFromSheet(frames_, name_, sheet_):
	if frames_.has_animation(name_):
		return
	frames_.add_animation(name_)
	frames_.set_animation_speed(name_,5.0)
	frames_.set_animation_loop(name_,true)
	_fill(frames_,name_,sheet_)

static func _fill(frames_, name_, sheet_):
	var texture=load(sheet_)
	for i in int(texture.get_width()/64):
		var atlas=AtlasTexture.new()
		atlas.atlas=texture
		atlas.region=Rect2(i*64,0,64,32)
		frames_.add_frame(name_,atlas)
