extends Node

@export var inventory: Array = []  # Holds all inventory items
@export var hotbar: Array = []    # Holds hotbar items
@export var crafting_recipes: Dictionary = {}  # Stores crafting recipes


func add_to_inventory(item_name: String, stack_size: int = 1) -> void:
	for slot in inventory:
		if slot.name == item_name and slot.stackable:
			slot.amount += stack_size
			return
	inventory.append({"name": item_name, "amount": stack_size, "stackable": true})


func can_craft(item_name: String) -> bool:
	if not crafting_recipes.has(item_name):
		return false
	for material in crafting_recipes[item_name]:
		if not has_material(material.name, material.amount):
			return false
	return true


func has_material(item_name: String, amount: int) -> bool:
	for slot in inventory:
		if slot.name == item_name and slot.amount >= amount:
			return true
	return false


func use_materials(item_name: String) -> void:
	for material in crafting_recipes[item_name]:
		for slot in inventory:
			if slot.name == material.name:
				slot.amount -= material.amount
				if slot.amount <= 0:
					inventory.erase(slot)
				break
