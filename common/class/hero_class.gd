extends Resource

# Data class pemain. Permainan baru mulai sebagai Petualang (NOVICE); class dipilih lewat Darkus
# di depan Ancient Dungeon (lihat CHOICES).
# Semua fungsi static: pakai lewat  const HeroClass=preload("res://common/class/hero_class.gd")

const KNIGHT="knight"
const ARCHER="archer"
const WIZARD="wizard"
const EXORCIST="exorcist"
const ASSASSIN="assassin"
const ALCHEMIST="alchemist"
const SAGE="sage"
const ENGINEER="engineer"
const DUKUN="dukun"
const ORDER=[KNIGHT,ARCHER,WIZARD,EXORCIST,ASSASSIN,ALCHEMIST,SAGE,ENGINEER,DUKUN]
const DEFAULT=KNIGHT
# Status awal pemain baru: belum punya class (hanya Pedang Kayu). Class dipilih nanti lewat
# Darkus di depan Ancient Dungeon. Bukan salah satu class di ORDER.
const NOVICE="novice"
# Class yang ditawarkan Darkus. Class lain (Exorcist, Asasin, Alkemis, Sage) tetap ada di
# data, tapi belum bisa dipilih sampai dibuka nanti.
const CHOICES=[KNIGHT,ARCHER,WIZARD]
# Pilihan lanjutan dari Darkus setelah 4 musuh dungeon (ular, pocong, leak bara, zombie) dikalahkan.
const ADVANCE_CHOICES=[ASSASSIN,ENGINEER]
# Tiga class rahasia yang dibuka oleh drop Segel Kelas setelah Bhuta Kala dikalahkan (Exorcist, Alkemis, Dukun).
# Yang boleh dipilih tergantung percobaan ke berapa Bhuta Kala berhasil dikalahkan (lihat getBossDropChoices).
const BOSS_DROP_CHOICES=[EXORCIST,ALCHEMIST,DUKUN]
const BOSS_DROP_KEY="dg_class_choice_done"
# jumlah percobaan gagal melawan Bhuta Kala (kalah atau kabur), disimpan di save (scene "dungeon")
const BOSS_FAIL_KEY="dg_boss_fails"
const ADVANCE_KEYS=["dg_ular","dg_poci","dg_leak","dg_zombie"]
# Tampilan karakter utama (tanpa perlengkapan class). Dipakai selama pemain memegang
# Pedang Kayu atau Tongkat Kayu; bukan class yang bisa dipilih.
const HERO="hero"

const FRAMES_PATH="res://common/fighters/classes/"

# frame (mulai 0) saat proyektil dilepas pada tiap animasi serangan
const CASTER_FRAMES={"attack_simple":[3],"attack_advanced":[4,6],"attack_special":[5]}
const LAUNCH_FRAMES={
	ARCHER:{"attack_simple":[3],"attack_advanced":[3,5],"attack_special":[5]},
	WIZARD:CASTER_FRAMES,
	EXORCIST:CASTER_FRAMES,
	ALCHEMIST:CASTER_FRAMES,
	SAGE:CASTER_FRAMES,
	DUKUN:CASTER_FRAMES,
	ENGINEER:{"attack_simple":[3],"attack_advanced":[4],"attack_special":[4]}
}

const INFO={
	NOVICE:{
		"name":"Petualang",
		"desc":"Belum punya class.",
		"life":100,
		"mana":40
	},
	KNIGHT:{
		"name":"Ksatria",
		"desc":"Tangguh. Perisai menahan 25% serangan.",
		"life":120,
		"mana":24
	},
	ARCHER:{
		"name":"Pemburu",
		"desc":"Lincah. Menembak dari jauh.",
		"life":100,
		"mana":36
	},
	WIZARD:{
		"name":"Penyihir",
		"desc":"Mana besar. Sihir api dan petir.",
		"life":80,
		"mana":60
	},
	EXORCIST:{
		"name":"Exorcist",
		"desc":"Jimat suci efektif melawan semua jenis musuh.",
		"life":90,
		"mana":50
	},
	ASSASSIN:{
		"name":"Asasin",
		"desc":"Cepat dan mematikan. Kritis +30%, bisa elak. Nyawa tipis.",
		"life":85,
		"mana":30
	},
	ALCHEMIST:{
		"name":"Alkemis",
		"desc":"Ramuan alkimia efektif melawan semua jenis musuh.",
		"life":95,
		"mana":44
	},
	ENGINEER:{
		"name":"Engineer",
		"desc":"Teknisi Sci-Fi. Kotak peledak dan Turet.",
		"life":95,
		"mana":45
	},
	DUKUN:{
		"name":"Dukun",
		"desc":"Membakar Hiolo, memanggil Mumi, Lampor, atau Randa secara acak. Mantra dan racun santet.",
		"life":95,
		"mana":52
	},
	SAGE:{
		"name":"Sage",
		"desc":"Penyembuh. +2 MP tiap giliran, serangan memulihkan HP.",
		"life":100,
		"mana":72
	}
}

static func isValid(class_):
	return ORDER.has(class_)

static func isNovice(class_):
	return class_==NOVICE

# true kalau pemain sudah punya class sungguhan (bukan Petualang)
static func hasClass(class_):
	return isValid(class_)

static func isAdvanceChoice(class_):
	return ADVANCE_CHOICES.has(class_)

# true kalau 4 musuh dungeon yang membuka pilihan Asasin / Engineer sudah dikalahkan
static func isAdvanceUnlocked():
	for key in ADVANCE_KEYS:
		if GlobalScenes.getParamForSceneOr("dungeon",key,false)!=true:
			return false
	return true

static func isChoice(class_):
	return CHOICES.has(class_)

static func getInfo(class_):
	if class_==NOVICE:
		return INFO[NOVICE]
	return INFO[class_ if isValid(class_) else DEFAULT]

static func getName(class_):
	return getInfo(class_).name

# senjata khas tiap class (id dari GlobalItems), diberikan Darkus saat class dipilih.
# Petualang (belum punya class) tidak punya senjata class: -1.
static func getWeaponId(class_):
	match class_:
		NOVICE:
			return -1
		ARCHER:
			return GlobalItems.ID.HUNTER_BOW
		WIZARD:
			return GlobalItems.ID.MAGIC_STAFF
		EXORCIST:
			return GlobalItems.ID.EXORCIST_PAPER
		ASSASSIN:
			return GlobalItems.ID.SHADOW_DAGGER
		ALCHEMIST:
			return GlobalItems.ID.ALCHEMY_FLASK
		SAGE:
			return GlobalItems.ID.ORB_SUCI
		ENGINEER:
			return GlobalItems.ID.SCIFI_WRENCH
		DUKUN:
			return GlobalItems.ID.DUKUN_STAFF
	return GlobalItems.ID.KNIGHT_SWORD

# class pemilik senjata khas ini ("" kalau bukan senjata khas class, mis. Pedang/Tongkat/Busur Kayu)
static func getClassOfWeapon(itemId_):
	for class_ in ORDER:
		if getWeaponId(class_)==itemId_:
			return class_
	return ""

# Pedang Kayu (senjata awal) bisa dipakai semua class.
# Tongkat Kayu pemberian Vera dan Busur Kayu (hadiah Anak Desa) bisa dipakai semua class.
static func canUseWeapon(class_, itemId_):
	if itemId_==getWeaponId(class_):
		return true
	if itemId_==GlobalItems.ID.WOODEN_STAFF or itemId_==GlobalItems.ID.WOODEN_BOW:
		return true
	# Pedang Kayu: senjata awal semua class
	return itemId_==GlobalItems.ID.WOOD_SWORD

static func isRanged(class_):
	return class_==ARCHER or isMagic(class_)

# class yang serangannya sihir (tidak dikurangi oleh hantu kebal fisik)
static func isMagic(class_):
	return class_==WIZARD or class_==EXORCIST or class_==ALCHEMIST or class_==SAGE or class_==DUKUN

static func hasShield(class_):
	return class_==KNIGHT

# pengali efek ramuan/makanan
static func getConsumeBonus(class_):
	return 1.3 if class_==ALCHEMIST else 1.0

# tambahan peluang serangan kritis
static func getCritBonus(class_):
	return 0.30 if class_==ASSASSIN else 0.0

# pengali damage terhadap hantu / iblis
static func getSpiritBonus(class_):
	return 1.8 if class_==EXORCIST else 1.0

# MP yang pulih tiap giliran di pertarungan
static func getTurnManaRegen(class_):
	return 2 if class_==SAGE else 0

# frame lepas proyektil bagi class tanpa proyektil sendiri (Ksatria, Asasin) yang memakai sihir
const MELEE_MAGIC_FRAMES={"attack_simple":[3],"attack_advanced":[4],"attack_special":[5]}

# kind_: "physical" tidak menembakkan apa pun; "magic" / "ranged" menembakkan proyektil
static func getLaunchFrames(class_, animation_, kind_="magic"):
	if kind_=="physical" or kind_=="gadget" or kind_=="summon":
		return []
	if LAUNCH_FRAMES.has(class_):
		return LAUNCH_FRAMES[class_].get(animation_,[])
	return MELEE_MAGIC_FRAMES.get(animation_,[])

# gaya terbang proyektil: "aim" (menghadap sasaran), "spin" (berputar), "arc" (dilempar melengkung)
static func getProjectileStyle(class_, kind_="magic"):
	if kind_=="ranged":
		return "aim"
	match class_:
		ARCHER:
			return "aim" if kind_!="magic" else "spin"
		ENGINEER:
			return "aim"
		ALCHEMIST:
			return "arc"
	return "spin"

# gambar proyektil: path teks / "" kalau tidak ada.
# Sihir dari class non-penyihir (Ksatria, Pemanah, Asasin) memakai bola sihir merah milik Vera.
static func getProjectilePath(class_, animation_, kind_="magic"):
	var special=animation_=="attack_special"
	if kind_=="physical" or kind_=="gadget" or kind_=="summon":
		return ""
	if kind_=="ranged":
		return FRAMES_PATH+("projectile-arrow-fire.png" if special else "projectile-arrow.png")
	match class_:
		WIZARD:
			return FRAMES_PATH+("projectile-fireball.png" if special else "projectile-bolt.png")
		EXORCIST:
			return FRAMES_PATH+("projectile-holy-big.png" if special else "projectile-holy.png")
		ALCHEMIST:
			return FRAMES_PATH+("projectile-flask-fire.png" if special else "projectile-flask.png")
		SAGE:
			return FRAMES_PATH+("projectile-sage-big.png" if special else "projectile-sage.png")
		DUKUN:
			return FRAMES_PATH+("projectile-dukun-big.png" if special else "projectile-dukun.png")
		ENGINEER:
			return FRAMES_PATH+"projectile-bolt.png"
	return FRAMES_PATH+("projectile-vera-big.png" if special else "projectile-vera.png")

# warna percikan saat proyektil mengenai sasaran
static func getImpactColors(class_, special_, kind_="magic"):
	if class_==ENGINEER:
		return [Color(0.35,0.95,1),Color(0.8,1,1),Color(1,0.4,0.35)]
	if kind_=="magic" and !isMagic(class_):
		return [Color(1,0.35,0.5),Color(1,0.7,0.8),Color(1,1,1)]
	if kind_=="ranged":
		return [Color(1,0.85,0.3),Color(1,0.5,0.2),Color(1,1,1)]
	match class_:
		ARCHER:
			return [Color(1,0.85,0.3),Color(1,0.5,0.2),Color(1,1,1)]
		EXORCIST:
			return [Color(1,0.93,0.55),Color(1,1,0.9),Color(1,0.78,0.3)]
		ALCHEMIST:
			return [Color(0.4,1,0.5),Color(0.85,1,0.85),Color(1,0.5,0.2)] if special_ else [Color(0.4,1,0.5),Color(0.85,1,0.85),Color(0.6,0.9,1)]
		SAGE:
			return [Color(0.45,1,0.7),Color(0.85,1,0.9),Color(1,1,1)]
		DUKUN:
			return [Color(1,0.45,0.2),Color(1,0.75,0.4),Color(0.86,0.83,0.9)]
	if special_:
		return [Color(1,0.85,0.3),Color(1,0.5,0.2),Color(1,1,1)]
	return [Color(0.5,0.9,1),Color(0.85,0.97,1),Color(1,1,1)]

# posisi proyektil muncul relatif terhadap tengah sprite petarung
static func getProjectileOrigin(class_, kind_="magic"):
	if isMagic(class_) and kind_=="magic":
		return Vector2(8,-2)
	return Vector2(20,18)


# ---------- Segel Kelas Bhuta Kala: pilihan menurut percobaan ----------
# Percobaan 1 (menang langsung): Exorcist, Alkemis (ilmuwan), atau Dukun.
# Percobaan 2: hanya Dukun atau Exorcist.
# Percobaan 3 dan seterusnya (mengulang terus): hanya Dukun.
static func getBossDropChoices(attempt_):
	if int(attempt_)<=1:
		return [EXORCIST,ALCHEMIST,DUKUN]
	if int(attempt_)==2:
		return [DUKUN,EXORCIST]
	return [DUKUN]

# percobaan saat ini = jumlah kegagalan sebelumnya + 1
static func getBossAttempt():
	return int(GlobalScenes.getParamForSceneOr("dungeon",BOSS_FAIL_KEY,0))+1

# dipanggil saat pemain kalah / kabur dari Bhuta Kala: percobaan berikutnya lebih sempit pilihannya
static func recordBossFail():
	GlobalScenes.saveParamForScene("dungeon",BOSS_FAIL_KEY,getBossAttempt())
