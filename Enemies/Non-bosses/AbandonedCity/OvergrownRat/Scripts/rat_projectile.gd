extends CharacterBody2D


@export var speed: float = 400.0
var gravity: float = 1800
var direction: Vector2



func _ready():
	$HostileHitbox.parried.connect(_on_parried)
	velocity.y = -850


func _physics_process(delta: float) -> void:
	velocity.y += gravity * delta
	
	velocity.x = direction.x * speed
	
	move_and_slide()
	
	if is_on_floor():
		queue_free()


func set_direction(dir: Vector2) -> void:
	direction = dir


func _on_parried():
	$HostileHitbox.damage_dealt = 0
	modulate = Color(1,1,0)
