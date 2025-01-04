extends CanvasLayer

var holding_item: Node2D = null


func _input(event) -> void:
	if event.is_action_pressed("Open_Inventory"):
		$Inventory.visible = !$Inventory.visible
		$Inventory.initialize(Global.inventory)

	if event.is_action_pressed("Scroll_Up"):
		Global.active_item_scroll_up()
	elif event.is_action_pressed("Scroll_Down"):
		Global.active_item_scroll_down()
