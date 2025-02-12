extends StaticBody2D


@export var sprite: Sprite2D
@export var area: Area2D

var breaking: bool = false
var regen: bool = false
var in_platform = false
var player: CharacterBody2D

@export var break_time: float = 0.5
@export var regen_time: float = 3.0

var breaking_timer: float
var regen_timer: float



func _ready():
	area.collision_layer = 0
	area.collision_mask = 8
	
	collision_layer = 1
	collision_mask = 0
	
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)


func _physics_process(delta):
	if breaking_timer > -5:
		breaking_timer -= delta
	if regen_timer > -5:
		regen_timer -= delta
	
	if breaking == true:
		if breaking_timer <= 0:
			collision_layer = 0
			collision_mask = 0
			sprite.visible = false
			regen_timer = regen_time
			regen = true
	
	if regen == true:
		breaking = false
		if regen_timer <= 0 and in_platform == false:
			regen = false
			collision_layer = 1
			collision_mask = 0
			sprite.visible = true
		else:
			pass


func _on_body_entered(body):
	if body.name == "Player":
		breaking_timer = break_time
		player = body
		in_platform = true
		breaking = true


func _on_body_exited(body):
	if body.name == "Player":
		in_platform = false
