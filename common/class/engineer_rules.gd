extends RefCounted

# Aturan Engineer (Sci-Fi Wrench), tanpa state supaya mudah diuji.
#
#   Skill 1  Pukulan Kunci   : pukulan fisik biasa.
#   Skill 2  Teknik Mesin    : memasang Kotak Mekanik. Kalau musuh menyerang kotak, kotak meledak
#                              (musuh 17-25, pemain 1-3). Dipakai lagi saat kotak ada: kotak jadi Turet.
#   Skill 3  Hantaman Berat  : pukulan berat, peluang membuat musuh bingung (lewat satu giliran).
#
# Turet: rapuh (nyawa 35), menembak SEKALI per giliran pemain dengan damage setara Vera (6-9),
# dan bisa diserang musuh. Kalau nyawanya habis, turet hancur dan kotak bisa dipasang lagi.

const BOX_DAMAGE_MIN=17
const BOX_DAMAGE_MAX=25
const SELF_DAMAGE_MIN=1
const SELF_DAMAGE_MAX=3
# peluang musuh menyerang kotak / turet (bukan pemain) saat ada di lapangan
const BOX_TARGET_CHANCE=0.5
const TURRET_TARGET_CHANCE=0.35

const TURRET_HP=40
const TURRET_DAMAGE_MIN=10
const TURRET_DAMAGE_MAX=10
# serangan musuh ke turet dikalikan ini (sama seperti serangan ke Vera)
const TURRET_HIT_MULT=0.8

const NONE="none"
const BOX="box"
const TURRET="turret"

static func rollBoxDamage(rng_:RandomNumberGenerator):
	return rng_.randi_range(BOX_DAMAGE_MIN,BOX_DAMAGE_MAX)

static func rollSelfDamage(rng_:RandomNumberGenerator):
	return rng_.randi_range(SELF_DAMAGE_MIN,SELF_DAMAGE_MAX)

static func rollTurretDamage(rng_:RandomNumberGenerator):
	return rng_.randi_range(TURRET_DAMAGE_MIN,TURRET_DAMAGE_MAX)
