extends CharacterBody2D


const DASH_SPEED = 1400.0
const DASH_TIME = 0.2

@export var speed = 650.0


##### Jump variables #####
var jump_counter: int = 0
var jump_buffer_countdown: float
var coyote_countdown: float
@export var coyote_time: float = 0.85
@export var jump_buffer: float = 0.05
@export var jump_height: float = 210
@export var jump_peak_time: float = 0.35
@export var jump_descend_time: float = 0.3
@export var max_fall_speed: float = 1500
@export var max_jumps: int = 2
@onready var jump_velocity: float = -2.0 * jump_height / jump_peak_time
@onready var jump_gravity: float = 2.0 * jump_height / (jump_peak_time * jump_peak_time)
@onready var descend_gravity: float = 2.0 * jump_height / (jump_descend_time * jump_descend_time)

##### Dash variables ##### (not yet final)
var dash_timer = 0.0
var is_dashing = false



func _process(delta):
	if Input.is_action_just_pressed("Jump"):
		jump_buffer_countdown = jump_buffer
	else:
		jump_buffer_countdown -= delta
	
	if is_on_floor():
		coyote_countdown = coyote_time
	else:
		coyote_countdown -= delta

func _physics_process(delta): 
	handle_gravity(delta)
	handle_jump()
	handle_dash(delta)
	handle_movement(delta)
	handle_facing_direction()
	handle_counter()
	handle_crouch()
	move_and_slide()



##### Jump processes #####
func handle_jump(): # Responsible for jump and double jump mechanics.
	if is_on_floor():
		jump_counter = 0
		
	if coyote_countdown > 0 and jump_buffer_countdown > 0:
		velocity.y = jump_velocity
		jump_buffer_countdown = 0
	elif not coyote_countdown > 0 and Input.is_action_just_pressed("Jump") and jump_counter < max_jumps - 1:
		velocity.y = jump_velocity
		jump_counter += 1
		jump_buffer_countdown = 0
		$Sprite.modulate = Color(0, 1, 0,) #Below 3 lines are to see when double jump occurs (as we dont have anim yet)
		await get_tree().create_timer(0.3).timeout
		$Sprite.modulate = Color(1, 1, 1)
		
	if not Input.is_action_pressed("Jump") and velocity.y < 0:
		velocity.y = lerp(velocity.y, 0.0, 0.3)
		
	if Input.is_action_just_released("Jump"):
		coyote_countdown = 0
func handle_gravity(delta): # Controls gravities.
	if velocity.y < 0:
		velocity.y += jump_gravity * delta
	elif velocity.y >= 0 and velocity.y < max_fall_speed:
		velocity.y += descend_gravity * delta

##### Dash processes #####  (not yet final)
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
		velocity.x = direction * speed if direction != 0 else move_toward(velocity.x, 0, speed)


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
		$Sprite.modulate = Color(1, 1, 1, 0.5)
		await get_tree().create_timer(0.3).timeout
		$Sprite.modulate = Color(1, 1, 1)


func handle_crouch(): # A placeholder for the crouch feature, currently just scales the player down.
	if Input.is_action_just_pressed("Crouch"):
		scale.y = 0.5
		position.y += 8
	elif Input.is_action_just_released("Crouch"):
		scale.y = 1.0
		position.y -= 8
