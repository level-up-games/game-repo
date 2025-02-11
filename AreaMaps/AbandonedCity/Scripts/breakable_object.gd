extends StaticBody2D


@export var health: int = 1
@export var item_drop_scene: PackedScene = preload("res://Items/Scenes/ItemDrop.tscn")

# Drop table: an Array of Dictionaries. For each drop, specify:
# - "item_name": the name of the item to drop.
# - "chance": a value between 0 and 1 representing the drop chance.
# - "min_quantity" and "max_quantity": the range of quantities to drop.
@export var drop_table: Array = [
	{"item_name": "Silver Coin", "chance": 0.8, "min_quantity": 0, "max_quantity": 3},
	{"item_name": "Copper Coin", "chance": 0.8, "min_quantity": 50, "max_quantity": 40},
	{"item_name": "Sonic Boots", "chance": 0.1, "min_quantity": 0, "max_quantity": 1}
]



func take_damage(damage, hitbox_position, knockback_speed) -> void:
	health -= damage
	if health <= 0:
		_on_break()


func _on_break() -> void:
	if $AnimationPlayer and $AnimationPlayer.has_animation("break"):
		$AnimationPlayer.play("break")
		$AnimationPlayer.animation_finished.connect(_drop_and_free)
	else:
		_drop_and_free()


func _drop_and_free() -> void:
	_drop_items()
	queue_free()


func _drop_items() -> void:
	for drop in drop_table:
		var quantity = 0
		
		for i in range(drop["max_quantity"]):
			if randf() <= drop["chance"]:
				quantity += 1
		
		if drop.has("min_quantity") and quantity < drop["min_quantity"]:
			quantity = drop["min_quantity"]
		
		if quantity > 0:
			var drop_instance = item_drop_scene.instantiate()
			drop_instance.item_name = drop["item_name"]
			drop_instance.item_quantity = quantity
			
			drop_instance.global_position = global_position + Vector2(randf_range(-30, 30), randf_range(-30, 30) - 35)
			
			get_tree().get_current_scene().add_child(drop_instance)
