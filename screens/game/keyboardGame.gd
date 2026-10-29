extends Control

signal fillField(text_)
signal close

#var textValue=""

@onready var _textField=$VBox/TextEdit

func eraseLetter():
	
	var textLength=getText().length()
	if textLength>0:
		var newText= getText().substr(0, textLength-1)
		updateField(newText)
	
func addLetter(letter_):
	var newText=getText()+letter_
	updateField(newText)

func updateField(text_):
	_textField.text=text_

func getText():
	return _textField.text

func reset():
	updateField("")


# Called when the node enters the scene tree for the first time.
func _ready():
	refreshUi()
	build()
	$VBox/HBoxContainer/submit.grab_focus()
	pass # Replace with function body.


func build():
	var templateButton=$Button
	
	var letterList=["A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z","-"]
	
	for letter in letterList:
		var newLetterBtn=templateButton.duplicate()

		newLetterBtn.connect("button_down", Callable(self, "_on_button_pressed").bind(letter))

		newLetterBtn.text=" "+letter+" "
		$VBox/GridContainer.add_child(newLetterBtn)
	

func _on_button_pressed(letter_):
	addLetter(letter_)


func _on_submit_button_down():
	submit()

# Kirim nama. Nama kosong tidak boleh dikonfirmasi.
func submit():
	var name_=getText().strip_edges()
	if name_=="":
		return
	emit_signal("fillField",name_)

# Pintasan keyboard:
#  - Enter      : konfirmasi nama (di mana pun fokus tombolnya)
#  - Backspace  : hapus satu huruf
#  - Escape     : kembali ke menu
#  - W/A/S/D atau panah : pindah antar tombol huruf, Spasi untuk menekan tombol
func _input(event):
	if !(event is InputEventKey) or !event.pressed or event.echo:
		return
	if event.keycode==KEY_ENTER or event.keycode==KEY_KP_ENTER:
		get_viewport().set_input_as_handled()
		submit()
	elif event.keycode==KEY_BACKSPACE:
		get_viewport().set_input_as_handled()
		eraseLetter()
	elif event.keycode==KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		emit_signal("close")


func _on_erase_button_down():
	eraseLetter()


func _on_Retour_button_down():
	emit_signal("close")

func refreshUi():
	$VBox/title.text=GlobalGame.getTraductionById(GlobalGame.TRAD_LABEL_VOTREPSEUDO)
	$VBox/HBoxContainer/Retour.text=GlobalGame.getTraductionById(GlobalGame.TRAD_BUTTON_RETOUR)
	$VBox/HBoxContainer/erase.text=GlobalGame.getTraductionById(GlobalGame.TRAD_BUTTON_EFFACER)
	$VBox/HBoxContainer/submit.text=GlobalGame.getTraductionById(GlobalGame.TRAD_BUTTON_VALIDER)
	
