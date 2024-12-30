extends Node2D


@export var camera: Camera2D

@export var left_limit: float
@export var right_limit: float
@export var top_limit: float
@export var bottom_limit: float

@export var change_left: bool
@export var change_right: bool
@export var change_top: bool
@export var change_bottom: bool


func _ready():
	pass


func _process(delta):
	pass


func _on_area_body_entered(body):
	if "Player" in body.name:
		if change_bottom == true:
			camera.limit_bottom = bottom_limit
		if change_top == true:
			camera.limit_top = top_limit
		if change_right == true:
			camera.limit_right = right_limit
		if change_left == true:
			camera.limit_left = left_limit
	else:
		pass
