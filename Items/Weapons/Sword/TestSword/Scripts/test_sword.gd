extends Node2D


@export var can_attack: bool = true # Controlled by AnimationPlayer
@export var parrying: bool = false # Controlled by AnimationPlayer

@onready var weapon_hitbox := $Sprite/Hitbox
@onready var animation := $AnimationPlayer
@onready var player_reference := $"PlayerReference"



func _ready():
	player_reference.visible = false
	animation.play("Hidden")
	
	#These lines will be redone such that the player node calls an attack function once the hotbar is done (i.e. once we can reliably attempt to call a child's functions).
	owner.Attack1.connect(_on_player_attack_1)
	owner.Attack2.connect(_on_player_attack_2)


func _process(delta):
	pass



#Below functions, as said above, will simply be called from the player node, instead of waiting for signals. Main mechanism stays the same.
##### Attack functions #####
func _on_player_attack_1():
	if can_attack == true:
		if Global.player_facing_direction == -1:
			animation.play("Attack 1 (Right)")
		else:
			animation.play("Attack 1 (Left)")
	else:
		pass


func _on_player_attack_2():
	if can_attack == true:
		if Global.player_facing_direction == -1:
			animation.play("Attack 2 (Right)")
		else:
			animation.play("Attack 2 (Left)")
	else:
		pass


func _on_animation_player_animation_finished(anim_name):
	if "Attack" in anim_name:
		animation.play("Hidden")
