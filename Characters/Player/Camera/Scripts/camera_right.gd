extends Area2D
class_name CameraRight


@onready var player_wall_ray_right = get_node("../../Player/Rays/WallRayRight")
@onready var camera = get_node("../../Player/PlayerCamera")

@export var player: CharacterBody2D
@export var right_limit: float = 150

var get_limits: bool = true



func _init():
	collision_layer = 2048
	collision_mask = 8


func _ready():
	camera.limit_right = player.global_position.x + 2000


func _process(delta):
	if get_limits == true:
		if player_wall_ray_right.is_colliding():
			var origin = player_wall_ray_right.global_transform.origin
			var collision_point = player_wall_ray_right.get_collision_point()
			var distance = origin.distance_to(collision_point)
			var limit_to_set = player.position.x + (distance + 50) + right_limit
			
			camera.limit_right = move_toward(camera.limit_right, limit_to_set, 3000 * delta)
		else:
			camera.limit_right = player.global_position.x + 2000
