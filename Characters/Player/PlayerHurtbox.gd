extends Area2D
class_name PlayerHurtbox



func _init():
	collision_layer = 0
	collision_mask = 2


func _ready():
	connect("area_entered", _on_area_entered)


func _on_area_entered(hitbox: HostileHitbox):
	if hitbox == null:
		return
	
	if owner.has_method("take_damage"):
		owner.take_damage(hitbox.damage_dealt, hitbox.hitbox_position, hitbox.knockback_speed)
		if hitbox.owner.has_method("handle_hit_bounce"):
			hitbox.owner.bouncing = true
