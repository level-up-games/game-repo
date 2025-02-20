extends CharacterBody2D


##### Reference variables #####
@onready var sprite: Sprite2D = $Sprite2D
@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var interaction_zone: Area2D = $InteractionZone

##### Show dialogue functions #####
@export var npc_name: String = "Villager1"

##### Movement variables #####
@export var is_moving: bool = true
@export var patrol_speed: float = 50.0
@export var patrol_point_a: float = 0
@export var patrol_point_b: float = 200
var moving_towards_a: bool = true
var player_in_range: bool = false
var gravity: float = 4750

##### Dialogue variables #####
@export var dialogue_json_path: String = "res://Characters/NPCs/TestNPC/Data/testNPCdialogue.json"
var dialogue_checkpoint: String = "start"
var in_dialogue: bool = false



##### Regular functions #####
func _ready() -> void:
	set_process_input(true)
	interaction_zone.body_entered.connect(_on_interaction_zone_entered)
	interaction_zone.body_exited.connect(_on_interaction_zone_exited)
	
	#anim_player.play("idle")


func _physics_process(delta: float) -> void:
	velocity.y += gravity * delta
	
	if not in_dialogue and is_moving:
		_patrol(delta)


func _patrol(delta: float) -> void:
	var target = patrol_point_a if moving_towards_a else patrol_point_b
	var direction = sign(target - position.x)
	velocity.x = direction * patrol_speed
	
	if abs(position.x - target) < 5:
		moving_towards_a = !moving_towards_a
	
	if velocity.x < 0:
		sprite.flip_h = true
	elif velocity.x > 0:
		sprite.flip_h = false
	
	move_and_slide()


##### Movement functions #####
func _face_player() -> void:
	if Global.player:
		if Global.player.global_position.x < global_position.x:
			sprite.flip_h = true
		else:
			sprite.flip_h = false


func resume_movement(new_checkpoint: String) -> void:
	dialogue_checkpoint = new_checkpoint
	in_dialogue = false
	#anim_player.play("walk")


##### Input functions #####
func _input(event: InputEvent) -> void:
	if player_in_range and not in_dialogue and Input.is_action_just_pressed("Interact"):
		_on_player_interact()


func _on_player_interact() -> void:
	in_dialogue = true
	velocity.x = 0
	_face_player()
	
	DialogueManager.show_npc_dialogue(dialogue_json_path, self)


func _on_interaction_zone_entered(body: Node) -> void:
	if body.name == "Player":
		# Optionally show a prompt: "Press E to talk"
		player_in_range = true


func _on_interaction_zone_exited(body: Node) -> void:
	if body.name == "Player":
		# Hide prompt if any.
		player_in_range = false
