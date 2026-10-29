extends Area2D
# Area interaksi untuk NPC dan benda yang bisa diajak bicara.
#
# Pemain harus berdiri di dalam area ini lalu menekan E (atau mengetuk tanda "E"
# di layar sentuh). Tidak ada lagi dialog yang muncul sendiri hanya karena
# pemain menabrak NPC. Pintu masuk/keluar tetap memakai door.tscn (otomatis).
#
# Sinyal 'playerOpenedDoor' sengaja dipertahankan agar semua koneksi lama di
# scene (talk, sellerTalk, discussionArea, adekTalk, dst.) tetap berfungsi.

signal playerOpenedDoor

# Jarak tanda "E" dari titik area (dalam piksel dunia, tidak ikut skala node).
@export var promptOffset := Vector2(0, -34)
# Matikan lewat kode jika NPC sedang tidak bisa diajak bicara.
@export var interactionEnabled := true

var _player = null
var _prompt : Label = null
var _lastTriggerFrame := -10


func _ready():
	_buildPrompt()


func _buildPrompt():
	_prompt = Label.new()
	_prompt.text = "E"
	_prompt.top_level = true
	_prompt.z_index = 100
	_prompt.visible = false
	_prompt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_prompt.custom_minimum_size = Vector2(13, 13)
	_prompt.add_theme_font_size_override("font_size", 8)
	_prompt.add_theme_color_override("font_color", Color(1, 0.96, 0.8))
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.13, 0.12, 0.2, 0.92)
	box.border_color = Color(1, 0.85, 0.45)
	box.set_border_width_all(1)
	box.set_corner_radius_all(3)
	box.content_margin_left = 2
	box.content_margin_right = 2
	box.content_margin_top = 0
	box.content_margin_bottom = 0
	_prompt.add_theme_stylebox_override("normal", box)
	add_child(_prompt)


func _findPlayer():
	for body in get_overlapping_bodies():
		if body.is_in_group("Player"):
			return body
	return null


func _playerCanAct(player_) -> bool:
	# saat dialog/menu terbuka, pemain tidak boleh memicu interaksi baru
	if "navigationEnabled" in player_ and !player_.navigationEnabled:
		return false
	# E yang baru dipakai untuk menutup dialog tidak boleh langsung membuka lagi
	if Engine.get_process_frames() <= GlobalGame.dialogEndFrame + 1:
		return false
	return true


func _process(_delta):
	_player = _findPlayer()
	var canAct = interactionEnabled and _player != null and _playerCanAct(_player)

	if _prompt != null:
		_prompt.visible = canAct
		if canAct:
			_prompt.reset_size()
			var bob = sin(Time.get_ticks_msec() / 220.0) * 1.5
			_prompt.global_position = global_position + promptOffset + Vector2(-_prompt.size.x / 2.0, bob)

	if canAct and Input.is_action_just_pressed("interact"):
		_trigger()


func _unhandled_input(event):
	# Layar sentuh / klik mouse pada tanda "E"
	if _prompt == null or !_prompt.visible:
		return
	var isTap = event is InputEventScreenTouch and event.pressed
	if !isTap:
		return
	var screenPos = get_viewport().get_canvas_transform() * _prompt.global_position
	var rect = Rect2(screenPos - Vector2(10, 10), _prompt.size * get_viewport().get_canvas_transform().get_scale() + Vector2(20, 20))
	if rect.has_point(event.position):
		_trigger()


func _trigger():
	var frame = Engine.get_process_frames()
	if frame == _lastTriggerFrame:
		return
	_lastTriggerFrame = frame
	emit_signal("playerOpenedDoor")
