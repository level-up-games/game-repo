extends Panel

@onready var dialogue_label: Label = $DialogueLabel

func _ready() -> void:
	visible = false

func show_dialogue(text: String) -> void:
	dialogue_label.text = text
	visible = true

func hide_dialogue() -> void:
	visible = false
