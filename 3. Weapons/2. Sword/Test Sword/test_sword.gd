extends Node2D


@onready var animation := $AnimationPlayer
@onready var player_reference := $"Player Reference"



func _ready():
	animation.play("Hidden")
	player_reference.visible = false
	owner.Attack1.connect(_on_player_attack_1)
	owner.Attack2.connect(_on_player_attack_2)
	

func _process(delta):
	pass


func _on_player_attack_1():
	if Global.player_facing_direction == -1:
		animation.play("Attack 1 (Right)")
	else:
		animation.play("Attack 1 (Left)")

func _on_player_attack_2():
	if Global.player_facing_direction == -1:
		animation.play("Attack 2 (Right)")
	else:
		animation.play("Attack 2 (Left)")

func _on_animation_player_animation_finished(anim_name):
	if "Attack" in anim_name:
	#if anim_name == "Attack 1 (Right)" or anim_name == "Attack 1 (Left)":
		animation.play("Hidden")
