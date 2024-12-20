extends Area2D
class_name HostileHurtbox



func _init():
	collision_layer = 0
	collision_mask = 64


func _ready():
	connect("area_entered", _on_area_entered)


func _on_area_entered(hitbox: PlayerHitbox):
	if hitbox == null:
		return
	
	if owner.has_method("take_damage"):
		owner.take_damage(hitbox.damage_dealt, hitbox.hitbox_position, hitbox.knockback_speed)
