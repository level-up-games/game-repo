extends Area2D

var player_in_range: bool = false
var dialogue_open: bool = false

var do_once = true

func _ready() -> void:
	# Connect the area signals
	self.body_entered.connect(_on_body_entered)
	self.body_exited.connect(_on_body_exited)

	
func _on_body_entered(body: Node) -> void:
	if body.name == "Player":
		player_in_range = true
		# Optionally: show a visual cue like an icon indicating "Press E"
	
func _on_body_exited(body: Node) -> void:
	if body.name == "Player":
		player_in_range = false


func _input(event: InputEvent) -> void:
	# When the player presses the interact button and is in range…
	if player_in_range and Input.is_action_just_pressed("Interact"):
		do_once = false
		DialogueManager.show_npc_dialogue("res://Characters/testNPCdialogue.json")
