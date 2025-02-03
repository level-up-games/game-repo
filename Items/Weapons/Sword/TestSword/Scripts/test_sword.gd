extends Node2D


@export var can_attack: bool = true # Controlled by AnimationPlayer
@export var parrying: bool = false # Controlled by AnimationPlayer

@onready var weapon_hitbox := $Sprite/Hitbox
@onready var animation := $AnimationPlayer
@onready var player_reference := $"PlayerReference"



func _ready():
	player_reference.visible = false
	animation.play("Hidden")
	
	Global.player.Attack1.connect(_on_player_attack_1)
	Global.player.Attack2.connect(_on_player_attack_2)


func _process(delta):
	pass


##### Attack functions #####
func _on_player_attack_1():
	if can_attack == true:
		weapon_hitbox.damage_dealt = weapon_hitbox.set_damage_dealt + randi_range(-1, 1)
		if Global.player_facing_direction == -1:
			animation.play("Attack 1 (Right)")
		else:
			animation.play("Attack 1 (Left)")
	else:
		pass


func _on_player_attack_2():
	if can_attack == true:
		weapon_hitbox.damage_dealt = weapon_hitbox.set_damage_dealt + 5 + randi_range(-2, 2)
		if Global.player_facing_direction == -1:
			animation.play("Attack 2 (Right)")
		else:
			animation.play("Attack 2 (Left)")
	else:
		pass


func _on_animation_player_animation_finished(anim_name):
	if "Attack" in anim_name:
		animation.play("Hidden")
