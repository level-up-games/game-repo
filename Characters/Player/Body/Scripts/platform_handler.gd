extends Area2D


@onready var player = get_parent()
var can_drop: bool = false



func _ready():
	collision_layer = 8
	collision_mask = 8192
	
	self.body_entered.connect(_on_body_entered)
	self.body_exited.connect(_on_body_exited)


func _physics_process(delta):
	if can_drop == true and Input.is_action_pressed("Down") and player.velocity.y == 0: # TODO: fix diagonal dodgyness - because of worldcollision hitboxes changing
		player.position.y += 3
	else:
		pass


func _on_body_entered(body):
	if body.name == "WorldCollision":
		can_drop = true


func _on_body_exited(body):
	if body.name == "WorldCollision":
		can_drop = false
