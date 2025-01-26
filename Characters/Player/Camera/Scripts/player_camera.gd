extends Camera2D



func _ready():
	pass


func _process(delta):
	handle_camera_bias(delta)


func handle_camera_bias(delta):
	if Global.player_facing_direction < 0:
		position.x = move_toward(position.x, 35, 280 * delta)
	elif Global.player_facing_direction > 0:
		position.x = move_toward(position.x, -35, 280 * delta)


func change_limits(left, right, top, bottom):
	limit_left = left
	limit_right = right
	limit_top = top
	limit_bottom = bottom
