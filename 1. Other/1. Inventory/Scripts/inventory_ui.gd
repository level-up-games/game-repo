extends Control

var is_open: bool = false

func _ready() -> void:
	visible = false

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("Open_Inventory"):
		is_open = !is_open
		visible = is_open
