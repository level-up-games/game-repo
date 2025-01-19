extends AudioStreamPlayer2D


##### General variables #####
@onready var player: CharacterBody2D = owner
@onready var sprite: AnimatedSprite2D = $"../../Sprite"

##### Running footstep variables #####
@export var footstep_sounds: Array[AudioStream]
@export var min_velocity: float = 450



func _ready():
	pass 


func _process(delta):
	handle_running()



func handle_running():
	if sprite.animation == "Run" or sprite.animation == "RunMirror":
		if sprite.frame == 2 or sprite.frame == 3 or sprite.frame == 12 or sprite.frame == 13 and playing == false:
			if player.is_on_floor() == false:
				return
		
			if player.velocity.length() < min_velocity:
				return
			
			stream = footstep_sounds[randi() % len(footstep_sounds)]
			play()
