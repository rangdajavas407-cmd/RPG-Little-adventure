extends CanvasLayer

const FightRules=preload("res://common/class/fight_rules.gd")

# Interface du combat : boite de message + menu d'actions navigable
# a la souris, au tactile, au clavier et a la manette

signal leave
signal attack(attack_)
signal usePotion
signal useFood
signal useItemById(itemId_)
signal defend
# pilih sasaran: index musuh (0/1), -1 = batal
signal targetPicked(index_)
signal useItemOnVera(itemId_)

const attackClass=preload("res://common/class/item/attack_class.gd")
const HeroClass=preload("res://common/class/hero_class.gd")
const PUNCH_DAMAGE=4


@onready var message=$messageBox/message
@onready var actions=$actions
@onready var buttonList=$actions/list

var showingAttacks=false
# diisi scene pertarungan: Vera ada dan nyawanya belum penuh (bisa disembuhkan)
var veraHealable=false
# true selama menu pilih sasaran musuh tampil (Esc = batal)
var pickingTarget=false
# Engineer (skill 2 = Kotak Mekanik): diisi scene pertarungan tiap giliran pemain
var gadgetState="none"
# Dukun / Exorcist / Alkemis (skill panggil): diisi scene pertarungan tiap giliran; true = makhluk masih bertarung
var summonAlive=false

func _ready():
	actions.visible=false
	_style_combat_ui()

func _unhandled_input(event):
	# Echap / bouton retour : revient du choix d'attaque au menu principal
	if actions.visible and pickingTarget and event.is_action_pressed("ui_cancel"):
		_on_targetCancel()
		get_viewport().set_input_as_handled()
		return
	if actions.visible and showingAttacks and event.is_action_pressed("ui_cancel"):
		showActions()
		get_viewport().set_input_as_handled()

func showMessage(text_):
	message.text=text_
	message.visible_ratio=0.0
	if !GlobalPlayer.isDialogAnimationEnabled():
		message.visible_ratio=1.0
		return
	var tween=message.create_tween()
	tween.tween_property(message, "visible_ratio", 1.0, 0.012*text_.length())

func hideWindow():
	actions.visible=false
	$messageBox.visible=true

func showWindow():
	showActions()

func showActions():
	showingAttacks=false
	$messageBox.visible=true
	_clear()
	var attackButton=_addButton(_trad(GlobalGame.TRAD_FIGHT_ATTACK), _on_attackButton_pressed)
	_addButton(_trad(GlobalGame.TRAD_FIGHT_INVENTORY), _on_inventoryButton_pressed)
	_addButton(_trad(GlobalGame.TRAD_FIGHT_FLEE), _on_leaveButton_pressed)
	_open(attackButton)

# daftar item yang bisa dipakai saat bertarung (hanya yang dimiliki)
func showInventory():
	showingAttacks=true
	$messageBox.visible=false
	_clear()
	var first=null
	for itemId in _battleItems():
		var count=GlobalPlayer.countItem(itemId)
		if count==0:
			continue
		var item=GlobalItems.getItem(itemId)
		var button=_addButton(item.name+"  x"+str(count), _on_itemChosen.bind(itemId))
		if !GlobalPlayer.canUseItem(itemId,true) and !_canHealVera(itemId):
			button.disabled=true
		elif first==null:
			first=button
	if buttonList.get_child_count()==0:
		var empty=_addButton(_trad(GlobalGame.TRAD_FIGHT_NO_ITEM), Callable())
		empty.disabled=true
	_addButton(_trad(GlobalGame.TRAD_FIGHT_BACK), showActions)
	_open(first)

# ---- pilih sasaran serangan (pertarungan melawan 2 musuh) ----
# labels_: teks tiap musuh yang masih hidup, indexes_: nomor musuh yang dikirim saat dipilih
func showEnemyTargets(labels_, indexes_):
	pickingTarget=true
	showingAttacks=true
	$messageBox.visible=false
	_clear()
	var first=null
	for i in labels_.size():
		var button=_addButton(labels_[i], _on_targetChosen.bind(indexes_[i]))
		if first==null:
			first=button
	_addButton(_trad(GlobalGame.TRAD_FIGHT_BACK), _on_targetCancel)
	_open(first)

func _on_targetChosen(index_):
	pickingTarget=false
	hideWindow()
	emit_signal("targetPicked",index_)

func _on_targetCancel():
	pickingTarget=false
	hideWindow()
	emit_signal("targetPicked",-1)

# ---- item penyembuh untuk Vera ----
func _healsLife(itemId_):
	for action in GlobalItems.getItem(itemId_).actionList:
		if action.action=="increaseLife":
			return true
	return false

func _canHealVera(itemId_):
	return veraHealable and _healsLife(itemId_)

func _on_itemChosen(itemId_):
	var forHero=GlobalPlayer.canUseItem(itemId_,true)
	var forVera=_canHealVera(itemId_)
	if forHero and forVera:
		showItemTargets(itemId_)
	elif forVera:
		_on_veraItemButton_pressed(itemId_)
	else:
		_on_itemButton_pressed(itemId_)

func showItemTargets(itemId_):
	showingAttacks=true
	$messageBox.visible=false
	_clear()
	var heroButton=_addButton(_trad(GlobalGame.TRAD_FIGHT_FOR) % GlobalGame.getHeroName(), _on_itemButton_pressed.bind(itemId_))
	_addButton(_trad(GlobalGame.TRAD_FIGHT_FOR) % GlobalGame.getTraductionById(GlobalGame.TRAD_WORD_VERA), _on_veraItemButton_pressed.bind(itemId_))
	_addButton(_trad(GlobalGame.TRAD_FIGHT_BACK), showInventory)
	_open(heroButton)

func _on_veraItemButton_pressed(itemId_):
	hideWindow()
	emit_signal("useItemOnVera",itemId_)

func showAttacks():
	showingAttacks=true
	# la liste des attaques est large : elle prend la place du message
	$messageBox.visible=false
	_clear()
	var first=null
	var weaponAttackList=GlobalPlayer.getWeaponAttackList()
	if weaponAttackList.is_empty():
		# sans arme, on se defend quand meme a mains nues
		weaponAttackList=[attackClass.new(_trad(GlobalGame.TRAD_FIGHT_PUNCH), "", PUNCH_DAMAGE, 0)]
	# sisa mana ditampilkan di atas daftar serangan
	var manaInfo=_addButton("MP "+str(GlobalPlayer.getMana())+"/"+str(GlobalPlayer.getMaxMana()), Callable())
	manaInfo.disabled=true
	for attackLoop in weaponAttackList:
		var button
		if GlobalPlayer.isAttackUnlocked(attackLoop):
			var label=attackLoop.name+" "+str(FightRules.boosted(attackLoop.damage))
			if attackLoop.isGadget():
				label=_gadgetLabel(attackLoop)
			elif attackLoop.isSummon():
				label=_summonLabel(attackLoop)
			if attackLoop.manaCost > 0:
				label+="  MP"+str(attackLoop.manaCost)
			button=_addButton(label, _on_attack_pressed.bind(attackLoop))
			if attackLoop.isMagic():
				# serangan sihir diberi warna biru supaya beda dengan serangan fisik
				button.add_theme_color_override("font_color", Color(0.55, 0.78, 1.0))
				button.add_theme_color_override("font_hover_color", Color(0.75, 0.9, 1.0))
				button.add_theme_color_override("font_focus_color", Color(0.75, 0.9, 1.0))
			if attackLoop.isGadget():
				button.add_theme_color_override("font_color", Color(0.45, 0.95, 1.0))
			if attackLoop.isSummon():
				# skill panggil diberi warna ungu supaya mudah dikenali
				button.add_theme_color_override("font_color", Color(0.82, 0.62, 1.0))
				button.add_theme_color_override("font_hover_color", Color(0.92, 0.8, 1.0))
				button.add_theme_color_override("font_focus_color", Color(0.92, 0.8, 1.0))
			if !GlobalPlayer.canUseMana(attackLoop.manaCost):
				button.disabled=true
			elif attackLoop.isGadget() and !_gadgetUsable():
				# Turet sedang aktif: tombol tampil tapi tidak bisa ditekan
				button.disabled=true
			elif attackLoop.isSummon() and summonAlive:
				# hanya satu makhluk dalam satu waktu
				button.disabled=true
			elif first==null:
				first=button
		else:
			# attaque visible mais verrouillee : donne un objectif d'xp
			button=_addButton(attackLoop.name+"  XP "+str(attackLoop.xpMin), Callable())
			button.disabled=true
	# Ksatria bisa bertahan dengan perisainya (kurangi serangan musuh giliran ini)
	if GlobalPlayer.hasShieldReady():
		var defendButton=_addButton(_trad(GlobalGame.TRAD_FIGHT_DEFEND), _on_defend_pressed)
		if first==null:
			first=defendButton
	_addButton(_trad(GlobalGame.TRAD_FIGHT_BACK), showActions)
	_open(first)

# teks tombol skill 2 Engineer sesuai keadaan kotak
func _gadgetLabel(attack_):
	match gadgetState:
		"box":
			return "Ubah Jadi Turet"
		"turret":
			return "Turet aktif"
	return attack_.name+" 17-25"

# teks tombol skill panggil: nama skill, atau "(aktif)" selama makhluknya masih bertarung
func _summonLabel(attack_):
	if summonAlive:
		return attack_.name+" (aktif)"
	return attack_.name

func _gadgetUsable():
	return gadgetState!="turret"

func _open(focus_):
	# le panneau reprend la taille de son contenu (il grandit vers le haut et la gauche)
	actions.offset_left=actions.offset_right
	actions.offset_top=actions.offset_bottom
	actions.visible=true
	# on attend que le conteneur ait pris sa taille avant de donner le focus
	await get_tree().process_frame
	_fitActions()
	if focus_!=null and is_instance_valid(focus_):
		focus_.grab_focus()

# panel tidak boleh lebih besar dari layar atau keluar dari tepinya
func _fitActions():
	actions.custom_minimum_size=Vector2(0,0)
	var screen=get_viewport().get_visible_rect().size
	# dari tepi kanan bawah, naik sesuai tinggi isi; kalau melewati atas layar rapatkan jarak antar tombol
	var maxHeight=screen.y-MENU_MARGIN*2.0
	if actions.size.y>maxHeight:
		buttonList.add_theme_constant_override("separation",0)
	else:
		buttonList.add_theme_constant_override("separation",1)

func _clear():
	for child in buttonList.get_children():
		buttonList.remove_child(child)
		child.queue_free()

# batas ukuran menu aksi (layar permainan 320x180)
const MENU_MARGIN=2.0

func _compactStyle(button_, name_):
	var box = StyleBoxFlat.new()
	box.content_margin_left = 5.0
	box.content_margin_right = 4.0
	box.content_margin_top = 3.0
	box.content_margin_bottom = 3.0
	box.corner_radius_top_left = 3
	box.corner_radius_top_right = 3
	box.corner_radius_bottom_left = 3
	box.corner_radius_bottom_right = 3
	match name_:
		"normal":
			box.bg_color = Color(0.10, 0.14, 0.21, 1.0)
			box.border_color = Color(0.20, 0.31, 0.40, 1.0)
			box.border_width_bottom = 1
		"hover", "focus":
			box.bg_color = Color(0.14, 0.28, 0.36, 1.0)
			box.border_color = Color(0.34, 0.75, 0.82, 1.0)
			box.border_width_left = 1
			box.border_width_top = 1
			box.border_width_right = 1
			box.border_width_bottom = 1
		"pressed", "hover_pressed":
			box.bg_color = Color(0.07, 0.23, 0.30, 1.0)
			box.border_color = Color(0.34, 0.75, 0.82, 1.0)
			box.border_width_bottom = 1
		"disabled":
			box.bg_color = Color(0.075, 0.09, 0.13, 0.9)
			box.border_color = Color(0.16, 0.20, 0.25, 1.0)
			box.border_width_bottom = 1
	button_.add_theme_stylebox_override(name_, box)

func _style_combat_ui():
	var panel = StyleBoxFlat.new()
	panel.bg_color = Color(0.045, 0.065, 0.105, 0.97)
	panel.border_color = Color(0.20, 0.43, 0.52, 1.0)
	panel.border_width_left = 1
	panel.border_width_top = 1
	panel.border_width_right = 1
	panel.border_width_bottom = 2
	panel.corner_radius_top_left = 4
	panel.corner_radius_top_right = 4
	panel.corner_radius_bottom_left = 4
	panel.corner_radius_bottom_right = 4
	panel.content_margin_left = 6
	panel.content_margin_right = 6
	panel.content_margin_top = 5
	panel.content_margin_bottom = 5
	$messageBox.add_theme_stylebox_override("panel", panel)
	var action_panel: StyleBoxFlat = panel.duplicate() as StyleBoxFlat
	action_panel.bg_color = Color(0.055, 0.075, 0.12, 0.98)
	action_panel.content_margin_left = 4
	action_panel.content_margin_right = 4
	action_panel.content_margin_top = 4
	action_panel.content_margin_bottom = 4
	actions.add_theme_stylebox_override("panel", action_panel)
	message.add_theme_color_override("font_color", Color(0.93, 0.96, 1.0, 1.0))
	message.add_theme_font_size_override("font_size", 7)
	buttonList.add_theme_constant_override("separation", 3)

func _addButton(text_, callable_:Callable):
	var button=Button.new()
	button.text=text_
	button.alignment=HORIZONTAL_ALIGNMENT_LEFT
	button.custom_minimum_size=Vector2(0,14)
	button.add_theme_font_size_override("font_size", 7)
	button.add_theme_color_override("font_color", Color(0.90, 0.94, 0.98, 1.0))
	button.add_theme_color_override("font_hover_color", Color(0.65, 0.91, 0.96, 1.0))
	button.add_theme_color_override("font_focus_color", Color(0.65, 0.91, 0.96, 1.0))
	button.add_theme_color_override("font_disabled_color", Color(0.43, 0.47, 0.52, 1.0))
	for styleName in ["normal","hover","pressed","disabled","hover_pressed","focus"]:
		_compactStyle(button,styleName)
	if callable_.is_valid():
		button.pressed.connect(callable_)
	buttonList.add_child(button)
	return button

# item yang bisa dipakai dari menu Inventaris saat bertarung
func _battleItems():
	return [
		GlobalItems.ID.HP_POTION,
		GlobalItems.ID.MANA_POTION,
		GlobalItems.ID.BIKA_AMBON,
		GlobalItems.ID.KUE_PUTU,
		GlobalItems.ID.LAKLAK,
		GlobalItems.ID.KELAPA,
		GlobalItems.ID.SOTO,
		GlobalItems.ID.JAMU_OJO_LALI
	]

func _trad(id_):
	return GlobalGame.getTraductionById(id_)

func _on_leaveButton_pressed():
	hideWindow()
	emit_signal("leave")

func _on_attackButton_pressed():
	showAttacks()

func _on_inventoryButton_pressed():
	showInventory()

func _on_potionButton_pressed():
	hideWindow()
	emit_signal("usePotion")

func _on_itemButton_pressed(itemId_):
	hideWindow()
	emit_signal("useItemById",itemId_)

func _on_foodButton_pressed():
	hideWindow()
	emit_signal("useFood")

func _on_defend_pressed():
	hideWindow()
	emit_signal("defend")

func _on_attack_pressed(attack_):
	hideWindow()
	emit_signal("attack", attack_)
