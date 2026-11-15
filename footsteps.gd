extends AudioStreamPlayer2D

const SOUND_PATH = "res://assets/sounds/step.wav"    # paste your sound's path here
const STEP_INTERVAL = 0.3                            # seconds between steps, lower = faster steps
const VOLUME_DB = -6.0                               # 0 = full volume, lower = quieter

@onready var body = get_parent()
var timer = 0.0

func _ready():
	stream = load("res://sfxmint-footsteps-single-10.wav")
	volume_db = VOLUME_DB
	if stream == null:
		print("ERROR: could not load footstep sound at ", "res://sfxmint-footsteps-single-10.wav")

func _process(delta):
	if stream == null:
		return
	if body.is_on_floor() and abs(body.velocity.x) > 10:
		timer -= delta
		if timer <= 0.0:
			pitch_scale = randf_range(0.9, 1.1)    # small variation so it doesn't sound robotic
			play()
			timer = STEP_INTERVAL
	else:
		timer = 0.0    # the first step plays right away when you start moving
