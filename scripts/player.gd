extends CharacterBody2D

const SPEED = 180.0
const JUMP_VELOCITY = -300.0
const DASH_SPEED = 400.0
const DASH_TIME = 0.2

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

var max_jumps = 2
var dash_timer = 0.0
var is_dashing = false
var jump_counter = 0

func _physics_process(delta): 
	handle_gravity(delta)
	handle_jump()
	handle_dash(delta)
	handle_movement(delta)
	handle_facing_direction()
	handle_counter()
	handle_crouch()
	move_and_slide()

func handle_gravity(delta):
	if not is_on_floor():
		velocity.y += gravity * delta

func handle_jump(): # Responsible for the jump mechanic (including double jumps).
	if Input.is_action_just_pressed("Jump") and (is_on_floor() or jump_counter < max_jumps - 1):
		velocity.y = JUMP_VELOCITY
		
		if is_on_floor():
			jump_counter = 1
		else:
			jump_counter += 1
	
	if is_on_floor():
		jump_counter = 0

func handle_dash(delta): # Responsible for the dash mechanic.
	if Input.is_action_just_pressed("Dash") and not is_dashing:
		start_dash()

	if is_dashing:
		perform_dash(delta)

func start_dash(): # Starts dashing when called.
	is_dashing = true
	dash_timer = DASH_TIME

func perform_dash(delta): # Performs the dash when called.
	var direction = Input.get_axis("Move_Left", "Move_Right")
	velocity.x = direction * DASH_SPEED if direction != 0 else DASH_SPEED * sign(velocity.x)
	dash_timer -= delta
	if dash_timer <= 0:
		is_dashing = false

func handle_movement(delta): # Responsible for movement left and right.
	if not is_dashing:
		var direction = Input.get_axis("Move_Left", "Move_Right")
		velocity.x = direction * SPEED if direction != 0 else move_toward(velocity.x, 0, SPEED)

func handle_facing_direction(): # Responsible for the direction the player faces.
	var facing_direction = Input.get_axis("Move_Left", "Move_Right")
	if Input.get_connected_joypads().size() == 0 and Input.is_action_pressed("Attack_1"): # This ensures that if a controller is not detected, the cursor dictates direction when attacking.
		facing_direction = get_local_mouse_position().x
	var facing_direction_controller = Input.get_axis("Face_Left", "Face_Right")
	if facing_direction_controller == 0 and Input.get_connected_joypads().size() != 0:
		facing_direction_controller = Input.get_axis("Move_Left", "Move_Right")
	
	if facing_direction_controller < 0:
		$Sprite.flip_h = false
	elif facing_direction_controller > 0:
		$Sprite.flip_h = true
	elif facing_direction < 0:
		$Sprite.flip_h = false
	elif facing_direction > 0:
		$Sprite.flip_h = true
	else:
		pass

func handle_counter(): # A very basic placeholder for the counter. A time between counters will later be added, dependent on whether it is succesful or not.
	if Input.is_action_just_pressed("Counter"):
		$Sprite.modulate = Color(1, 0, 0)
		await get_tree().create_timer(0.3).timeout
		$Sprite.modulate = Color(1, 1, 1)

func handle_crouch(): # A placeholder for the crouch feature, currently just scales the player down.
	if Input.is_action_just_pressed("Crouch"):
		scale.y = 0.5
		position.y += 8
	elif Input.is_action_just_released("Crouch"):
		scale.y = 1.0
		position.y -= 8
