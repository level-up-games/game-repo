extends Label

var item_name: String
var item_quantity: int = 1

func update_text():
	text = "+%d %s" % [item_quantity, item_name]

func _ready():
	var tween = create_tween()
	tween.tween_property(self, "position", position + Vector2(0, -30), 2.0)
	tween.tween_property(self, "modulate", Color(1, 1, 1, 0), 2.0)

	await get_tree().create_timer(2.0).timeout
	queue_free()
