extends RefCounted

# Regles du combat au tour par tour (sans etat, testables)

const DAMAGE_VARIANCE=0.2
const CRITICAL_CHANCE=0.1
const CRITICAL_MULTIPLIER=2
const ENEMY_MISS_CHANCE=0.15
const FLEE_CHANCE=0.75
# v9.18: pengali damage SEMUA serangan pemain (semua class, Kotak/Turet Engineer, balasan Asasin, tinju).
# Angka dasar di globalItems.gd tidak diubah; pengali dipakai saat menghitung dan di label tombol serangan.
const PLAYER_DAMAGE_BOOST=1.7

# v9.24: Perisai Kelapa. Satu ronde, damage yang masuk berkurang 10-26% (diundi sekali saat kelapa dimakan)
const COCONUT_SHIELD_MIN=0.10
const COCONUT_SHIELD_MAX=0.26

static func rollCoconutShield(rng_:RandomNumberGenerator):
	return rng_.randf_range(COCONUT_SHIELD_MIN,COCONUT_SHIELD_MAX)

static func applyShield(damage_, reduction_):
	return max(1,int(round(float(damage_)*(1.0-reduction_))))

static func boosted(damage_):
	return int(round(float(damage_)*PLAYER_DAMAGE_BOOST))

# degats d'une attaque : +/- 20% autour de la valeur de base, avec une chance de coup critique
static func rollDamage(baseDamage_, rng_:RandomNumberGenerator, canBeCritical_=true, critBonus_=0.0):
	var damage=int(round(baseDamage_*rng_.randf_range(1.0-DAMAGE_VARIANCE, 1.0+DAMAGE_VARIANCE)))
	var critical=canBeCritical_ and rng_.randf() < CRITICAL_CHANCE+critBonus_
	if critical:
		damage*=CRITICAL_MULTIPLIER
	return {"damage":max(1, damage), "critical":critical}

static func rollEnemyHit(rng_:RandomNumberGenerator):
	return rng_.randf() >= ENEMY_MISS_CHANCE

static func rollFlee(rng_:RandomNumberGenerator):
	return rng_.randf() < FLEE_CHANCE
