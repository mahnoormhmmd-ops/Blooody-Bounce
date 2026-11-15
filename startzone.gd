extends Area2D

@export_file("*.tscn") var next_level = ""
@export var win_text = "LEVEL COMPLETE!"
@export var win_time = 5.0

const FONT_PATH = "rres://assets/fonts/PixelOperator8-Bold.ttf"   
const FONT_SIZE = 25
const WIN_SOUND_PATH = "res://Level_Complete_Jingle_DailySounds.wav"   
const WIN_SOUND_VOLUME_DB = 0.0

var done = false

func _physics_process(_delta):
	if done:
		return
	# the level only finishes when every coin has been collected
	if get_tree().get_nodes_in_group("coin").size() > 0:
		return
	for body in get_overlapping_bodies():
		if body.is_in_group("player"):
			win()
			return

func win():
	done = true
	play_win_sound()

	var layer = CanvasLayer.new()
	layer.layer = 100
	add_child(layer)

	var center = CenterContainer.new()
	layer.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.9)
	style.set_border_width_all(4)
	style.border_color = Color(1, 0.9, 0.3)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(24)

	var panel = PanelContainer.new()
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)

	var label = Label.new()
	label.text = win_text
	label.add_theme_font_size_override("font_size", FONT_SIZE)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if ResourceLoader.exists(FONT_PATH):
		label.add_theme_font_override("font", load(FONT_PATH))
	panel.add_child(label)

	await get_tree().create_timer(win_time).timeout
	if next_level != "":
		get_tree().change_scene_to_file(next_level)
	else:
		get_tree().reload_current_scene()

func play_win_sound():
	var stream = load("res://Level_Complete_Jingle_DailySounds.wav")
	if stream == null:
		print("ERROR: could not load win sound at ", "res://Level_Complete_Jingle_DailySounds.wav")
		return
	var p = AudioStreamPlayer.new()
	p.stream = stream
	p.volume_db = WIN_SOUND_VOLUME_DB
	p.process_mode = Node.PROCESS_MODE_ALWAYS    
	get_tree().root.add_child(p)                 
	p.finished.connect(p.queue_free)
	p.play()
