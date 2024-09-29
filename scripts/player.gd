extends CharacterBody2D

const SPEED = 180.0
const JUMP_VELOCITY = -300.0
const DASH_SPEED = 400.0
const DASH_TIME = 0.2
const MAX_JUMPS = 2

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

var dash_timer = 0.0
var is_dashing = false
var jump_counter = 0

func _physics_process(delta):
	handle_gravity(delta)
	handle_jump()
	handle_dash(delta)
	handle_movement(delta)
	move_and_slide()

func handle_gravity(delta):
	if not is_on_floor():
		velocity.y += gravity * delta

func handle_jump():
	if Input.is_action_just_pressed("ui_accept") and (is_on_floor() or jump_counter < MAX_JUMPS - 1):
		velocity.y = JUMP_VELOCITY
		
		if is_on_floor():
			jump_counter = 1
		else:
			jump_counter += 1
	
	if is_on_floor():
		jump_counter = 0

func handle_dash(delta):
	if Input.is_action_just_pressed("dash") and not is_dashing:
		start_dash()

	if is_dashing:
		perform_dash(delta)

func start_dash():
	is_dashing = true
	dash_timer = DASH_TIME

func perform_dash(delta):
	var direction = Input.get_axis("custom_left", "custom_right")
	velocity.x = direction * DASH_SPEED if direction != 0 else DASH_SPEED * sign(velocity.x)
	dash_timer -= delta
	if dash_timer <= 0:
		is_dashing = false

func handle_movement(delta):
	if not is_dashing:
		var direction = Input.get_axis("custom_left", "custom_right")
		velocity.x = direction * SPEED if direction != 0 else move_toward(velocity.x, 0, SPEED)
