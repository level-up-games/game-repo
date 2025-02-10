extends StaticBody2D


@export var max_health: int = 50
var current_health: int

@export var drop_interval: int = 5
var next_drop_threshold: int

@export var item_drop_scene: PackedScene = preload("res://Items/Scenes/ItemDrop.tscn")

# Incremental drop table: each time a drop threshold is crossed, these drops occur.
# For example, for each 5 health lost, drop 1 to 2 wood with 100% chance,
# and drop an apple with a 20% chance.
@export var incremental_drop_table: Array = [
	{"item_name": "Wood", "min_quantity": 1, "max_quantity": 2, "chance": 1.0},
	{"item_name": "Apple", "min_quantity": 1, "max_quantity": 1, "chance": 0.2}
]

# Final drop table: when health reaches 0, these drops occur.
@export var final_drop_table: Array = [
	{"item_name": "Wood", "min_quantity": 5, "max_quantity": 15, "chance": 1.0},
	{"item_name": "Apple", "min_quantity": 0, "max_quantity": 2, "chance": 0.5}
]



func _ready() -> void:
	current_health = max_health
	next_drop_threshold = max_health - drop_interval


func take_damage(damage, hitbox_position, knockback_speed) -> void:
	var previous_health = current_health
	current_health -= damage
	
	# For every interval of damage lost (e.g. every 5 health),
	# trigger a drop event. This loop accounts for cases where damage
	# crosses multiple intervals at once.
	while previous_health > next_drop_threshold and current_health <= next_drop_threshold:
		_drop_interval_items()
		next_drop_threshold -= drop_interval
	
	if current_health <= 0:
		_on_break()

# Called each time a drop threshold is reached (e.g. at health 45, 40, 35, etc.)
func _drop_interval_items() -> void:
	for drop in incremental_drop_table:
		if randf() <= drop["chance"]:
			# Use randf_range(min, max+1) and floor it to get an integer quantity.
			var quantity = int(floor(randf_range(drop["min_quantity"], drop["max_quantity"] + 1)))
			if quantity > 0:
				_spawn_drop(drop["item_name"], quantity)


func _on_break() -> void:
	# Optionally play a break animation here.
	# If you have an AnimationPlayer with an animation called "break", you can do:
	if $AnimationPlayer and $AnimationPlayer.has_animation("break"):
		$AnimationPlayer.play("break")
		$AnimationPlayer.animation_finished.connect(_drop_and_free)
	else:
		_drop_and_free()


func _drop_and_free() -> void:
	for drop in final_drop_table:
		if randf() <= drop["chance"]:
			var quantity = int(floor(randf_range(drop["min_quantity"], drop["max_quantity"] + 1)))
			if quantity > 0:
				_spawn_drop(drop["item_name"], quantity)
	queue_free()

# Spawns a drop instance at the tree's position (with a small random offset)
func _spawn_drop(item_name: String, quantity: int) -> void:
	var drop_instance = item_drop_scene.instantiate()
	drop_instance.item_name = item_name
	drop_instance.item_quantity = quantity
	# Add a small random offset so drops aren’t exactly overlapping
	var offset = Vector2(randf_range(-35, 35), randf_range(-75, 75) - 175)
	drop_instance.global_position = global_position + offset
	get_tree().get_current_scene().add_child(drop_instance)
