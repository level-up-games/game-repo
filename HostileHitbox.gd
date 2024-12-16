extends Area2D
class_name HostileHitbox


@export var damage_dealt: int = 10



func _init():
	collision_layer = 2
	collision_mask = 0
