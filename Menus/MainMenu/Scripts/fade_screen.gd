extends ColorRect



var opacity: float = 1.0



func _ready():
	self_modulate = Color(1, 1, 1, 1)


func _process(delta):
	self_modulate = Color(1, 1, 1, opacity)
	opacity -= delta
