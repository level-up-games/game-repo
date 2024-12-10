extends Control

func _ready():
	hide_inventory()


func populate_inventory() -> void:
	for i in range(Global.inventory.size()):
		var slot = $GridContainer.get_child(i)
		var item = Global.inventory[i]
		slot.text = "%s (x%d)" % [item.name, item.amount]


func show_inventory() -> void:
	visible = true
	populate_inventory()


func hide_inventory() -> void:
	visible = false
