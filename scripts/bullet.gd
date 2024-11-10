extends CharacterBody2D

var pos: Vector2
var rota: float
var dir: float
var speed = 1000


func _ready() -> void:
	pos = global_position
	rota = rotation


func _physics_process(delta: float) -> void:
	velocity = Vector2(speed, 0).rotated(dir)
	move_and_slide()
