extends Resource

class_name attack_class

# jenis serangan:
#   PHYSICAL = fisik (hantu hanya menerima 50% damage)
#   MAGIC    = sihir (menembakkan proyektil, hantu menerima damage penuh, Exorcist 1,8x)
#   RANGED   = tembakan fisik (panah)
const PHYSICAL="physical"
const MAGIC="magic"
const RANGED="ranged"
#   GADGET   = skill alat (Engineer): tidak menyerang langsung, memasang Kotak Mekanik / mengubahnya jadi Turet
const GADGET="gadget"
#   SUMMON   = skill panggil (Dukun, Exorcist, Alkemis): memanggil satu makhluk pembantu, tidak memilih sasaran
const SUMMON="summon"

# status yang bisa ditimbulkan serangan
const CONFUSE="confuse"
const BLEED="bleed"
const POISON="poison"
const FREEZE="freeze"

# efek khusus skill (field "special")
#   barrier     = Jimat Pengusir (Exorcist): peluang memunculkan Barrier atau Perisai Suci
#   tube        = Tabung Reaksi (Alkemis): peluang Blizzard (beku) atau Racun
#   summon_dukun / summon_banaspati / summon_alchemy = daftar makhluk yang bisa dipanggil
const SPECIAL_BARRIER="barrier"
const SPECIAL_TUBE="tube"
const SPECIAL_SUMMON_DUKUN="summon_dukun"
const SPECIAL_SUMMON_BANASPATI="summon_banaspati"
const SPECIAL_SUMMON_ALCHEMY="summon_alchemy"

# sikap yang aktif setelah serangan dipakai
#   DODGE = Siaga Bayangan (Asasin): giliran musuh berikutnya bisa dielak, kadang serangannya dibalikkan
const DODGE="dodge"

var name
var animation
var damage
var xpMin
var manaCost
# HP yang ikut dipulihkan saat serangan ini dipakai (0 = tidak ada)
var heal
var kind
# efek tambahan pada musuh: "" / "confuse" (bingung, lewat satu giliran) / "bleed" (pendarahan)
var status
var statusChance
# sikap setelah memakai serangan ini: "" / "dodge"
var stance
# efek khusus skill (lihat SPECIAL_*), "" = tidak ada
var special

func _init(name_,animation_,damage_,xpMin_,manaCost_=0,heal_=0,kind_="physical",status_="",statusChance_=0.0,stance_="",special_=""):
	self.name=name_
	self.animation=animation_
	self.damage=damage_
	self.xpMin=xpMin_
	self.manaCost=manaCost_
	self.heal=heal_
	self.kind=kind_
	self.status=status_
	self.statusChance=statusChance_
	self.stance=stance_
	self.special=special_

func isMagic():
	return kind==MAGIC

func isGadget():
	return kind==GADGET

func hasDodgeStance():
	return stance==DODGE

func isSummon():
	return kind==SUMMON

# skill yang tidak menyerang sasaran langsung dan tidak memicu proyektil
func isSelfAction():
	return kind==GADGET or kind==SUMMON
