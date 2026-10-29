extends Node2D

# Sigil ritual di lantai ruang Bhuta Kala (Ancient Dungeon), digambar seluruhnya lewat kode:
# cincin ganda, bintang terbalik, deretan rune, lalu membara dan mengeluarkan bara api.
#   reveal  0..1 : seberapa banyak sigil sudah tergambar (cincin -> bintang -> rune)
#   energy  0..1 : dari merah redup (0) sampai oranye menyala (1)
#   beam    0..1 : tiang cahaya yang naik dari tengah lingkaran
# Posisi node = pusat lingkaran di lantai.

const RADIUS=46.0
const RUNE_COUNT=24
# lingkaran dipipihkan supaya tampak menempel di lantai (sudut pandang miring seperti lantai dungeon)
const SQUASH=0.62

var reveal=0.0: set=_setReveal
var energy=0.0: set=_setEnergy
var beam=0.0: set=_setBeam

var embers=[]
var emberTime=0.0
var pulse=0.0


# titik di sekeliling lingkaran (sudah dipipihkan), dipakai untuk menaruh dupa dan lilin.
# index 0..4 = ujung bintang terbalik (ujung 0 menghadap ke bawah / selatan)
static func ringPoint(index_, scale_=1.0, offset_=0.0):
	var angle=PI/2.0+TAU*(float(index_)+offset_)/5.0
	return Vector2(cos(angle),sin(angle)*SQUASH)*RADIUS*scale_


func _setReveal(value_):
	reveal=value_
	queue_redraw()

func _setEnergy(value_):
	energy=value_
	queue_redraw()

func _setBeam(value_):
	beam=value_
	queue_redraw()


func _process(delta):
	if reveal<=0.0:
		return
	pulse+=delta
	# bara naik dari lingkaran begitu energinya cukup
	if energy>0.25:
		emberTime+=delta*(4.0+energy*40.0)
		while emberTime>=1.0:
			emberTime-=1.0
			_spawnEmber()
	var alive=[]
	for e in embers:
		e.life-=delta
		if e.life>0.0:
			e.pos+=e.vel*delta
			alive.append(e)
	embers=alive
	queue_redraw()


func _spawnEmber():
	var angle=randf()*TAU
	var dist=sqrt(randf())*RADIUS*0.95
	var life=randf_range(0.8,1.8)
	embers.append({
		"pos":Vector2(cos(angle)*dist,sin(angle)*dist*SQUASH),
		"vel":Vector2(randf_range(-7.0,7.0),randf_range(-36.0,-16.0)),
		"life":life,
		"max":life
	})


func _draw():
	if reveal<=0.0:
		return
	var base=Color(0.78,0.1,0.16)
	var hot=Color(1.0,0.62,0.3)
	var beat=0.5+0.5*sin(pulse*3.0)
	var heat=clampf(energy*0.85+beat*0.15*energy,0.0,1.0)
	var col=base.lerp(hot,heat)
	var glow=0.14+0.26*energy

	draw_set_transform(Vector2.ZERO,0.0,Vector2(1.0,SQUASH))

	var stage=reveal*3.0
	var ringFrac=clampf(stage,0.0,1.0)
	var starFrac=clampf(stage-1.0,0.0,1.0)
	var runeFrac=clampf(stage-2.0,0.0,1.0)

	# cahaya dasar di dalam lingkaran
	if energy>0.0:
		draw_circle(Vector2.ZERO,RADIUS*(0.55+0.4*energy),Color(col.r,col.g,col.b,0.08+0.16*energy))

	# cincin luar, cincin dalam, dan lingkaran kecil di tengah
	_arc(RADIUS,ringFrac,col,glow,2.0)
	_arc(RADIUS*0.86,ringFrac,col,glow,1.0)
	_arc(RADIUS*0.3,starFrac,col,glow,1.0)

	# bintang terbalik: lima garis digambar berurutan
	var pts=[]
	for i in 5:
		var angle=PI/2.0+TAU*float(i)/5.0
		pts.append(Vector2(cos(angle),sin(angle))*RADIUS*0.86)
	for k in 5:
		var t=clampf(starFrac*5.0-float(k),0.0,1.0)
		if t<=0.0:
			break
		var a=pts[(k*2)%5]
		var b=pts[((k+1)*2)%5]
		_seg(a,a.lerp(b,t),col,glow,1.0)
	if starFrac>=1.0:
		for p in pts:
			draw_circle(p,1.8,col)

	# rune di antara dua cincin
	var shown=int(runeFrac*RUNE_COUNT)
	for i in shown:
		var ang=-PI/2.0+TAU*float(i)/RUNE_COUNT
		var dir=Vector2(cos(ang),sin(ang))
		var r1=RADIUS*0.88
		var r2=RADIUS*0.985
		var side=Vector2(-dir.y,dir.x)*2.2
		var mid=dir*(r1+(r2-r1)*0.55)
		match i%3:
			0:
				_seg(dir*r1,dir*r2,col,glow,1.0)
			1:
				_seg(dir*r1+side,dir*r2-side,col,glow,1.0)
				_seg(dir*r1-side,dir*r2+side,col,glow,1.0)
			_:
				_seg(dir*r1,mid,col,glow,1.0)
				_seg(mid-side,mid+side,col,glow,1.0)

	# mata di pusat saat energi sudah besar
	if energy>0.5:
		draw_circle(Vector2.ZERO,2.0+3.0*energy,Color(1.0,0.85,0.55,0.35+0.4*energy))

	# bara api dan tiang cahaya digambar tanpa dipipihkan
	draw_set_transform(Vector2.ZERO,0.0,Vector2.ONE)

	if beam>0.0:
		var height=150.0*beam
		var width=14.0+10.0*beam
		var slices=12
		for i in slices:
			var f=float(i)/float(slices)
			var w=width*(1.0-0.5*f)
			var alpha=(1.0-f)*0.45*beam
			draw_rect(Rect2(-w*0.5,-height*f-height/float(slices),w,height/float(slices)+1.0),Color(1.0,0.5+0.3*(1.0-f),0.3,alpha))

	for e in embers:
		var f=e.life/e.max
		draw_rect(Rect2(e.pos-Vector2(0.5,0.5),Vector2(1.5,1.5)),Color(1.0,0.55+0.4*(1.0-f),0.2,clampf(f*1.4,0.0,1.0)))


func _arc(radius_,frac_,col_,glow_,width_):
	if frac_<=0.0:
		return
	var endAngle=-PI/2.0+TAU*frac_
	draw_arc(Vector2.ZERO,radius_,-PI/2.0,endAngle,72,Color(col_.r,col_.g,col_.b,glow_),width_*4.0,true)
	draw_arc(Vector2.ZERO,radius_,-PI/2.0,endAngle,72,col_,width_,true)


func _seg(a_,b_,col_,glow_,width_):
	draw_line(a_,b_,Color(col_.r,col_.g,col_.b,glow_),width_*4.0,true)
	draw_line(a_,b_,col_,width_,true)
