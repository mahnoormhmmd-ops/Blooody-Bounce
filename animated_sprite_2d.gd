extends AnimatedSprite2D

@onready var body = get_parent()

func _process(_delta):
	# face the direction of movement
	if body.velocity.x < -1:
		flip_h = true
	elif body.velocity.x > 1:
		flip_h = false

	# pick the animation
	if not body.is_on_floor():
		play_anim("jump")
	elif abs(body.velocity.x) > 1:
		play_anim("run")
	else:
		play_anim("idle")

func play_anim(anim_name):
	if sprite_frames.has_animation(anim_name):
		play(anim_name)
	else:
		play("idle")
