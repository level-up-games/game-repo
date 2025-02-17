extends Panel

@export var ItemClass: PackedScene = preload("res://Items/Scenes/Item.tscn")
@onready var tooltip = preload("res://Characters/Player/Inventory/Scenes/Tooltip.tscn").instantiate()

var default_texture = preload("res://Characters/Player/Inventory/Assets/inv-slot.png")
var selected_texture = preload("res://Characters/Player/Inventory/Assets/selected.png")
var default_style: StyleBoxTexture = null
var selected_style: StyleBoxTexture = null

var item: Node2D = null

var slot_index
var slot_type

enum SlotType {
	HOTBAR = 0,
	INVENTORY = 1,
	ACCESSORY = 2,
}


func _ready() -> void:
	default_style = StyleBoxTexture.new()
	selected_style = StyleBoxTexture.new()
	default_style.texture = default_texture
	selected_style.texture = selected_texture
	refresh_style()
	self.mouse_entered.connect(_on_mouse_entered)
	self.mouse_exited.connect(_on_mouse_exited)


func refresh_style():
	if slot_type == SlotType.HOTBAR and Global.active_item_slot == slot_index:
		set("theme_override_styles/panel", selected_style)
	else:
		set("theme_override_styles/panel", default_style)


func pick_from_slot() -> void:
	if item:
		remove_child(item)
		var inventory_node: Node = find_parent("UserInterface")
		inventory_node.add_child(item)
		item = null


func put_into_slot(new_item: Node2D) -> void:
	item = new_item
	item.position = Vector2(0, 0)
	var inventory_node: Node = find_parent("UserInterface")
	inventory_node.remove_child(item)
	add_child(item)


func initialize_item(item_name: String, item_quantity: int) -> void:
	if item == null:
		item = ItemClass.instantiate()
		add_child(item)
		item.set_item(item_name, item_quantity)
	else:
		item.set_item(item_name, item_quantity)


func _on_mouse_entered():
	if item:
		Global.ui.add_child(tooltip)
		tooltip.show_tooltip(item["item_name"])


func _on_mouse_exited():
	Global.ui.remove_child(tooltip)
	tooltip.hide_tooltip()
