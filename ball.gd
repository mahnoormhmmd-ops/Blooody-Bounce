extends CharacterBody2D

const DEBUG = false

const DEATH_SOUND_PATH = "res://dyingsound.wav"
const DEATH_SOUND_VOLUME_DB = 0.0

const BOUNCE_SOUND_PATH = "res://cartoon-boing.wav"
const BOUNCE_VOLUME_DB = 0.0
const BOUNCE_HEARING_DISTANCE = 400.0

const BLOCK = 16.0

const BODY_RADIUS = 9.0       # what the ball bumps into walls with
const HURT_RADIUS = 11.0      # what kills the player

const GRAVITY = 900.0
const BOUNCE_FORCE = 220.0
const PATROL_SPEED = 40.0
const CHASE_SPEED = 120.0

const SEE_X = 3 * BLOCK       # turns red when you are this close sideways
const LOSE_X = 4 * BLOCK      # turns back to normal when you are this far
const SEE_Y = 3 * BLOCK       # must be about on the same level to notice you
const LOSE_Y = 5 * BLOCK      # generous, so bouncing can't cancel the chase

const DEATH_TEXT = "Don’t worry, losing is part of the game…\napparently, it’s the only part you’re good at.\nNow bounce back AGAIN!"
const DEATH_FONT_PATH = "res://assets/fonts/PixelOperator8.ttf"
const DEATH_FONT_SIZE = 25
const DEATH_MESSAGE_TIME = 3.5
const RESTART_LEVEL = "res://game.tscn"    # the scene to load when you die (level 1)

var direction = 1
var chasing = false
var armed = false
var player
var body_node
var hurt_node
var bounce_player
var player_shape

func _ready():
	setup_bounce_sound()
	body_node = find_shape(self)
	hurt_node = find_shape($HurtBox)
	fix_shapes()

	player = get_tree().get_first_node_in_group("player")
	if player == null:
		print("ERROR: no node is in the group 'player'")
	else:
		add_collision_exception_with(player)
		player_shape = find_shape(player)

	if DEBUG:
		print("ball origin: ", global_position, "  ball center: ", ball_center())
		if player:
			print("player origin: ", player.global_position, "  player center: ", player_center())

	# safe period at the start so you don't die instantly
	await get_tree().create_timer(1.5).timeout
	armed = true

func find_shape(parent):
	for c in parent.get_children():
		if c is CollisionShape2D:
			return c
	return null

func fix_shapes():
	var s = max(scale.x, 0.01)
	if body_node:
		var shape = CircleShape2D.new()
		shape.radius = BODY_RADIUS / s
		body_node.shape = shape
		body_node.position = $Sprite2D.position
	if hurt_node:
		var shape2 = CircleShape2D.new()
		shape2.radius = HURT_RADIUS / s
		hurt_node.shape = shape2
		hurt_node.position = $Sprite2D.position

# the real middle of the ball and of the player (not the node origins)
func ball_center() -> Vector2:
	if body_node:
		return body_node.global_position
	return global_position

func player_center() -> Vector2:
	if player_shape:
		return player_shape.global_position
	return player.global_position

func _physics_process(delta):
	velocity.y += GRAVITY * delta

	update_state()

	if chasing and player:
		var dx = player_center().x - ball_center().x
		if abs(dx) > 2:
			velocity.x = sign(dx) * CHASE_SPEED
		else:
			velocity.x = 0
		$Sprite2D.modulate = Color(1, 0.4, 0.4)
	else:
		# turn around at walls and at the edge of the platform
		if is_on_wall() or not floor_ahead():
			direction *= -1
		velocity.x = direction * PATROL_SPEED
		$Sprite2D.modulate = Color(1, 1, 1)

	move_and_slide()

	# bounce every time it lands
	if is_on_floor():
		velocity.y = -BOUNCE_FORCE
		play_bounce_sound()

	check_kill()

func update_state():
	if player == null:
		return
	var dx = abs(player_center().x - ball_center().x)
	var dy = abs(player_center().y - ball_center().y)

	if chasing:
		if dx > LOSE_X or dy > LOSE_Y:
			chasing = false
			if velocity.x != 0:
				direction = sign(velocity.x)
	else:
		if dx < SEE_X and dy < SEE_Y and can_see_player():
			chasing = true

func floor_ahead():
	var space = get_world_2d().direct_space_state
	var from = ball_center() + Vector2(direction * 14, 0)
	var to = from + Vector2(0, 48)
	var query = PhysicsRayQueryParameters2D.create(from, to)
	query.exclude = [get_rid()]
	return not space.intersect_ray(query).is_empty()

func can_see_player():
	# a wall between the ball and you blocks its view
	var space = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(ball_center(), player_center())
	query.exclude = [get_rid(), player.get_rid()]
	return space.intersect_ray(query).is_empty()

func check_kill():
	if not armed:
		return
	# only a real overlap of the HurtBox and the player kills
	for body in $HurtBox.get_overlapping_bodies():
		if body.is_in_group("player"):
			armed = false
			kill_player()
			return

func kill_player():
	get_tree().paused = true    # freeze the game behind the message
	play_death_sound()

	var layer = CanvasLayer.new()
	layer.layer = 100
	add_child(layer)

	var center = CenterContainer.new()
	layer.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# the box: dark background, red border, rounded corners
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.9)
	style.set_border_width_all(4)
	style.border_color = Color(1, 0.2, 0.2)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(24)

	var panel = PanelContainer.new()
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)

	var label = Label.new()
	label.text = DEATH_TEXT
	label.add_theme_font_size_override("font_size", DEATH_FONT_SIZE)
	label.add_theme_color_override("font_color", Color(1, 1, 1))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if ResourceLoader.exists(DEATH_FONT_PATH):
		label.add_theme_font_override("font", load(DEATH_FONT_PATH))
	panel.add_child(label)

	await get_tree().create_timer(DEATH_MESSAGE_TIME).timeout
	get_tree().paused = false    # must unpause before restarting
	get_tree().change_scene_to_file(RESTART_LEVEL)

func play_death_sound():
	var stream = load(DEATH_SOUND_PATH)
	if stream == null:
		print("ERROR: could not load death sound at ", DEATH_SOUND_PATH)
		return
	var p = AudioStreamPlayer.new()
	p.stream = stream
	p.volume_db = DEATH_SOUND_VOLUME_DB
	p.process_mode = Node.PROCESS_MODE_ALWAYS    # keeps playing while the game is paused
	get_tree().root.add_child(p)                 # survives the switch back to level 1
	p.finished.connect(p.queue_free)
	p.play()

func setup_bounce_sound():
	var stream = load(BOUNCE_SOUND_PATH)
	if stream == null:
		print("ERROR: could not load bounce sound at ", BOUNCE_SOUND_PATH)
		return
	bounce_player = AudioStreamPlayer2D.new()
	bounce_player.stream = stream
	bounce_player.volume_db = BOUNCE_VOLUME_DB
	bounce_player.max_distance = BOUNCE_HEARING_DISTANCE
	add_child(bounce_player)

func play_bounce_sound():
	if bounce_player:
		bounce_player.pitch_scale = randf_range(0.9, 1.1)    # slight variation so it isn't repetitive
		bounce_player.play()
