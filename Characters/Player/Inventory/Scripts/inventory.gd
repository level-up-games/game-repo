extends "res://Characters/Player/Inventory/Scripts/base.gd"

@onready var accessory_slots = $TextureRect/AccessorySlots.get_children()

func _ready() -> void:
	ui = find_parent("User Interface")
	type = SlotClass.SlotType.INVENTORY
	super._ready()
	initialize(Global.inventory)
	
	for i in range(accessory_slots.size()):
		accessory_slots[i].connect("gui_input", self.slot_gui_input.bind(accessory_slots[i]))
		accessory_slots[i].slot_index = i
		accessory_slots[i].slot_type = SlotClass.SlotType.ACCESSORY
	initialize_accessories(accessory_slots)
	# TODO: why the fuck is the inventory weird again


func initialize_accessories(accessory_slots) -> void:
	for i in range(accessory_slots.size()):
		if Global.accessories.has(i):
			accessory_slots[i].initialize_item(Global.accessories[i][0], Global.accessories[i][1])
