extends Area2D

@export var item_name: String = "Default Item"
@export var stack_size: int = 1


func _on_area_entered(body: Node) -> void:
	print('entered')
	if body.name == "Player":
		print('touched by player')
		Global.add_to_inventory(item_name, stack_size)
		print("Picked up: %s (x%d)" % [item_name, stack_size])
		queue_free()
