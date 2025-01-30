extends CharacterBody2D


enum State {IDLE, PATROLLING, AGGRESSIVE, SWOOPING}
var current_state: State = State.IDLE


##### Node references #####
@onready var sprite: AnimatedSprite2D = $Sprite
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var nav_agent: NavigationAgent2D = $NavigationAgent
@onready var detection_area: Area2D = $DetectionArea
@onready var detection_collision = $DetectionArea/Collision
@onready var first_detection_ray = $FirstDetectionRay
var player: Node2D = null

##### Patrol variables #####
@export var patrol_radius: float = 550.0
@export var acceleration: float = 800
@export var max_speed: float = 270.0
@export var erratic_amplitude: float = 60.0
@export var erratic_frequency: float = 3.5
var player_seen: bool = false
var time_passed: float = 0.0
var patrol_center: Vector2
var patrol_timer : float = 0.0
var direction: Vector2 = Vector2.ZERO
var suspend_movement: bool = false
var suspend_movement_timer: float = 0.0

##### Swoop variables #####
@export var swoop_speed: float = 460.0
@export var windup_time: float = 0.42 # EyeGlow animation time --> 10/24
@export var swoop_time: float = 1.5
@export var swoop_height_offset: float = -260.0
@export var swoop_speed_factor: float = 0.5
@export var play_swoop_anim: bool = false
var wait_for_deprep_timer: float = 0.15
var swoop_start_pos: Vector2
var swoop_end_pos: Vector2
var swoop_control_pos: Vector2
var swoop_mid_pos: Vector2
var swoop_phase: int = 0 # 0 = wind-up, 1 = swoop
var swoop_timer: float
var swoop_cooldown_timer: float = 0
var can_swoop: bool = true
var is_swooping: bool = false
var swoop_curve_length: float
var distance_traveled: float = 0.0

##### Attack-related variables #####
@export var health: int = 50
@export var bounce_speed: float = 300.0
var bouncing: bool = false



##### High level functions #####
func _ready() -> void:
	player_seen = false
	
	patrol_center = global_position
	
	detection_area.body_entered.connect(_on_detection_area_body_entered)
	detection_area.body_exited.connect(_on_detection_area_body_exited)

	current_state = State.PATROLLING
	animation_player.play("Idle")


func _physics_process(delta: float) -> void:
	match current_state:
		State.IDLE:
			_process_idle(delta)
		State.PATROLLING:
			_process_patrolling(delta)
		State.AGGRESSIVE:
			_process_aggressive(delta)
		State.SWOOPING:
			_process_swooping(delta)
	
	handle_death()
	handle_damage_timers(delta)
	handle_facing_direction()
	handle_hit_bounce(delta)
	handle_swoop_cooldown(delta)
	handle_wall_vision()
	
	move_and_slide()


func _process_idle(delta: float) -> void:
	velocity = Vector2.ZERO


func _process_patrolling(delta: float) -> void:
	patrol_timer -= delta
	
	if patrol_timer <= 0:
		patrol_timer = randf_range(2.0, 4.0)
		var angle = randf() * 2 * PI
		var distance = randf() * patrol_radius
		var random_target = patrol_center + Vector2(distance, 0).rotated(angle)
		direction = (random_target - global_position).normalized()
	
	var target_velocity = direction * max_speed
	velocity = velocity.move_toward(target_velocity, acceleration * delta)
	
	if global_position.distance_to(patrol_center) > patrol_radius:
		direction = (patrol_center - global_position).normalized()
	
	if animation_player.current_animation == "DePrepare":
		pass
	else:
		animation_player.play("Idle")


func _process_aggressive(delta: float) -> void:
	if is_instance_valid(player) == false:
		current_state = State.PATROLLING
		return
	
	if bouncing == false and can_swoop == true and randf() < 0.0025: # Chance per frame, so x60 chance per second
		current_state = State.SWOOPING
		_start_swoop_attack()
	
	var path_direction = (player.global_position - global_position).normalized()
	nav_agent.target_position = player.global_position + Vector2(0, -190)
	nav_agent.target_desired_distance = 8.0  # How close to consider the next point "reached" 
	var next_point = nav_agent.get_next_path_position()
	if next_point != Vector2.ZERO:
		path_direction = (next_point - global_position).normalized()
	
	var move_direction = path_direction
	time_passed += delta
	var offset_y = sin(time_passed * erratic_frequency) * erratic_amplitude
	# Direction is shifted up or down by offset_y
	var y_mirror = Vector2(-path_direction.y, path_direction.x)
	move_direction += y_mirror * (offset_y / 100.0)

	if suspend_movement == false and bouncing == false:
		var target_velocity = move_direction.normalized() * max_speed
		velocity = velocity.move_toward(target_velocity, acceleration * delta)
	
	move_and_slide()
	
	if animation_player.current_animation == "DePrepare":
		pass
	else:
		animation_player.play("Idle")


func _process_swooping(delta: float) -> void:
	if player == null or is_instance_valid(player) == false:
		current_state = State.PATROLLING
		can_swoop = true
		return

	if swoop_phase == 0:
		wait_for_deprep_timer = 0.21
		
		animation_player.play("EyeGlow")
	
		var away_path_direction = (3 * Vector2((global_position.x - player.global_position.x), 0).normalized()) + Vector2(0, -1)
		var target_velocity = away_path_direction.normalized() * swoop_speed
		velocity = velocity.move_toward(target_velocity, acceleration * delta)
		
		move_and_slide()
		
		#if far away enough x wise: else: do above
		if global_position.distance_to(player.global_position + Vector2(0, -180)) > 180:
			swoop_timer -= delta

		if swoop_timer <= 0:
			swoop_phase = 1
			swoop_timer = 0.0
			swoop_start_pos = global_position
			swoop_mid_pos = player.global_position
			swoop_end_pos = Vector2(2.0 * swoop_mid_pos.x - swoop_start_pos.x, swoop_start_pos.y)
			# Compute the control point so that B(0.5) = p1 exactly:
			# B(0.5) = 0.25 * p0 + 0.5 * pc + 0.25 * p2 = p1  =>  pc = 2 * p1 - 0.5 * (p0 + p2)
			swoop_control_pos = 2.0 * swoop_mid_pos - 0.5 * (swoop_start_pos + swoop_end_pos)
			swoop_control_pos.y += swoop_height_offset
			distance_traveled = 0.0
			swoop_curve_length = approximate_bezier_length(swoop_start_pos, swoop_control_pos, swoop_end_pos, 20)

	elif swoop_phase == 1:
		velocity = Vector2.ZERO
		move_and_slide()
		
		# 1) Increase distance traveled
		distance_traveled += swoop_speed * 2.25 * delta
		
		# 2) Convert to param t
		var t = distance_traveled / swoop_curve_length
		if t > 1.0:
			t = 1.0
		
		if play_swoop_anim == true:
			animation_player.play("Swoop")
		elif play_swoop_anim == false and t < 0.5:
			animation_player.play("Prepare")
		
		# 3) Evaluate the Bezier at t
		var one_minus_t = 1.0 - t
		var p0 = swoop_start_pos
		var p1 = swoop_control_pos
		var p2 = swoop_end_pos
		
		var bezier_pos = (one_minus_t * one_minus_t * p0) + (2.0 * one_minus_t * t * p1) + (t * t * p2)
		
		if t < 0.9:
			global_position = bezier_pos
		
		if t > 0.9:
			var post_swoop_speed = swoop_speed * 0.9
			var post_swoop_direction = Vector2((swoop_mid_pos.x - swoop_start_pos.x), (swoop_start_pos.y - swoop_mid_pos.y)).normalized()
			velocity = post_swoop_direction * post_swoop_speed
		
		if t >= 1.0 or (t > 0.1 and (is_on_wall() == true or is_on_ceiling() == true or is_on_floor() == true)):
			play_swoop_anim = false
			animation_player.play("DePrepare")
			wait_for_deprep_timer -= delta
			if wait_for_deprep_timer <= 0:
				animation_player.play("Idle")
				is_swooping = false
				can_swoop = false
				swoop_cooldown_timer = 3
				current_state = State.AGGRESSIVE


##### Other functions #####
func handle_wall_vision():
	if is_instance_valid(player) == true:
		first_detection_ray.target_position = (player.global_position + Vector2(0, -90)) - first_detection_ray.global_position
		if player_seen == false:
			if first_detection_ray.is_colliding() == false:
				player_seen = true
				current_state = State.AGGRESSIVE
	else:
		first_detection_ray.target_position = Vector2(99999, 99999)


func handle_swoop_cooldown(delta):
	swoop_cooldown_timer -= delta
	if swoop_cooldown_timer <= 0:
		can_swoop = true


func _start_swoop_attack() -> void:
	can_swoop = false
	is_swooping = true
	current_state = State.SWOOPING

	swoop_phase = 0
	swoop_timer = windup_time


func approximate_bezier_length(p0: Vector2, p1: Vector2, p2: Vector2, steps: int = 20) -> float:
	var length = 0.0
	var prev_pos = p0
	
	for i in range(1, steps + 1):
		var t = float(i) / steps
		var one_minus_t = 1.0 - t
		var pos = (one_minus_t * one_minus_t * p0) + (2.0 * one_minus_t * t * p1) + (t * t * p2)
		length += prev_pos.distance_to(pos)
		prev_pos = pos
	
	return length


func handle_damage_timers(delta):
	suspend_movement_timer -= delta
	if suspend_movement_timer <= 0:
			suspend_movement = false


func take_damage(damage, hitbox_position, knockback_speed):
	health -= damage
	
	suspend_movement_timer = 0.001
	suspend_movement = true
	
	var knockback_direction: Vector2 = global_position - hitbox_position
	velocity = Vector2(0, 0)
	velocity = knockback_direction.normalized() * knockback_speed
	
	var popup_scene = preload("res://Enemies/damage_popup.tscn")
	var popup = popup_scene.instantiate() as RichTextLabel
	get_tree().get_current_scene().add_child(popup)
	
	var random_offset_x = randf_range(-15, 15)
	var spawn_pos = global_position + Vector2(random_offset_x, -50)
	popup.show_damage(damage, spawn_pos, false)
	
	sprite.modulate = Color(1, 0, 0)
	await get_tree().create_timer(0.1).timeout
	sprite.modulate = Color(1, 1, 1)


func handle_hit_bounce(delta):
	if player == null or is_instance_valid(player) == false:
		return
	
	if bouncing == true:
		var bounce_direction = (global_position - (player.global_position + Vector2(0, -90))).normalized()
		
		var move_direction = bounce_direction
		time_passed += delta
		var offset_y = sin(time_passed * erratic_frequency * 0.5) * erratic_amplitude
		# Direction is shifted up or down by offset_y
		var y_mirror = Vector2(-bounce_direction.y, bounce_direction.x)
		move_direction += y_mirror * (offset_y / 100.0)
		
		var target_velocity = move_direction.normalized() * max_speed * 1.5
		velocity = velocity.move_toward(target_velocity, acceleration * 1.5 * delta)
		await get_tree().create_timer(0.25).timeout
		bouncing = false


func handle_facing_direction():
	if bouncing == false:
		if velocity.x > 0 and current_state != State.SWOOPING:
			sprite.flip_h = true
		elif velocity.x < 0 and current_state != State.SWOOPING:
			sprite.flip_h = false
		elif velocity.x < 0 and current_state == State.SWOOPING and swoop_phase != 1:
			sprite.flip_h = true
		elif velocity.x > 0 and current_state == State.SWOOPING and swoop_phase != 1:
			sprite.flip_h = false


func handle_death():
	if health <=0:
		queue_free()


##### Signal functions #####
func _on_detection_area_body_entered(body: Node) -> void:
	if body.name == "Player":
		player = body
		if player_seen == true:
			current_state = State.AGGRESSIVE


func _on_detection_area_body_exited(body: Node) -> void:
	if body == player:
		player = null
		current_state = State.PATROLLING
