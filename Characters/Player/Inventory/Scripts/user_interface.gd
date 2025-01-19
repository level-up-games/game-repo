extends CanvasLayer

var holding_item: Node2D = null



# We'll define a helper to get the mouse world position
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
				var click_pos = get_mouse_world_position() + Vector2(250, -65) # weird ass inventory position problem, top left is (250, -65) away, so this corrects it

				var inv_rect = $Inventory.get_rect()

				if not inv_rect.has_point(click_pos):
					# This means we right-clicked outside the inventory
					drop_item_in_world(holding_item)
					# Remove from cursor
					holding_item.queue_free()
					holding_item = null


func drop_item_in_world(item_node: Node2D) -> void:
	# We'll spawn an item_drop node in the game world with the same item data
	var item_name = item_node.item_name
	var item_quantity = item_node.item_quantity

	# For instance, we can place the drop near the Player
	# or near the mouse position. Let's do near the Player:
	var item_drop_scene = preload("res://Items/Scenes/ItemDrop.tscn")
	var drop_instance = item_drop_scene.instantiate()

	drop_instance.item_name = item_name
	drop_instance.item_quantity = item_quantity

	# Place it near the player
	if Global.player:
		drop_instance.global_position = Global.player.global_position + Vector2(75 * Global.current_mouse_direction, -75)
	else:
		# fallback: place at mouse
		drop_instance.global_position = get_mouse_world_position()

	# Add it to the current scene
	get_tree().current_scene.add_child(drop_instance)

	# Optionally: if you have physics or an initial velocity, you can set that here
	# e.g. drop_instance.velocity = Vector2(50, -100)
