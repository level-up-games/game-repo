extends Area2D
class_name CameraBottom


@onready var player_ground_ray = get_node("../../Player/Rays/GroundRay")

@export var camera: Camera2D
@export var player: CharacterBody2D
@export var bottom_limit: float = 150



func _init():
	collision_layer = 256
	collision_mask = 8


func _ready():
	pass


func _process(delta):
	if player_ground_ray.is_colliding():
		var origin = player_ground_ray.global_transform.origin
		var collision_point = player_ground_ray.get_collision_point()
		var distance = origin.distance_to(collision_point)
		camera.limit_bottom = player.position.y + (distance + 30) + bottom_limit
	else:
		camera.limit_bottom = player.position.y + 1500
