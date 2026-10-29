extends RefCounted

# Efek visual tiap senjata di layar pertarungan (dipanggil oleh common/fighters/player.gd).
# Semuanya dibuat lewat kode (Line2D, glow, percikan) supaya tidak butuh sheet baru:
#
#   Pedang Kayu      -> tebasan kayu + serpihan; Pedang Api: lengkung api + bara
#   Pedang Ksatria   -> tebasan baja, silang; serangan terkuat emas + gelombang kejut
#   Tongkat Kayu     -> ketukan pendek / bola sihir merah milik Vera
#   Busur (kayu/Pemburu) -> badan menarik tali, jejak panah, panah api berbara
#   Tongkat Penyihir -> lingkaran sihir, jejak bola sihir, petir, ledakan api
#   Botol Alkemis    -> gelembung, genangan ramuan, ledakan api
#   Jimat Exorcist   -> cincin cahaya, tiang cahaya suci
#   Orb Suci (Sage)  -> kilau hijau naik
#   Hiolo Sesat (Dukun) -> lingkaran mantra merah bara, asap & bara naik (skill panggil: api roh hijau)
#   Kunci Inggris    -> hantaman berat, percikan listrik
#   Belati Asasin    -> gerak terjang & tebasan sudah diurus spiderFight.gd (tidak diubah di sini)
#
# Gaya dipilih dari SENJATA yang dipegang + jenis serangan (styleOf), tingkat dari nama animasi
# (1 = biasa, 2 = lanjutan, 3 = khusus).

const Z_FX=55

const LEVEL_BY_ANIMATION={"attack_simple":1,"attack_advanced":2,"attack_special":3,"attack_ultimate":4}

# frame (mulai 0) saat senjata jarak dekat mengenai sasaran; badan menerjang satu frame sebelumnya
const HIT_FRAME={"attack_simple":4,"attack_advanced":5,"attack_special":5,"attack_ultimate":5}

# jarak terjang badan ke arah musuh (px) per tingkat
const LUNGE={1:12.0,2:20.0,3:28.0,4:36.0}

# warna utama & tepi per gaya
const PALETTE={
	"wood_sword":[Color(0.86,0.66,0.40),Color(1.0,0.94,0.78)],
	"knight":[Color(0.75,0.86,1.0),Color(1.0,1.0,1.0)],
	"staff_hit":[Color(1.0,0.38,0.5),Color(1.0,0.85,0.9)],
	"wrench":[Color(1.0,0.78,0.30),Color(1.0,1.0,0.85)],
	"wizard":[Color(0.5,0.85,1.0),Color(0.9,0.98,1.0)],
	"vera":[Color(1.0,0.35,0.5),Color(1.0,0.8,0.88)],
	"alchemy":[Color(0.45,1.0,0.5),Color(0.88,1.0,0.9)],
	"holy":[Color(1.0,0.9,0.5),Color(1.0,1.0,0.92)],
	"sage":[Color(0.45,1.0,0.7),Color(0.9,1.0,0.95)],
	"dukun":[Color(0.95,0.36,0.2),Color(0.86,0.83,0.9)],
	"bow":[Color(1.0,0.9,0.55),Color(1.0,1.0,0.9)],
	"gadget":[Color(0.35,0.95,1.0),Color(0.85,1.0,1.0)],
	"dagger":[Color(0.8,0.85,1.0),Color(1.0,1.0,1.0)]
}

# warna serangan khusus (tingkat 3)
const PALETTE_SPECIAL={
	"wood_sword":[Color(1.0,0.5,0.12),Color(1.0,0.95,0.5)],
	"knight":[Color(1.0,0.82,0.25),Color(1.0,1.0,0.85)],
	"wrench":[Color(0.4,0.9,1.0),Color(0.9,1.0,1.0)],
	"wizard":[Color(1.0,0.55,0.15),Color(1.0,0.92,0.5)],
	"alchemy":[Color(1.0,0.5,0.15),Color(1.0,0.9,0.5)],
	"dukun":[Color(0.45,1.0,0.55),Color(0.92,1.0,0.9)],
	"bow":[Color(1.0,0.5,0.15),Color(1.0,0.92,0.5)]
}

var _glowTex=null
var _addMat=null
var _crescentCurve=null
var _trailTick=0


# ---------------------------------------------------------------- pemilihan gaya

func level(animation_):
	return LEVEL_BY_ANIMATION.get(animation_,1)

# gaya efek dari senjata yang dipegang dan jenis serangannya
func styleOf(weaponId_, kind_):
	if kind_=="gadget":
		return "gadget"
	if kind_=="ranged":
		return "bow"
	if weaponId_==GlobalItems.ID.WOOD_SWORD:
		return "wood_sword"
	if weaponId_==GlobalItems.ID.KNIGHT_SWORD:
		return "knight"
	if weaponId_==GlobalItems.ID.SHADOW_DAGGER:
		return "dagger"
	if weaponId_==GlobalItems.ID.SCIFI_WRENCH:
		return "wrench"
	if weaponId_==GlobalItems.ID.MAGIC_STAFF:
		return "wizard"
	if weaponId_==GlobalItems.ID.ALCHEMY_FLASK:
		return "alchemy"
	if weaponId_==GlobalItems.ID.EXORCIST_PAPER:
		return "holy"
	if weaponId_==GlobalItems.ID.ORB_SUCI:
		return "sage"
	if weaponId_==GlobalItems.ID.DUKUN_STAFF:
		return "dukun"
	if weaponId_==GlobalItems.ID.WOODEN_STAFF:
		return "staff_hit" if kind_=="physical" else "vera"
	return "wood_sword" if kind_=="physical" else "vera"

# [warna utama, warna tepi]
func colors(style_, level_):
	if level_>=3 and PALETTE_SPECIAL.has(style_):
		return PALETTE_SPECIAL[style_]
	return PALETTE.get(style_,PALETTE["wood_sword"])

func _sparkColors(style_, level_):
	var c=colors(style_,level_)
	return [c[0],c[1],c[0].lightened(0.4)]


# ---------------------------------------------------------------- hook dari player.gd

# dipanggil saat animasi serang mulai: badan bersiap, aura / lingkaran sihir muncul
func windup(player_, origin_, weaponId_, animation_, kind_):
	var host=player_.get_parent()
	if host==null:
		return
	var style=styleOf(weaponId_,kind_)
	if str(animation_)=="attack_ultimate":
		# Ultimate: tahan sejenak, lingkaran rune berlapis, aura besar dan hujan partikel.
		var baseUltimate=player_.global_position
		var ultimateColors=PALETTE_SPECIAL.get(style,PALETTE.get(style,PALETTE["wood_sword"]))
		var mainColor=ultimateColors[0]
		var edgeColor=ultimateColors[1]
		player_.poseSprite(Vector2(-5.0,-2.0),0.28)
		runeCircle(host,player_,baseUltimate+Vector2(0,24),mainColor,34.0,0.85)
		ring(host,baseUltimate+Vector2(0,8),edgeColor,28.0,0.7,3.0)
		ring(host,baseUltimate+Vector2(0,8),mainColor,44.0,0.9,2.5)
		charge(host,origin_,mainColor,1.8,0.65)
		glow(host,baseUltimate+Vector2(0,-12),edgeColor,1.7,0.65,2.0)
		sparks(host,baseUltimate+Vector2(0,4),[mainColor,edgeColor,Color(1,1,1)],18,32.0,0.8,-20.0,3.0)
		_shake(host)
		return
	var lv=level(animation_)
	var c=colors(style,lv)
	var base=player_.global_position
	match style:
		"wood_sword","knight","staff_hit","wrench":
			# tarik badan ke belakang sebelum menerjang
			player_.poseSprite(Vector2(-2.0-float(lv),0.0),0.22)
			if lv>=3:
				charge(host,base+Vector2(14,-8),c[0],0.8,0.32)
				sparks(host,base+Vector2(12,-6),_sparkColors(style,lv),5,12.0,0.3,-8.0)
		"bow":
			player_.poseSprite(Vector2(-3.0,0.0),0.26)
			if lv>=2:
				charge(host,base+Vector2(18,2),c[0],0.5+0.15*float(lv),0.3)
		"wizard","vera":
			runeCircle(host,player_,base+Vector2(0,24),c[0],14.0+6.0*float(lv),0.5)
			charge(host,origin_,c[0],0.5+0.2*float(lv),0.34)
		"alchemy":
			charge(host,origin_,c[0],0.5+0.15*float(lv),0.3)
			sparks(host,origin_,_sparkColors(style,lv),4+lv,10.0,0.5,-16.0,3.0)
		"holy":
			ring(host,base+Vector2(0,-26),c[0],12.0+4.0*float(lv),0.45,1.5)
			# v9.31: tanpa bola cahaya (orb hanya milik Sage); serpihan emas seperti kertas jimat yang bergetar
			sparks(host,origin_,_sparkColors(style,lv),4+lv,10.0,0.4,-10.0,2.0)
			if lv>=2:
				runeCircle(host,player_,base+Vector2(0,24),c[0],16.0+4.0*float(lv),0.5)
		"sage":
			charge(host,origin_,c[0],0.5+0.15*float(lv),0.32)
			sparks(host,base+Vector2(0,10),_sparkColors(style,lv),4+lv,14.0,0.55,-18.0,2.0)
		"dukun":
			# v9.31: dupa. Lingkaran mantra merah bara di kaki, asap dan bara naik dari Hiolo (tanpa bola cahaya;
			# juga dipakai saat memanggil makhluk, tingkat 3 = api roh hijau)
			runeCircle(host,player_,base+Vector2(0,24),c[0],14.0+6.0*float(lv),0.55)
			sparks(host,origin_,_sparkColors(style,lv),5+lv,12.0,0.7,-22.0,2.0)
		"gadget":
			charge(host,origin_,c[0],0.7,0.3)
			sparks(host,origin_,_sparkColors(style,lv),6,12.0,0.3)

# dipanggil tiap pergantian frame animasi serang (serangan jarak dekat)
func onFrame(player_, weaponId_, animation_, kind_, frame_):
	if kind_!="physical":
		return
	var style=styleOf(weaponId_,kind_)
	if style=="dagger":
		return
	var hit=HIT_FRAME.get(animation_,3)
	var lv=level(animation_)
	if frame_==hit-1:
		_lunge(player_,lv)
	elif frame_==hit:
		_strike(player_,style,lv)

# dipanggil saat proyektil dilepas
func onLaunch(player_, origin_, weaponId_, animation_, kind_):
	var host=player_.get_parent()
	if host==null:
		return
	var style=styleOf(weaponId_,kind_)
	var lv=level(animation_)
	var c=colors(style,lv)
	if style=="bow":
		# tali dilepas: badan tersentak ke depan, kepulan kecil di ujung busur
		player_.poseSprite(Vector2(1.5,0.0),0.05)
		ring(host,origin_,c[1],7.0+2.0*float(lv),0.18,1.5)
		sparks(host,origin_,[c[0],c[1]],3,8.0,0.18)
	else:
		glow(host,origin_,c[1],0.7+0.15*float(lv),0.18,1.8)

# dipanggil tiap frame selama proyektil terbang: jejak di belakangnya
func trail(t_, host_, sprite_, style_, level_):
	if host_==null or !is_instance_valid(host_) or !is_instance_valid(sprite_):
		return
	var pos=sprite_.global_position
	var c=colors(style_,level_)
	_trailTick+=1
	match style_:
		"bow":
			# garis cepat; panah api meninggalkan bara
			_dot(host_,pos,c[1],Vector2(5,1.5),0.14,Vector2.ZERO)
			if level_>=3 and _trailTick%2==0:
				_dot(host_,pos,c[0],Vector2(3,3),0.3,Vector2(0,-8))
		"alchemy":
			if _trailTick%2==0:
				_dot(host_,pos,c[1],Vector2(3,3),0.35,Vector2(randf_range(-4,4),-10))
		_:
			if _trailTick%2==0:
				glow(host_,pos,c[0],0.32+0.06*float(level_),0.24,0.25)

# dipanggil saat proyektil mengenai sasaran
func impact(host_, pos_, weaponId_, animation_, kind_):
	if host_==null or !is_instance_valid(host_):
		return
	var style=styleOf(weaponId_,kind_)
	var lv=level(animation_)
	var c=colors(style,lv)
	var sp=_sparkColors(style,lv)
	match style:
		"bow":
			ring(host_,pos_,c[1],12.0+3.0*float(lv),0.22,1.5)
			sparks(host_,pos_,[Color(0.62,0.42,0.24),c[0],c[1]],5+lv,14.0,0.3,10.0)
			if lv>=3:
				glow(host_,pos_,c[0],1.4,0.3,1.5)
				sparks(host_,pos_,sp,8,20.0,0.5,-14.0)
		"wizard":
			glow(host_,pos_,c[0],1.0+0.3*float(lv),0.3,1.5)
			ring(host_,pos_,c[1],14.0+6.0*float(lv),0.3,2.0)
			if lv==2:
				# Petir Sihir: sambaran dari atas
				bolt(host_,pos_+Vector2(randf_range(-6,6),-70),pos_,c[1],2.5,0.22,8.0,8)
				bolt(host_,pos_+Vector2(randf_range(-10,10),-70),pos_,c[0],1.5,0.2,10.0,8)
			if lv>=3:
				ring(host_,pos_,c[0],34.0,0.4,2.5)
				sparks(host_,pos_,sp,12,26.0,0.5,-12.0,3.0)
				_shake(host_)
		"vera":
			glow(host_,pos_,c[0],1.0+0.2*float(lv),0.28,1.5)
			ring(host_,pos_,c[1],14.0+4.0*float(lv),0.26,2.0)
		"alchemy":
			puddle(host_,pos_+Vector2(0,14),c[0],12.0+4.0*float(lv),0.9)
			sparks(host_,pos_,sp,5+2*lv,16.0,0.6,-18.0,3.0)
			glow(host_,pos_,c[1],0.9,0.25,1.4)
			if lv>=3:
				glow(host_,pos_,c[0],1.8,0.35,1.5)
				ring(host_,pos_,c[0],30.0,0.35,2.5)
				_shake(host_)
		"holy":
			pillar(host_,pos_+Vector2(0,18),c[0],54.0+10.0*float(lv),10.0+3.0*float(lv),0.4)
			ring(host_,pos_,c[1],16.0+6.0*float(lv),0.32,2.0)
			if lv>=3:
				ring(host_,pos_,c[0],38.0,0.45,2.5)
				_shake(host_)
		"sage":
			glow(host_,pos_,c[0],1.0,0.3,1.5)
			sparks(host_,pos_,sp,6+lv,14.0,0.6,-20.0,2.0)
			ring(host_,pos_,c[1],14.0+4.0*float(lv),0.28,1.5)
		"dukun":
			glow(host_,pos_,c[0],1.1+0.2*float(lv),0.3,1.5)
			ring(host_,pos_,c[1],14.0+5.0*float(lv),0.3,2.0)
			sparks(host_,pos_,sp,6+2*lv,16.0,0.6,-16.0,2.0)
		_:
			glow(host_,pos_,c[0],0.9,0.25,1.4)


# ---------------------------------------------------------------- serangan jarak dekat

func _lunge(player_, lv_):
	var to=player_.targetPosition
	if to==null:
		return
	var delta=to-player_.global_position
	var reach=min(LUNGE[lv_],max(0.0,delta.length()-36.0))
	player_.poseSprite(delta.normalized()*reach,0.07)
	if lv_>=2:
		_ghost(player_,Color(1,1,1,0.45) if lv_==2 else Color(1.0,0.85,0.4,0.55))

func _ghost(player_, color_):
	var src=player_.get_node_or_null("AnimatedSprite2D")
	var host=player_.get_parent()
	if src==null or host==null or src.sprite_frames==null or !src.sprite_frames.has_animation(src.animation):
		return
	var tex=src.sprite_frames.get_frame_texture(src.animation,src.frame)
	if tex==null:
		return
	var ghost=Sprite2D.new()
	ghost.texture=tex
	ghost.modulate=color_
	ghost.z_index=4
	host.add_child(ghost)
	ghost.global_position=src.global_position
	var tw=ghost.create_tween()
	tw.tween_property(ghost,"modulate:a",0.0,0.2)
	tw.tween_callback(ghost.queue_free)

# efek di tubuh musuh saat senjata jarak dekat kena
func _strike(player_, style_, lv_):
	var host=player_.get_parent()
	if host==null:
		return
	var to=player_.targetPosition
	if to==null:
		to=player_.global_position+Vector2(110,-40)
	var c=colors(style_,lv_)
	var sp=_sparkColors(style_,lv_)
	match style_:
		"wood_sword":
			arc(host,to+Vector2(-6,8),24.0,deg_to_rad(-140.0),deg_to_rad(10.0),c[0],4.0,0.1,0.2)
			sparks(host,to,[Color(0.62,0.42,0.24),c[0],c[1]],6,16.0,0.3,12.0)
			if lv_>=2:
				arc(host,to+Vector2(6,-6),22.0,deg_to_rad(170.0),deg_to_rad(30.0),c[1],3.0,0.1,0.18,0.08)
				sparks(host,to+Vector2(0,16),[Color(0.7,0.6,0.45),Color(0.85,0.78,0.6)],5,12.0,0.35,8.0)
			if lv_>=3:
				# Pedang Api: lengkung menyala, bara naik
				arc(host,to+Vector2(0,0),30.0,deg_to_rad(-170.0),deg_to_rad(30.0),c[1],3.0,0.12,0.22,0.04)
				glow(host,to,c[0],1.5,0.3,1.4)
				sparks(host,to,sp,10,22.0,0.55,-18.0,3.0)
				_shake(host)
		"knight":
			arc(host,to+Vector2(-4,6),24.0,deg_to_rad(-150.0),deg_to_rad(5.0),c[0],4.0,0.09,0.2)
			streak(host,to,deg_to_rad(35.0),34.0,c[1],2.0,0.03)
			sparks(host,to,sp,6,16.0,0.25)
			if lv_>=2:
				arc(host,to+Vector2(4,-4),24.0,deg_to_rad(175.0),deg_to_rad(20.0),c[1],3.0,0.09,0.18,0.07)
				streak(host,to,deg_to_rad(-35.0),38.0,c[0],2.5,0.08)
				ring(host,to,c[1],16.0,0.22,1.5)
			if lv_>=3:
				# serangan terkuat: tebasan silang emas + gelombang kejut
				streak(host,to,deg_to_rad(-60.0),58.0,c[0],3.5,0.0)
				streak(host,to,deg_to_rad(60.0),58.0,c[1],3.5,0.07)
				streak(host,to,deg_to_rad(90.0),50.0,c[0],2.5,0.14)
				ring(host,to,c[0],36.0,0.4,3.0)
				glow(host,to,c[0],1.6,0.3,1.4)
				sparks(host,to,sp,12,26.0,0.45,6.0,3.0)
				_shake(host)
		"staff_hit":
			arc(host,to+Vector2(-4,4),20.0,deg_to_rad(-130.0),deg_to_rad(0.0),c[0],3.0,0.09,0.16)
			ring(host,to,c[1],12.0,0.2,1.5)
			sparks(host,to,[c[0],c[1],Color(0.6,0.4,0.25)],5,14.0,0.28,8.0)
		"wrench":
			# hantaman: cincin kejut + debu, tingkat 3 menyetrum
			arc(host,to+Vector2(-2,-2),20.0,deg_to_rad(-120.0),deg_to_rad(-10.0),c[0],5.0,0.08,0.16)
			ring(host,to,c[1],16.0+6.0*float(lv_),0.25,2.0)
			sparks(host,to,sp,6+lv_,18.0,0.3,10.0,3.0)
			if lv_>=3:
				bolt(host,to+Vector2(-26,-14),to+Vector2(26,14),c[1],2.0,0.22,8.0,6)
				bolt(host,to+Vector2(-24,16),to+Vector2(24,-16),c[0],2.0,0.22,8.0,6)
				glow(host,to,c[0],1.5,0.3,1.4)
				ring(host,to,c[0],34.0,0.4,2.5)
				_shake(host)
			elif lv_>=2:
				_shake(host)
		_:
			ring(host,to,c[1],14.0,0.22,1.5)
			sparks(host,to,sp,6,16.0,0.28)


# ---------------------------------------------------------------- bahan dasar efek

func _additive():
	if _addMat==null:
		_addMat=CanvasItemMaterial.new()
		_addMat.blend_mode=CanvasItemMaterial.BLEND_MODE_ADD
	return _addMat

func _glowTexture():
	if _glowTex==null:
		var gradient=Gradient.new()
		gradient.set_color(0,Color(1,1,1,1))
		gradient.set_color(1,Color(1,1,1,0))
		var tex=GradientTexture2D.new()
		tex.gradient=gradient
		tex.fill=GradientTexture2D.FILL_RADIAL
		tex.fill_from=Vector2(0.5,0.5)
		tex.fill_to=Vector2(1.0,0.5)
		tex.width=64
		tex.height=64
		_glowTex=tex
	return _glowTex

func _crescent():
	# lebar garis: ekor tipis, kepala tebal (kesan menyapu)
	if _crescentCurve==null:
		var curve=Curve.new()
		curve.add_point(Vector2(0.0,0.05))
		curve.add_point(Vector2(0.8,1.0))
		curve.add_point(Vector2(1.0,0.7))
		_crescentCurve=curve
	return _crescentCurve

func _put(host_, node_, pos_):
	node_.z_index=Z_FX
	host_.add_child(node_)
	node_.global_position=pos_

func _shake(host_):
	if host_!=null and host_.has_method("_shakeScreen"):
		host_._shakeScreen()

# bola cahaya lembut; size_ 1.0 = 64 px, membesar/mengecil sebesar grow_ lalu memudar
func glow(host_, pos_, color_, size_=1.0, time_=0.25, grow_=1.0):
	var s=Sprite2D.new()
	s.texture=_glowTexture()
	s.material=_additive()
	s.modulate=color_
	s.scale=Vector2(size_,size_)
	_put(host_,s,pos_)
	var tw=s.create_tween()
	tw.tween_property(s,"scale",Vector2(size_*grow_,size_*grow_),time_)
	tw.parallel().tween_property(s,"modulate:a",0.0,time_)
	tw.tween_callback(s.queue_free)
	return s

# cahaya yang membesar perlahan (mengumpulkan tenaga) lalu padam
func charge(host_, pos_, color_, size_=0.8, time_=0.3):
	var s=Sprite2D.new()
	s.texture=_glowTexture()
	s.material=_additive()
	s.modulate=Color(color_.r,color_.g,color_.b,0.0)
	s.scale=Vector2(size_*0.2,size_*0.2)
	_put(host_,s,pos_)
	var tw=s.create_tween()
	tw.tween_property(s,"scale",Vector2(size_,size_),time_).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(s,"modulate:a",0.95,time_)
	tw.tween_property(s,"modulate:a",0.0,0.12)
	tw.tween_callback(s.queue_free)

# cincin yang melebar
func ring(host_, pos_, color_, radius_=18.0, time_=0.28, width_=2.0):
	var k=max(1.0,radius_/8.0)
	var line=Line2D.new()
	line.default_color=color_
	line.width=width_/k
	line.closed=true
	var pts=PackedVector2Array()
	for i in 24:
		var a=TAU*float(i)/24.0
		pts.append(Vector2(cos(a),sin(a))*8.0)
	line.points=pts
	line.scale=Vector2(0.3,0.3)
	_put(host_,line,pos_)
	var tw=line.create_tween()
	tw.tween_property(line,"scale",Vector2(k,k),time_).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(line,"modulate:a",0.0,time_)
	tw.tween_callback(line.queue_free)

# percikan kecil; gravity_ > 0 jatuh, < 0 naik
func sparks(host_, pos_, colors_, count_=8, dist_=18.0, time_=0.3, gravity_=0.0, size_=2.0):
	for i in count_:
		var r=ColorRect.new()
		r.size=Vector2(size_,size_)
		r.color=colors_[i%colors_.size()]
		_put(host_,r,pos_)
		var ang=TAU*float(i)/float(count_)+randf()*0.6
		var dist=dist_*randf_range(0.6,1.2)
		var to=pos_+Vector2(cos(ang),sin(ang))*dist+Vector2(0,gravity_)
		var tw=r.create_tween()
		tw.tween_property(r,"global_position",to,time_).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.parallel().tween_property(r,"modulate:a",0.0,time_)
		tw.tween_callback(r.queue_free)

# titik kecil (jejak proyektil): menyusut sambil memudar dan hanyut sedikit
func _dot(host_, pos_, color_, size_, time_, drift_):
	var r=ColorRect.new()
	r.size=size_
	r.color=color_
	_put(host_,r,pos_-size_/2.0)
	var tw=r.create_tween()
	tw.tween_property(r,"modulate:a",0.0,time_)
	tw.parallel().tween_property(r,"scale",Vector2(0.2,0.2),time_)
	if drift_!=Vector2.ZERO:
		tw.parallel().tween_property(r,"global_position",r.global_position+drift_,time_)
	tw.tween_callback(r.queue_free)

# lengkung tebasan yang menyapu dari from_ ke to_ (radian) di sekitar center_
func arc(host_, center_, radius_, from_, to_, color_, width_=3.0, time_=0.1, fade_=0.16, delay_=0.0):
	var line=Line2D.new()
	line.default_color=color_
	line.width=width_
	line.begin_cap_mode=Line2D.LINE_CAP_ROUND
	line.end_cap_mode=Line2D.LINE_CAP_ROUND
	line.width_curve=_crescent()
	line.visible=false
	_put(host_,line,center_)
	var tw=line.create_tween()
	if delay_>0.0:
		tw.tween_interval(delay_)
	tw.tween_callback(line.show)
	tw.tween_method(_setArc.bind(line,radius_,from_,to_),0.0,1.0,time_)
	tw.tween_property(line,"modulate:a",0.0,fade_)
	tw.tween_callback(line.queue_free)

func _setArc(t_, line_, radius_, from_, to_):
	if !is_instance_valid(line_):
		return
	var pts=PackedVector2Array()
	var steps=10
	var head=lerp(from_,to_,t_)
	var tail=lerp(from_,to_,max(0.0,t_-0.55))
	for i in steps+1:
		var a=lerp(tail,head,float(i)/float(steps))
		pts.append(Vector2(cos(a),sin(a))*radius_)
	line_.points=pts

# garis tebasan lurus yang memanjang dari satu sisi ke sisi lain
func streak(host_, center_, angle_, length_, color_, width_=2.5, delay_=0.0, time_=0.08):
	var line=Line2D.new()
	line.default_color=color_
	line.width=width_
	line.begin_cap_mode=Line2D.LINE_CAP_ROUND
	line.end_cap_mode=Line2D.LINE_CAP_ROUND
	line.visible=false
	_put(host_,line,center_)
	var dir=Vector2(cos(angle_),sin(angle_))
	var tw=line.create_tween()
	if delay_>0.0:
		tw.tween_interval(delay_)
	tw.tween_callback(line.show)
	tw.tween_method(_setStreak.bind(line,dir,length_),0.0,1.0,time_)
	tw.tween_property(line,"modulate:a",0.0,0.18)
	tw.tween_callback(line.queue_free)

func _setStreak(t_, line_, dir_, length_):
	if !is_instance_valid(line_):
		return
	var start=-dir_*length_/2.0
	line_.points=PackedVector2Array([start,start+dir_*length_*t_])

# sambaran petir bergerigi dari from_ ke to_ (koordinat global)
func bolt(host_, from_, to_, color_, width_=2.0, time_=0.18, jitter_=7.0, segments_=7):
	var dir=to_-from_
	var normal=dir.orthogonal().normalized()
	var pts=PackedVector2Array()
	for i in segments_+1:
		var p=dir*(float(i)/float(segments_))
		if i>0 and i<segments_:
			p+=normal*randf_range(-jitter_,jitter_)
		pts.append(p)
	for pass_ in 2:
		var line=Line2D.new()
		line.points=pts
		line.begin_cap_mode=Line2D.LINE_CAP_ROUND
		line.end_cap_mode=Line2D.LINE_CAP_ROUND
		if pass_==0:
			# lapisan cahaya di belakang
			line.default_color=Color(color_.r,color_.g,color_.b,0.35)
			line.width=width_*3.0
			line.material=_additive()
		else:
			line.default_color=color_
			line.width=width_
		_put(host_,line,from_)
		var tw=line.create_tween()
		tw.tween_property(line,"modulate:a",0.0,time_)
		tw.tween_callback(line.queue_free)

# lingkaran sihir miring di tanah (diletakkan tepat di belakang petarung supaya kaki tetap terlihat)
func runeCircle(host_, below_, pos_, color_, radius_=22.0, time_=0.5):
	var holder=Node2D.new()
	holder.scale=Vector2(1.0,0.38)
	var spin=Node2D.new()
	holder.add_child(spin)
	spin.add_child(_polyLine(radius_,28,color_,1.5,0.0))
	spin.add_child(_polyLine(radius_*0.8,4,color_,1.0,0.0))
	spin.add_child(_polyLine(radius_*0.8,4,color_,1.0,PI/4.0))
	host_.add_child(holder)
	holder.global_position=pos_
	if below_!=null and below_.get_parent()==host_:
		host_.move_child(holder,below_.get_index())
	holder.modulate.a=0.0
	var tw=holder.create_tween()
	tw.tween_property(holder,"modulate:a",0.9,0.12)
	tw.parallel().tween_property(spin,"rotation",PI*0.8,time_)
	tw.tween_property(holder,"modulate:a",0.0,0.15)
	tw.tween_callback(holder.queue_free)

func _polyLine(radius_, sides_, color_, width_, rot_):
	var line=Line2D.new()
	line.default_color=color_
	line.width=width_
	line.closed=true
	var pts=PackedVector2Array()
	for i in sides_:
		var a=rot_+TAU*float(i)/float(sides_)
		pts.append(Vector2(cos(a),sin(a))*radius_)
	line.points=pts
	return line

# tiang cahaya suci yang turun menimpa sasaran
func pillar(host_, pos_, color_, height_=70.0, width_=14.0, time_=0.35):
	var r=ColorRect.new()
	r.color=Color(color_.r,color_.g,color_.b,0.75)
	r.size=Vector2(width_,height_)
	r.pivot_offset=Vector2(width_/2.0,height_)
	r.material=_additive()
	_put(host_,r,pos_+Vector2(-width_/2.0,-height_))
	r.scale=Vector2(0.2,1.0)
	var tw=r.create_tween()
	tw.tween_property(r,"scale:x",1.0,0.08)
	tw.tween_property(r,"scale:x",0.0,time_)
	tw.parallel().tween_property(r,"modulate:a",0.0,time_)
	tw.tween_callback(r.queue_free)
	glow(host_,pos_,color_,1.0,0.3,1.5)

# genangan ramuan di tanah
func puddle(host_, pos_, color_, radius_=14.0, time_=0.9):
	var poly=Polygon2D.new()
	var pts=PackedVector2Array()
	for i in 16:
		var a=TAU*float(i)/16.0
		pts.append(Vector2(cos(a)*radius_,sin(a)*radius_*0.4))
	poly.polygon=pts
	poly.color=Color(color_.r,color_.g,color_.b,0.55)
	poly.scale=Vector2(0.2,0.2)
	_put(host_,poly,pos_)
	var tw=poly.create_tween()
	tw.tween_property(poly,"scale",Vector2(1.0,1.0),0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_interval(time_*0.4)
	tw.tween_property(poly,"modulate:a",0.0,time_*0.6)
	tw.tween_callback(poly.queue_free)
