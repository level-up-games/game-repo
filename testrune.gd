extends CharacterBody2D


var player_in_range: bool = false
var dialogue_open: bool = false

@export var npc: bool = true



func _ready() -> void:
	set_process_input(true)
	
	$Area2D.body_entered.connect(_on_body_entered)
	$Area2D.body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node) -> void:
	if body.name == "Player":
		player_in_range = true
		# Optionally: show a visual cue like an icon indicating "Press E"


func _on_body_exited(body: Node) -> void:
	if body.name == "Player":
		player_in_range = false
		if dialogue_open == true:
			pass


func _input(event: InputEvent) -> void:
	if player_in_range and Input.is_action_just_pressed("Interact"):
		if dialogue_open == false:
			DialogueManager.show_readable_dialogue({"text": "This is an ancient rune inscribed with cryptic symbols."})
			dialogue_open = true
		else:
			dialogue_open = false
