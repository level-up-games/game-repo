extends StaticBody2D


@onready var sprite = $Sprite
@onready var collision := $WorldCollision
@onready var interaction_area := $InteractionZone
@onready var anim_player := $AnimationPlayer

@export var required_item: String = "Apple"
@export var is_locked: bool = true

var player_in_range: bool = false



func _ready() -> void:
	interaction_area.body_entered.connect(_on_body_entered)
	interaction_area.body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node) -> void:
	if body.name == "Player":
		player_in_range = true
		# Optionally show a UI prompt (e.g., "Press E to unlock")
		# This can be done by calling a function on a UI manager.
	

func _on_body_exited(body: Node) -> void:
	if body.name == "Player":
		player_in_range = false
		# Optionally hide the UI prompt.


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("Interact") and is_locked == true and player_in_range == true:
		_try_unlock()


func _try_unlock() -> void:
	# For this placeholder, we check if the player "has" an apple.
	# Assume your Player script has a function "has_item(item_name: String) -> bool".
	var player = get_tree().get_current_scene().get_node("Player")
	if player and player.has_item(required_item) == true:
		_unlock_gate()
	else:
		# Optionally, display a message: "You need an [required_item] to open this gate."
		pass


func _unlock_gate() -> void:
	is_locked = false
	collision.disabled = true
	
	if anim_player and anim_player.has_animation("open"):
		anim_player.play("open")
	else:
		sprite.visible = false
