extends Control

@onready var inventory: Inventory = preload("res://1. Other/1. Inventory/PlayerInventory.tres")
@onready var slots: Array = $NinePatchRect/GridContainer.get_children()

var is_open: bool = false


func _ready() -> void:
	update_slots()
	visible = false


func update_slots() -> void:
	for i in range(min(inventory.items.size(), slots.size())):
		slots[i].update(inventory.items[i])


func _process(delta: float) -> void:
	if Input.is_action_just_pressed("Open_Inventory"):
		is_open = !is_open
		visible = is_open
