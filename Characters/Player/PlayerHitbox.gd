extends Area2D
class_name PlayerHitbox


@export var knockback_speed: float = 750.0
@export var set_damage_dealt: int = 10
var damage_dealt: int
var hitbox_position: Vector2



func _init():
	collision_layer = 64
	collision_mask = 0


func _process(delta):
	hitbox_position = global_position
