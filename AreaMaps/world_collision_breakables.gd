extends TileMapLayer


@export var health: int = 15



func _init():
	pass


func _process(delta):
	if health <= 0:
		queue_free()


func take_damage(damage, hitbox_position, knockback_speed):
	health -= damage
