extends Control

# Layar pilih class (dipakai Darkus di Ancient Dungeon). Isi 'classList' sebelum node ditambahkan.
# Tata letak (layar 320x180), v9.24: ada margin 12 px kiri/kanan, jarak 4-6 px antar bagian dan padding di dalam panel.
#   y   5..15   judul
#   y  16..24   subjudul
#   y  28..76   kartu class (sprite beranimasi 0.7x + nama di pita bawah); kartu terpilih punya bingkai emas
#   y  82..152  panel info (padding 8): nama + HP/MP, deskripsi, garis, senjata, skill
#   y 158..172  tombol Kembali (kiri) dan Pilih Class (kanan); sisa 8 px di bawah
# Sprite 64x64 (kaki di y=64 bingkai, bagian tertinggi di y=14) diskalakan SPRITE_SCALE supaya SEMUA pose masuk di
# dalam kartu dengan sedikit ruang di atas, kaki di atas pita nama (clip_contents menjaganya).
# Font tema (default.tres) punya spacing_top=5 yang menurunkan teks 5 px dan memotong bagian bawah
# label kecil, jadi semua label layar ini memakai font tanpa spacing_top (lihat _tightFont).
# Menyorot / menyentuh kartu = pratinjau. Class dipilih lewat tombol "Pilih Class" atau dengan menekan
# kartu yang sudah terpilih sekali lagi, supaya tidak terpilih tanpa sengaja.

signal chosen(class_)
signal cancelled

const HeroClass=preload("res://common/class/hero_class.gd")
const ClassSprites=preload("res://common/fighters/classSprites.gd")
const DefaultTheme=preload("res://common/themes/default.tres")

const COL_BG=Color(0.07,0.06,0.13,1.0)
const COL_PANEL=Color(0.12,0.11,0.21,1.0)
const COL_CARD=Color(0.14,0.13,0.24,1.0)
const COL_CARD_ON=Color(0.22,0.19,0.34,1.0)
const COL_LINE=Color(0.32,0.30,0.48,1.0)
const COL_GOLD=Color(1.0,0.85,0.4,1.0)
const COL_TEXT=Color(0.92,0.92,0.97,1.0)
const COL_DIM=Color(0.62,0.62,0.75,1.0)
const COL_SKILL=Color(0.6,0.85,1.0,1.0)

const DogicaFont=preload("res://common/themes/fonts/dogica.ttf")

const MARGIN_X=12
const CONTENT_W=296            # 320 - 2 * MARGIN_X
const CARD_GAP=8
const CARD_MAX_W=90
const HEADER_Y=5
const SUBTITLE_Y=16
const CARD_TOP=28
const CARD_H=48
const SPRITE_SCALE=0.7
# titik tengah sprite di dalam kartu: bagian tertinggi (y=14 bingkai) jatuh di y~2.4 kartu, kaki (y=64) di y~37.4
const SPRITE_Y=15
const NAME_Y=39
const NAME_H=9
const PANEL_Y=82
const PANEL_H=70
const PANEL_PAD=8
const FOOTER_Y=158
const FOOTER_H=14
# tekan kartu dalam waktu singkat setelah terpilih hanya memilih (sentuhan = sorot + tekan sekaligus)
const CONFIRM_DELAY_MSEC=350

var classList=HeroClass.CHOICES
var headerText="PILIH CLASS"
var subtitleText="Maksimal 4 class dimiliki"
var confirmText="Pilih Class"
var sprites={}
var cards={}
var nameLabels={}
var nameBands={}
var current=""
var selectedAt=0
var confirmButton
var backButton
var nameLabel
var statLabel
var descLabel
var weaponLabel
var skillLabel
var tightFontCache=null


func _ready():
	theme=DefaultTheme
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var bg=ColorRect.new()
	bg.color=COL_BG
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	_buildHeader()
	_buildCards()
	_buildInfoPanel()
	_buildFooter()
	_wireFocus()

	cards[classList[0]].grab_focus()
	_select(classList[0])


# ---------------------------------------------------------------- membangun UI

# font dogica tanpa spacing_top (tema memakai spacing_top=5 yang membuat teks turun dan terpotong di label kecil)
func _tightFont():
	if tightFontCache==null:
		tightFontCache=FontVariation.new()
		tightFontCache.base_font=DogicaFont
		tightFontCache.spacing_top=0
		tightFontCache.spacing_bottom=0
	return tightFontCache


func _box(color_, border_=Color(0,0,0,0), borderWidth_=0, radius_=3):
	var box=StyleBoxFlat.new()
	box.bg_color=color_
	box.border_color=border_
	box.set_border_width_all(borderWidth_)
	box.set_corner_radius_all(radius_)
	return box


func _label(text_, pos_, size_, color_, fontSize_=8, align_=HORIZONTAL_ALIGNMENT_LEFT, parent_=null, wrap_=false):
	var label=Label.new()
	if wrap_:
		label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_override("font",_tightFont())
	label.add_theme_constant_override("line_spacing",2)
	label.text=text_
	label.position=pos_
	label.size=size_
	label.horizontal_alignment=align_
	label.clip_text=true
	label.add_theme_font_size_override("font_size",fontSize_)
	label.add_theme_color_override("font_color",color_)
	label.mouse_filter=Control.MOUSE_FILTER_IGNORE
	if parent_!=null:
		parent_.add_child(label)
	else:
		add_child(label)
	return label


func _buildHeader():
	_label(headerText,Vector2(0,HEADER_Y),Vector2(320,11),COL_GOLD,10,HORIZONTAL_ALIGNMENT_CENTER)
	_label(subtitleText,Vector2(0,SUBTITLE_Y),Vector2(320,8),COL_DIM,7,HORIZONTAL_ALIGNMENT_CENTER)


# lebar kartu menyesuaikan jumlah class (margin kiri/kanan tetap MARGIN_X)
static func cardWidthFor(count_):
	return mini(CARD_MAX_W,int((CONTENT_W-CARD_GAP*(count_-1))/count_))


func _buildCards():
	var count=classList.size()
	# lebar kartu menyesuaikan jumlah class supaya selalu rapi dan di tengah
	var cardW=cardWidthFor(count)
	var totalW=cardW*count+CARD_GAP*(count-1)
	var startX=int((320-totalW)/2)   # sama dengan MARGIN_X kalau kartu memenuhi lebar
	for i in count:
		var class_=classList[i]
		var card=Button.new()
		card.position=Vector2(startX+i*(cardW+CARD_GAP),CARD_TOP)
		card.size=Vector2(cardW,CARD_H)
		card.clip_contents=true
		card.focus_mode=Control.FOCUS_ALL
		card.add_theme_stylebox_override("focus",StyleBoxEmpty.new())
		card.focus_entered.connect(_select.bind(class_))
		card.mouse_entered.connect(card.grab_focus)
		card.pressed.connect(_on_card_pressed.bind(class_))
		add_child(card)
		cards[class_]=card

		var sprite=AnimatedSprite2D.new()
		sprite.sprite_frames=ClassSprites.build(class_)
		# bingkai 64x64: kaki di y=64, bagian tertinggi di y=14. Titik tengah di SPRITE_Y supaya seluruh pose
		# (termasuk serangan lanjutan) ada di dalam kartu dan kaki tepat di atas label nama
		sprite.position=Vector2(cardW/2,SPRITE_Y)
		sprite.scale=Vector2(SPRITE_SCALE,SPRITE_SCALE)
		sprite.animation_finished.connect(_on_preview_finished.bind(class_))
		sprite.play("idle")
		card.add_child(sprite)
		sprites[class_]=sprite

		# v9.18: bayangan tanah di bawah kaki + pita nama gelap, supaya nama tidak menimpa kaki dan sprite 'berpijak'
		var shadow=Polygon2D.new()
		shadow.polygon=_ellipse(13.0,3.5,16)
		shadow.color=Color(0,0,0,0.38)
		shadow.position=Vector2(cardW/2,SPRITE_Y+32*SPRITE_SCALE)
		card.add_child(shadow)
		card.move_child(shadow,0)   # di bawah sprite, tetap di atas latar kartu
		var band=ColorRect.new()
		band.position=Vector2(0,NAME_Y-1)
		band.size=Vector2(cardW,CARD_H-NAME_Y+1)
		band.mouse_filter=Control.MOUSE_FILTER_IGNORE
		card.add_child(band)
		nameBands[class_]=band
		nameLabels[class_]=_label(HeroClass.getName(class_),Vector2(2,NAME_Y),Vector2(cardW-4,NAME_H),COL_TEXT,8,HORIZONTAL_ALIGNMENT_CENTER,card)

		# muncul berurutan dengan halus
		card.modulate.a=0.0
		var fadeIn=card.create_tween()
		fadeIn.tween_interval(0.05*i)
		fadeIn.tween_property(card,"modulate:a",1.0,0.25)
	_applyCardStyles()


func _ellipse(rx_, ry_, steps_):
	var points=PackedVector2Array()
	for i in steps_:
		var a=TAU*i/steps_
		points.append(Vector2(cos(a)*rx_,sin(a)*ry_))
	return points


func _buildInfoPanel():
	var panel=Panel.new()
	panel.position=Vector2(MARGIN_X,PANEL_Y)
	panel.size=Vector2(CONTENT_W,PANEL_H)
	panel.add_theme_stylebox_override("panel",_box(COL_PANEL,COL_LINE,1,4))
	panel.mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_child(panel)

	var inner=CONTENT_W-PANEL_PAD*2    # 280
	nameLabel=_label("",Vector2(PANEL_PAD,5),Vector2(140,10),COL_GOLD,9,HORIZONTAL_ALIGNMENT_LEFT,panel)
	statLabel=_label("",Vector2(CONTENT_W-PANEL_PAD-140,6),Vector2(140,9),COL_TEXT,8,HORIZONTAL_ALIGNMENT_RIGHT,panel)
	# dua baris: 7 px + jarak 2 px + 7 px = 16 px
	descLabel=_label("",Vector2(PANEL_PAD,17),Vector2(inner,17),COL_TEXT,7,HORIZONTAL_ALIGNMENT_LEFT,panel,true)

	var line=ColorRect.new()
	line.color=COL_LINE
	line.position=Vector2(PANEL_PAD,37)
	line.size=Vector2(inner,1)
	line.mouse_filter=Control.MOUSE_FILTER_IGNORE
	panel.add_child(line)

	weaponLabel=_label("",Vector2(PANEL_PAD,40),Vector2(inner,8),COL_DIM,7,HORIZONTAL_ALIGNMENT_LEFT,panel)
	skillLabel=_label("",Vector2(PANEL_PAD,50),Vector2(inner,17),COL_SKILL,7,HORIZONTAL_ALIGNMENT_LEFT,panel,true)


func _buildFooter():
	backButton=Button.new()
	backButton.text="Kembali"
	backButton.position=Vector2(MARGIN_X,FOOTER_Y)
	backButton.size=Vector2(64,FOOTER_H)
	backButton.pressed.connect(_on_back)
	add_child(backButton)

	confirmButton=Button.new()
	confirmButton.text=confirmText
	confirmButton.position=Vector2(320-MARGIN_X-80,FOOTER_Y)
	confirmButton.size=Vector2(80,FOOTER_H)
	confirmButton.add_theme_color_override("font_color",COL_GOLD)
	confirmButton.add_theme_color_override("font_focus_color",COL_GOLD)
	confirmButton.add_theme_color_override("font_hover_color",COL_GOLD)
	confirmButton.pressed.connect(_on_confirm)
	add_child(confirmButton)

	_label("Sorot, lalu Pilih",Vector2(MARGIN_X+64+4,FOOTER_Y+3),Vector2(320-2*MARGIN_X-64-80-8,8),COL_DIM,6,HORIZONTAL_ALIGNMENT_CENTER)


func _wireFocus():
	var count=classList.size()
	for i in count:
		var card=cards[classList[i]]
		card.focus_neighbor_left=cards[classList[(i+count-1)%count]].get_path()
		card.focus_neighbor_right=cards[classList[(i+1)%count]].get_path()
		card.focus_neighbor_top=card.get_path()
		card.focus_neighbor_bottom=confirmButton.get_path()
	confirmButton.focus_neighbor_top=cards[classList[0]].get_path()
	confirmButton.focus_neighbor_left=backButton.get_path()
	confirmButton.focus_neighbor_right=confirmButton.get_path()
	confirmButton.focus_neighbor_bottom=confirmButton.get_path()
	backButton.focus_neighbor_top=cards[classList[0]].get_path()
	backButton.focus_neighbor_right=confirmButton.get_path()
	backButton.focus_neighbor_left=backButton.get_path()
	backButton.focus_neighbor_bottom=backButton.get_path()


# ---------------------------------------------------------------- perilaku

func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"):
		_on_back()
		get_viewport().set_input_as_handled()


# bingkai emas untuk kartu terpilih, bingkai redup untuk yang lain
func _applyCardStyles():
	for class_ in cards.keys():
		var on=class_==current
		var card=cards[class_]
		var box=_box(COL_CARD_ON if on else COL_CARD,COL_GOLD if on else COL_LINE,2 if on else 1,4)
		for state in ["normal","hover","pressed","hover_pressed","disabled"]:
			card.add_theme_stylebox_override(state,box)
		nameLabels[class_].add_theme_color_override("font_color",COL_GOLD if on else COL_DIM)
		nameBands[class_].color=Color(0.30,0.24,0.08,0.85) if on else Color(0.05,0.04,0.10,0.75)


func _select(class_):
	if current==class_:
		return
	current=class_
	selectedAt=Time.get_ticks_msec()
	var info=HeroClass.getInfo(class_)
	nameLabel.text=info.name
	statLabel.text="HP "+str(info.life)+"    MP "+str(info.mana)
	descLabel.text=info.desc
	var weapon=GlobalItems.getItem(HeroClass.getWeaponId(class_))
	var names=[]
	for attack in weapon.actionList:
		names.append(attack.name)
	weaponLabel.text="Senjata: "+weapon.name
	skillLabel.text="Skill: "+" · ".join(names)
	_applyCardStyles()
	for key in sprites.keys():
		if key==class_:
			sprites[key].play("attack_simple")
			sprites[key].modulate=Color(1,1,1)
		else:
			sprites[key].play("idle")
			sprites[key].modulate=Color(0.6,0.6,0.7)


func _on_preview_finished(class_):
	# setelah memperagakan serangan, kembali siaga; kalau masih terpilih, ulangi dengan serangan lanjutan
	var sprite=sprites[class_]
	if sprite.animation=="idle":
		return
	sprite.play("idle")
	if class_==current:
		await get_tree().create_timer(1.2).timeout
		if class_==current and is_instance_valid(sprite):
			sprite.play("attack_advanced")


# menekan kartu: kartu baru = memilih (pratinjau); kartu yang sudah terpilih ditekan lagi = konfirmasi
func _on_card_pressed(class_):
	if class_==current and Time.get_ticks_msec()-selectedAt>CONFIRM_DELAY_MSEC:
		emit_signal("chosen",class_)
	elif class_!=current:
		cards[class_].grab_focus()
		_select(class_)


func _on_confirm():
	if current!="":
		emit_signal("chosen",current)


func _on_back():
	emit_signal("cancelled")
