extends Area2D
class_name CameraTop


@onready var player_ceiling_ray = get_node("../../Player/Rays/CeilingRay")
@onready var camera = get_node("../../Player/PlayerCamera")

@export var player: CharacterBody2D
@export var top_limit: float = 150

var get_limits: bool = true



func _init():
	collision_layer = 512
	collision_mask = 8


func _ready():
	camera.limit_top = player.position.y - 1500


func _process(delta):
	if get_limits == true:
		if player_ceiling_ray.is_colliding():
			var origin = player_ceiling_ray.global_transform.origin
			var collision_point = player_ceiling_ray.get_collision_point()
			var distance = origin.distance_to(collision_point)
			var limit_to_set = player.position.y - (distance + 150) - top_limit
			
			camera.limit_top = move_toward(camera.limit_top, limit_to_set, 3000 * delta)
		else:
			camera.limit_top = player.position.y - 1500
