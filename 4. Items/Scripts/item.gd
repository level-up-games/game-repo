extends StaticBody2D

@export var item: InventoryItem
var player = null


func _on_area_2d_body_entered(body: Node2D) -> void:
	print("entered")
	print(body.name)
	if body.name == "Player":
		player = body
		player.collect(item)
		await get_tree().create_timer(0.1).timeout
		self.queue_free()
