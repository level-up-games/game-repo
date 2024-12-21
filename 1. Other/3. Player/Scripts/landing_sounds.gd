extends AudioStreamPlayer2D


##### General variables #####
@onready var player: CharacterBody2D = owner
@onready var sprite: AnimatedSprite2D = $"../../Sprite"

##### Jumping variables #####
var was_on_floor: bool = true
var previous_jump_velocity: float
@export var landing_sounds: Array[AudioStream]



func _ready():
	pass


func _process(delta):
	handle_landing()



func handle_landing():
	if was_on_floor == false and player.is_on_floor() == true and previous_jump_velocity > 1000:
		volume_db = 3
		stream = landing_sounds[randi() % len(landing_sounds)]
		play()
	was_on_floor = player.is_on_floor()
	previous_jump_velocity = player.velocity.y
