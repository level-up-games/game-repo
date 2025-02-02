extends Area2D
class_name CameraBottom


@onready var player_ground_ray = get_node("../../Player/Rays/GroundRay")
@onready var camera = get_node("../../Player/PlayerCamera")

@export var player: CharacterBody2D
@export var bottom_limit: float = 250

var get_limits: bool = true



func _init():
	collision_layer = 256
	collision_mask = 8


func _ready():
	camera.limit_bottom = player.position.y + 1200


func _process(delta):
	if get_limits == true:
		if player_ground_ray.is_colliding():
			var origin = player_ground_ray.global_transform.origin
			var collision_point = player_ground_ray.get_collision_point()
			var distance = origin.distance_to(collision_point)
			var limit_to_set = player.position.y + (distance + 30) + bottom_limit
			
			camera.limit_bottom = move_toward(camera.limit_bottom, limit_to_set, 3000 * delta)
		else:
			camera.limit_bottom = move_toward(camera.limit_bottom, player.position.y + 600, 3000 * delta)
