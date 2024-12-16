extends Node2D


@export var camera: Camera2D #= get_node("/root/Abandoned City 1/Player/Player Camera")

@export var left_limit: float
@export var right_limit: float
@export var top_limit: float
@export var bottom_limit: float



func _ready():
	pass


func _process(delta):
	pass


func _on_area_body_entered(body):
	if "Player" in body.name:
		camera.limit_bottom = bottom_limit
		camera.limit_top = top_limit
		camera.limit_right = right_limit
		camera.limit_left = left_limit
	else:
		pass
