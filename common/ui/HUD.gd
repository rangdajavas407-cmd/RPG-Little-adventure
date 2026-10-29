extends CanvasLayer

signal save
signal quit

signal equipItem(item_)
signal useItem(item_)
signal refreshTouchUi

signal openMenu
signal closeMenu

const MENU_SAVE=0
const MENU_QUIT=2   # v9.24: Inventaris dihapus dari menu jeda, dibuka lewat tombol tas di sebelah Menu

const LOW_LIFE_RATIO=0.3
const ConsumeAnim=preload("res://common/ui/consumeAnim.gd")

# true selama animasi minum/makan (menu tetap "tertutup" sampai animasi selesai)
var consuming=false

@onready var btnBlock=$btnBlock
@onready var confirmation=$confirmation
@onready var parameters=$parameters

var displayedGems=0
# frame de fermeture du menu (la meme touche Echap ne doit pas le rouvrir)
var menuClosedFrame=-1
var displayedXp=0

# Called when the node enters the scene tree for the first time.
func _ready():
	displayedGems=GlobalPlayer.getGemsBalance()
	displayedXp=GlobalPlayer.getXp()
	setLife(GlobalPlayer.getLife())
	setMana(GlobalPlayer.getMana())
	setGems(displayedGems)
	setXp(displayedXp)

	btnBlock.visible=false
	confirmation.visible=false
	parameters.visible=false
	$modalBackdrop.visible=false
	$saved.visible=false

	$inventoryList.setItemList(GlobalPlayer.getItemsList())

	refreshUi()

func refreshUi():
	$Control/btnMenu.text=GlobalGame.getTraductionById(GlobalGame.TRAD_UI_MENU)
	$btnBlock/list/title.text=GlobalGame.getTraductionById(GlobalGame.TRAD_UI_PAUSE)
	$btnBlock/list/btnCancell.text=GlobalGame.getTraductionById(GlobalGame.TRAD_UI_RESUME)
	$btnBlock/list/btnSave.text=GlobalGame.getTraductionById(GlobalGame.TRAD_UI_SAVE)
	$btnBlock/list/btnParameters.text=GlobalGame.getTraductionById(GlobalGame.TRAD_UI_SETTINGS)
	$btnBlock/list/btnQuit.text=GlobalGame.getTraductionById(GlobalGame.TRAD_UI_QUIT)
	$confirmation/list/title.text=GlobalGame.getTraductionById(GlobalGame.TRAD_UI_QUIT_CONFIRM)
	$confirmation/list/warning.text=GlobalGame.getTraductionById(GlobalGame.TRAD_UI_QUIT_WARNING)
	$confirmation/list/buttons/btnYes.text=GlobalGame.getTraductionById(GlobalGame.TRAD_UI_YES)
	$confirmation/list/buttons/btnNo.text=GlobalGame.getTraductionById(GlobalGame.TRAD_UI_NO)
	$parameters/list/title.text=GlobalGame.getTraductionById(GlobalGame.TRAD_UI_SETTINGS)
	$parameters/list/touchUiEnabled.text=GlobalGame.getTraductionById(GlobalGame.TRAD_UI_TOUCH)
	$parameters/list/dialogAnimationEnabled.text=GlobalGame.getTraductionById(GlobalGame.TRAD_UI_DIALOG_ANIMATION)
	$parameters/list/saveParameters.text=GlobalGame.getTraductionById(GlobalGame.TRAD_UI_CLOSE)
	$saved/label.text=GlobalGame.getTraductionById(GlobalGame.TRAD_UI_SAVED)

func _process(delta):
	# coeur qui clignote quand la vie est basse
	var lowLife=GlobalPlayer.getLife() <= GlobalPlayer.getMaxLife()*LOW_LIFE_RATIO
	if lowLife and (Time.get_ticks_msec()/250)%2==0:
		$Control/lifeIcon.modulate=Color(1,1,1,0.35)
	else:
		$Control/lifeIcon.modulate=Color.WHITE

func _unhandled_input(event):
	# Echap / bouton retour : revient en arriere dans les menus
	if !event.is_action_pressed("ui_cancel"):
		return
	if parameters.visible:
		_on_saveParameters_button_down()
	elif confirmation.visible:
		_on_btnNo_button_down()
	elif btnBlock.visible:
		_on_btnCancell_button_down()
	else:
		return
	get_viewport().set_input_as_handled()

func isMenuOpen():
	return btnBlock.visible or confirmation.visible or parameters.visible or $inventoryList.getWindow().visible

func emitOpenMenu():
	$modalBackdrop.visible=true
	get_tree().paused=true
	emit_signal("openMenu")

func emitCloseMenu():
	$modalBackdrop.visible=false
	get_tree().paused=false
	menuClosedFrame=Engine.get_process_frames()
	emit_signal("closeMenu")

func reloadGems():
	var gems=GlobalPlayer.getGemsBalance()
	if gems > displayedGems:
		popGain($Control/gem, gems-displayedGems)
	displayedGems=gems
	setGems(gems)

func reloadInventory():
	$inventoryList.setItemList(GlobalPlayer.getItemsList())

func reloadLife():
	setLife(GlobalPlayer.getLife())

func reloadMana():
	setMana(GlobalPlayer.getMana())

func reloadXp():
	var xp=GlobalPlayer.getXp()
	if xp > displayedXp:
		popGain($Control/xp, xp-displayedXp)
	displayedXp=xp
	setXp(xp)

# petit "+N" qui monte au-dessus d'un compteur
func popGain(label_:Label, value_):
	var pop=Label.new()
	pop.text="+"+str(value_)
	pop.add_theme_color_override("font_color", Color(1, 0.82, 0.4))
	pop.add_theme_color_override("font_outline_color", Color(0.13, 0.125, 0.2))
	pop.add_theme_constant_override("outline_size", 2)
	pop.add_theme_font_size_override("font_size", 6)
	pop.position=label_.position+Vector2(0, 8)
	$Control.add_child(pop)
	var tween=pop.create_tween()
	tween.tween_property(pop, "position:y", pop.position.y+8, 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(pop, "modulate:a", 0.0, 0.6).set_delay(0.3)
	tween.tween_callback(pop.queue_free)
	# le compteur s'illumine brievement
	var bump=label_.create_tween()
	bump.tween_property(label_, "modulate", Color(1, 0.82, 0.4), 0.05)
	bump.tween_property(label_, "modulate", Color.WHITE, 0.4)

func setLife(life_):
	$Control/life.text=str(life_)

func setMana(mana_):
	$Control/mana.text=str(mana_)+"/"+str(GlobalPlayer.getMaxMana())

func setGems(gems_):
	$Control/gem.text=str(gems_)

func setXp(xp_):
	$Control/xp.text=str(xp_)


func openPauseMenu():
	if isMenuOpen() or menuClosedFrame==Engine.get_process_frames():
		return
	refreshUi()
	btnBlock.visible=true
	emitOpenMenu()
	$btnBlock/list/btnCancell.grab_focus()

func _on_Button_button_down():
	openPauseMenu()


# v9.17: tombol tas di sebelah Menu membuka inventaris langsung (tanpa lewat menu jeda).
# (Inventaris sudah dihapus dari menu jeda, tombol tas ini satu-satunya jalan.) Dunia berhenti, ESC / tombol tutup menutupnya lewat closeInventory.
func openInventoryDirect():
	if isMenuOpen() or consuming or menuClosedFrame==Engine.get_process_frames():
		return
	refreshUi()
	emitOpenMenu()
	$inventoryList.showWindow()


func _on_btnBag_pressed():
	openInventoryDirect()


func _on_btnSave_button_down():
	emit_signal("save")
	btnBlock.visible=false
	$saved.visible=true
	$savedTimer.start()
	emitCloseMenu()

func _on_btnQuit_button_down():
	btnBlock.visible=false
	confirmation.visible=true
	$confirmation/list/buttons/btnNo.grab_focus()

func _on_btnYes_button_down():
	confirmation.visible=false
	emitCloseMenu()
	emit_signal("quit")


func _on_btnNo_button_down():
	confirmation.visible=false
	btnBlock.visible=true
	$btnBlock/list/btnQuit.grab_focus()

func _on_inventoryList_equipItem(item_):
	# memasang senjata khas class bisa mengganti class aktif (HP/MP maksimum ikut berubah)
	reloadLife()
	reloadMana()
	emit_signal("equipItem",item_)
	emitCloseMenu()

func _on_btnCancell_button_down():
	btnBlock.visible=false
	emitCloseMenu()


func _on_savedTimer_timeout():
	$saved.visible=false


func _on_inventoryList_useItem(item_):
	emit_signal("useItem",item_)
	reloadLife()
	reloadMana()
	var result=GlobalPlayer.lastUseResult
	if result.is_empty():
		# HP & Mana sudah penuh -> item tidak dipakai
		_showFullNotice()
		emitCloseMenu()
		return
	# animasi minum / makan, dunia tetap berhenti sampai selesai
	consuming=true
	var anim=ConsumeAnim.new()
	anim.setup(item_,result)
	add_child(anim)
	await anim.finished
	consuming=false
	emitCloseMenu()

func _showFullNotice():
	var label=Label.new()
	label.text=GlobalGame.getTraductionById(GlobalGame.TRAD_UI_FULL)
	label.add_theme_color_override("font_outline_color",Color(0.13,0.125,0.2))
	label.add_theme_constant_override("outline_size",3)
	label.position=Vector2(60,150)
	label.process_mode=Node.PROCESS_MODE_ALWAYS
	add_child(label)
	var tween=label.create_tween()
	tween.tween_property(label,"modulate:a",0.0,1.2).set_delay(0.8)
	tween.tween_callback(label.queue_free)

func _on_player_pressMenu():
	openPauseMenu()


func _on_btnParameters_button_down():
	btnBlock.visible=false
	parameters.visible=true

	$parameters/list/touchUiEnabled.set_pressed_no_signal(GlobalPlayer.isTouchEnabled())
	$parameters/list/dialogAnimationEnabled.set_pressed_no_signal(GlobalPlayer.isDialogAnimationEnabled())

	$parameters/list/touchUiEnabled.grab_focus()


func _on_saveParameters_button_down():
	parameters.visible=false
	emit_signal("refreshTouchUi")
	btnBlock.visible=true
	$btnBlock/list/btnParameters.grab_focus()


func _on_touchUiEnabled_toggled(button_pressed):
	if(button_pressed):
		GlobalPlayer.enableTouch()
	else:
		GlobalPlayer.disableTouch()


func _on_dialogAnimationEnabled_toggled(button_pressed):
	if(button_pressed):
		GlobalPlayer.enableDialogAnimation()
	else:
		GlobalPlayer.disableDialogAnimation()


func _on_inventoryList_closeInventory():
	if consuming:
		return
	emitCloseMenu()
