extends Panel

@onready var text_label: RichTextLabel = $TextLabel

func setup(data: Dictionary) -> void:
	# For simple readable objects, data might just have a "text" key.
	$TextLabel.parse_bbcode(data.get("text", ""))
	# Optionally, implement page turning if multiple pages exist.
	visible = true

func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("Interact"):
		queue_free()  # Close the dialogue on interact.
