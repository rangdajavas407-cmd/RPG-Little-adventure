extends CanvasLayer

const TextFit=preload("res://common/ui/textFit.gd")

signal discussionFinished

var multiDialogList=[]
var currentDiscussionPage=0
var currentDiscussionLine=0

var disableDisplayByCharacter=false

var lastNextFrame=-1
var _windowTween: Tween

# posisi kotak dialog terhadap tepi bawah layar (sama dengan di simpleDialog.tscn)
const WINDOW_TOP=-60.0
const WINDOW_BOTTOM=-6.0
const SLIDE_DISTANCE=10.0

func _process(delta):
	# uniquement quand le dialogue est affiche
	if getWindow().visible and (Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("interact")):
		_on_Button_pressed()
	# fleche "suite" qui clignote
	if getWindow().visible:
		getNextButton().modulate.a=1.0 if (Time.get_ticks_msec()/350)%2==0 else 0.25

# potret (opsional) tampil di kiri atas kotak dialog selama pembicara itu bicara
func addDiscussion(talker_,discussionList_,portrait_=""):
	multiDialogList.append({"talker":talker_,"discussionLineList":discussionList_,"portrait":portrait_})

var portraitRect=null

func _updatePortrait():
	var path=""
	if multiDialogList.size()>currentDiscussionPage:
		path=multiDialogList[currentDiscussionPage].get("portrait","")
	if path=="":
		if portraitRect!=null:
			portraitRect.visible=false
		return
	if portraitRect==null:
		portraitRect=TextureRect.new()
		portraitRect.mouse_filter=Control.MOUSE_FILTER_IGNORE
		portraitRect.stretch_mode=TextureRect.STRETCH_KEEP
		portraitRect.scale=Vector2(0.72,0.72)
		add_child(portraitRect)
		move_child(portraitRect,0)
	portraitRect.texture=load(path)
	# kaki potret menempel di tepi atas kotak dialog (layar 180 px tinggi)
	portraitRect.position=Vector2(6,180+WINDOW_TOP-portraitRect.texture.get_height()*0.8+2)
	portraitRect.visible=true

func start():
	# tombol yang membuka dialog (E) tidak boleh ikut melewati baris pertama
	lastNextFrame=Engine.get_process_frames()
	setTalker(getCurrentDiscussionTalker())
	_updatePortrait()
	getDiscussion().text=getCurrentDiscussionLine()
	getWindow().visible=true
	getWindow().modulate.a=0.0
	# mulai sedikit di bawah lalu naik ke tempatnya (jangan pakai position: kotak menempel di bawah lewat anchor)
	getWindow().offset_top=WINDOW_TOP+SLIDE_DISTANCE
	getWindow().offset_bottom=WINDOW_BOTTOM+SLIDE_DISTANCE
	if _windowTween and _windowTween.is_running():
		_windowTween.kill()
	_windowTween=create_tween()
	_windowTween.set_parallel(true)
	_windowTween.tween_property(getWindow(), "modulate:a", 1.0, 0.18)
	_windowTween.tween_property(getWindow(), "offset_top", WINDOW_TOP, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_windowTween.tween_property(getWindow(), "offset_bottom", WINDOW_BOTTOM, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	$Timer.start()

func end():
	if _windowTween and _windowTween.is_running():
		_windowTween.kill()
	getWindow().visible=false
	getWindow().modulate.a=1.0
	getWindow().offset_top=WINDOW_TOP
	getWindow().offset_bottom=WINDOW_BOTTOM
	if portraitRect!=null:
		portraitRect.visible=false
	$Timer.stop()

func _ready():
	getWindow().visible=false
	# Gaya panel SAMA dengan kotak pesan saat battle (navy gelap, garis teal, sudut membulat)
	var panel_style=StyleBoxFlat.new()
	panel_style.bg_color=Color(0.045,0.065,0.105,0.97)
	panel_style.border_color=Color(0.20,0.43,0.52,1.0)
	panel_style.border_width_left=1
	panel_style.border_width_top=1
	panel_style.border_width_right=1
	panel_style.border_width_bottom=2
	panel_style.set_corner_radius_all(4)
	getWindow().add_theme_stylebox_override("panel",panel_style)
	# tab nama pembicara: aksen teal seperti tombol terpilih di battle
	var tab_style=StyleBoxFlat.new()
	tab_style.bg_color=Color(0.07,0.23,0.30,1.0)
	tab_style.border_color=Color(0.34,0.75,0.82,1.0)
	tab_style.set_border_width_all(1)
	tab_style.set_corner_radius_all(3)
	tab_style.content_margin_left=5
	tab_style.content_margin_right=5
	tab_style.content_margin_top=1
	tab_style.content_margin_bottom=1
	getWindow().get_node("talkerTab").add_theme_stylebox_override("panel",tab_style)
	getTalker().add_theme_color_override("font_color",Color(0.65,0.91,0.96,1.0))
	getDiscussion().add_theme_color_override("default_color",Color(0.93,0.96,1.0,1.0))
	# Baca nyaman: bungkus kalimat panjang agar tidak keluar dari panel dialog.
	if getDiscussion() is Label:
		getDiscussion().autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	resetCharacterVisible()

#access
func getWindow():
	return $window

func getNextButton():
	return getWindow().get_node("nextButton")

func getDiscussion():
	return getWindow().get_node("discussion")

func getTalker():
	return getWindow().get_node("talkerTab/talker")

func setTalker(talker_):
	TextFit.fit(getTalker(),talker_,150)
	getWindow().get_node("talkerTab").visible=talker_!=""
	# l'onglet reprend la taille du nom
	getWindow().get_node("talkerTab").reset_size()
	


func getCurrentDiscussion():
	return multiDialogList[currentDiscussionPage]

func getCurrentDiscussionTalker():
	return multiDialogList[currentDiscussionPage]["talker"]

func getCurrentDiscussionLine():
	return getCurrentDiscussion()["discussionLineList"][currentDiscussionLine]

func shouldContinueNextPage():
	if currentDiscussionPage < multiDialogList.size()-1:
		return true
	else:
		return false

func shouldContinueNextLine():
	if currentDiscussionLine < getCurrentDiscussion()["discussionLineList"].size()-1:
		return true
	return false

func resetCharacterVisible():
	getDiscussion().set_visible_characters(0)


func next():
	# un seul avancement par frame (Entree peut arriver par plusieurs chemins)
	if lastNextFrame==Engine.get_process_frames():
		return
	lastNextFrame=Engine.get_process_frames()
	if !GlobalPlayer.isDialogAnimationEnabled()  or getDiscussion().get_visible_characters() > getDiscussion().get_total_character_count():
		if shouldContinueNextLine():
			currentDiscussionLine+=1
			resetCharacterVisible()
			getDiscussion().text=getCurrentDiscussionLine()
		elif shouldContinueNextPage():
			currentDiscussionPage+=1
			currentDiscussionLine=0
			resetCharacterVisible()
			setTalker(getCurrentDiscussionTalker())
			_updatePortrait()
			getDiscussion().text=getCurrentDiscussionLine()
		else:
			currentDiscussionPage=0
			currentDiscussionLine=0
			resetCharacterVisible()
			disableDisplayByCharacter=true
			# dipakai area interaksi agar E penutup dialog tidak membuka dialog lagi
			GlobalGame.dialogEndFrame=Engine.get_process_frames()
			emit_signal("discussionFinished")

func displayNextCharacter():
	
	if !GlobalPlayer.isDialogAnimationEnabled()  :
		getDiscussion().set_visible_characters(getDiscussion().get_total_character_count())
	else:
		getDiscussion().set_visible_characters(getDiscussion().get_visible_characters()+1)
	
	if(getDiscussion().get_total_character_count() > getDiscussion().get_visible_characters() ):		
		getNextButton().visible=false
	else:
		getNextButton().visible=true

func _on_Timer_timeout():
	displayNextCharacter()

func _on_Button_pressed():
	next()


