extends Panel

@onready var item_visual: Sprite2D = $CenterContainer/Panel/ItemDisplay

func update(item: InventoryItem):
	if !item:
		item_visual.visible = false
		return
	item_visual.visible = true
	item_visual.texture = item.texture
