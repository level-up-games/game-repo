extends Panel



func setup(data: Dictionary) -> void:
	$TextLabel.parse_bbcode(data.get("text", ""))
	# Optionally, implement page turning if multiple pages exist.
	visible = true


func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("Interact"):
		queue_free()
