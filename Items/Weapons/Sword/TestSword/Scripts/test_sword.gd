extends Weapon


@export var parrying: bool = false # Controlled by AnimationPlayer

@onready var weapon_hitbox := $Sprite/Hitbox
@onready var animation := $AnimationPlayer
@onready var player_reference := $"PlayerReference"



func _ready():
	player_reference.visible = false
	animation.play("Hidden")


func _on_attack1():
	if can_attack == true:
		weapon_hitbox.damage_dealt = weapon_hitbox.set_damage_dealt + randi_range(-1, 1)
		if Global.player_facing_direction == -1:
			animation.play("Attack 1 (Right)")
		else:
			animation.play("Attack 1 (Left)")


func _on_attack2():
	if can_attack == true:
		weapon_hitbox.damage_dealt = weapon_hitbox.set_damage_dealt + 5 + randi_range(-2, 2)
		if Global.player_facing_direction == -1:
			animation.play("Attack 2 (Right)")
		else:
			animation.play("Attack 2 (Left)")


func _on_animation_player_animation_finished(anim_name):
	if "Attack" in anim_name:
		animation.play("Hidden")
