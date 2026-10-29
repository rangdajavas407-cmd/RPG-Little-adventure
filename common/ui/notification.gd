extends Control

# Toast minimalis di tengah atas layar: satu kotak kecil, huruf pixel kecil, tampil sebentar lalu hilang.
# display(teks, jenis) -> jenis: info, danger, story, success, reward (hanya mengubah warna garis & bingkai)
# Seluruh tampilan dibuat lewat kode agar ukurannya mengikuti isi teks (bukan ukuran tetap).

const DefaultTheme=preload("res://common/themes/default.tres")

const KINDS={
	"info":Color(0.35,0.78,0.86),
	"danger":Color(0.92,0.36,0.30),
	"story":Color(0.72,0.55,0.95),
	"success":Color(0.45,0.82,0.52),
	"reward":Color(0.96,0.78,0.34)
}

const FONT_SIZE=6
const MAX_TEXT_WIDTH=150.0
const TOP_MARGIN=5.0
const MARGIN=3

var toast: PanelContainer
var label: Label
var _tween: Tween
var _queue: Array = []
var _showing := false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	toast = PanelContainer.new()
	toast.theme = DefaultTheme
	toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toast.visible = false
	add_child(toast)
	label = Label.new()
	label.add_theme_font_size_override("font_size", FONT_SIZE)
	label.add_theme_color_override("font_color", Color(0.94, 0.96, 0.98))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toast.add_child(label)

func _applyStyle(color_: Color) -> void:
	var panel := StyleBoxFlat.new()
	panel.bg_color = Color(0.05, 0.07, 0.11, 0.92)
	panel.border_color = Color(color_.r, color_.g, color_.b, 0.8)
	panel.set_border_width_all(1)
	panel.set_corner_radius_all(3)
	# margin tipis (3 px) di sekeliling teks; warna jenis ditandai bingkai
	panel.content_margin_left = MARGIN
	panel.content_margin_right = MARGIN
	panel.content_margin_top = MARGIN
	panel.content_margin_bottom = MARGIN
	toast.add_theme_stylebox_override("panel", panel)

func display(text_: String, kind_: String = "info", _title: String = "") -> void:
	_queue.append({"text": text_, "kind": kind_})
	if !_showing:
		_next()

func _next() -> void:
	if _queue.is_empty():
		_showing = false
		toast.visible = false
		return
	_showing = true
	var item = _queue.pop_front()
	_applyStyle(KINDS.get(item.kind, KINDS["info"]))

	# lebar mengikuti teks (maksimal MAX_TEXT_WIDTH, lebih dari itu dibungkus ke baris berikutnya)
	var font := label.get_theme_font("font")
	var textWidth := font.get_string_size(item.text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x
	label.text = item.text
	if textWidth > MAX_TEXT_WIDTH:
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.custom_minimum_size = Vector2(MAX_TEXT_WIDTH, 0)
	else:
		label.autowrap_mode = TextServer.AUTOWRAP_OFF
		label.custom_minimum_size = Vector2(0, 0)
	toast.modulate.a = 0.0
	toast.visible = true
	toast.reset_size()
	await get_tree().process_frame
	toast.reset_size()
	var screenWidth := get_viewport_rect().size.x
	toast.position = Vector2(floorf((screenWidth - toast.size.x) / 2.0), TOP_MARGIN)

	if _tween and _tween.is_running():
		_tween.kill()
	# tampil total sekitar 2-3 detik (termasuk memudar)
	var hold := clampf(1.7 + float(item.text.length()) * 0.015, 2.0, 2.6)
	if !_queue.is_empty():
		hold = minf(hold, 2.0)
	_tween = create_tween()
	_tween.tween_property(toast, "modulate:a", 1.0, 0.12)
	_tween.tween_interval(hold)
	_tween.tween_property(toast, "modulate:a", 0.0, 0.15)
	_tween.tween_callback(_next)
