extends Resource

# Aturan makhluk panggilan (v9.30): Dukun (Mumi / Lampor / Randa), Exorcist (Banaspati), Alkemis (Golem / Mecha).
# Semua angka ada di sini supaya mudah disetel. Dipakai oleh spiderFight.gd dan summon.gd (gambar).
# Hanya SATU makhluk yang boleh aktif dalam satu waktu; kalau tumbang, skill panggil bisa dipakai lagi.

const MUMMY="mummy"
const LAMPOR="lampor"
const RANDA="randa"
const BANASPATI="banaspati"
const GOLEM="golem"
const MECHA="mecha"

# efek khusus yang dibawa serangan makhluk
const EFFECT_NONE=""
const EFFECT_SLOW="slow"       # musuh melambat: sering kehilangan giliran
const EFFECT_POISON="poison"   # musuh keracunan
const EFFECT_TAUNT="taunt"     # semua serangan musuh dialihkan ke makhluk ini (pemain tidak diserang)
const EFFECT_DRAIN="drain"     # Banaspati: menyedot tenaga musuh -> MP pemain, kalau MP penuh jadi HP

# daftar pilihan per skill panggil (nilai "special" di attack_class)
const CHOICES={
	"summon_dukun":[MUMMY,LAMPOR,RANDA],
	"summon_banaspati":[BANASPATI],
	"summon_alchemy":[GOLEM,MECHA]
}

# damage = serangan makhluk tiap giliran pemain, heal = HP pemain pulih saat makhluk dipanggil,
# life = nyawa makhluk, target = peluang musuh menyerang makhluk (taunt selalu 100%), effectChance = peluang efek kena
const DATA={
	MUMMY:{
		"tag":"Slow","name":"Mumi","desc":"Serang 20, melambatkan musuh","damage":20,"heal":47,"life":45,
		"effect":EFFECT_SLOW,"effectChance":0.75,"target":0.3,
		"appear":"Mumi bangkit dari perban kuno!","attack":"Mumi menghantam musuh!"
	},
	LAMPOR:{
		"tag":"Racun","name":"Lampor","desc":"Serang 20, meracuni musuh","damage":20,"heal":47,"life":35,
		"effect":EFFECT_POISON,"effectChance":0.75,"target":0.3,
		"appear":"Lampor melesat turun dalam kobaran api hijau!","attack":"Lampor menyambar musuh!"
	},
	RANDA:{
		"tag":"Taunt","name":"Randa","desc":"Serang 20, memancing serangan musuh","damage":20,"heal":47,"life":70,
		"effect":EFFECT_TAUNT,"effectChance":1.0,"target":1.0,
		"appear":"Randa muncul menjerit! Semua musuh menoleh padanya!","attack":"Randa mencakar musuh!"
	},
	BANASPATI:{
		"tag":"Sedot MP","name":"Banaspati","desc":"Sedot tenaga musuh jadi MP (penuh jadi HP)","damage":0,"heal":0,"life":40,
		"effect":EFFECT_DRAIN,"effectChance":1.0,"target":0.3,"drain":12,
		"appear":"Banaspati, bola api hantu, menyala di sisimu!","attack":"Banaspati menyedot tenaga musuh!"
	},
	GOLEM:{
		"tag":"Tank","name":"Golem","desc":"Tangguh (nyawa 90), serang 18","damage":18,"heal":0,"life":90,
		"effect":EFFECT_NONE,"effectChance":0.0,"target":0.45,
		"appear":"Golem batu terbentuk dari ramuanmu!","attack":"Golem menghantam musuh!"
	},
	MECHA:{
		"tag":"Serang kuat","name":"Mecha","desc":"Serang kuat 26, nyawa 50","damage":26,"heal":0,"life":50,
		"effect":EFFECT_NONE,"effectChance":0.0,"target":0.25,
		"appear":"Mecha rakitan alkimia menyala dan berdiri!","attack":"Mecha menembakkan meriam!"
	}
}

# efek tabung reaksi Alkemis
const TUBE_EFFECT_CHANCE=0.8
const TUBE_BLIZZARD_BONUS_DAMAGE=10
# efek musuh
const SLOW_TURNS=3
const SLOW_SKIP_CHANCE=0.5
const ENEMY_POISON_TURNS=3
const ENEMY_POISON_DAMAGE=5
# Exorcist: Jimat Pengusir (skill 1)
const BARRIER_CHANCE=0.35          # peluang muncul salah satu dari Barrier / Perisai Suci
const BARRIER_SHARE=0.5            # dari yang muncul, separuh Barrier, separuh Perisai
const HOLY_SHIELD_REDUCTION=0.5    # Perisai Suci: damage masuk -50% selama satu giliran musuh
# makhluk yang diserang musuh menerima damage x ini (seperti Vera)
const HIT_MULT=0.8

static func getData(kind_):
	return DATA[kind_]

static func getChoices(special_):
	return CHOICES.get(special_,[])

# v9.31: tidak ada menu pilih makhluk. Skill panggil selalu GACHA: makhluk diundi acak dari daftar skill-nya
# (Dukun: Mumi / Lampor / Randa, Alkemis: Golem / Mecha, Exorcist: Banaspati). Peluang sama rata.
static func roll(special_, rng_):
	var choices=getChoices(special_)
	if choices.is_empty():
		return ""
	return choices[rng_.randi_range(0,choices.size()-1)]

static func isTaunt(kind_):
	return DATA[kind_].effect==EFFECT_TAUNT
