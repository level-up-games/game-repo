extends CanvasLayer

var holding_item: Node2D = null


func _ready():
	Global.ui = self


func get_mouse_world_position() -> Vector2:
	return get_viewport().get_mouse_position()


func _input(event) -> void:
	if event.is_action_pressed("Open_Inventory"):
		$Inventory.visible = !$Inventory.visible
		$Inventory.initialize(Global.inventory)

	if event.is_action_pressed("Scroll_Up"):
		Global.active_item_scroll_up()
	elif event.is_action_pressed("Scroll_Down"):
		Global.active_item_scroll_down()
	
	 # Handle right-click outside inventory for dropping
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			# If we're holding an item
			if holding_item != null:
				# Check if the mouse is outside the inventory panel
				# For example, check if the click position is not inside $Inventory's rect
				var click_pos = get_mouse_world_position() + Vector2(250, -65) # weird ass inventory/hotbar position problem, top left is (250, -65) away, so this corrects it
			
				var inv_rect = $Inventory.get_rect()
				var hotbar_rect = $Hotbar.get_rect()
		
				if not inv_rect.has_point(click_pos):
					if not hotbar_rect.has_point(click_pos):
						# This means we right-clicked outside the inventory
						drop_item_in_world(holding_item)
						# Remove from cursor
						holding_item.queue_free()
						holding_item = null


func drop_item_in_world(item_node: Node2D) -> void:
	var item_name = item_node.item_name
	var item_quantity = item_node.item_quantity
	
	var item_drop_scene = preload("res://Items/Scenes/ItemDrop.tscn")
	var drop_instance = item_drop_scene.instantiate()
	
	drop_instance.item_name = item_name
	drop_instance.item_quantity = item_quantity
	
	if Global.player:
		drop_instance.bounce_on_spawn = false
		drop_instance.global_position = Global.player.global_position + Vector2(0, -100)
		drop_instance.velocity = Vector2(350 * Global.current_mouse_direction, -150)
	else:
		drop_instance.global_position = get_mouse_world_position()
	
	get_tree().current_scene.add_child(drop_instance)
