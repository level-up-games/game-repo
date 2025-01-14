extends CharacterBody2D


signal Attack1
signal Attack2
signal Attack3
signal Attack4


##### General variables #####
@onready var player_sprite = $Sprite
@onready var player_world_collision = $WorldCollision
@onready var player_hurtbox_collision = $Hurtbox/HurtboxCollision
@onready var animation_player = $AnimationPlayer

##### Movement variables #####
var suspend_movement: bool = false
var suspend_movement_timer: float = 0.0
@export var acceleration_time: float = 0.06
@export var decceleration_time: float = 0.05
@export var max_speed: float = 600.0
@onready var acceleration: float = max_speed / acceleration_time
@onready var decceleration: float = max_speed / decceleration_time

##### Dash variables #####
var dash_countdown: float
var dash_cooldown_countdown: float = 0
var is_dashing: bool = false
@export var dash_cooldown: float = 1.0
@export var dash_time: float = 0.2
@export var dash_distance: float = 280
@onready var dash_velocity: float = dash_distance / dash_time

##### Jump variables #####
var suspend_gravity: bool = false
var jump_counter: int = 0
var jump_buffer_countdown: float
var coyote_countdown: float
@export var coyote_time: float = 0.085
@export var jump_buffer: float = 0.05
@export var jump_height: float = 290
@export var jump_peak_time: float = 0.45
@export var jump_descend_time: float = 0.35
@export var max_fall_speed: float = 1500
@export var max_jumps: int = 1
@onready var jump_velocity: float = -2.0 * jump_height / jump_peak_time
@onready var jump_gravity: float = 2.0 * jump_height / (jump_peak_time * jump_peak_time)
@onready var descend_gravity: float = 2.0 * jump_height / (jump_descend_time * jump_descend_time)

##### Health variables #####
var invinc_timer: float = 1.0

##### Attack variables #####
var can_attack: bool = true

##### Counter and parry variables #####
var can_counter: bool = true
var counter_cooldown_timer: float = 0.0
var is_countering: bool = false
var counter_active_timer: float = 0.0
@export var counter_cooldown: float = 1.0
@export var counter_duration: float = 0.05 # THIS MAY CHANGE DUE TO DIFFICULT BOSS ATTACK REACTION TIMES


func _physics_process(delta):
	Global.player = self
	
	##### Normal functions #####
	handle_jump()
	handle_gravity(delta)
	handle_dash()
	handle_movement(delta)
	handle_facing_direction()
	handle_attacks()
	handle_counter()
	move_and_slide()

	##### Timer functions #####
	countdown_jump_buffer(delta)
	countdown_coyote(delta)
	countdown_dash(delta)
	handle_damage_timers(delta)
	handle_counter_cooldowns(delta)
	pickup()


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
	if suspend_movement == false:
		if not is_dashing:
			if get_movement_direction() > 0:
				animation_player.play("Run")
				if velocity.x < max_speed:
					velocity.x += acceleration * delta
					
			if get_movement_direction() < 0:
				animation_player.play("Run")
				if velocity.x > -max_speed:
					velocity.x -= acceleration * delta
					
			if get_movement_direction() == 0:
				if velocity.x > 0:
					velocity.x -= decceleration * delta
					if velocity.x < 0:
						velocity.x = 0
				elif velocity.x < 0:
					velocity.x += decceleration * delta
					if velocity.x > 0:
						velocity.x = 0
				else:
					velocity.x = 0
					animation_player.play("Idle")
					
			elif -max_speed > velocity.x:
				velocity.x = -max_speed
			elif velocity.x > max_speed:
				velocity.x = max_speed
	else:
		pass



##### Dash functions #####
func countdown_dash(delta): # Counts down the dash_countdown variable.
	if Input.is_action_just_pressed("Dash") and is_dashing == false and dash_cooldown_countdown < 0:
		dash_countdown = dash_time
		is_dashing = true
	else:
		dash_countdown -= delta
		dash_cooldown_countdown -= delta


func handle_dash(): # Responsible for the dash mechanic.
	if suspend_movement == false:
		if is_dashing == true and get_movement_direction() != 0:
			velocity.x = dash_velocity * sign(get_movement_direction())
			animation_player.play("Run")
		elif is_dashing == true and get_movement_direction() == 0:
			velocity.x = dash_velocity * -sign(handle_facing_direction())
			animation_player.play("Run")
		
		if is_dashing == true and dash_countdown < 0:
			is_dashing = false
			dash_cooldown_countdown = dash_cooldown
	else:
		pass


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
	if suspend_movement == false:
		if is_on_floor():
			jump_counter = 0
			
		if coyote_countdown > 0 and jump_buffer_countdown > 0:
			velocity.y = jump_velocity
			jump_buffer_countdown = 0
		elif coyote_countdown < 0 and Input.is_action_just_pressed("Jump") and jump_counter < max_jumps:
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
	if suspend_gravity == false:
		if velocity.y < 0:
			velocity.y += jump_gravity * delta
		elif velocity.y >= 0 and velocity.y < max_fall_speed:
			velocity.y += descend_gravity * delta



##### Health functions #####
func take_damage(damage, hitbox_position, knockback_speed):
	if invinc_timer <= 0:
		if is_countering == false and damage != 0:
			Global.player_take_damage(damage)
			invinc_timer = 0.5
			suspend_movement_timer = 0.1
			suspend_movement = true
			
			var knockback_direction: Vector2 = (global_position - Vector2(0, 90)) - hitbox_position
			velocity = Vector2(0, 0)
			velocity = knockback_direction.normalized() * knockback_speed
			
			for i in range(3):
				player_sprite.modulate = Color(0.8, 0.8, 0.8, 0.5)
				await get_tree().create_timer(0.083334).timeout
				player_sprite.modulate = Color(1, 1, 1, 1)
				await get_tree().create_timer(0.083334).timeout
			
		elif is_countering == true:
			can_counter = true
			$CPUParticles2D.emitting = true # placeholder for anim
			invinc_timer = 1.5
			
			for i in range(9):
				player_sprite.modulate = Color(0.8, 0.8, 0.8, 0.5)
				await get_tree().create_timer(0.083334).timeout
				player_sprite.modulate = Color(1, 1, 1, 1)
				await get_tree().create_timer(0.083334).timeout
	else:
		pass


func handle_damage_timers(delta):
	invinc_timer -= delta
	suspend_movement_timer -= delta
	if suspend_movement_timer <= 0:
			suspend_movement = false



##### Attack functions #####
func handle_attacks():
	if can_attack and Input.is_action_just_pressed("Attack_1"):
		emit_signal("Attack1")

	if can_attack and Input.is_action_just_pressed("Attack_2"):
		emit_signal("Attack2")
		
	if can_attack and Input.is_action_just_pressed("Attack_3"):
		emit_signal("Attack3")
		
	if can_attack and Input.is_action_just_pressed("Attack_4"):
		emit_signal("Attack4")



##### Counter and parry functions #####
func handle_counter_cooldowns(delta):
	if counter_active_timer > -5:
		counter_active_timer -= delta
	else:
		pass
	
	if counter_cooldown_timer > -5:
		counter_cooldown_timer -= delta
	else:
		pass
	
	if counter_cooldown_timer <= 0:
		can_counter = true
	else:
		can_counter = false


func handle_counter():
	if Input.is_action_just_pressed("Counter") and can_counter == true:
		player_sprite.modulate = Color(1, 0, 0) # placeholder for anim
		is_countering = true
		counter_active_timer = counter_duration
		counter_cooldown_timer = counter_cooldown
		can_counter = false
		await get_tree().create_timer(counter_duration).timeout # placeholder for anim
		player_sprite.modulate = Color(1, 1, 1) # placeholder for anim
	else:
		pass
	
	if counter_active_timer <= 0:
		is_countering = false


##### Items/Inventory functions #####
func pickup() -> void:
	if Input.is_action_pressed("Interact"):
		if $PickupZone.items_in_range.size() > 0:
			var pickup_item = $PickupZone.items_in_range.values()[0]
			pickup_item.pick_up_item(self)
			$PickupZone.items_in_range.erase(pickup_item)
