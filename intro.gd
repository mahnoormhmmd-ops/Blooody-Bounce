extends Node

static var shown = false      # remembers the intro was already shown, so it doesn't replay on restart

const INTRO_TEXT = "The king threw you out of the kingdom into this deadly dungeon. 
Collect the coins and bring them back if you want to bounce back from this setback ;D"
const FONT_PATH = "res://assets/fonts/PixelOperator8.ttf"   
const FONT_SIZE = 25
const SHOW_TIME = 5.0         # seconds the box stays before fading
const FADE_TIME = 1.5         # seconds the fade takes

var layer
var panel
var finished = false

func _ready():
	if shown:
		queue_free()
		return
	shown = true
	process_mode = Node.PROCESS_MODE_ALWAYS    # keeps running while the game is paused
	get_tree().paused = true
	build_box()
	await get_tree().create_timer(SHOW_TIME).timeout
	fade_out()

func build_box():
	layer = CanvasLayer.new()
	layer.layer = 100
	add_child(layer)

	var center = CenterContainer.new()
	layer.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.85)
	style.set_border_width_all(3)
	style.border_color = Color(1, 0.9, 0.3)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(24)

	panel = PanelContainer.new()
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)

	var label = Label.new()
	label.text = INTRO_TEXT
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.custom_minimum_size = Vector2(get_viewport().get_visible_rect().size.x * 0.6, 0)
	label.add_theme_font_size_override("font_size", FONT_SIZE)
	if ResourceLoader.exists(FONT_PATH):
		label.add_theme_font_override("font", load(FONT_PATH))
	panel.add_child(label)

func _unhandled_input(event):
	# press any key or click to skip
	if finished:
		return
	if (event is InputEventKey and event.pressed) or (event is InputEventMouseButton and event.pressed):
		get_viewport().set_input_as_handled()
		fade_out()

func fade_out():
	if finished:
		return
	finished = true
	var tween = create_tween()
	tween.tween_property(panel, "modulate:a", 0.0, FADE_TIME)
	await tween.finished
	layer.hide()
	get_tree().paused = false
