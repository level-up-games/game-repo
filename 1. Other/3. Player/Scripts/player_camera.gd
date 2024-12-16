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
	else:
		if Global.player_facing_direction == -1:
			position.x = 35
		else:
			position.x = -35
