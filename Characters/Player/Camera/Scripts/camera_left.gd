extends Area2D
class_name CameraLeft


@onready var player_wall_ray_left = get_node("../../Player/Rays/WallRayLeft")
@onready var camera = get_node("../../Player/PlayerCamera")

@export var player: CharacterBody2D
@export var left_limit: float = 150

var get_limits: bool = true



func _init():
	collision_layer = 1024
	collision_mask = 8


func _ready():
	camera.limit_left = player.position.x - 2000


func _process(delta):
	if get_limits == true:
		if player_wall_ray_left.is_colliding():
			var origin = player_wall_ray_left.global_transform.origin
			var collision_point = player_wall_ray_left.get_collision_point()
			var distance = origin.distance_to(collision_point)
			var limit_to_set = player.position.x - (distance + 50) - left_limit
			
			camera.limit_left = move_toward(camera.limit_left, limit_to_set, 3000 * delta)
		else:
			camera.limit_left = move_toward(camera.limit_left, player.position.x - 2000, 3000 * delta)
