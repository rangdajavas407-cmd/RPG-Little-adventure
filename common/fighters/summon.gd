extends Node2D

# Makhluk panggilan di layar pertarungan (v9.30), digambar lewat kode (tanpa file gambar), seperti gadget.gd.
#   Dukun    : Mumi, Lampor, Randa
#   Exorcist : Banaspati
#   Alkemis  : Golem, Mecha
# Titik (0,0) = tengah badan; kaki sekitar y=+13. Dipakai oleh spiderFight.gd.

const SummonRules=preload("res://common/class/summon_rules.gd")

var kind=SummonRules.MUMMY
var hp=1
var maxHp=1
var t=0.0
# dorongan ke depan saat menyerang (piksel), berkurang sendiri
var lunge=0.0
var facing=1.0

func _ready():
	z_index=5

func setKind(kind_):
	kind=kind_
	queue_redraw()

func setHealth(hp_, maxHp_):
	hp=hp_
	maxHp=max(1,maxHp_)
	queue_redraw()

# menerjang ke arah musuh sebentar (dipanggil saat menyerang)
func kick():
	lunge=9.0

func _process(delta_):
	t+=delta_
	if lunge>0.0:
		lunge=max(0.0,lunge-delta_*40.0)
	queue_redraw()

func _draw():
	var bob=sin(t*3.0)*1.5
	var floating=kind==SummonRules.LAMPOR or kind==SummonRules.BANASPATI
	if floating:
		bob=sin(t*4.0)*2.5-3.0
	# bayangan di tanah
	draw_rect(Rect2(-9,12,18,3),Color(0,0,0,0.3))
	draw_set_transform(Vector2(lunge*facing,bob),0.0,Vector2.ONE)
	match kind:
		SummonRules.MUMMY:
			_drawMummy()
		SummonRules.LAMPOR:
			_drawLampor()
		SummonRules.RANDA:
			_drawRanda()
		SummonRules.BANASPATI:
			_drawBanaspati()
		SummonRules.GOLEM:
			_drawGolem()
		SummonRules.MECHA:
			_drawMecha()
	draw_set_transform(Vector2.ZERO,0.0,Vector2.ONE)
	# bar nyawa
	var ratio=clamp(float(hp)/float(maxHp),0.0,1.0)
	draw_rect(Rect2(-11,-22,22,3),Color(0,0,0,0.75))
	draw_rect(Rect2(-10,-21,20.0*ratio,1),Color(0.4,1,0.5) if ratio>0.4 else Color(1,0.4,0.35))

# ---------------------------------------------------------------- Mumi

func _drawMummy():
	var wrap=Color(0.88,0.84,0.7)
	var wrapDark=Color(0.62,0.57,0.44)
	# kaki
	draw_rect(Rect2(-6,6,5,7),wrap)
	draw_rect(Rect2(1,6,5,7),wrap)
	# badan berperban
	draw_rect(Rect2(-7,-6,14,13),wrap)
	for i in 4:
		draw_rect(Rect2(-7,-5+i*3,14,1),wrapDark)
	# lengan terulur ke depan
	draw_rect(Rect2(6,-4,9,4),wrap)
	draw_rect(Rect2(6,-2,9,1),wrapDark)
	# kepala
	draw_rect(Rect2(-5,-15,11,10),wrap)
	draw_rect(Rect2(-5,-12,11,1),wrapDark)
	draw_rect(Rect2(-5,-9,11,1),wrapDark)
	# mata menyala + celah gelap
	draw_rect(Rect2(-3,-12,9,3),Color(0.1,0.07,0.1))
	draw_rect(Rect2(-2,-11,2,1),Color(1.0,0.35,0.25))
	draw_rect(Rect2(2,-11,2,1),Color(1.0,0.35,0.25))
	# ujung perban menjuntai
	draw_rect(Rect2(-8,-2,2,6+int(sin(t*5.0)*1.5)),wrapDark)

# ---------------------------------------------------------------- Lampor

func _drawLampor():
	var flick=sin(t*9.0)
	var green=Color(0.35,1.0,0.5,0.9)
	var deep=Color(0.1,0.55,0.35,0.9)
	# ekor api bergelombang
	for i in 5:
		var x=-5.0-i*3.2
		var y=3.0+sin(t*7.0+i*0.9)*2.5
		draw_circle(Vector2(x,y),4.0-i*0.6,Color(0.2,0.8,0.45,0.7-i*0.1))
	# kobaran utama
	draw_circle(Vector2(2,0),8.0,deep)
	draw_circle(Vector2(3,-1),6.0+flick*0.6,green)
	# lidah api di atas
	var tip=PackedVector2Array([Vector2(-1,-6),Vector2(3,-15+flick*1.5),Vector2(7,-6)])
	draw_colored_polygon(tip,green)
	# inti dan mata
	draw_circle(Vector2(4,-1),3.0,Color(0.88,1.0,0.9))
	draw_rect(Rect2(2,-2,2,2),Color(0.05,0.2,0.1))
	draw_rect(Rect2(6,-2,2,2),Color(0.05,0.2,0.1))

# ---------------------------------------------------------------- Randa (Rangda)

func _drawRanda():
	var hair=Color(0.95,0.95,0.98)
	var robe=Color(0.16,0.07,0.2)
	var skin=Color(0.78,0.14,0.16)
	# rambut putih liar
	for i in 7:
		var a=-2.9+i*0.48
		var reach=11.0+sin(t*4.0+i)*1.5
		draw_line(Vector2(0,-9),Vector2(0,-9)+Vector2(cos(a),sin(a))*reach,hair,2.0)
	# jubah gelap
	draw_rect(Rect2(-8,-3,16,16),robe)
	draw_rect(Rect2(-8,10,16,2),Color(0.45,0.1,0.2))
	# cakar terulur
	draw_rect(Rect2(7,-2,8,3),skin)
	draw_rect(Rect2(14,-3,2,1),hair)
	draw_rect(Rect2(14,0,2,1),hair)
	# wajah merah
	draw_rect(Rect2(-6,-14,12,12),skin)
	draw_rect(Rect2(-6,-14,12,2),Color(0.5,0.08,0.12))
	# mata melotot
	draw_rect(Rect2(-5,-11,4,3),Color(1,1,0.85))
	draw_rect(Rect2(1,-11,4,3),Color(1,1,0.85))
	draw_rect(Rect2(-3,-10,1,2),Color(0.1,0,0))
	draw_rect(Rect2(3,-10,1,2),Color(0.1,0,0))
	# taring dan lidah panjang
	draw_rect(Rect2(-5,-5,2,5),hair)
	draw_rect(Rect2(3,-5,2,5),hair)
	var tongue=4.0+sin(t*6.0)*2.0
	draw_rect(Rect2(-1,-5,3,tongue+3.0),Color(0.95,0.35,0.45))

# ---------------------------------------------------------------- Banaspati

func _drawBanaspati():
	var flick=sin(t*10.0)
	var outer=Color(1.0,0.35,0.1,0.85)
	var mid=Color(1.0,0.62,0.12,0.95)
	# lidah api berkobar
	for i in 5:
		var x=-8.0+i*4.0
		var h=7.0+sin(t*8.0+i*1.3)*3.0
		draw_colored_polygon(PackedVector2Array([Vector2(x-3,-4),Vector2(x,-4-h-4),Vector2(x+3,-4)]),outer)
	draw_circle(Vector2(0,2),10.0,outer)
	draw_circle(Vector2(0,3),7.5+flick*0.5,mid)
	draw_circle(Vector2(0,4),4.0,Color(1.0,0.95,0.6))
	# wajah hantu
	draw_rect(Rect2(-5,0,3,3),Color(0.25,0.03,0.0))
	draw_rect(Rect2(2,0,3,3),Color(0.25,0.03,0.0))
	draw_rect(Rect2(-3,5,6,2),Color(0.25,0.03,0.0))

# ---------------------------------------------------------------- Golem

func _drawGolem():
	var stone=Color(0.52,0.5,0.46)
	var stoneLight=Color(0.68,0.66,0.6)
	var stoneDark=Color(0.3,0.29,0.28)
	# kaki
	draw_rect(Rect2(-8,6,7,7),stoneDark)
	draw_rect(Rect2(1,6,7,7),stoneDark)
	# badan batu besar
	draw_rect(Rect2(-10,-8,20,16),stone)
	draw_rect(Rect2(-10,-8,20,3),stoneLight)
	draw_rect(Rect2(-3,-4,1,10),stoneDark)
	draw_rect(Rect2(2,-1,1,8),stoneDark)
	# lengan dan kepalan
	draw_rect(Rect2(-14,-6,5,12),stoneDark)
	draw_rect(Rect2(9,-6,5,12),stoneDark)
	draw_rect(Rect2(10,3,7,6),stone)
	# kepala kecil dengan mata menyala
	draw_rect(Rect2(-5,-15,10,8),stone)
	draw_rect(Rect2(-5,-15,10,2),stoneLight)
	var eye=Color(0.4,1.0,0.9,0.7+0.3*sin(t*5.0))
	draw_rect(Rect2(-3,-12,2,2),eye)
	draw_rect(Rect2(1,-12,2,2),eye)
	# lumut
	draw_rect(Rect2(-8,-8,4,2),Color(0.3,0.55,0.3))

# ---------------------------------------------------------------- Mecha

func _drawMecha():
	var steel=Color(0.46,0.52,0.62)
	var light=Color(0.7,0.76,0.86)
	var dark=Color(0.16,0.18,0.25)
	var glow=Color(0.35,0.95,1.0,0.6+0.4*sin(t*5.0))
	# kaki
	draw_rect(Rect2(-7,6,5,7),dark)
	draw_rect(Rect2(2,6,5,7),dark)
	draw_rect(Rect2(-8,12,7,2),steel)
	draw_rect(Rect2(1,12,7,2),steel)
	# badan
	draw_rect(Rect2(-8,-6,16,13),dark)
	draw_rect(Rect2(-7,-5,14,11),steel)
	draw_rect(Rect2(-7,-5,14,3),light)
	draw_rect(Rect2(-4,1,8,2),glow)
	# meriam di lengan kanan
	draw_rect(Rect2(7,-4,9,5),dark)
	draw_rect(Rect2(14,-3,4,3),light)
	draw_circle(Vector2(18,-1.5),1.5,glow)
	# kepala dengan visor
	draw_rect(Rect2(-5,-14,10,8),dark)
	draw_rect(Rect2(-4,-13,8,6),steel)
	draw_rect(Rect2(-3,-11,7,2),glow)
	draw_rect(Rect2(-1,-17,2,3),dark)
	draw_circle(Vector2(0,-18),1.2,Color(1.0,0.3,0.3))
