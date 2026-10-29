extends Node2D

# Perlengkapan ritual di sekeliling sigil, digambar lewat kode:
#   "dupa"      batang setanggi yang ditancapkan, ujungnya membara dan berasap
#   "pedupaan"  wadah perunggu berkaki tiga berisi bara, asapnya tebal
#   "lilin"     lilin hitam dengan nyala kecil
# Posisi node = titik dasar benda di lantai (supaya urutan gambar y-sort dengan pemain benar).
#   appear 0..1 : benda tumbuh dari lantai
#   lit    0..1 : padam sampai menyala penuh

var kind="dupa"
var appear=1.0: set=_setAppear
var lit=0.0: set=_setLit

var time=0.0
var smoke=[]
var smokeTimer=0.0


func setup(kind_):
	kind=kind_


func _ready():
	time=randf()*10.0
	_setAppear(appear)


func _setAppear(value_):
	appear=value_
	scale=Vector2(1.0,maxf(value_,0.001))
	modulate.a=clampf(value_*2.0,0.0,1.0)

func _setLit(value_):
	lit=value_
	queue_redraw()


func _process(delta):
	time+=delta
	if lit>0.05 and kind!="lilin":
		smokeTimer+=delta*(9.0 if kind=="pedupaan" else 5.0)*lit
		while smokeTimer>=1.0:
			smokeTimer-=1.0
			smoke.append({"age":0.0,"life":randf_range(1.6,2.8),"phase":randf()*TAU})
	var alive=[]
	for s in smoke:
		s.age+=delta
		if s.age<s.life:
			alive.append(s)
	smoke=alive
	if lit>0.0 or !smoke.is_empty():
		queue_redraw()


func _draw():
	match kind:
		"dupa":
			_drawIncense()
		"pedupaan":
			_drawCenser()
		"lilin":
			_drawCandle()


# titik asap keluar (koordinat lokal)
func _smokeOrigin():
	match kind:
		"pedupaan":
			return Vector2(0,-10)
		_:
			return Vector2(0,-17)


func _drawSmoke():
	var origin=_smokeOrigin()
	var big=1.6 if kind=="pedupaan" else 1.0
	for s in smoke:
		var f=s.age/s.life
		var pos=origin+Vector2(sin(s.phase+s.age*2.2)*(2.0+7.0*f)*big,-s.age*(11.0 if kind=="dupa" else 14.0))
		var radius=(1.0+3.2*f)*big
		var alpha=(1.0-f)*0.34
		draw_circle(pos,radius,Color(0.78,0.72,0.84,alpha))


func _drawIncense():
	# gundukan pasir kecil di dasar + batang dupa
	draw_rect(Rect2(-3,-2,6,2),Color(0.22,0.16,0.18))
	draw_rect(Rect2(-2,-3,4,1),Color(0.30,0.22,0.22))
	draw_line(Vector2(0,-2),Vector2(0,-17),Color(0.5,0.22,0.12),1.0)
	if lit>0.0:
		var flick=0.8+0.2*sin(time*13.0)
		draw_circle(Vector2(0,-17),3.0,Color(1.0,0.4,0.1,0.22*lit*flick))
		draw_rect(Rect2(-0.5,-17.5,1.5,1.5),Color(1.0,0.5+0.3*flick,0.15,lit))
	_drawSmoke()


func _drawCenser():
	var bronze=Color(0.46,0.30,0.15)
	var light=Color(0.72,0.5,0.25)
	# kaki tiga
	draw_rect(Rect2(-6,-3,2,3),bronze)
	draw_rect(Rect2(-1,-3,2,3),bronze)
	draw_rect(Rect2(4,-3,2,3),bronze)
	# badan wadah
	draw_colored_polygon(PackedVector2Array([Vector2(-8,-10),Vector2(8,-10),Vector2(6,-3),Vector2(-6,-3)]),bronze)
	draw_line(Vector2(-8,-10),Vector2(8,-10),light,1.5)
	draw_line(Vector2(-6,-6),Vector2(6,-6),Color(0.3,0.19,0.1),1.0)
	# bara di dalamnya
	if lit>0.0:
		var flick=0.5+0.5*sin(time*9.0)
		draw_rect(Rect2(-4,-11,2,1),Color(1.0,0.35+0.3*flick,0.1,lit))
		draw_rect(Rect2(0,-11.5,2,1.5),Color(1.0,0.45+0.3*(1.0-flick),0.12,lit))
		draw_rect(Rect2(3,-11,1.5,1),Color(1.0,0.3,0.1,lit))
		draw_circle(Vector2(0,-11),6.0,Color(1.0,0.35,0.1,0.14*lit))
	_drawSmoke()


func _drawCandle():
	# badan lilin hitam
	draw_rect(Rect2(-1.5,-9,3,9),Color(0.12,0.1,0.15))
	draw_rect(Rect2(-1.5,-9,1,9),Color(0.28,0.24,0.34))
	draw_rect(Rect2(-2.5,-1,5,1),Color(0.2,0.16,0.2))
	if lit>0.0:
		var flick=0.5+0.5*sin(time*17.0+position.x)
		var height=4.0+1.5*flick
		draw_circle(Vector2(0,-12),7.0,Color(1.0,0.5,0.15,0.16*lit))
		draw_colored_polygon(PackedVector2Array([Vector2(0,-9-height),Vector2(-1.7,-10),Vector2(0,-8.5),Vector2(1.7,-10)]),Color(1.0,0.55,0.15,lit))
		draw_colored_polygon(PackedVector2Array([Vector2(0,-9-height*0.6),Vector2(-0.8,-9.8),Vector2(0,-9),Vector2(0.8,-9.8)]),Color(1.0,0.92,0.55,lit))
