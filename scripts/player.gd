extends CharacterBody2D

const SPEED = 180.0
const JUMP_VELOCITY = -300.0
const DASH_SPEED = 400.0
const DASH_TIME = 0.2

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

var dash_timer = 0.0
var is_dashing = false

func _physics_process(delta):
	if not is_on_floor():
		velocity.y += gravity * delta

	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	if Input.is_action_just_pressed("dash") and not is_dashing:
		is_dashing = true
		dash_timer = DASH_TIME

	if is_dashing:
		var direction = Input.get_axis("custom_left", "custom_right")
		if direction != 0:
			velocity.x = direction * DASH_SPEED
		else:
			velocity.x = DASH_SPEED * sign(velocity.x)
		dash_timer -= delta
		if dash_timer <= 0:
			is_dashing = false
	else:
		var direction = Input.get_axis("custom_left", "custom_right")
		if direction != 0:
			velocity.x = direction * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()
