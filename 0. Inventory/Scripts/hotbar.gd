extends Control

@export var slot_count = 5
var selected_slot = 0


func _ready():
	for i in range(slot_count):
		$GridContainer.get_child(i).pressed.connect(func() -> void:
			_on_slot_selected(i))
	update_selected_slot()


func _on_slot_selected(slot_index: int) -> void:
	selected_slot = slot_index
	update_selected_slot()


func update_selected_slot() -> void:
	for i in range(slot_count):
		var slot = $GridContainer.get_child(i)
		slot.modulate = Color.YELLOW if i == selected_slot else Color.WHITE  # Yellow if selected
