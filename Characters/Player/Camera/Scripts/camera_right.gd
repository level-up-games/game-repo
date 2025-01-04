extends Area2D
class_name CameraRight


@onready var player_wall_ray_right = get_node("../../Player/Rays/WallRayRight")

@export var camera: Camera2D
@export var player: CharacterBody2D
@export var right_limit: float = 150



func _init():
	collision_layer = 2048
	collision_mask = 8


func _ready():
	pass


func _process(delta):
	if player_wall_ray_right.is_colliding():
		var origin = player_wall_ray_right.global_transform.origin
		var collision_point = player_wall_ray_right.get_collision_point()
		var distance = origin.distance_to(collision_point)
		camera.limit_right = player.position.x + (distance + 50) + right_limit
	else:
		camera.limit_right = player.position.x + 2000
