extends CharacterBody2D


enum State {PATROLLING, AGGRESSIVE, RUNNING_AWAY, BURROWING, UNDERGROUND, BURST_ATTACK}
var current_state: State = State.PATROLLING


##### Node references #####
@onready var sprite: Sprite2D = $Sprite
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var detection_area: Area2D = $DetectionArea
@onready var hostile_hitbox: Area2D = $HostileHitbox
@onready var hostile_hurtbox: Area2D = $HostileHurtbox
@onready var dust_particles: CPUParticles2D = $CPUParticles2D
@onready var rat_projectile_spawner: Node2D = $RatProjectileSpawner
@onready var first_detection_ray = $FirstDetectionRay
@export var patrol_polygon: CollisionPolygon2D
@export var projectile_scene: PackedScene
var player: CharacterBody2D

##### Movement variables #####
@export var max_speed: float = 350.0
@export var acceleration: float = 1200
@export var jump_speed: float = -500.0
@export var gravity: float = 1800.0
var run_away_dir: Vector2
var under_dir: float
var pause: float = 0.75
var suspend_movement: bool = false
var suspend_movement_timer: float = 0.0

##### Patrol variables #####
var player_seen: bool = false
var patrol_direction: float = 1.0  # 1 = right, -1 = left

##### Time variables #####
@export var run_away_time: float = 2.0
@export var burrow_time: float = 0.4
@export var underground_time: float = 4.0
@export var burst_attack_time: float = 0.6
@export var burrow_cooldown_time: float = 3.0
var burrow_cooldown: float
var patrol_timer: float = 0.0
var state_timer: float = 0.0

##### Attack-related variables #####
@export var health: int = 50
@export var bounce_speed: float = 300.0
var bouncing: bool = false
var hit_bounce_timer: float

##### Item variables #####
@export var item_drop_scene: PackedScene = preload("res://Items/Scenes/ItemDrop.tscn")

# Drop table: an Array of Dictionaries. For each drop, specify:
# - "item_name": the name of the item to drop.
# - "chance": a value between 0 and 1 representing the drop chance.
# - "min_quantity" and "max_quantity": the range of quantities to drop.
@export var drop_table: Array = [
	{"item_name": "Coin", "chance": 0.8, "min_quantity": 0, "max_quantity": 3},
]



##### High level functions #####
func _ready() -> void:
	burrow_cooldown = burrow_cooldown_time
	player_seen = false
	
	sprite.visible = true
	dust_particles.emitting = false
	hostile_hitbox.collision_layer = 2
	hostile_hitbox.collision_mask = 64
	hostile_hurtbox.collision_layer = 0
	hostile_hurtbox.collision_mask = 64
	
	detection_area.body_entered.connect(_on_detection_body_entered)
	detection_area.body_exited.connect(_on_detection_body_exited)
	
	current_state = State.PATROLLING
	#animation_player.play("walk")


func _physics_process(delta: float) -> void:
	if suspend_movement == false:
		velocity.y += gravity * delta
	
	match current_state:
		State.PATROLLING:
			_process_patrolling(delta)
		State.AGGRESSIVE:
			_process_aggressive(delta)
		State.RUNNING_AWAY:
			_process_run_away(delta)
		State.BURROWING:
			_process_burrowing(delta)
		State.UNDERGROUND:
			_process_underground(delta)
		State.BURST_ATTACK:
			_process_burst_attack(delta)
	
	
	handle_hit_bounce(delta)
	handle_damage_timers(delta)
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
	sprite.visible = true
	dust_particles.emitting = false
	hostile_hitbox.collision_layer = 2
	hostile_hitbox.collision_mask = 64
	hostile_hurtbox.collision_layer = 0
	hostile_hurtbox.collision_mask = 64

	patrol_timer -= delta
	if patrol_timer <= 0:
		if patrol_direction == 1.0:
			patrol_direction = -1.0
		else:
			patrol_direction = 1.0
		patrol_timer = randf_range(3.0, 6.0)

	if suspend_movement == false and bouncing == false:
		var target_velocity = Vector2((patrol_direction * max_speed * 0.5), 0)
		velocity.x = velocity.move_toward(target_velocity, acceleration * delta).x

	if not _is_within_polygon(global_position, patrol_polygon.polygon, patrol_polygon):
		patrol_direction = Vector2((global_position.x - patrol_polygon.global_position.x), 0).normalized().x

	#animation_player.play("walk")


func _process_aggressive(delta: float) -> void:
	if burrow_cooldown > 0:
		burrow_cooldown -= delta
	
	sprite.visible = true
	dust_particles.emitting = false
	hostile_hitbox.collision_layer = 2
	hostile_hitbox.collision_mask = 64
	hostile_hurtbox.collision_layer = 0
	hostile_hurtbox.collision_mask = 64
	
	if not is_instance_valid(player):
		current_state = State.PATROLLING
		return

	var dir_x = sign(player.global_position.x - global_position.x)
	if suspend_movement == false and bouncing == false:
		var target_velocity = Vector2((dir_x * max_speed), 0)
		velocity.x = velocity.move_toward(target_velocity, acceleration * delta).x

	if is_on_floor():
		if randf() < 0.01:
			if suspend_movement == false and bouncing == false:
				velocity.y = jump_speed
				#animation_player.play("jump")

	if randf() < 0.002 and burrow_cooldown <= 0:
		_start_run_away()


func _process_run_away(delta: float) -> void:
	state_timer -= delta

	if suspend_movement == false and bouncing == false:
		var target_velocity = Vector2((run_away_dir.x * max_speed), 0)
		velocity.x = velocity.move_toward(target_velocity, acceleration * delta).x

	if state_timer <= 0:
		_start_burrowing()


func _process_burrowing(delta: float) -> void:
	state_timer -= delta
	
	velocity.x = 0

	if state_timer <= 0:
		sprite.visible = false
		dust_particles.emitting = true

		current_state = State.UNDERGROUND
		pause = 0.75
		under_dir = 1
		state_timer = underground_time


func _process_underground(delta: float) -> void:
	state_timer -= delta
	
	hostile_hitbox.collision_layer = 0
	hostile_hitbox.collision_mask = 0
	hostile_hurtbox.collision_layer = 0
	hostile_hurtbox.collision_mask = 0

	var target_velocity = Vector2((under_dir * max_speed), 0)
	velocity.x = velocity.move_toward(target_velocity, acceleration * delta).x

	if randf() < 0.007: # Chance per frame, so x60
		under_dir = Vector2((player.global_position.x - global_position.x), 0).normalized().x
	
	if state_timer <= 0:
		under_dir = 0
		pause -= delta
		if pause <= 0:
			_start_burst_attack()


func _process_burst_attack(delta: float) -> void:
	state_timer -= delta

	if state_timer <= 0:
		burrow_cooldown = burrow_cooldown_time
		current_state = State.AGGRESSIVE
		#animation_player.play("walk")


##### Other functions #####
func _drop_items() -> void:
	for drop in drop_table:
		var quantity = 0
		
		for i in range(drop["max_quantity"]):
			if randf() <= drop["chance"]:
				quantity += 1
		
		if drop.has("min_quantity") and quantity < drop["min_quantity"]:
			quantity = drop["min_quantity"]
		
		if quantity > 0:
			var drop_instance = item_drop_scene.instantiate()
			drop_instance.item_name = drop["item_name"]
			drop_instance.item_quantity = quantity
			
			drop_instance.global_position = global_position + Vector2(randf_range(-30, 30), randf_range(-30, 30))
			
			get_tree().get_current_scene().add_child(drop_instance)


func handle_wall_vision():
	if is_instance_valid(player) == true:
		first_detection_ray.target_position = (player.global_position + Vector2(0, -90)) - first_detection_ray.global_position
		if player_seen == false:
			if first_detection_ray.is_colliding() == false:
				player_seen = true
				current_state = State.AGGRESSIVE
	else:
		first_detection_ray.target_position = Vector2(99999, 99999)


func _start_run_away() -> void:
	current_state = State.RUNNING_AWAY
	state_timer = run_away_time
	run_away_dir = Vector2((global_position.x - player.global_position.x), 0).normalized()
	#animation_player.play("run_away")


func _start_burrowing() -> void:
	current_state = State.BURROWING
	state_timer = burrow_time
	#animation_player.play("burrow")


func _start_burst_attack() -> void:
	current_state = State.BURST_ATTACK
	state_timer = burst_attack_time
	#animation_player.play("burst")

	sprite.visible = true
	dust_particles.emitting = false
	hostile_hitbox.collision_layer = 2
	hostile_hitbox.collision_mask = 64
	hostile_hurtbox.collision_layer = 0
	hostile_hurtbox.collision_mask = 64

	if suspend_movement == false and bouncing == false:
		velocity.y = jump_speed * 2

	if projectile_scene:
		var proj = projectile_scene.instantiate()
		proj.global_position = rat_projectile_spawner.global_position
		var dir = ((player.global_position + Vector2(0, -90) )- rat_projectile_spawner.global_position).normalized()
		if proj.has_method("set_direction"):
			proj.set_direction(dir)
		get_tree().current_scene.add_child(proj)


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
	velocity = knockback_direction.normalized() * knockback_speed * 0.1
	
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
		_drop_items()
		queue_free()


##### Signal functions #####
func _on_detection_body_entered(body: Node) -> void:
	if body.name == "Player":
		player = body as CharacterBody2D
		if player_seen == true:
			current_state = State.AGGRESSIVE
			#animation_player.play("walk")


func _on_detection_body_exited(body: Node) -> void:
	if body == player and current_state not in [State.BURROWING, State.UNDERGROUND, State.BURST_ATTACK, State.RUNNING_AWAY]:
		player = null
		current_state = State.PATROLLING
		#animation_player.play("walk")


func _is_within_polygon(point: Vector2, poly: PackedVector2Array, polygon_node: CollisionPolygon2D) -> bool:
	var inv = polygon_node.get_global_transform().inverse()
	var local_rat_pos = inv * global_position
	return Geometry2D.is_point_in_polygon(local_rat_pos, poly)
