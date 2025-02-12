extends Area2D

@export var dialogue_text: String = "This is some mysterious text..."
var player_in_range: bool = false
var dialogue_open: bool = false

# Reference to your DialogueBox. Adjust the node path as needed.
@onready var dialogue_box = get_node("../Player/UserInterface/DialogueBox")

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
		if dialogue_open:
			_close_dialogue()

func _input(event: InputEvent) -> void:
	# When the player presses the interact button and is in range…
	if player_in_range and Input.is_action_just_pressed("Interact"):
		if dialogue_open:
			_close_dialogue()
		else:
			_open_dialogue()

func _open_dialogue() -> void:
	dialogue_open = true
	# Call the dialogue box’s function to show text.
	dialogue_box.show_dialogue(dialogue_text)

func _close_dialogue() -> void:
	dialogue_open = false
	dialogue_box.hide_dialogue()
