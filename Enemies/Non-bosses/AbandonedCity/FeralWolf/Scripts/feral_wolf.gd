extends CharacterBody2D


enum State {PATROLLING, AGGRESSIVE, BACKING_UP, LEAP_ATTACK}
var current_state: State = State.PATROLLING


##### Node references #####
@onready var sprite: Sprite2D = $Sprite
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var detection_area: Area2D = $DetectionArea
@onready var hostile_hitbox: Area2D = $HostileHitbox
@onready var hostile_hurtbox: Area2D = $HostileHurtbox
@onready var first_detection_ray = $FirstDetectionRay
@export var patrol_polygon: CollisionPolygon2D
var player: Node2D

##### Movement variables #####
@export var max_speed: float = 700.0
@export var acceleration: float = 1200
@export var jump_speed: float = -500.0
@export var gravity: float = 1800.0
@export var leap_force_x: float = 1050.0
@export var leap_force_y: float = -450.0
var direction: float = 1.0
var can_leap: bool = true
var suspend_movement: bool = false
var suspend_movement_timer: float = 0.0

##### Patrol variables #####
@export var patrol_switch_interval: float = 3.0
var player_seen: bool = false

##### Time variables #####
@export var leap_cooldown: float = 2.0
@export var back_up_time: float = 1.0     # how long the wolf backs away
@export var windup_time: float = 0.4      # pause before leap
var patrol_timer: float = 0.0
var state_timer: float = 0.0

##### Attack-related variables #####
@export var health: int = 70
@export var bounce_speed: float = 300.0
var bouncing: bool = false
var parried_time: float
var hit_bounce_timer: float


##### High level functions #####
func _ready() -> void:
	detection_area.body_entered.connect(_on_detection_area_body_entered)
	detection_area.body_exited.connect(_on_detection_area_body_exited)
	
	hostile_hitbox.parried.connect(_on_parried)
	
	current_state = State.PATROLLING
	#animation_player.play("walk")  # or some default anim
	
	patrol_timer = patrol_switch_interval


func _physics_process(delta: float) -> void:
	if suspend_movement == false:
		velocity.y += gravity * delta
	
	match current_state:
		State.PATROLLING:
			_process_patrolling(delta)
		State.AGGRESSIVE:
			_process_aggressive(delta)
		State.BACKING_UP:
			_process_backing_up(delta)
		State.LEAP_ATTACK:
			_process_leap_attack(delta)
	
	handle_hit_bounce(delta)
	handle_damage_timers(delta)
	handle_parry_timers(delta)
	handle_hit_timer(delta)
	handle_death()
	handle_wall_vision()

	move_and_slide()
	
	if bouncing == false:
		if velocity.x < 0:
			sprite.flip_h = true
		elif velocity.x > 0:
			sprite.flip_h = false


func _process_patrolling(delta: float) -> void:
	patrol_timer -= delta
	if patrol_timer <= 0:
		patrol_timer = patrol_switch_interval
		direction *= -1.0
	
	if not _is_within_polygon(global_position, patrol_polygon.polygon, patrol_polygon):
		direction = Vector2((global_position.x - patrol_polygon.global_position.x), 0).normalized().x
	
	if suspend_movement == false and bouncing == false:
		var target_velocity = Vector2((direction * max_speed * 0.3), 0)
		velocity.x = velocity.move_toward(target_velocity, acceleration * delta).x
	
	#animation_player.play("walk")  # patrolling anim


func _process_aggressive(delta: float) -> void:
	if not is_instance_valid(player):
		current_state = State.PATROLLING
		return
	
	var dir_x = sign(player.global_position.x - global_position.x)
	if suspend_movement == false and bouncing == false:
		var target_velocity = Vector2((dir_x * max_speed), 0)
		velocity.x = velocity.move_toward(target_velocity, acceleration * delta).x
	
	if can_leap and randf() < 0.0035:
		if abs(player.global_position.x - global_position.x) < 300:
			_start_back_up()
		else:
			_start_leap_attack()


func _process_backing_up(delta: float) -> void:
	state_timer -= delta
	
	if not is_instance_valid(player):
		current_state = State.PATROLLING
		return
	
	var away_dir = sign(global_position.x - player.global_position.x)
	if suspend_movement == false and bouncing == false:
		var target_velocity = Vector2((away_dir * max_speed * 0.4), 0)
		velocity.x = velocity.move_toward(target_velocity, acceleration * delta).x
	
	if state_timer <= 0:
		_start_leap_attack()


func _process_leap_attack(delta: float) -> void:
	state_timer -= delta
	if state_timer > 0:
		# Still wind-up time
		velocity.x = 0
		return
	
	# If windup is done, we do the actual leap only once, then go back to aggressive
	if is_on_floor() and state_timer > -0.01:
		hostile_hitbox.can_be_parried = true
		if player:
			var dir_x = sign(player.global_position.x - global_position.x)
			velocity.x = dir_x * abs(player.global_position.x - global_position.x) * 2
			velocity.y = leap_force_y
		else:
			velocity.x = direction * leap_force_x
			velocity.y = leap_force_y
		#animation_player.play("leap_attack")
	
	can_leap = false
	
	# Timer for "leap cooldown"
	var cd_timer = get_tree().create_timer(leap_cooldown)
	cd_timer.timeout.connect(func() -> void:
		can_leap = true
	)
	
	if is_on_floor() and state_timer < -0.01:
		hostile_hitbox.can_be_parried = false
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


func _start_back_up() -> void:
	current_state = State.BACKING_UP
	state_timer = back_up_time
	#animation_player.play("run_back")


func _start_leap_attack() -> void:
	current_state = State.LEAP_ATTACK
	state_timer = windup_time
	velocity.x = 0
	# This is the "windup" portion
	#animation_player.play("leap_windup")


func handle_damage_timers(delta):
	suspend_movement_timer -= delta
	if suspend_movement_timer <= 0:
		suspend_movement = false


func take_damage(damage, hitbox_position, knockback_speed):
	health -= damage
	
	if current_state not in [State.LEAP_ATTACK] or parried_time > 0:
		suspend_movement_timer = 0.001
		suspend_movement = true
		
		var knockback_direction: Vector2 = global_position - hitbox_position
		velocity = Vector2(0, 0)
		velocity = knockback_direction.normalized() * knockback_speed * 0.6
	
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
	
	if bouncing == true and hit_bounce_timer <= 0:
		velocity.x = 0
		
		var bounce_direction = (global_position - (player.global_position + Vector2(0, -90))).normalized()
		
		var target_velocity = bounce_direction * max_speed * 1.5
		velocity.x = velocity.move_toward(target_velocity, acceleration * 20 * delta).x
		hit_bounce_timer = 0.25


func handle_hit_timer(delta):
	hit_bounce_timer -= delta
	
	if hit_bounce_timer <= 0:
		if bouncing == true:
			velocity.x = 0
		bouncing = false


func handle_death():
	if health <=0:
		queue_free()


func _on_parried():
	parried_time = 0.5
	
	hostile_hitbox.damage_dealt = 0
	modulate = Color(1,1,0)


func handle_parry_timers(delta):
	parried_time -= delta

	if parried_time <= 0:
		hostile_hitbox.damage_dealt = hostile_hitbox.original_damage_dealt
		modulate = Color(1,1,1)

##### Signal functions #####
func _on_detection_area_body_entered(body: Node) -> void:
	if body.name == "Player":  # or check group
		player = body as Node2D
		if player_seen == true:
			current_state = State.AGGRESSIVE
			#animation_player.play("run")


func _on_detection_area_body_exited(body: Node) -> void:
	if body == player and current_state not in [State.BACKING_UP, State.LEAP_ATTACK]:
		player = null
		current_state = State.PATROLLING
		#animation_player.play("walk")


func _is_within_polygon(point: Vector2, poly: PackedVector2Array, polygon_node: CollisionPolygon2D) -> bool:
	var inv = polygon_node.get_global_transform().inverse()
	var local_wolf_pos = inv * global_position
	return Geometry2D.is_point_in_polygon(local_wolf_pos, poly)
