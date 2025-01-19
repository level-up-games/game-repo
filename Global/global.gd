extends Node

var player: CharacterBody2D = null

var player_facing_direction: int = 1
var player_movement_direction: float = 0.0

##### Item variables #####
var item_data: Dictionary
const SlotClass: Resource = preload("res://Characters/Player/Inventory/Scripts/slot.gd")

##### Hotbar variables #####
signal active_item_updated
const NUM_HOTBAR_SLOTS = 8
var hotbar = {}  #--> slot_index: [item_name, item_quantity]
var active_item_slot = 0

##### Inventory variables #####
const NUM_INVENTORY_SLOTS = 20
var inventory = {}  #--> slot_index: [item_name, item_quantity]
var accessories = {}  #--> slot_index: [item_name, item_quantity]

##### Player health/combat variables #####
@export var player_max_health: int = 100
@export var player_health: int = 100



##### Regular functions #####
func _ready() -> void:
	item_data = load_data("res://Items/Data/item_data.json")



##### Hotbar functions #####
func active_item_scroll_down() -> void:
	active_item_slot = (active_item_slot + 1) % NUM_HOTBAR_SLOTS
	emit_signal("active_item_updated")


func active_item_scroll_up() -> void:
	if active_item_slot == 0:
		active_item_slot = NUM_HOTBAR_SLOTS - 1
	else:
		active_item_slot -= 1
	emit_signal("active_item_updated")



##### Inventory functions #####
func add_item(item_name: String, item_quantity: int) -> void:
	# Try adding to the hotbar first
	for slot_index in range(NUM_HOTBAR_SLOTS):
		if hotbar.has(slot_index) and hotbar[slot_index][0] == item_name:
			var stack_size = int(item_data[item_name]["stack_size"])
			var able_to_add = stack_size - hotbar[slot_index][1]
			if able_to_add >= item_quantity:
				hotbar[slot_index][1] += item_quantity
				update_slot_visual(slot_index, hotbar[slot_index][0], hotbar[slot_index][1], SlotClass.SlotType.HOTBAR)
				return
			else:
				hotbar[slot_index][1] += able_to_add
				item_quantity -= able_to_add
				update_slot_visual(slot_index, hotbar[slot_index][0], hotbar[slot_index][1], SlotClass.SlotType.HOTBAR)
	
	for slot_index in range(NUM_HOTBAR_SLOTS):
		if not hotbar.has(slot_index):
			hotbar[slot_index] = [item_name, item_quantity]
			update_slot_visual(slot_index, hotbar[slot_index][0], hotbar[slot_index][1], SlotClass.SlotType.HOTBAR)
			return
	
	# Add remaining quantity to the inventory
	for item in inventory:
		if inventory[item][0] == item_name:
			var stack_size = int(item_data[item_name]["stack_size"])
			var able_to_add = stack_size - inventory[item][1]
			if able_to_add >= item_quantity:
				inventory[item][1] += item_quantity
				update_slot_visual(item, inventory[item][0], inventory[item][1], SlotClass.SlotType.INVENTORY)
				return
			else:
				inventory[item][1] += able_to_add
				item_quantity -= able_to_add
				update_slot_visual(item, inventory[item][0], inventory[item][1], SlotClass.SlotType.INVENTORY)
	
	for i in range(NUM_INVENTORY_SLOTS):
		if not inventory.has(i):
			inventory[i] = [item_name, item_quantity]
			update_slot_visual(i, inventory[i][0], inventory[i][1], SlotClass.SlotType.INVENTORY)
			return


func update_slot_visual(slot_index: int, item_name: String, new_quantity: int, slot_type: SlotClass.SlotType) -> void:
	var path = ""
	
	if slot_type == SlotClass.SlotType.HOTBAR:
		path = "UserInterface/Hotbar/TextureRect/GridContainer/HotbarSlot" + str(slot_index + 1)
	elif slot_type == SlotClass.SlotType.INVENTORY:
		path = "UserInterface/Inventory/TextureRect/GridContainer/Slot" + str(slot_index + 1)

	var slot = player.get_node(path)
	slot.initialize_item(item_name, new_quantity)


func get_target_dict(slot: SlotClass) -> Dictionary:
	match slot.slot_type:
		SlotClass.SlotType.INVENTORY:
			print("Inventory: " + str(inventory))
			return inventory
		SlotClass.SlotType.HOTBAR:
			print("Hotbar: " + str(hotbar))
			return hotbar
		SlotClass.SlotType.ACCESSORY:
			print("Accessories: " + str(accessories))
			return accessories
		_:
			print("Unknown slot type: ", slot.slot_type)
			return {}


func add_item_to_empty_slot(item, slot: SlotClass) -> void:
	var target_dict = get_target_dict(slot)
	if target_dict != null:
		target_dict[slot.slot_index] = [item.item_name, item.item_quantity]


func remove_item(slot: SlotClass) -> void:
	var target_dict = get_target_dict(slot)
	if target_dict != null and slot.slot_index in target_dict:
		target_dict.erase(slot.slot_index)


func add_item_quantity(slot: SlotClass, quantity_to_add: int) -> void:
	var target_dict = get_target_dict(slot)
	if target_dict != null and slot.slot_index in target_dict:
		slot.item.add_item_quantity(quantity_to_add)
		target_dict[slot.slot_index][1] += quantity_to_add


func subtract_item_quantity(slot: SlotClass, quantity_to_subtract: int) -> void:
	var target_dict = get_target_dict(slot)
	if target_dict != null and slot.slot_index in target_dict:
		slot.item.decrease_item_quantity(quantity_to_subtract)
		target_dict[slot.slot_index][1] -= quantity_to_subtract
		if target_dict[slot.slot_index][1] <= 0:
			target_dict.erase(slot.slot_index)
			slot.pick_from_slot()  # so the panel no longer holds that item


##### Item functions #####
func load_data(file_path: String) -> Dictionary:
	var json_data: Dictionary = {}
	var file_data: FileAccess = FileAccess.open(file_path, FileAccess.ModeFlags.READ)

	if file_data:
		var json_parser = JSON.new()
		json_parser.parse(file_data.get_as_text())
		json_data = json_parser.data
	else:
		push_error("File does not exist or cannot be opened: %s".format(file_path))

	return json_data



##### Player health/combat functions #####
func player_take_damage(damage):
	player_health -= damage
	print(player_health)
