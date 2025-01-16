extends Node2D

var item_name
var item_quantity


func _ready():
	if item_name != null:
		$TextureRect.texture = load(Global.item_data[item_name]["texture_path"])
		show_label()



func set_item(nm: String, qt: int) -> void:
	item_name = nm
	item_quantity = qt
	$TextureRect.texture = load(Global.item_data[item_name]["texture_path"])
	show_label()


func show_label():
	if item_quantity == 1:
		$Label.visible = false
	else:
		$Label.visible = true
		$Label.text = str(item_quantity)


func add_item_quantity(amount_to_add):
	item_quantity += amount_to_add
	show_label()
	print(amount_to_add, item_quantity)


func decrease_item_quantity(amount_to_remove):
	item_quantity -= amount_to_remove
	show_label()
