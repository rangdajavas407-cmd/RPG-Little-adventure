extends "res://screens/ending/epic/epicStage.gd"

# Epilog sinematik. Urutan bab:
#  A  Darkus tersadar dan bingung            B  Ranbyus teringat Adek, memotong Darkus, pergi mencari buah
#  1  Buah Suwarga di ruang terdalam         2  Lari keluar dungeon bersama Darkus
#  3  Menghampiri Pak Tabib                  4  Rombongan menuju Desa Pohon (Kades Beruang + Ibu Toko Kepiting ikut)
#  5  Tiba di Desa Pohon, warga menyambut ("kamu yang memperbaiki sumur kami")   6  Pak Tabib merawat Adek dengan Buah Suwarga
#  7  Adek sadar                             8  Adek berlari keluar rumah, semua bergembira
#  9  Adek berlari, melompat memeluk Kakak   9b Warga memberi selamat (sprite warga sendiri)
#  10 Penutup bersama
#  11 Darkus bercerita tentang garis keturunan Leviathan, lalu TAMAT

const PAL={
	"dawn":{"top":Color("#2a2150"),"bot":Color("#f2a06c"),"sx":210,"sy":112,"sr":14,"sc":Color("#ffe3a6"),"sg":Color(1,0.7,0.4,0.55),"m1":Color("#47386d"),"m2":Color("#35295a"),"tree":Color("#1c1a33"),"gr":Color("#3b5a45"),"rd":Color("#85705a")},
	"day":{"top":Color("#5fb0e6"),"bot":Color("#d4ecf7"),"sx":250,"sy":26,"sr":12,"sc":Color("#fff6c9"),"sg":Color(1,0.95,0.7,0.35),"m1":Color("#86a6c9"),"m2":Color("#6c8eb0"),"tree":Color("#3d7a47"),"gr":Color("#58a04c"),"rd":Color("#c6a76d")},
	"dusk":{"top":Color("#34244f"),"bot":Color("#ff9456"),"sx":90,"sy":104,"sr":16,"sc":Color("#ffd08a"),"sg":Color(1,0.55,0.3,0.6),"m1":Color("#5b3b6e"),"m2":Color("#46305a"),"tree":Color("#241a34"),"gr":Color("#3d5a3a"),"rd":Color("#8d6d55")},
	"night":{"top":Color("#070a1c"),"bot":Color("#1c2447"),"sx":240,"sy":30,"sr":11,"sc":Color("#e8eeff"),"sg":Color(0.6,0.7,1,0.4),"m1":Color("#1a2140"),"m2":Color("#141a33"),"tree":Color("#0b1022"),"gr":Color("#1d3a33"),"rd":Color("#3b3a4a")},
	"morning":{"top":Color("#7cc3ec"),"bot":Color("#ffe6b8"),"sx":150,"sy":70,"sr":14,"sc":Color("#fff0b8"),"sg":Color(1,0.9,0.6,0.5),"m1":Color("#9fb9d6"),"m2":Color("#86a3c4"),"tree":Color("#3f8a4c"),"gr":Color("#62ad52"),"rd":Color("#d2b57c")}
}
var tone_node: CanvasModulate

func tone(col,sec=1.0):
	var t=create_tween(); t.tween_property(tone_node,"color",col,sec); await t.finished

func slowmo(scale,sec):
	Engine.time_scale=scale
	await get_tree().create_timer(sec,true,false,true).timeout
	Engine.time_scale=1.0

# ================================================================ warga desa (v9.13)
# Lima penduduk Desa Pohon dengan sprite sendiri (tools/make_warga_sprites.py).
const WARGA=["wayan","made","kadek","nyoman","putu"]
const WARGA_KIND={"wayan":"warga1","made":"warga2","kadek":"warga3","nyoman":"warga4","putu":"warga5"}
const WARGA_MORNING={"kadek":Vector2(28,152),"made":Vector2(76,140),"nyoman":Vector2(178,141),"wayan":Vector2(268,141),"putu":Vector2(304,152)}

# layout: {"id": posisi}. Warga di kanan layar (x > 160) menghadap ke kiri.
func add_warga(layout,flip_all=false):
	for id in layout:
		add_actor(id,WARGA_KIND[id],layout[id],flip_all or layout[id].x>160.0)

# semua warga bersorak (tangan terangkat) lalu kembali berdiri
func warga_cheer(ids,sec=1.6):
	for id in ids:
		anim(id,"cheer")
		hop(id,3.0,3)
	await wait(sec)
	for id in ids:
		anim(id,"idle")

func _run():
	tone_node=CanvasModulate.new(); add_child(tone_node)
	await bars(true,0.1)
	# dari rumah Ranbyus (buah diberikan di rumah) mulai di bab 6; dari dungeon mulai dari bab A
	if GlobalScenes.getParamForSceneOr("story","epic_from_home",false) != true:
		await ch_a_wake()
		await ch_b_cutoff()
		await ch_1_fruit()
		await ch_2_run()
		await ch_3_tabib()
		await ch_4_journey()
		await ch_5_arrive()
	await ch_6_heal()
	await ch_7_wake()
	await ch_8_run_out()
	await ch_9_thanks()
	await ch_9b_warga()
	await ch_10_together()
	await ch_11_lore()
	hide_box()

# ================================================================ latar
func set_hall(width):
	reset_world()
	var bg=layer(0.0); sky(bg,Color("#0a0912"),Color("#1d1731"))
	var far=layer(0.5)
	for x in range(-120,int(width*0.5)+420,56):
		rect(far,x,24,10,106,Color("#171226"))
		poly(far,[Vector2(x+10,130),Vector2(x+10,66),Vector2(x+28,44),Vector2(x+46,66),Vector2(x+46,130)],Color("#120e1f"))
	var mid=layer(1.0)
	rect(mid,-240,128,width+640,80,Color("#26203a")); rect(mid,-240,124,width+640,4,Color("#3b3258"))
	for x in range(-240,int(width)+400,24): rect(mid,x,128,1,80,Color("#1c172b"))
	for x in range(40,int(width)+240,150):
		rect(mid,x,52,3,16,Color("#4a3f35")); disc(mid,Vector2(x+1.5,47),3,Color("#ffb347"),8)
		glow(mid,Vector2(x+1.5,48),36,Color(1.0,0.55,0.2,0.7),true)
	return mid

func set_chamber():
	reset_world()
	var bg=layer(0.0); sky(bg,Color("#04141a"),Color("#0d3a3a"))
	var back=layer(1.0)
	for i in 9:
		var x=-20+i*40
		poly(back,[Vector2(x,-20),Vector2(x+16,-20),Vector2(x+8,22+(i*13)%30)],Color("#082229"))
		poly(back,[Vector2(x+14,185),Vector2(x+30,185),Vector2(x+22,148-(i*17)%26)],Color("#082229"))
	rect(back,-240,132,800,60,Color("#0e4a4c"))
	glow(back,Vector2(160,150),130,Color(0.2,0.9,0.8,0.25))
	rect(back,126,118,68,16,Color("#3a4a4e")); rect(back,134,108,52,12,Color("#4b5f63")); rect(back,142,100,36,9,Color("#5f777b"))
	beam(back,160,-10,128,26,72,Color(1.0,0.9,0.5,0.20))
	var fruit=Node2D.new(); fruit.position=Vector2(160,86); back.add_child(fruit)
	poly(fruit,[Vector2(-1,-6),Vector2(-9,-12),Vector2(-4,-4)],Color("#4ccf6a")); poly(fruit,[Vector2(1,-6),Vector2(9,-12),Vector2(4,-4)],Color("#3fb85c"))
	disc(fruit,Vector2.ZERO,7,Color("#ffcf4d")); disc(fruit,Vector2(-2,-2),3,Color("#fff1b0"),10); disc(fruit,Vector2(2,3),3,Color("#ff9a5a"),10)
	glow(fruit,Vector2.ZERO,48,Color(1,0.85,0.4,0.9),true)
	fruit.name="fruit"
	var bob=fruit.create_tween().set_loops(); bob.tween_property(fruit,"position:y",82.0,1.4).set_trans(Tween.TRANS_SINE); bob.tween_property(fruit,"position:y",87.0,1.4).set_trans(Tween.TRANS_SINE)
	fruit.set_meta("bob",bob)
	puff(back,Vector2(160,110),Vector2(40,20),30,3.5,Vector2(0,-1),20,10,Color(1.0,0.95,0.6,0.9),Vector2.ZERO,1.5)
	return fruit

func set_road(pal,width):
	reset_world()
	var P=PAL[pal]
	var bg=layer(0.0); sky(bg,P.top,P.bot)
	if pal=="night":
		for i in 40: rect(bg,(i*53)%320,(i*29)%90,1.5,1.5,Color(1,1,1,0.8))
	disc(bg,Vector2(P.sx,P.sy),P.sr,P.sc,20); glow(bg,Vector2(P.sx,P.sy),90,P.sg)
	var m1=layer(0.1); var m2=layer(0.3); var tr=layer(0.65); var gr=layer(1.0)
	for x in range(-260,int(width*0.1)+420,110): poly(m1,[Vector2(x,126),Vector2(x+55,52+abs(sin(x*0.37))*34),Vector2(x+110,126)],P.m1)
	for x in range(-260,int(width*0.3)+420,80): poly(m2,[Vector2(x,130),Vector2(x+40,84+abs(sin(x*0.71))*22),Vector2(x+80,130)],P.m2)
	for x in range(-200,int(width*0.65)+420,34):
		var h=26+abs(sin(x*0.9))*14
		poly(tr,[Vector2(x,132),Vector2(x+11,132-h),Vector2(x+22,132)],P.tree); rect(tr,x+9,132,4,6,Color("#2a1d18"))
	rect(gr,-260,130,width+700,70,P.gr); rect(gr,-260,138,width+700,18,P.rd); rect(gr,-260,137,width+700,1,Color(0,0,0,0.25))
	for x in range(-260,int(width)+440,47): rect(gr,x,141+(x*7)%9,3,1,Color(0,0,0,0.2))
	return gr

func set_village(pal):
	var gr=set_road(pal,320)
	var P=PAL[pal]
	var tree=layer(1.0)
	poly(tree,[Vector2(128,134),Vector2(140,86),Vector2(146,34),Vector2(174,34),Vector2(180,86),Vector2(194,134)],Color("#5a3d2b"))
	poly(tree,[Vector2(146,40),Vector2(150,134),Vector2(156,134),Vector2(154,40)],Color("#6b4a35"))
	for c in [[100,30,34],[130,10,36],[166,2,40],[204,10,36],[232,30,34],[150,34,36],[186,34,36],[120,48,28],[214,48,28]]:
		disc(tree,Vector2(c[0],c[1]),c[2],Color("#2f6b3a")); disc(tree,Vector2(c[0]-6,c[1]-6),c[2]*0.6,Color("#3f8a4a"))
	for hx in [78,226]:
		rect(tree,hx,58,34,26,Color("#7a5238")); poly(tree,[Vector2(hx-4,58),Vector2(hx+17,42),Vector2(hx+38,58)],Color("#a4553d"))
		rect(tree,hx+11,66,9,10,Color("#ffcf70")); glow(tree,Vector2(hx+15,70),26,Color(1,0.75,0.35,0.6),pal=="dusk" or pal=="night")
	for lx in [40,280]:
		rect(tree,lx,104,2,32,Color("#4a3a2e")); glow(tree,Vector2(lx+1,102),30,Color(1,0.75,0.4,0.55),true)
	rect(tree,150,116,20,18,Color("#3a281c")); rect(tree,153,119,14,15,Color("#14100c"))
	puff(tree,Vector2(160,100),Vector2(150,30),22,5.0,Vector2(0,-1),40,6,Color(1,0.95,0.6,0.8),Vector2.ZERO,1.2)
	return gr

func set_house():
	reset_world()
	var bg=layer(0.0); sky(bg,Color("#2a1c14"),Color("#3a281c"))
	var w=layer(1.0)
	rect(w,-240,-120,800,250,Color("#4a3426"))
	for x in range(-240,560,14): rect(w,x,-120,1,250,Color("#3a281c"))
	rect(w,-240,128,800,70,Color("#3b2a1e")); rect(w,-240,126,800,3,Color("#5a4030"))
	rect(w,60,30,46,50,Color("#2a1a10")); rect(w,64,34,38,42,Color("#2c4a78")); rect(w,82,34,2,42,Color("#2a1a10")); rect(w,64,54,38,2,Color("#2a1a10"))
	beam(w,95,40,132,34,70,Color(0.6,0.75,1.0,0.16))
	rect(w,258,104,38,24,Color("#5a3d2b")); disc(w,Vector2(277,98),3,Color("#ffcf70"),8); glow(w,Vector2(277,98),70,Color(1,0.72,0.36,0.65),true)
	return w

# ================================================================ A
func ch_a_wake():
	var mid=set_hall(320)
	var sg=Sprite2D.new(); sg.texture=SIGIL; sg.position=Vector2(170,139); sg.scale=Vector2(150.0/SIGIL.get_width(),46.0/SIGIL.get_height())
	sg.modulate=Color(0.7,0.25,0.9,0.55); mid.add_child(sg)
	puff(mid,Vector2(170,122),Vector2(70,6),26,2.4,Vector2(0,-1),25,14,Color(0.95,0.25,0.2,0.9),Vector2.ZERO,1.6)
	puff(mid,Vector2(170,126),Vector2(90,4),16,3.4,Vector2(0,-1),10,8,Color(0.35,0.33,0.4,0.55),Vector2.ZERO,3.5)
	add_actor("gordon","gordon",Vector2(98,146))
	var d=add_actor("darkus","darkus",Vector2(176,144)); anim("darkus","lie")
	cam_snap(Vector2(176,112),1.5)
	await fade(0.0,1.8)
	await caption("Ruang terdalam Ancient Dungeon. Keheningan menelan sisa-sisa pertarungan.",3.0)
	await caption("Asap hitam Satan sudah lenyap. Darkus tergeletak tak sadarkan diri di lantai batu.",3.2)
	# v9.29: pemain mendekat, berlutut, dan menyadarkan Darkus (bukan bangun sendiri)
	cam_to(Vector2(140,112),1.6,1.8)
	await go("gordon",Vector2(148,146),1.9).finished
	emote("gordon","!",Color("#ff7a7a"))
	squash("gordon",1.06,0.8,0.3)              # berlutut di sisi Darkus
	await say("gordon","Darkus...? Darkus! Bangun! Kau bisa dengar aku?")
	hop("gordon",2.0,2); await wait(0.45)      # mengguncang bahunya pelan
	hop("darkus",1.5,2)
	await say("gordon","Satan sudah pergi. Tolong... buka matamu.")
	squash("gordon",1.0,1.0,0.3)
	await wait(0.7)
	# bangun pelan: terbaring -> bersandar -> duduk -> berdiri (sprite asli, bukan putaran)
	anim("darkus","situp"); await wait(1.1)
	anim("darkus","sit"); await wait(0.6)
	anim("darkus","idle"); hop("darkus",3.0,1)
	await wait(0.3)
	cam_to(Vector2(166,108),1.7,1.6)
	await say("darkus","...Ugh... kepalaku...")
	emote("darkus","?")
	await say("darkus","Di mana... ini? Kenapa tubuhku terasa seperti bukan milikku?")
	await cam_to(Vector2(170,118),2.3,1.4)
	await say("darkus","Tanganku... penuh abu hitam. Aku cuma ingat satu suara yang berbisik... lalu semuanya gelap.")
	await cam_to(Vector2(150,112),1.5,1.4)
	face("gordon",false); anim("gordon","idle")
	await say("gordon","Darkus... kau sudah sadar. Syukurlah.")
	await say("darkus","Ranbyus? Kenapa kau babak belur begitu? Jangan bilang... akulah yang melakukannya?")
	hide_box()

# ================================================================ B
func ch_b_cutoff():
	await say("darkus","Dengar, ada yang harus kuberitahu. Tentang makhluk itu, dan kenapa dia memilih tubuhku—","darkus")
	# kilas balik: Adek di ranjang
	flash(Color(1,1,1),0.4,0.7)
	var fb=ColorRect.new(); fb.color=Color(0.1,0.07,0.04,0.0); fb.size=Vector2(W,H); ui.add_child(fb); ui.move_child(fb,1)
	var ad=TextureRect.new(); var at=AtlasTexture.new(); at.atlas=load("res://screens/tree-village/assets/adek-wakeup.png"); at.region=Rect2(0,0,320,282)
	ad.texture=at; ad.size=Vector2(320,282)*0.42; ad.position=Vector2(100,32); ad.modulate=Color(1,0.9,0.75,0.0); ui.add_child(ad); ui.move_child(ad,2)
	var t=create_tween().set_parallel(true); t.tween_property(fb,"color:a",0.88,0.6); t.tween_property(ad,"modulate:a",0.95,0.9)
	await t.finished
	pulse_vignette(3)
	await say("gordon","Adek... napasnya makin pelan. Pak Tabib bilang waktunya tinggal sebentar lagi...","gordon")
	var t2=create_tween().set_parallel(true); t2.tween_property(fb,"color:a",0.0,0.5); t2.tween_property(ad,"modulate:a",0.0,0.5)
	await t2.finished
	fb.queue_free(); ad.queue_free()
	emote("gordon","!",Color("#ff7a7a"))
	await say("gordon","Maaf, Darkus. Ceritamu nanti saja.")
	await say("darkus","Tunggu, Ranbyus, ini penting! Soal tubuhku, soal—")
	await say("gordon","Adekku sedang kritis! Aku harus menemukan Buah Suwarga sekarang juga!")
	hide_box()
	puff(world,Vector2(120,146),Vector2(8,2),14,0.8,Vector2(-1,-0.4),30,30,Color(0.7,0.65,0.6,0.8),Vector2(0,40),2.0,true)
	var g=go("gordon",Vector2(420,146),1.5)
	cam_to(Vector2(300,110),1.2,1.5)
	await g.finished
	await say("darkus","Ranbyus! ...Dia benar-benar pergi.","darkus")
	emote("darkus","!")
	await say("darkus","Lorong itu bisa runtuh kapan saja. Sial, aku tak boleh membiarkannya sendirian!")
	hide_box()
	var d=go("darkus",Vector2(430,146),1.6)
	await cam_to(Vector2(330,110),1.2,1.2)
	await fade(1.0,0.9)

# ================================================================ 1
func ch_1_fruit():
	var fruit=set_chamber()
	add_actor("gordon","gordon",Vector2(-30,146))
	cam_snap(Vector2(160,90),1.0)
	await fade(0.0,1.4)
	await caption("Ruang terdalam. Tempat Buah Suwarga bersemayam selama seratus tahun.",3.0)
	var g=go("gordon",Vector2(80,146),2.2)
	await g.finished
	emote("gordon","!")
	await cam_to(Vector2(160,98),1.7,1.8)
	await say("gordon","Itu dia... Buah Suwarga.")
	await caption("Konon, buah ini mekar sekali dalam seratus tahun, menyimpan napas kehidupan.",3.0)
	await go("gordon",Vector2(138,146),1.6).finished
	shake(1.5,0.6)
	await say("gordon","Tunggu ya, Dek... Kakak datang.")
	hide_box()
	flash(Color(1,0.95,0.7),0.9,0.9)
	slowmo(0.35,1.0)
	fruit.get_meta("bob").kill()
	var tw=create_tween(); tw.tween_property(fruit,"position",Vector2(142,112),0.9).set_trans(Tween.TRANS_SINE)
	await tw.finished
	await wait(0.5)
	puff(world,Vector2(160,40),Vector2(120,4),40,1.2,Vector2(0,1),20,30,Color(0.7,0.65,0.6,0.9),Vector2(0,60),2.0)
	shake(5.0,1.8)
	add_actor("darkus","darkus",Vector2(-20,146))
	var d=go("darkus",Vector2(60,146),1.0)
	await cam_to(Vector2(130,100),1.3,1.0)
	await say("darkus","Ranbyus! Penjaga dungeon runtuh karena buahnya diambil! Lari, sekarang!")
	hide_box()
	await say("gordon","Ayo!","gordon")
	hide_box()
	await fade(1.0,0.5)

# ================================================================ 2
func ch_2_run():
	set_hall(1250)
	for x in [300,560,820,1050]:
		puff(world,Vector2(x,-10),Vector2(90,4),26,1.3,Vector2(0,1),12,30,Color(0.62,0.58,0.55,0.9),Vector2(0,70),2.2)
	add_actor("gordon","gordon",Vector2(40,146)); add_actor("darkus","darkus",Vector2(8,146))
	cam_snap(Vector2(160,100),1.2)
	await fade(0.0,0.6)
	var a=go("gordon",Vector2(520,146),2.8); var b=go("darkus",Vector2(488,146),2.8)
	cam_to(Vector2(520,100),1.2,2.8); shake(2.5,2.6)
	await a.finished
	await say("darkus","Terus lari! Jangan menoleh ke belakang!")
	hide_box()
	flash(Color(1,0.6,0.3),0.6,0.4)
	var a2=go("gordon",Vector2(1150,146),3.0); var b2=go("darkus",Vector2(1118,146),3.0)
	cam_to(Vector2(1090,100),1.2,3.0); shake(3.5,2.8)
	caption("Lorong runtuh di belakang mereka, menelan cahaya obor satu per satu.",2.0)
	await a2.finished
	flash(Color(1,1,0.9),1.2,1.0)
	await fade(1.0,0.6,Color.WHITE)

# ================================================================ 3
func ch_3_tabib():
	var roadGr=set_road("dawn",700)
	poly(roadGr,[Vector2(-10,150),Vector2(-10,86),Vector2(20,64),Vector2(54,86),Vector2(54,150)],Color("#0b0a14"))
	puff(world,Vector2(22,140),Vector2(26,6),22,2.6,Vector2(1,-0.5),30,12,Color(0.8,0.72,0.65,0.8),Vector2.ZERO,3.0)
	add_actor("tabib","tabib",Vector2(330,148),true)
	add_actor("gordon","gordon",Vector2(40,148)); add_actor("darkus","darkus",Vector2(10,148))
	cam_snap(Vector2(120,100),1.2)
	await fade(0.0,1.2,Color.WHITE)
	var g=go("gordon",Vector2(215,148),2.0); var d=go("darkus",Vector2(185,148),2.1)
	cam_to(Vector2(230,100),1.2,2.0)
	await g.finished
	emote("tabib","!")
	await say("tabib","Ranbyus! Syukurlah kalian selamat!")
	var f=glow(A("gordon"),Vector2(0,-20),36,Color(1,0.85,0.4,0.9),true)
	await cam_to(Vector2(245,100),1.8,1.4)
	await say("gordon","Pak Tabib... aku mendapatkannya. Buah Suwarga.","gordon")
	await say("tabib","Itu nyata... Kupikir itu cuma dongeng para tetua.")
	await say("tabib","Masih ada waktu, tapi tidak banyak. Cahayanya harus kita olah sebelum padam.")
	await cam_to(Vector2(190,100),1.4,1.2)
	await say("tabib","Lalu siapa anak muda ini?")
	await say("darkus","Darkus. Aku berutang nyawa pada Ranbyus. Izinkan aku ikut.")
	await say("tabib","Baiklah. Kita berangkat sekarang.")
	hide_box()
	await fade(1.0,0.7)

# ================================================================ 4
func ch_4_journey():
	set_road("day",1700)
	tone_node.color=Color.WHITE
	add_actor("tabib","tabib",Vector2(80,146)); add_actor("gordon","gordon",Vector2(48,147)); add_actor("darkus","darkus",Vector2(18,148))
	# gerbang Desa Beruang
	var gate=layer(1.0)
	rect(gate,650,96,6,48,Color("#5a3d2b")); rect(gate,730,96,6,48,Color("#5a3d2b")); rect(gate,646,92,94,8,Color("#6b4a35"))
	add_actor("bear","bear",Vector2(738,147),true,Color.WHITE,1.15)
	add_actor("ibu","ibu",Vector2(1180,147),true)
	cam_snap(Vector2(160,100),1.0)
	await fade(0.0,1.0)
	await caption("Mereka bergegas melintasi hutan, menyusuri jalan menuju Desa Pohon.",2.6)
	var p1=go("tabib",Vector2(560,146),4.0); var p2=go("gordon",Vector2(528,147),4.0); var p3=go("darkus",Vector2(498,148),4.0)
	cam_to(Vector2(560,100),1.0,4.0)
	await p1.finished
	await say("bear","Berhenti! Aku dengar kabar dari para penduduk. Anak itu kritis, ya?")
	await say("gordon","Benar, Kepala Desa. Kami membawa obatnya.","gordon")
	await say("bear","Kau yang menyelamatkan desaku. Biar aku dan pasukan beruangku ikut mengawal kalian!")
	var b=go("bear",Vector2(584,148),1.0)
	await b.finished
	await tone(Color(1.0,0.93,0.82),2.0)
	var q1=go("tabib",Vector2(1100,146),4.5); var q2=go("gordon",Vector2(1066,147),4.5); var q3=go("darkus",Vector2(1032,148),4.5); var q4=go("bear",Vector2(1000,148),4.5)
	cam_to(Vector2(1100,100),1.0,4.5)
	await q1.finished
	await say("ibu","Tunggu! Ada anak yang sakit parah? Aku bawa kain bersih dan air hangat dari tokoku!")
	await say("ibu","Jangan ditolak. Biar aku bantu menjaga adikmu!")
	await say("tabib","Kami butuh setiap tangan. Ayo.","tabib")
	await go("ibu",Vector2(1160,147),0.8).finished
	await tone(Color(1.0,0.72,0.5),1.6)
	hide_box()
	var r1=go("tabib",Vector2(1620,146),5.0); var r2=go("gordon",Vector2(1586,147),5.0); var r3=go("darkus",Vector2(1552,148),5.0); var r4=go("bear",Vector2(1520,148),5.0); var r5=go("ibu",Vector2(1488,147),5.0)
	cam_to(Vector2(1560,100),1.0,5.0)
	caption("Matahari condong ke barat. Lima bayangan panjang berlari melawan waktu.",2.6)
	await r1.finished
	await say("darkus","Maaf soal tadi. Ceritaku bisa menunggu sampai Adekmu selamat.","darkus")
	await say("gordon","Terima kasih, Darkus.","gordon")
	hide_box()
	await fade(1.0,0.8)

# ================================================================ 5
func ch_5_arrive():
	tone_node.color=Color.WHITE
	set_village("dusk")
	# warga Desa Pohon menunggu di kanan, memakai sprite warga sendiri
	add_warga({"wayan":Vector2(196,141),"made":Vector2(220,148),"kadek":Vector2(244,140),"nyoman":Vector2(268,149),"putu":Vector2(292,143)},true)
	add_actor("bunda","bunda",Vector2(176,146),true)
	for n in [["tabib",-60],["gordon",-92],["darkus",-124],["bear",-156],["ibu",-188]]:
		add_actor(n[0],n[0],Vector2(n[1],147))
	cam_snap(Vector2(160,100),1.0)
	await fade(0.0,1.2)
	await caption("Desa Pohon. Lentera-lentera menyala, menanti kepulangan mereka.",2.8)
	var ts=[go("tabib",Vector2(112,146),3.0),go("gordon",Vector2(80,147),3.0),go("darkus",Vector2(48,148),3.0),go("bear",Vector2(16,148),3.0),go("ibu",Vector2(-16,147),3.0)]
	await ts[1].finished
	for id in WARGA: face(id,true)
	emote("wayan","!"); emote("kadek","!"); emote("putu","!")
	await say("wayan","Itu mereka pulang! Eh... itu kamu yang memperbaiki sumur kami, kan?")
	for id in WARGA: hop(id,5.0,2)
	puff(world,Vector2(160,20),Vector2(120,6),40,2.2,Vector2(0,1),25,26,Color(1,0.82,0.9,0.95),Vector2(0,10),2.0)
	await say("made","Wah, hebat ya kamu. Masih kecil, tapi berani sampai sejauh itu!")
	await say("putu","Kak, itu apa? Kok bercahaya...!")
	await say("kadek","Kamu memang hebat. Kalian semua juga! Terima kasih sudah menjaganya.")
	await say("nyoman","Sudah, sudah. Adiknya menunggu, Nak. Cepat pulang, kami berdoa dari tadi.")
	hide_box()
	await go("bunda",Vector2(110,147),1.0).finished
	emote("bunda","<3",Color("#ff8aa8"))
	await cam_to(Vector2(100,106),1.6,1.2)
	await say("bunda","Ranbyus... anakku.")
	await say("gordon","Bunda, aku bawa obatnya. Adek di mana?","gordon")
	await say("bunda","Di kamarnya... napasnya semakin pelan, Nak.")
	await say("tabib","Tak ada waktu lagi. Antar aku ke Adek, sekarang.")
	hide_box()
	var k=0
	for id in WARGA:
		go(id,Vector2(actors[id].position.x,(120 if k%2==0 else 160)),0.9)
		k+=1
	await go("bunda",Vector2(180,147),1.0).finished
	await fade(1.0,0.6)

# ================================================================ 6
func ch_6_heal():
	set_house()
	tone_node.color=Color(1,0.9,0.82)
	var bed=add_actor("adekbed","adekbed",Vector2(214,150))
	add_actor("bunda","bunda",Vector2(256,152),true); add_actor("gordon","gordon",Vector2(160,150)); add_actor("tabib","tabib",Vector2(184,150))
	add_actor("darkus","darkus",Vector2(80,150)); add_actor("bear","bear",Vector2(56,150)); add_actor("ibu","ibu",Vector2(104,150))
	face("gordon",false); face("tabib",false); face("darkus",false); face("bear",false); face("ibu",false)
	cam_snap(Vector2(180,100),1.2)
	await fade(0.0,1.2)
	await say("tabib","Tenanglah semuanya. Buah ini hanya bisa dipakai sekali.")
	var fruit=Node2D.new(); fruit.position=Vector2(190,126); world.add_child(fruit)
	disc(fruit,Vector2.ZERO,5,Color("#ffcf4d")); disc(fruit,Vector2(-1,-1),2,Color("#fff1b0"),8); glow(fruit,Vector2.ZERO,30,Color(1,0.85,0.4,0.9),true)
	await cam_to(Vector2(170,110),1.7,1.4)
	await say("tabib","Aku akan menumbuknya menjadi sari kehidupan.")
	var t=create_tween(); t.tween_property(fruit,"scale",Vector2(1.4,0.5),0.4); t.tween_property(fruit,"scale",Vector2(0.1,0.1),0.5)
	await t.finished
	fruit.queue_free()
	puff(world,Vector2(190,122),Vector2(6,2),30,1.4,Vector2(0,-1),50,26,Color(1,0.9,0.4,1),Vector2(0,10),1.6,true)
	flash(Color(1,0.9,0.5),0.7,0.5)
	await say("tabib","Cahaya kehidupan... kembalilah pada tubuh yang kehilangannya.")
	hide_box()
	var sg=Sprite2D.new(); sg.texture=SIGIL; sg.position=Vector2(214,146); sg.scale=Vector2(170.0/SIGIL.get_width(),52.0/SIGIL.get_height()); sg.modulate=Color(1,0.85,0.4,0.0); sg.z_index=-2; world.add_child(sg)
	var tg=create_tween().set_parallel(true); tg.tween_property(sg,"modulate:a",0.8,1.2); tg.tween_property(sg,"rotation",0.5,3.0)
	await cam_to(Vector2(214,118),2.4,1.6)
	var hl=Sprite2D.new(); hl.texture=HEAL; hl.position=Vector2(214,126); hl.modulate=Color(1,1,1,0.0); hl.z_index=20; world.add_child(hl)
	create_tween().tween_property(hl,"modulate:a",0.9,1.0)
	puff(world,Vector2(214,128),Vector2(30,10),34,2.2,Vector2(0,-1),20,18,Color(1,0.9,0.5,0.95),Vector2.ZERO,1.6)
	await caption("Cahaya hangat menyelimuti ranjang. Seisi ruangan menahan napas.",2.6)
	await pulse_vignette(3)
	await caption("tuk... tuk... tuk...",1.6)
	create_tween().tween_property(hl,"modulate:a",0.0,1.2)
	await say("bunda","Adek... bangunlah, Nak...")
	hide_box()

# ================================================================ 7
func ch_7_wake():
	await cam_to(Vector2(206,122),2.8,1.4)
	var spr=A("adekbed").get_node("spr")
	spr.play("wake")
	await wait(1.1)
	flash(Color(1,0.95,0.7),0.8,0.55)
	puff(world,Vector2(214,120),Vector2(40,10),40,2.0,Vector2(0,-1),60,34,Color(1,0.85,0.5,1),Vector2(0,20),1.8,true)
	await wait(0.6)
	await say("","...Kak...?","adek")
	await cam_to(Vector2(170,112),1.7,1.4)
	emote("gordon","!"); emote("bunda","<3",Color("#ff8aa8")); emote("tabib","<3",Color("#ff8aa8"))
	await say("gordon","Adek...? Adek!")
	await say("bunda","Anakku! Dia sadar... dia sadar!")
	await say("tabib","Syukurlah... Syukurlah, buah itu bekerja.")
	await say("darkus","...Dia akhirnya membuka matanya.")
	await say("ibu","Syukurlah, Nak. Syukurlah.")
	hide_box()
	for id in ["gordon","bunda","tabib","darkus","bear","ibu"]:
		hop(id,5.0,2)
	puff(world,Vector2(160,0),Vector2(150,6),50,2.4,Vector2(0,1),20,30,Color(1,0.92,0.6,0.95),Vector2(0,15),2.0)
	await wait(1.6)

# ================================================================ 8
func ch_8_run_out():
	var spr=A("adekbed").get_node("spr")
	var pos=A("adekbed").position
	A("adekbed").queue_free(); actors.erase("adekbed")
	var ak=add_actor("adek","adek",Vector2(pos.x-6,pos.y))
	face("adek",true)
	flash(Color(1,0.95,0.8),0.4,0.5)
	await say("adek","Kak... Adek nggak sakit lagi! Adek mau lihat langit!")
	hide_box()
	var a=go("adek",Vector2(-40,150),1.3)
	cam_to(Vector2(120,110),1.2,1.3)
	await wait(0.5)
	go("gordon",Vector2(-40,150),1.6); go("bunda",Vector2(-60,152),2.0); go("tabib",Vector2(-70,150),2.2)
	go("darkus",Vector2(-80,150),2.2); go("bear",Vector2(-100,150),2.4); go("ibu",Vector2(-110,150),2.4)
	await fade(1.0,0.8,Color.WHITE)
	# di luar rumah: pagi hari
	set_village("morning"); tone_node.color=Color.WHITE
	add_warga(WARGA_MORNING)
	for id in ["gordon","bunda","tabib","darkus","bear","ibu"]:
		add_actor(id,id,Vector2(-60-randi()%40,146+randi()%8))
	add_actor("adek","adek",Vector2(150,146)); face("adek",false)
	beam(world,170,-20,140,30,150,Color(1,0.95,0.7,0.16))
	cam_snap(Vector2(160,100),1.0)
	await fade(0.0,1.2,Color.WHITE)
	await caption("Pagi pertama setelah malam yang sangat panjang.",2.4)
	for id in WARGA: hop(id,5.0,3)
	puff(world,Vector2(160,10),Vector2(170,6),60,2.6,Vector2(0,1),25,26,Color(1,0.8,0.9,0.95),Vector2(0,12),2.0)
	var l1=go("adek",Vector2(250,150),1.0)
	await l1.finished
	hop("adek",8.0,3)
	var l2=go("adek",Vector2(70,142),1.4)
	var ps=[go("gordon",Vector2(130,147),2.0),go("bunda",Vector2(104,148),2.2),go("tabib",Vector2(212,146),2.0),go("darkus",Vector2(240,148),2.0),go("bear",Vector2(280,148),2.2),go("ibu",Vector2(40,147),2.2)]
	await say("adek","Lihat, Kak! Adek bisa lari lagi! Adek bisa lari!")
	await say("kadek","Hidup Adek! Hidup Ranbyus!")
	await say("made","Adek sudah bisa lari lagi... syukurlah!")
	hide_box()

# ================================================================ 9
func ch_9_thanks():
	# --- Adek berlari lalu melompat memeluk Ranbyus ---
	face("gordon",true); face("adek",false)
	go("bunda",Vector2(160,150),0.8)      # Bunda bergeser ke kanan Ranbyus supaya jalur Adek kosong
	squash("gordon",1.0,0.9,0.4)          # Ranbyus sedikit berjongkok membuka tangan
	await cam_to(Vector2(104,112),1.7,1.2)
	emote("adek","!"); emote("gordon","!")
	await say("adek","Kakak...! Kakaaak!")
	hide_box()
	await go("adek",Vector2(92,148),0.8).finished
	var gp=actors["gordon"].position
	slowmo(0.4,1.0)
	var jump=leap("adek",Vector2(gp.x-5.0,gp.y+1.0),0.55,22.0)
	cam_to(Vector2(114,108),2.3,1.0)
	await jump.finished

	# --- tabrakan pelukan ---
	hug_hold("adek","gordon",6.0)
	face("gordon",true)
	flash(Color(1,0.95,0.8),0.5,0.35)
	shake(1.5,0.3)
	var bump=create_tween(); bump.tween_property(actors["gordon"],"position:x",gp.x+2.0,0.12); bump.tween_property(actors["gordon"],"position:x",gp.x,0.2)
	await squash("gordon",1.1,0.84,0.12).finished
	squash("gordon",1.02,0.92,0.4)
	var hug_at=Vector2(gp.x-2.0,gp.y-18.0)
	glow(world,hug_at,70,Color(1,0.85,0.7,0.5))
	puff(world,hug_at,Vector2(14,10),26,1.6,Vector2(0,-1),40,18,Color(1,0.9,0.6,0.95),Vector2.ZERO,1.8,true)
	hearts(hug_at+Vector2(0,-14),8,16.0)
	sway("adek",1.4,1.6); sway("gordon",1.2,1.6)
	await cam_to(Vector2(gp.x-2.0,gp.y-28.0),3.0,1.6)

	# --- haru, manja, dan janji ---
	tears("adek",3.0)
	await say("adek","Kakak... Adek kangen. Adek kira Kakak nggak akan pulang lagi...")
	tears("gordon",3.0)
	emote("gordon","<3",Color("#ff8aa8"))
	await say("gordon","Maaf ya, Dek. Kakak lama perginya. Tapi Kakak pulang, kan? Kakak pulang.","gordon")
	hearts(hug_at+Vector2(0,-14),5,14.0)
	await say("adek","Jangan pergi lama-lama lagi ya, Kak... janji?")
	await say("gordon","Janji, Dek. Kakak janji.","gordon")
	# Adek manja: menyusup lebih erat di bahu Kakak
	hop("adek",2.0,2)
	emote("adek","<3",Color("#ff8aa8"))
	hearts(hug_at+Vector2(0,-14),4,12.0)
	await say("adek","Kak... gendong Adek sebentar lagi ya. Adek masih lemes... dan hangat banget di sini.")
	await say("gordon","Iya, iya... dasar manja. Pegangan yang erat ya.","gordon")
	hide_box()

	# --- Bunda ikut terharu ---
	await cam_to(Vector2(112,110),2.0,1.2)
	await go("bunda",Vector2(gp.x+24.0,149),0.9).finished
	face("bunda",true)
	emote("bunda","<3",Color("#ff8aa8"))
	tears("bunda",3.0)
	await say("bunda","Anak-anak Bunda... syukurlah kalian berdua selamat. Bunda tidak butuh apa-apa lagi.")
	await say("tabib","Janji yang ditepati... itulah obat terbaik.","tabib")
	hide_box()

	# --- pelukan dilepas ---
	unsway("adek"); unsway("gordon")
	create_tween().tween_property(actors["adek"].get_node("spr"),"position:y",0.0,0.3)
	squash("gordon",1.0,1.0,0.3)
	await go("adek",Vector2(gp.x-16.0,150),0.5).finished
	face("adek",false)
	flash(Color(1,0.95,0.75),1.0,0.5)
	await caption("Janji untuk Adek.",3.0)

# ================================================================ 9b
# Warga berkumpul memberi selamat atas kepulangan Ranbyus dan sembuhnya Adek.
func ch_9b_warga():
	var spots={"kadek":Vector2(60,142),"nyoman":Vector2(82,152),"bunda":Vector2(104,149),"adek":Vector2(126,150),"gordon":Vector2(148,148),
		"putu":Vector2(170,153),"made":Vector2(192,142),"tabib":Vector2(214,146),"wayan":Vector2(236,143),"darkus":Vector2(258,148),"bear":Vector2(282,148),"ibu":Vector2(40,147)}
	var moves=[]
	for id in spots: moves.append(go(id,spots[id],1.8))
	cam_to(Vector2(160,106),1.35,2.0)
	await moves[0].finished
	await wait(0.4)
	for id in spots: face(id,spots[id].x>148.0)
	face("adek",false)
	await say("nyoman","Selamat ya, Nak... adikmu sudah sembuh. Syukurlah, syukurlah.")
	emote("nyoman","<3",Color("#ff8aa8"))
	await say("wayan","Air bersih mengalir lagi, Adek pun sehat. Desa kami berutang budi padamu, Ranbyus.")
	await say("made","Kamu memang hebat. Masih kecil, tapi hatimu sebesar gunung.")
	await say("kadek","Kalau kamu butuh apa-apa, bilang saja. Satu desa siap membantu!")
	await say("putu","Adek! Nanti main sama aku ya! Aku punya layang-layang baru!")
	face("adek",true)
	hop("adek",4.0,2)
	await say("adek","Iya! Adek mau! Tapi sama Kakak juga ya!")
	face("adek",false)
	await say("gordon","Terima kasih, semuanya. Aku tidak berjalan sendirian.","gordon")
	await say("ibu","Nah, siapa yang mau kue? Hari ini semuanya gratis dari tokoku!")
	hide_box()
	flash(Color(1,0.95,0.75),0.8,0.4)
	puff(world,Vector2(160,10),Vector2(170,6),70,2.6,Vector2(0,1),25,26,Color(1,0.8,0.9,0.95),Vector2(0,12),2.0)
	hearts(Vector2(148,118),6,24.0)
	await warga_cheer(WARGA,2.0)

# ================================================================ 10
func ch_10_together():
	await cam_to(Vector2(160,92),1.0,2.0)
	var pos={"gordon":128,"adek":146,"bunda":108,"tabib":184,"darkus":206,"bear":232,"ibu":78,
		"kadek":24,"made":50,"nyoman":166,"wayan":262,"putu":286}
	for id in pos: go(id,Vector2(pos[id],149),1.4)
	await wait(1.6)
	for id in pos: face(id,pos[id]>146 and id!="adek")
	await say("bunda","Terima kasih, Nak. Terima kasih sudah membawa Adek pulang.")
	await say("tabib","Kalian semua pahlawan hari ini.","tabib")
	hide_box()
	puff(world,Vector2(160,30),Vector2(160,4),60,3.0,Vector2(0,1),25,22,Color(1,0.9,0.6,0.95),Vector2(0,12),2.0)
	await cam_to(Vector2(160,70),1.0,3.5)
	await title("JANJI UNTUK ADEK","Sebuah perjalanan yang berakhir dengan pulang",3.4)
	await fade(1.0,1.2)

# ================================================================ 11
func ch_11_lore():
	set_road("night",400); tone_node.color=Color(0.75,0.82,1.0)
	var rock=layer(1.0); poly(rock,[Vector2(190,140),Vector2(200,122),Vector2(232,118),Vector2(246,140)],Color("#2a2f45"))
	add_actor("darkus","darkus",Vector2(214,124)); anim("darkus","sit")
	add_actor("gordon","gordon",Vector2(-30,148))
	# siluet Leviathan di balik bulan (muncul saat Darkus bercerita)
	var lv=layer(0.0); lv.modulate.a=0.0
	var pts=[]
	for i in 28: pts.append(Vector2(-40+i*14,60+sin(i*0.55)*26-i*0.7))
	for i in range(27,-1,-1): pts.append(Vector2(-40+i*14,72+sin(i*0.55)*26-i*0.7))
	poly(lv,pts,Color("#05060f")); disc(lv,Vector2(350,24),6,Color("#ff3a3a"),10); glow(lv,Vector2(350,24),30,Color(1,0.2,0.2,0.8),true)
	cam_snap(Vector2(190,96),1.4)
	await fade(0.0,1.4)
	await caption("Malam itu, jauh dari keramaian pesta, Darkus duduk sendirian menatap bulan.",3.0)
	var g=go("gordon",Vector2(180,148),2.4)
	await g.finished
	await say("gordon","Kau tidak ikut berpesta?","gordon")
	await say("darkus","Tadi di dungeon, kau belum sempat mendengar ceritaku.")
	await say("darkus","Sekarang aku mengerti kenapa makhluk-makhluk jahat selalu mengincar tubuhku.")
	var tl=create_tween(); tl.tween_property(lv,"modulate:a",0.85,2.5)
	await cam_to(Vector2(214,90),1.3,2.0)
	await say("darkus","Orang tuaku bukan manusia biasa. Mereka keturunan Leviathan, naga laut purba.")
	await say("darkus","Darah itu menurun padaku, bersama sebuah kutukan. Itu sebabnya Satan dan yang lain memburuku.")
	shake(1.5,0.6)
	await say("gordon","Jadi selama ini kau berlari sendirian?","gordon")
	await say("darkus","Ya... sampai hari ini.")
	await cam_to(Vector2(200,112),2.0,1.6)
	await say("darkus","Untuk pertama kalinya ada yang menerimaku tanpa takut pada darahku.")
	await say("gordon","Kau bagian dari keluarga kami sekarang, Darkus.","gordon")
	await say("darkus","Kalau begitu... kutukan ini akan kuhadapi bersama kalian.")
	hide_box()
	create_tween().tween_property(lv,"modulate:a",0.0,2.5)
	await cam_to(Vector2(190,96),1.2,3.0)
	await fade(1.0,1.8)
	await title("TAMAT","Terima kasih sudah bermain Janji untuk Adek",3.6)
