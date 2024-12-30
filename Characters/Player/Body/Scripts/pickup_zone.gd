extends Area2D

var items_in_range = {}

func _on_body_entered(body: Node2D) -> void:
	items_in_range[body] = body


func _on_body_exited(body: Node2D) -> void:
	if items_in_range.has(body):
		items_in_range.erase(body)
