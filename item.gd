extends Area2D

const SOUND_PATH = "res://assets/sounds/coin.wav"    # paste your sound's path here
const SOUND_VOLUME_DB = 0.0                          # 0 = full volume, lower = quieter

@onready var sprite = $Sprite2D
var t = 0.0

func _ready():
	add_to_group("coin")
	body_entered.connect(_on_body_entered)

func _process(delta):
	t += delta
	sprite.frame = int(t * 10) % sprite.hframes

func _on_body_entered(body):
	if body.is_in_group("player"):
		remove_from_group("coin")
		play_sound()
		queue_free()

func play_sound():
	var stream = load("res://game-coin.wav")
	if stream == null:
		print("ERROR: could not load sound at ", "res://game-coin.wav")
		return
	# the coin is about to disappear, so the sound gets its own player in the level
	var p = AudioStreamPlayer.new()
	p.stream = stream
	p.volume_db = SOUND_VOLUME_DB
	get_tree().current_scene.add_child(p)
	p.finished.connect(p.queue_free)   
	p.play()
