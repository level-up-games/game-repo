extends Area2D
class_name HostileHitbox


signal parried
signal broken_parry


@export var can_be_parried: bool = false
@export var knockback_speed: float = 750.0
@export var damage_dealt: int = 10
var hitbox_position: Vector2



func _init():
	collision_layer = 2
	collision_mask = 64
	
	self.area_entered.connect(_on_area_entered)


func _process(delta):
	hitbox_position = global_position


func _on_area_entered(player_hitbox):
	if can_be_parried == true and player_hitbox.get_parent().get_parent().parrying == true:
		emit_signal("parried")
		print("parry")
	elif can_be_parried == false and player_hitbox.get_parent().get_parent().parrying == true:
		emit_signal("broken_parry")
		print("broken_parry")
	else:
		pass
