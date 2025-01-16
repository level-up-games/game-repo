extends Base

func _ready() -> void:
	ui = find_parent("User Interface")
	type = SlotClass.SlotType.HOTBAR
	super._ready()
	for i in range(slots.size()):
		Global.active_item_updated.connect(slots[i].refresh_style)
	initialize(Global.hotbar)
	Global.active_item_updated.emit()
