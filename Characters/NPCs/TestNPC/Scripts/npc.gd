extends CharacterBody2D
class_name NPC


var player_in_range: bool = false



# Unique identifier for this NPC (used to track dialogue checkpoints).
@export var npc_name: String = "Villager1"

# Dialogue JSON path for this NPC's conversation.
@export var dialogue_json_path: String = "res://Characters/testNPCdialogue.json"

# Whether this NPC should move (patrol) or remain static.
@export var is_moving: bool = true

# Patrol settings (if is_moving is true).
@export var patrol_speed: float = 50.0
@export var patrol_point_a: Vector2 = Vector2.ZERO
@export var patrol_point_b: Vector2 = Vector2(200, 0)

# Internal state for patrol movement.
var moving_towards_a: bool = true

# Dialogue checkpoint; can be stored here (or you can use a global dictionary keyed by npc_name).
var dialogue_checkpoint: String = "start"

# A flag to indicate if the NPC is currently in dialogue (and thus should stop moving).
var in_dialogue: bool = false

# Cached references:
@onready var sprite: Sprite2D = $Sprite2D
@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var interaction_zone: Area2D = $InteractionZone

func _ready() -> void:
	
	
	DialogueManager.npc = self
	
	set_process_input(true)
	interaction_zone.body_entered.connect(_on_interaction_zone_entered)
	interaction_zone.body_exited.connect(_on_interaction_zone_exited)
	
	
	# Optionally set the NPC's starting position to patrol_point_a.
	position = patrol_point_a
	# Connect signals for interaction zone.
	interaction_zone.body_entered.connect(_on_interaction_zone_entered)
	interaction_zone.body_exited.connect(_on_interaction_zone_exited)
	
	# Set a default animation.
	anim_player.play("idle")

func _physics_process(delta: float) -> void:
	
	print(in_dialogue)
	
	
	
	
	if not in_dialogue and is_moving:
		_patrol(delta)
	# Optionally, update other behavior (e.g., turning to face the player if near)

func _patrol(delta: float) -> void:
	# Simple linear interpolation between two patrol points.
	var target = patrol_point_a if moving_towards_a else patrol_point_b
	var direction = (target - position).normalized()
	velocity = direction * patrol_speed
	move_and_slide()
	
	# Flip sprite based on horizontal direction (for example).
	if velocity.x < 0:
		sprite.flip_h = true
	elif velocity.x > 0:
		sprite.flip_h = false
	
	# When near the target, switch direction.
	if position.distance_to(target) < 5:
		moving_towards_a = !moving_towards_a



func _input(event: InputEvent) -> void:
	if player_in_range and not in_dialogue and Input.is_action_just_pressed("Interact"):
		_on_player_interact()





func _on_interaction_zone_entered(body: Node) -> void:
	if body.name == "Player":
		# Optionally show a prompt: "Press E to talk"
		player_in_range = true

func _on_interaction_zone_exited(body: Node) -> void:
	if body.name == "Player":
		# Hide prompt if any.
		player_in_range = false

func _on_player_interact() -> void:
	# Called when the player presses interact while in range.
	# Stop movement and face the player.
	in_dialogue = true
	velocity = Vector2.ZERO
	_face_player()
	
	# Launch dialogue via DialogueManager.
	DialogueManager.show_npc_dialogue(dialogue_json_path, npc_name)
	# DialogueManager should use npc_name to look up any saved checkpoint.
	# Optionally, you can pause NPC movement here.

func _face_player() -> void:
	# Assuming you can get the player's position from Global.player
	if Global.player:
		if Global.player.global_position.x < global_position.x:
			sprite.flip_h = false  # Face left
		else:
			sprite.flip_h = true   # Face right

# This function should be called by the DialogueManager when the conversation ends.
func resume_movement(new_checkpoint: String) -> void:
	# Update dialogue checkpoint based on conversation progression.
	dialogue_checkpoint = new_checkpoint
	in_dialogue = false
	anim_player.play("walk")  # Resume a walking animation if desired.
