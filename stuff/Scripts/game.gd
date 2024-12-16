extends Node2D

@onready var inventory = $"Player/User Interface/Inventory"

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("Open_Inventory"):
		if inventory.visible:
			inventory.hide_inventory()
			# $CraftingMenu.visible = false
		else:
			inventory.show_inventory()
			# $CraftingMenu.visible = true
