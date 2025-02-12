extends Area2D


@export_file() var next_scene: String
var start: bool = false
var player: CharacterBody2D



func _ready():
	self.body_entered.connect(_on_body_entered)
	
	collision_layer = 0
	collision_mask = 8


func _process(delta):
	if start == true:
		player.velocity = Vector2.ZERO
		player.suspend_movement_timer = 1
		player.suspend_movement = true
		player.animation_player.play("Idle")
		FadeScreen.fade_transition(4, 4, 0.5, next_scene)


func _on_body_entered(body):
	if body.name == "Player":
		start = true
		player = body
