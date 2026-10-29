extends CanvasLayer

# Panel tujuan ringkas di kanan atas, dengan animasi masuk singkat.
const DefaultTheme=preload("res://common/themes/default.tres")
const PANEL_WIDTH=112.0
const FONT_SIZE=6
var bg: PanelContainer
var label: Label
var pendingText=""
var _tween: Tween

func _init():
	layer=3

func _ready():
	bg=PanelContainer.new()
	bg.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var style=StyleBoxFlat.new()
	style.bg_color=Color(0.035,0.055,0.095,0.90)
	style.border_color=Color(0.22,0.56,0.66,0.92)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.content_margin_left=6
	style.content_margin_right=6
	style.content_margin_top=4
	style.content_margin_bottom=4
	bg.add_theme_stylebox_override("panel",style)
	bg.position=Vector2(320.0-PANEL_WIDTH-4.0,12.0)
	bg.modulate.a=0.0
	add_child(bg)
	label=Label.new()
	label.theme=DefaultTheme
	label.mouse_filter=Control.MOUSE_FILTER_IGNORE
	label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size",FONT_SIZE)
	label.add_theme_color_override("font_color",Color(0.91,0.96,1.0,1.0))
	label.custom_minimum_size=Vector2(PANEL_WIDTH-12,0)
	bg.add_child(label)
	_refresh()
	_tween=create_tween()
	_tween.tween_property(bg,"modulate:a",1.0,0.24).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tween.parallel().tween_property(bg,"position:y",16.0,0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func setText(text_):
	pendingText=text_
	if is_instance_valid(label):
		_refresh()

func _refresh():
	if !is_instance_valid(label) or !is_instance_valid(bg):
		return
	label.text=pendingText
	label.reset_size()
	await get_tree().process_frame
	if !is_instance_valid(label) or !is_instance_valid(bg):
		return
	label.reset_size()
	bg.size=Vector2(PANEL_WIDTH,label.size.y+8)
