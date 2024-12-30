extends Area2D
class_name CameraLeft


@onready var player_wall_ray_left = get_node("../../Player/Rays/WallRayLeft")

@export var camera: Camera2D
@export var player: CharacterBody2D
@export var left_limit: float = 150



func _init():
	collision_layer = 1024
	collision_mask = 8


func _ready():
	pass


func _process(delta):
	if player_wall_ray_left.is_colliding():
		var origin = player_wall_ray_left.global_transform.origin
		var collision_point = player_wall_ray_left.get_collision_point()
		var distance = origin.distance_to(collision_point)
		camera.limit_left = player.position.x - (distance - 50) - left_limit
