extends CanvasLayer


@onready var color_rect = $ColorRect
var opacity: float = 0.0
var increase_opacity: int = 0 # 0 = decrease, 1 = increase, 2 = hold
var opacity_increase_rate: float = 4.0
var opacity_decrease_rate: float = 4.0
var changed_scene: bool = false
var scene_to_load



func _ready():
	color_rect.modulate = Color(1, 1, 1, 1)
	color_rect.visible = true
	layer = -1

func _process(delta):
	color_rect.modulate = Color(1, 1, 1, opacity)
	
	if opacity > 0:
		layer = 10
	else:
		layer = -1
		changed_scene = false
	
	if increase_opacity == 0 and opacity > 0:
		opacity -= delta * opacity_decrease_rate
	elif increase_opacity == 1 and opacity < 1:
		opacity += delta * opacity_increase_rate
	else:
		pass
	
	if opacity >= 1 and changed_scene == false:
		get_tree().change_scene_to_file(scene_to_load)
		changed_scene = true


func fade_transition(decrease_rate: float, increase_rate: float, hold_time: float, scene):
	scene_to_load = scene
	opacity_decrease_rate = decrease_rate
	opacity_increase_rate = increase_rate
	increase_opacity = 1
	if hold_time >= 1/increase_rate:
		pass
	else:
		hold_time = (1/increase_rate) + 0.1
	await get_tree().create_timer(hold_time).timeout
	increase_opacity = 0
