extends Node2D

# Kotak Mekanik Engineer, digambar lewat kode (tanpa file gambar).
#   mode "box"    : kotak baja dengan lampu cyan
#   mode "turret" : kotak yang berubah jadi turet dengan laras mengarah ke musuh
# Dipakai oleh spiderFight.gd.

const BOX="box"
const TURRET="turret"

var mode=BOX
var aimAngle=0.0
var pulse=0.0
var recoil=0.0
var hp=1
var maxHp=1

func _ready():
	z_index=5

func setMode(mode_):
	mode=mode_
	queue_redraw()

func aimAt(globalPos_):
	aimAngle=(globalPos_-global_position).angle()
	queue_redraw()

func setHealth(hp_, maxHp_):
	hp=hp_
	maxHp=max(1,maxHp_)
	queue_redraw()

func kick():
	recoil=3.0

func _process(delta_):
	pulse+=delta_
	if recoil>0.0:
		recoil=max(0.0,recoil-delta_*14.0)
	queue_redraw()

func _draw():
	var steel=Color(0.42,0.47,0.56)
	var dark=Color(0.16,0.18,0.25)
	var red=Color(0.78,0.16,0.18)
	var glow=Color(0.35,0.95,1.0,0.55+0.4*sin(pulse*5.0))
	# bayangan
	draw_rect(Rect2(-10,8,20,3),Color(0,0,0,0.3))
	# badan kotak
	draw_rect(Rect2(-9,-6,18,14),dark)
	draw_rect(Rect2(-8,-5,16,12),steel)
	draw_rect(Rect2(-8,-5,16,3),Color(0.62,0.68,0.78))
	draw_rect(Rect2(-8,5,16,2),red)
	if mode==BOX:
		# lampu cyan + palang
		draw_rect(Rect2(-5,0,10,2),glow)
		draw_rect(Rect2(-1,-5,2,12),dark)
	else:
		# kubah + laras turet
		draw_rect(Rect2(-5,-9,10,5),dark)
		draw_rect(Rect2(-4,-8,8,3),steel)
		var dir=Vector2.from_angle(aimAngle)
		var base=Vector2(0,-6)-dir*recoil
		draw_line(base,base+dir*13.0,dark,4.0)
		draw_line(base,base+dir*12.0,Color(0.7,0.76,0.86),2.0)
		draw_circle(base+dir*13.0,1.6,glow)
		draw_circle(Vector2(0,-6),2.0,glow)
		# bar nyawa turet (rapuh)
		var ratio=clamp(float(hp)/float(maxHp),0.0,1.0)
		draw_rect(Rect2(-10,-17,20,3),Color(0,0,0,0.75))
		draw_rect(Rect2(-9,-16,18.0*ratio,1),Color(0.4,1,0.5) if ratio>0.4 else Color(1,0.4,0.35))
