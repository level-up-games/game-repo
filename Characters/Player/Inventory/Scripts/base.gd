extends Node2D

const SlotClass: Resource = preload("res://Characters/Player/Inventory/Scripts/slot.gd")
var ui
var type

@onready var slots = $TextureRect/GridContainer.get_children()


func _ready() -> void:
	# Connect the input signal to the handler for each inventory slot
	for i in range(slots.size()):
		slots[i].connect("gui_input", self.slot_gui_input.bind(slots[i]))
		slots[i].slot_index = i
		slots[i].slot_type = type


func initialize(global_container: Dictionary) -> void:
	for i in range(slots.size()):
		if global_container.has(i):
			slots[i].initialize_item(global_container[i][0], global_container[i][1])


func slot_gui_input(event: InputEvent, slot: Node) -> void:
	# Handle the logic when the left mouse button is clicked
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		Global.remove_item(slot)
		if ui.holding_item:
			handle_item_drag(event, slot)
		elif slot.item:
			# Pick up the item from the slot if there is one
			ui.holding_item = slot.item
			slot.pick_from_slot()
			ui.holding_item.global_position = get_global_mouse_position()


func handle_item_drag(event: InputEvent, slot: Node) -> void:
	# Handle item dragging and placement into the slot
	if not slot.item:
		Global.add_item_to_empty_slot(ui.holding_item, slot)
		slot.put_into_slot(ui.holding_item)
		ui.holding_item = null
	else:
		if ui.holding_item.item_name != slot.item.item_name:
			swap_items(event, slot)
		else:
			stack_items(slot)


func swap_items(event: InputEvent, slot: Node) -> void:
	# Swap items between the holding item and the slot item
	Global.remove_item(slot)
	Global.add_item_to_empty_slot(ui.holding_item, slot)
	var temp_item: Node2D = slot.item
	slot.pick_from_slot()
	temp_item.global_position = event.global_position
	slot.put_into_slot(ui.holding_item)
	ui.holding_item = temp_item


func stack_items(slot: Node) -> void:
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
	# TODO: why is ui null sometimes?
	if ui == null:
		ui = find_parent("UserInterface")
	elif ui.holding_item:
		ui.holding_item.global_position = get_global_mouse_position()
