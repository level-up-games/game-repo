extends Area2D
class_name PlayerHitbox


@export var damage_dealt: int = 10



func _init():
	collision_layer = 64
	collision_mask = 0
