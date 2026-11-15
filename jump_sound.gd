extends AudioStreamPlayer2D

const SOUND_PATH = "res://jump.wav"    
const SOUND_VOLUME_DB = -4.0          

@onready var body = get_parent()
var was_on_floor = true

func _ready():
	stream = load("res://jump.wav")
	volume_db = SOUND_VOLUME_DB
	if stream == null:
		print("ERROR: could not load jump sound at ", SOUND_PATH)

func _physics_process(_delta):
	var on_floor = body.is_on_floor()
	
	if stream != null and was_on_floor and not on_floor and body.velocity.y < 0:
		pitch_scale = randf_range(0.95, 1.05)    
		play()
	was_on_floor = on_floor
