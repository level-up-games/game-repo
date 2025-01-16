extends CharacterBody2D

#
# ------------------------------
# ENUMS & EXPORTED VARIABLES
# ------------------------------
#
enum State {
	IDLE,
	PATROLLING,
	AGGRESSIVE,
	SWOOPING
}

@export var patrol_radius: float = 1500.0
@export var detection_radius: float = 200.0
@export var speed: float = 280.0
@export var bounce_force: float = 250.0

# Parabolic swoop parameters
@export var swoop_duration: float = 1.0
@export var swoop_cooldown: float = 3.0

# Aggressive “erratic” movement
@export var erratic_amplitude: float = 80.0
@export var erratic_frequency: float = 5.0

# Raycast / line-of-sight mask for walls (TileMap on layer 1, for example)
@export var environment_layer_mask: int = 1

#
# ------------------------------
# NODE REFERENCES (ONREADY)
# ------------------------------
#
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var detection_area: Area2D = $DetectionArea
@onready var damage_area: Area2D = $Hitbox
# If you have a Hurtbox:
# @onready var hurtbox: Area2D = $Hurtbox


#
# ------------------------------
# INTERNAL VARIABLES
# ------------------------------
#
var current_state: State = State.IDLE

# Player
var player: Node2D = null
var has_detected_player: bool = false

# Patrolling
var patrol_center: Vector2
var patrol_timer: float = 0.0
var direction: Vector2 = Vector2.ZERO

# Time counter for erratic motion
var time_passed: float = 0.0

# Swoop
var is_swooping: bool = false
var can_swoop: bool = true
var swoop_timer: float = 0.0

# Bezier control points for the parabola
var swoop_start_pos: Vector2
var swoop_middle_pos: Vector2
var swoop_end_pos: Vector2
var swoop_control_pos: Vector2


#
# ------------------------------
# _READY
# ------------------------------
#
func _ready() -> void:
	# Store the initial position as the patrol center
	patrol_center = global_position

	# Connect signals
	detection_area.body_entered.connect(_on_detection_area_body_entered)
	detection_area.body_exited.connect(_on_detection_area_body_exited)
	damage_area.body_entered.connect(_on_damage_area_body_entered)
	# If you want to watch for the bat taking damage, connect the Hurtbox signals, etc.

	# Start in PATROLLING
	current_state = State.PATROLLING
	animation_player.play("fly")


#
# ------------------------------
# MAIN LOOP
# ------------------------------
#
func _physics_process(delta: float) -> void:
	
	if health <=0:
		queue_free()
	
	match current_state:
		State.IDLE:
			_process_idle(delta)
			print("idle")
		State.PATROLLING:
			_process_patrolling(delta)
			print("pat")
		State.AGGRESSIVE:
			_process_aggressive(delta)
			print("agro")
		State.SWOOPING:
			_process_swooping(delta)
			print("swoop")

	move_and_slide()

	# Flip the sprite based on horizontal velocity
	if velocity.x > 0:
		animated_sprite.flip_h = true
	elif velocity.x < 0:
		animated_sprite.flip_h = false


#
# ------------------------------
# STATE: IDLE
# ------------------------------
#
func _process_idle(delta: float) -> void:
	velocity = Vector2.ZERO
	# Typically do nothing or transition after a timer


#
# ------------------------------
# STATE: PATROLLING
# ------------------------------
#
func _process_patrolling(delta: float) -> void:
	time_passed += delta
	patrol_timer -= delta

	# Occasionally pick a new random direction in the patrol_radius
	if patrol_timer <= 0.0:
		patrol_timer = randf_range(2.0, 4.0)
		var angle = randf() * TAU
		var dist = randf() * patrol_radius
		var random_target = patrol_center + Vector2(dist, 0).rotated(angle)
		direction = (random_target - global_position).normalized()

	# Move in that direction
	velocity = direction * speed

	# If we're too far from the center, steer back
	if global_position.distance_to(patrol_center) > patrol_radius:
		direction = (patrol_center - global_position).normalized()


#
# ------------------------------
# STATE: AGGRESSIVE
# ------------------------------
#
func _process_aggressive(delta: float) -> void:
	time_passed += delta
	#if not is_instance_valid(player):
		# Player might've left or been destroyed
		#current_state = State.PATROLLING
		#return

	# Use NavigationAgent2D pathfinding
	nav_agent.target_position = player.global_position
	var next_point = nav_agent.get_next_path_position()

	var dir = Vector2.ZERO
	if next_point != Vector2.ZERO:
		dir = (next_point - global_position).normalized()
	else:
		# Fallback: move directly
		dir = (player.global_position - global_position).normalized()

	# Make it erratic: add a small sine wave offset 
	var offset_value = sin(time_passed * erratic_frequency) * erratic_amplitude
	# For sideways offset, use a perpendicular vector
	var perpendicular = Vector2(-dir.y, dir.x).normalized()
	dir += perpendicular * (offset_value / 100.0)

	velocity = dir.normalized() * speed

	# Random chance to swoop OR use some condition
	# e.g. "if distance < 150 and can_swoop, then swoop"
	if can_swoop and randf() < 0.01:
		_start_swoop_attack()


#
# ------------------------------
# START SWOOP ATTACK
# ------------------------------
#
func _start_swoop_attack() -> void:
	# Only begin if allowed
	if not can_swoop:
		return

	can_swoop = false
	is_swooping = true
	current_state = State.SWOOPING
	animation_player.play("swoop")

	# We'll define the parabola so it crosses the player at t = 0.5
	swoop_start_pos = global_position
	swoop_middle_pos = player.global_position
	# End pos: symmetrical on the other side of the player
	swoop_end_pos = 2.0 * swoop_middle_pos - swoop_start_pos

	# Control point ensuring the curve passes exactly at swoop_middle_pos for t=0.5:
	# B(0.5) = (p0 + 2*pc + p2)/4 = p1  =>  pc = 2*p1 - 0.5*(p0 + p2)
	swoop_control_pos = 2.0 * swoop_middle_pos - 0.5 * (swoop_start_pos + swoop_end_pos)

	# If you want a deeper trough (further down), you can shift control point's y:
	# swoop_control_pos.y += 50.0  # But then it won't exactly cross the player at t=0.5

	swoop_timer = 0.0


#
# ------------------------------
# STATE: SWOOPING (PARABOLA)
# ------------------------------
#
func _process_swooping(delta: float) -> void:
	swoop_timer += delta
	var t = swoop_timer / swoop_duration
	if t > 1.0:
		t = 1.0

	var one_minus_t = 1.0 - t
	# Quadratic Bezier
	var pos = one_minus_t * one_minus_t * swoop_start_pos + 2.0 * one_minus_t * t * swoop_control_pos + t * t * swoop_end_pos

	global_position = pos
	# Overriding the position directly = ignoring collisions 
	# but that might be desired for a “phase-through” effect.

	if t >= 1.0:
		# Swoop finished
		is_swooping = false
		current_state = State.AGGRESSIVE
		animation_player.play("fly")

		# Reset swoop after a cooldown
		var timer = get_tree().create_timer(swoop_cooldown)
		timer.timeout.connect(_on_swoop_cooldown_timeout)


func _on_swoop_cooldown_timeout() -> void:
	can_swoop = true


#
# ------------------------------
# DETECTION AREA SIGNALS
# ------------------------------
#
func _on_detection_area_body_entered(body: Node) -> void:
	if body.name == "Player":
		# If we haven't seen the player yet, check line-of-sight
		if not has_detected_player:
			if _has_line_of_sight_to(body.global_position):
				has_detected_player = true
				player = body as Node2D
				current_state = State.AGGRESSIVE
				animation_player.play("fly")
			else:
				has_detected_player = true
				player = body as Node2D
				# We see the player in radius, but there's a wall in between -> ignore
				current_state = State.AGGRESSIVE
				pass
		else:
			# We already know the player, so no line-of-sight check needed
			player = body as Node2D
			current_state = State.AGGRESSIVE
			animation_player.play("fly")


func _on_detection_area_body_exited(body: Node) -> void:
	if body == player:
		# If the player leaves detection area, revert to patrolling 
		# (or do nothing, depends on your design)
		player = null
		current_state = State.PATROLLING
		animation_player.play("fly")


#
# ------------------------------
# DAMAGE AREA SIGNALS
# ------------------------------
#
func _on_damage_area_body_entered(body: Node) -> void:
	# Contact damage
	if body.name == "Player":
		# Use your custom damage system or a method on the player
		# body.take_damage(whatever_amount)
		# Then bounce the bat away
		_bounce_from_player(body)


func _bounce_from_player(player_body: Node) -> void:
	var away_dir = (global_position - player_body.global_position).normalized()
	velocity = away_dir * bounce_force


#
# ------------------------------
# HELPER: LINE-OF-SIGHT CHECK
# ------------------------------
#
func _has_line_of_sight_to(target_pos: Vector2) -> bool:
	# We'll do a raycast from bat to target
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(global_position, target_pos)
	# Exclude self or anything that might incorrectly block the ray
	query.exclude = [self]
	# Only collide with environment layer (e.g. layer 1 for walls/tiles)
	query.collision_mask = 1 << environment_layer_mask

	var result = space_state.intersect_ray(query)
	# If 'result' is null, no walls in between => line of sight is clear
	return result == null




@export var health: int = 50


var suspend_movement: bool = false
var suspend_movement_timer: float = 0.0


func take_damage(damage, hitbox_position, knockback_speed):
	health -= damage
	#$Sprite.animation = "hit"
	
	suspend_movement_timer = 0.1
	suspend_movement = true
		
	var knockback_direction: Vector2 = global_position - hitbox_position
	velocity = Vector2(0, 0)
	velocity = knockback_direction.normalized() * knockback_speed
	
	await get_tree().create_timer(0.1).timeout
	#$Sprite.animation = "default"


func handle_damage_timers(delta):
	suspend_movement_timer -= delta
	if suspend_movement_timer <= 0:
		suspend_movement = false
