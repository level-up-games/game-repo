extends Area2D
class_name DropEnabler


var can_drop: bool = false
var player



func _ready():
	collision_layer = 0
	collision_mask = 8

	self.body_entered.connect(_on_body_entered)
	self.body_exited.connect(_on_body_exited)


func _process(delta):
	if can_drop == true and Input.is_action_pressed("Down") and player.velocity.y == 0:
		player.position.y += 1
	else:
		pass


func _on_body_entered(body):
	if body.name == "Player":
		can_drop = true
		player = body
	else:
		pass


func _on_body_exited(body):
	if body.name == "Player":
		can_drop = false
	else:
		pass
