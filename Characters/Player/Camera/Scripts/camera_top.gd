extends Area2D
class_name CameraTop


@onready var player_ceiling_ray = get_node("../../Player/Rays/CeilingRay")

@export var camera: Camera2D
@export var player: CharacterBody2D
@export var top_limit: float = 150

var get_limits: bool = true



func _init():
	collision_layer = 512
	collision_mask = 8


func _ready():
	pass


func _process(delta):
	if get_limits == true:
		if player_ceiling_ray.is_colliding():
			var origin = player_ceiling_ray.global_transform.origin
			var collision_point = player_ceiling_ray.get_collision_point()
			var distance = origin.distance_to(collision_point)
			camera.limit_top = player.position.y - (distance + 150) - top_limit
		else:
			camera.limit_top = player.position.y - 1500
