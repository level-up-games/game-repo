extends CharacterBody2D



func _ready():
	$HostileHitbox.parried.connect(_on_parried)


func _physics_process(delta):
	velocity.x = 1400
	move_and_slide()


func _on_parried():
	$HostileHitbox.damage_dealt = 0
	modulate = Color(1,1,0)
