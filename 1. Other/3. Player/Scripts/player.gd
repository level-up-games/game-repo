extends CharacterBody2D


signal Attack1
signal Attack2
signal Attack3
signal Attack4


const DASH_SPEED = 1400.0
const DASH_TIME = 0.2

var invinc_timer = 1


@export var speed = 650.0

@onready var player_sprite = $Sprite
@onready var player_world_collision = $WorldCollision
@onready var player_hurtbox_collision = $Hurtbox/HurtboxCollision

##### Jump variables #####
var jump_counter: int = 0
var jump_buffer_countdown: float
var coyote_countdown: float
@export var coyote_time: float = 0.085
@export var jump_buffer: float = 0.05
@export var jump_height: float = 210
@export var jump_peak_time: float = 0.35
@export var jump_descend_time: float = 0.3
@export var max_fall_speed: float = 1500
@export var max_jumps: int = 2
@onready var jump_velocity: float = -2.0 * jump_height / jump_peak_time
@onready var jump_gravity: float = 2.0 * jump_height / (jump_peak_time * jump_peak_time)
@onready var descend_gravity: float = 2.0 * jump_height / (jump_descend_time * jump_descend_time)

##### Dash variables #####
var dash_countdown: float
var dash_cooldown_countdown: float = 0
var is_dashing: bool = false
@export var dash_cooldown: float = 1.0
@export var dash_time: float = 0.2
@export var dash_distance: float = 280
@onready var dash_velocity: float = dash_distance / dash_time

##### Attack variables #####
@export var attack_damage: int = 10
@export var punch_speed: float = 0.2  # Time for punch to complete
var can_attack: bool = true
var attack_active: bool = false
var attack_timer: float = 0

##### Parry/Counter variables #####
@export var parry_window: float = 0.2  # Time window for successful parry
@export var counter_window: float = 0.2  # Time window for successful counter
var parry_active: bool = false
var counter_active: bool = false



func _physics_process(delta): 
	##### Normal functions #####
	handle_jump()
	handle_gravity(delta)
	handle_dash()
	handle_movement(delta)
	handle_facing_direction()
	handle_counter()
	move_and_slide()

	##### Timer functions #####
	countdown_jump_buffer(delta)
	countdown_coyote(delta)
	countdown_dash(delta)

	handle_attack(delta)
	handle_parry_counter(delta)

	invinc_timer -= delta

##### Jump functions #####
func countdown_jump_buffer(delta): # Counts down the jump_buffer_countdown variable.
	if Input.is_action_just_pressed("Jump"):
		jump_buffer_countdown = jump_buffer
	else:
		jump_buffer_countdown -= delta


func countdown_coyote(delta): # Counts down the coyote_countdown variable.
	if is_on_floor():
		coyote_countdown = coyote_time
	else:
		coyote_countdown -= delta


func handle_jump(): # Responsible for jump and double jump mechanics.
	if is_on_floor():
		jump_counter = 0
		
	if coyote_countdown > 0 and jump_buffer_countdown > 0:
		velocity.y = jump_velocity
		jump_buffer_countdown = 0
	elif coyote_countdown < 0 and Input.is_action_just_pressed("Jump") and jump_counter < max_jumps - 1:
		velocity.y = jump_velocity
		jump_counter += 1
		jump_buffer_countdown = 0
		player_sprite.modulate = Color(0, 1, 0,) #Below 3 lines are to see when double jump occurs (as we dont have anim yet)
		await get_tree().create_timer(0.3).timeout
		player_sprite.modulate = Color(1, 1, 1)
		
	if not Input.is_action_pressed("Jump") and velocity.y < 0:
		velocity.y = lerp(velocity.y, 0.0, 0.3)
		
	if Input.is_action_just_released("Jump"):
		coyote_countdown = 0


func handle_gravity(delta): # Controls gravities.
	if velocity.y < 0:
		velocity.y += jump_gravity * delta
	elif velocity.y >= 0 and velocity.y < max_fall_speed:
		velocity.y += descend_gravity * delta


##### Dash functions #####
func countdown_dash(delta): # Counts down the dash_countdown variable.
	if Input.is_action_just_pressed("Dash") and is_dashing == false and dash_cooldown_countdown < 0:
		dash_countdown = dash_time
		is_dashing = true
	else:
		dash_countdown -= delta
		dash_cooldown_countdown -= delta


func handle_dash(): # Responsible for the dash mechanic.
	if is_dashing == true and get_movement_direction() != 0:
		velocity.x = dash_velocity * sign(get_movement_direction())
	elif is_dashing == true and get_movement_direction() == 0:
		velocity.x = dash_velocity * sign(handle_facing_direction())
	
	if is_dashing == true and dash_countdown < 0:
		is_dashing = false
		dash_cooldown_countdown = dash_cooldown


##### Movement functions #####
func get_movement_direction() -> float: # Gets the movement direction (not the facing direction).
	var movement_direction = Input.get_axis("Move_Left", "Move_Right")
	Global.player_movement_direction = movement_direction
	
	return movement_direction


func handle_facing_direction() -> float: # Responsible for the direction the player faces, and also returns this direction when called.
	var facing_direction = Input.get_axis("Move_Left", "Move_Right")
	var facing_direction_controller = Input.get_axis("Face_Left", "Face_Right")
	
	if Input.get_connected_joypads().size() == 0 and (Input.is_action_pressed("Attack_1") or Input.is_action_pressed("Attack_2") or Input.is_action_pressed("Attack_3") or Input.is_action_pressed("Attack_4")): # This ensures that if a controller is not detected, the cursor dictates direction when attacking.
		facing_direction = get_local_mouse_position().x
	
	if facing_direction_controller == 0 and Input.get_connected_joypads().size() != 0:
		facing_direction_controller = Input.get_axis("Move_Left", "Move_Right")
	
	if facing_direction_controller > 0:
		player_sprite.flip_h = false
		player_world_collision.scale.x = 1
		player_hurtbox_collision.scale.x = 1
	elif facing_direction_controller < 0:
		player_sprite.flip_h = true
		player_world_collision.scale.x = -1
		player_hurtbox_collision.scale.x = -1
	elif facing_direction > 0:
		player_sprite.flip_h = false
		player_world_collision.scale.x = 1
		player_hurtbox_collision.scale.x = 1
	elif facing_direction < 0:
		player_sprite.flip_h = true
		player_world_collision.scale.x = -1
		player_hurtbox_collision.scale.x = -1

	if player_sprite.flip_h == false:
		Global.player_facing_direction = -1
		return -1
	if player_sprite.flip_h == true:
		Global.player_facing_direction = 1
		return 1
	else:
		return 0


func handle_movement(delta): # Responsible for movement left and right.
	if not is_dashing:
		if get_movement_direction() != 0:
			velocity.x = sign(get_movement_direction()) * speed
			$AnimationPlayer.play("Run")
		else: 
			velocity.x = 0
			$AnimationPlayer.play("Idle")



func handle_counter(): # A very basic placeholder for the counter. A time between counters will later be added, dependent on whether it is succesful or not.
	if Input.is_action_just_pressed("Counter"):
		player_sprite.modulate = Color(1, 1, 1, 0.5)
		await get_tree().create_timer(0.3).timeout
		player_sprite.modulate = Color(1, 1, 1)




##### Attack Function #####
func handle_attack(delta):
	if can_attack and Input.is_action_just_pressed("Attack_1"):
		emit_signal("Attack1")
		# Start punch
		attack_active = true
		can_attack = false
		attack_timer = punch_speed

	if can_attack and Input.is_action_just_pressed("Attack_2"):
		emit_signal("Attack2")
		
	if can_attack and Input.is_action_just_pressed("Attack_3"):
		emit_signal("Attack3")
		
	if can_attack and Input.is_action_just_pressed("Attack_4"):
		emit_signal("Attack4")

	if attack_active:
		attack_timer -= delta
		if attack_timer <= 0:
			# End punch
			attack_active = false
			player_sprite.modulate = Color(1, 1, 1)  # Reset color
			can_attack = true


##### Parry and Counter Functions #####
func handle_parry_counter(delta):
	if Input.is_action_just_pressed("Attack_1") and not parry_active:
		parry_active = true
		player_sprite.modulate = Color(0, 1, 1)  # Visual indicator of parry
		await get_tree().create_timer(parry_window).timeout
		parry_active = false
		player_sprite.modulate = Color(1, 1, 1)  # Reset color after parry window ends

	if Input.is_action_just_pressed("Counter") and not counter_active:
		counter_active = true
		player_sprite.modulate = Color(1, 1, 0)  # Visual indicator of counter
		await get_tree().create_timer(counter_window).timeout
		counter_active = false
		player_sprite.modulate = Color(1, 1, 1)  # Reset color after counter window ends


##### Attack-Detection Function #####
func detect_attack():
	# Check if player successfully parried
	if parry_active:
		# Add logic to prevent attack damage and refresh attacks
		print("Parry successful!")
		can_attack = true

	elif counter_active:
		# Add logic to prevent damage, refresh dashes, and unlock powerful moves
		print("Counter successful!")
		can_attack = true


##### Health/combat functions #####
func take_damage(damage):
	if invinc_timer <= 0:
		Global.player_take_damage(damage)
		invinc_timer = 1
	else:
		pass
