extends Area2D

var player_in_range: bool = false
var dialogue_open: bool = false

@export var npc: bool = true



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
	if npc == true:
		if player_in_range and Input.is_action_just_pressed("Interact"):
			DialogueManager.show_npc_dialogue("res://Characters/testNPCdialogue.json", "john apple")
	else:
		if player_in_range and Input.is_action_just_pressed("Interact"):
			DialogueManager.show_readable_dialogue({"text": "This is an ancient rune inscribed with cryptic symbols."})
