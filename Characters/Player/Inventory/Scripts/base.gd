extends Node2D

const SlotClass: Resource = preload("res://Characters/Player/Inventory/Scripts/slot.gd")
const ItemClass: PackedScene = preload("res://4. Items/Scenes/Item.tscn")

var ui
var type

@onready var slots = $TextureRect/GridContainer.get_children()
var original_slot: SlotClass = null


func _ready() -> void:
	# Connect the input signal to the handler for each inventory slot
	for i in range(slots.size()):
		var slot = slots[i]
		slot.connect("gui_input", self.slot_gui_input.bind(slot))
		slot.slot_index = i
		slot.slot_type = type


func initialize(global_container: Dictionary) -> void:
	# Initialize slots with items from the global container
	for i in range(slots.size()):
		if global_container.has(i):
			slots[i].initialize_item(global_container[i][0], global_container[i][1])


func able_to_put_into_slot(slot: SlotClass) -> bool:
	# Determine if the item can be placed in the slot
	var holding_item = find_parent("UserInterface").holding_item
	if holding_item == null:
		return true

	var item_category = Global.item_data[holding_item.item_name]["item_category"]
	if slot.slot_type == SlotClass.SlotType.ACCESSORY:
		return item_category == "Accessory"
	return true


func slot_gui_input(event: InputEvent, slot: SlotClass) -> void:
	# Handle mouse clicks on inventory slots
	original_slot = slot
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			handle_left_click(slot, event)
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			handle_right_click(slot)


func handle_left_click(slot: SlotClass, event: InputEvent) -> void:
	# Handle left-click logic for item dragging or placement
	if ui == null:
		ui = find_parent("UserInterface")

	if not able_to_put_into_slot(slot):
		return

	Global.remove_item(slot)
	if ui.holding_item:
		handle_item_drag(event, slot)
	elif slot.item:
		ui.holding_item = slot.item
		slot.pick_from_slot()
		ui.holding_item.global_position = get_global_mouse_position()
		Global.remove_item(slot)


func handle_right_click(slot: SlotClass) -> void:
	# Handle right-click for splitting item stacks
	if ui == null:
		ui = find_parent("UserInterface")
	
	# Case 1: Splitting from the slot's item
	if slot.item and slot.item.item_quantity > 1 and ui.holding_item == null:
		var half_quantity = slot.item.item_quantity / 2
		var remaining_quantity = slot.item.item_quantity - half_quantity

		slot.item.set_item(slot.item.item_name, remaining_quantity)

		var new_item = ItemClass.instantiate()
		new_item.set_item(slot.item.item_name, half_quantity)
		ui.add_child(new_item)

		ui.holding_item = new_item
		ui.holding_item.global_position = get_global_mouse_position()

	# Case 2: Splitting the holding item
	elif ui.holding_item and ui.holding_item.item_quantity > 1:
		var half_quantity = ui.holding_item.item_quantity / 2
		var remaining_quantity = ui.holding_item.item_quantity - half_quantity

		ui.holding_item.set_item(ui.holding_item.item_name, remaining_quantity)

		if original_slot and original_slot.item:
			original_slot.item.add_item_quantity(half_quantity)
		elif original_slot:
			original_slot.initialize_item(ui.holding_item.item_name, half_quantity)


func handle_item_drag(event: InputEvent, slot: SlotClass) -> void:
	# Handle item dragging and placement into the slot
	if not slot.item:
		if able_to_put_into_slot(slot):
			Global.add_item_to_empty_slot(ui.holding_item, slot)
			slot.put_into_slot(ui.holding_item)
			ui.holding_item = null
	else:
		if ui.holding_item.item_name != slot.item.item_name:
			swap_items(event, slot)
		else:
			stack_items(slot)


func swap_items(event: InputEvent, slot: SlotClass) -> void:
	# Swap items between the holding item and the slot item
	Global.remove_item(slot)
	Global.add_item_to_empty_slot(ui.holding_item, slot)

	var temp_item: Node2D = slot.item
	slot.pick_from_slot()
	temp_item.global_position = event.global_position

	slot.put_into_slot(ui.holding_item)
	ui.holding_item = temp_item


func stack_items(slot: SlotClass) -> void:
	# Handle stacking of items in the same slot
	var stack_size = int(Global.item_data[slot.item.item_name]['stack_size'])
	var able_to_add = stack_size - slot.item.item_quantity

	if able_to_add >= ui.holding_item.item_quantity:
		Global.add_item_quantity(slot, ui.holding_item.item_quantity)
		slot.item.add_item_quantity(ui.holding_item.item_quantity)
		ui.holding_item.queue_free()
		ui.holding_item = null
	else:
		Global.add_item_quantity(slot, able_to_add)
		slot.item.add_item_quantity(able_to_add)
		ui.holding_item.decrease_item_quantity(able_to_add)


func _input(event: InputEvent) -> void:
	# Update the position of the holding item if it's being dragged
	if ui == null:
		ui = find_parent("UserInterface")
	elif ui.holding_item:
		ui.holding_item.global_position = get_global_mouse_position()
