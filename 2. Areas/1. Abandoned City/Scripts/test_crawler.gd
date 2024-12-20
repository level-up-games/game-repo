extends CharacterBody2D


@onready var WallRay = $WallRay
@onready var GroundRay = $GroundRay

@export var speed: float = 100.0

var suspend_movement: bool = false
var suspend_movement_timer: float = 0.0

var direction: int = -1
var gravity: int = 980

var health: int = 25



func _ready():
	$Sprite.animation = "default"


func _physics_process(delta):
	if suspend_movement == false:
		#velocity.y += gravity * delta
		velocity.x = speed * direction
	
	if health <=0:
		queue_free()
	move_and_slide()
	
	handle_damage_timers(delta)
	handle_direction()

func handle_direction():
	if GroundRay.is_colliding() == false:
		GroundRay.position.x = -GroundRay.position.x
		WallRay.target_position.x = -WallRay.target_position.x
		direction = -direction
	
	if WallRay.is_colliding() == true:
		WallRay.target_position.x = -WallRay.target_position.x
		GroundRay.position.x = -GroundRay.position.x
		direction = -direction


func take_damage(damage, hitbox_position, knockback_speed):
	health -= damage
	$Sprite.animation = "hit"
	
	suspend_movement_timer = 0.1
	suspend_movement = true
		
	var knockback_direction: Vector2 = global_position - hitbox_position
	velocity = Vector2(0, 0)
	velocity = knockback_direction.normalized() * knockback_speed
	
	await get_tree().create_timer(0.1).timeout
	$Sprite.animation = "default"


func handle_damage_timers(delta):
	suspend_movement_timer -= delta
	if suspend_movement_timer <= 0:
			suspend_movement = false
