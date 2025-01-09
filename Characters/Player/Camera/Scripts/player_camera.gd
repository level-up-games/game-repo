extends Camera2D



func _ready():
	pass


func _process(delta):
	handle_camera_bias()


func handle_camera_bias():
	if Global.player_movement_direction > 0:
		position.x = 35
	elif Global.player_movement_direction < 0:
		position.x = -35


func change_limits(left, right, top, bottom):
	limit_left = left
	limit_right = right
	limit_top = top
	limit_bottom = bottom
