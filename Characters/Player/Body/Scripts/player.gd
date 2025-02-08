extends CharacterBody2D


signal Attack1
signal Attack2
signal Attack3
signal Attack4
signal Attack1_released
signal Attack2_released
signal Attack3_released
signal Attack4_released


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
var current_weapon_instance: Node = null
var current_weapon_name: String = ""

##### Counter and parry variables #####
var can_counter: bool = true
var counter_cooldown_timer: float = 0.0
var is_countering: bool = false
var counter_active_timer: float = 0.0
@export var counter_cooldown: float = 1.0
@export var counter_duration: float = 0.05 # THIS MAY CHANGE DUE TO DIFFICULT BOSS ATTACK REACTION TIMES

##### Inventory variables #####
var held_item = Global.get_held_item()



func _ready():
	Global.player = self


func _physics_process(delta):
	Global.player = self
	held_item = Global.get_held_item()
	
	##### Normal functions #####
	handle_jump()
	handle_gravity(delta)
	handle_dash()
	handle_movement(delta)
	handle_facing_direction()
	handle_attacks()
	prepare_weapon()
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
func handle_animation(anim: String):
	if anim == "Run":
		if handle_facing_direction() > 0:
			#if animation_player.current_animation == "RunMirror":
				#var current_frame = animation_player.current
			animation_player.play("RunMirror")
			player_sprite.flip_h = true
		if handle_facing_direction() < 0:
			animation_player.play("Run")
			player_sprite.flip_h = false
	
	if anim == "Idle":
		if handle_facing_direction() > 0:
			animation_player.play("IdleMirror")
			player_sprite.flip_h = false
		if handle_facing_direction() < 0:
			animation_player.play("Idle")
			player_sprite.flip_h = false


func get_movement_direction() -> float: # Gets the movement direction (not the facing direction).
	var movement_direction = Input.get_axis("Move_Left", "Move_Right")
	Global.player_movement_direction = movement_direction
	if movement_direction != 0:
		Global.player_last_movement_direction = movement_direction
	
	return movement_direction


func handle_facing_direction() -> float:
	var facing_direction = get_movement_direction()
	var facing_direction_controller = 0.0
	
	if Input.get_connected_joypads().size() != 0:
		facing_direction_controller = Input.get_axis("Face_Left", "Face_Right")
		if facing_direction_controller == 0:
			facing_direction_controller = get_movement_direction()
	
	if Input.get_connected_joypads().size() == 0 and (Input.is_action_pressed("Attack_1") or Input.is_action_pressed("Attack_2") or Input.is_action_pressed("Attack_3") or Input.is_action_pressed("Attack_4")):
		facing_direction = get_local_mouse_position().x
	
	var final_direction: bool
	
	if facing_direction_controller > 0:
		final_direction = false
	elif facing_direction_controller < 0:
		final_direction = true
	elif facing_direction > 0:
		final_direction = false
	elif facing_direction < 0:
		final_direction = true
	else:
		if Global.player_facing_direction == -1:
			final_direction = false
		elif Global.player_facing_direction == 1:
			final_direction = true
		else:
			final_direction = false

	if final_direction == false:
		Global.player_facing_direction = -1
		return -1
	else:
		Global.player_facing_direction = 1
		return 1


func handle_movement(delta): # Responsible for movement left and right.
	if suspend_movement == false:
		if not is_dashing:
			if get_movement_direction() > 0:
				handle_animation("Run")
				if velocity.x < max_speed:
					velocity.x += acceleration * delta
					
			if get_movement_direction() < 0:
				handle_animation("Run")
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
					handle_animation("Idle")
					
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
			handle_animation("Run")
		elif is_dashing == true and get_movement_direction() == 0:
			velocity.x = dash_velocity * -sign(handle_facing_direction())
			handle_animation("Run")
		
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
			
			var popup_scene = preload("res://Enemies/damage_popup.tscn")
			var popup = popup_scene.instantiate() as RichTextLabel
			get_tree().get_current_scene().add_child(popup)
			
			var random_offset_x = randf_range(-15, 15)
			var spawn_pos = global_position + Vector2(random_offset_x, -170)
			popup.show_damage(damage, spawn_pos, true)
			
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
func prepare_weapon() -> void:
	if held_item and Global.item_data[held_item.item_name]["item_category"] == "Weapon":
		var new_weapon_name = held_item.item_name
		
		if new_weapon_name != current_weapon_name:
			if current_weapon_instance:
				current_weapon_instance.queue_free()
				current_weapon_instance = null
				
			if Global.item_data.has(new_weapon_name) and Global.item_data[new_weapon_name].has("weapon_scene_path"):
				var scene_path = Global.item_data[new_weapon_name]["weapon_scene_path"]
				var weapon_scene = ResourceLoader.load(scene_path)
				if weapon_scene:
					current_weapon_instance = weapon_scene.instantiate()
					add_child(current_weapon_instance)
					if current_weapon_instance.has_method("setup_weapon"):
						current_weapon_instance.setup_weapon(self)
					current_weapon_name = new_weapon_name
	else:
		if current_weapon_instance:
			current_weapon_instance.queue_free()
			current_weapon_instance = null
			current_weapon_name = ""


func handle_attacks() -> void:
	if can_attack and Input.is_action_just_pressed("Attack_1"):
		var click_pos = get_viewport().get_mouse_position() + Vector2(250, -65) # weird ass inventory/hotbar position problem, top left is (250, -65) away, so this corrects it
		var inv_rect = $UserInterface/Inventory.get_rect()
		var hotbar_rect = $UserInterface/Hotbar.get_rect()
		if not inv_rect.has_point(click_pos) and not hotbar_rect.has_point(click_pos):
			emit_signal("Attack1")
	if can_attack and Input.is_action_just_released("Attack_1"):
		var click_pos = get_viewport().get_mouse_position() + Vector2(250, -65)
		var inv_rect = $UserInterface/Inventory.get_rect()
		var hotbar_rect = $UserInterface/Hotbar.get_rect()
		if not inv_rect.has_point(click_pos) and not hotbar_rect.has_point(click_pos):
			emit_signal("Attack1_released")
			
	if can_attack and Input.is_action_just_pressed("Attack_2"):
		var click_pos = get_viewport().get_mouse_position() + Vector2(250, -65) # weird ass inventory/hotbar position problem, top left is (250, -65) away, so this corrects it
		var inv_rect = $UserInterface/Inventory.get_rect()
		var hotbar_rect = $UserInterface/Hotbar.get_rect()
		if not inv_rect.has_point(click_pos) and not hotbar_rect.has_point(click_pos):
			emit_signal("Attack2")
	if can_attack and Input.is_action_just_released("Attack_2"):
		var click_pos = get_viewport().get_mouse_position() + Vector2(250, -65)
		var inv_rect = $UserInterface/Inventory.get_rect()
		var hotbar_rect = $UserInterface/Hotbar.get_rect()
		if not inv_rect.has_point(click_pos) and not hotbar_rect.has_point(click_pos):
			emit_signal("Attack2_released")
			
	if can_attack and Input.is_action_just_pressed("Attack_3"):
		var click_pos = get_viewport().get_mouse_position() + Vector2(250, -65) # weird ass inventory/hotbar position problem, top left is (250, -65) away, so this corrects it
		var inv_rect = $UserInterface/Inventory.get_rect()
		var hotbar_rect = $UserInterface/Hotbar.get_rect()
		if not inv_rect.has_point(click_pos) and not hotbar_rect.has_point(click_pos):
			emit_signal("Attack3")
	if can_attack and Input.is_action_just_released("Attack_3"):
		var click_pos = get_viewport().get_mouse_position() + Vector2(250, -65)
		var inv_rect = $UserInterface/Inventory.get_rect()
		var hotbar_rect = $UserInterface/Hotbar.get_rect()
		if not inv_rect.has_point(click_pos) and not hotbar_rect.has_point(click_pos):
			emit_signal("Attack3_released")
			
	if can_attack and Input.is_action_just_pressed("Attack_4"):
		var click_pos = get_viewport().get_mouse_position() + Vector2(250, -65) # weird ass inventory/hotbar position problem, top left is (250, -65) away, so this corrects it
		var inv_rect = $UserInterface/Inventory.get_rect()
		var hotbar_rect = $UserInterface/Hotbar.get_rect()
		if not inv_rect.has_point(click_pos) and not hotbar_rect.has_point(click_pos):
			emit_signal("Attack4")
	if can_attack and Input.is_action_just_released("Attack_4"):
		var click_pos = get_viewport().get_mouse_position() + Vector2(250, -65)
		var inv_rect = $UserInterface/Inventory.get_rect()
		var hotbar_rect = $UserInterface/Hotbar.get_rect()
		if not inv_rect.has_point(click_pos) and not hotbar_rect.has_point(click_pos):
			emit_signal("Attack4_released")


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
func has_item(item_name: String) -> bool:
	var ui = $UserInterface
	
	if ui.holding_item:
		if ui.holding_item.item_name == item_name:
			return true
	
	if Global.hotbar.has(Global.active_item_slot):
		var slot_data = Global.hotbar[Global.active_item_slot]
		if slot_data[0] == item_name:
			return true
	
	return false


func pickup() -> void:
	if Input.is_action_pressed("Interact"):
		if $PickupZone.items_in_range.size() > 0:
			var pickup_item = $PickupZone.items_in_range.values()[0]
			pickup_item.pick_up_item(self)
			$PickupZone.items_in_range.erase(pickup_item)
