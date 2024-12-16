extends CharacterBody2D


@onready var WallRay = $WallRay
@onready var GroundRay = $GroundRay

@export var speed: float = 100.0

var direction: int = -1
var gravity: int = 980


var health: int = 25

func _ready():
	$Sprite.animation = "default"

func _physics_process(delta):
	#velocity.y += gravity * delta
	velocity.x = speed * direction
	handle_direction()
	if health <=0:
		queue_free()
	move_and_slide()


func handle_direction():
	if GroundRay.is_colliding() == false:
		GroundRay.position.x = -GroundRay.position.x
		WallRay.target_position.x = -WallRay.target_position.x
		direction = -direction
	
	if WallRay.is_colliding() == true:
		WallRay.target_position.x = -WallRay.target_position.x
		GroundRay.position.x = -GroundRay.position.x
		direction = -direction

func take_damage(damage):
	health -= damage
	$Sprite.animation = "hit"
	await get_tree().create_timer(0.2).timeout
	$Sprite.animation = "default"
