extends StaticBody2D


var timer = 1.0
@onready var bullet = preload("res://Enemies/Non-bosses/AbandonedCity/Testers/Scenes/test_projectile.tscn")



func _ready():
	pass



func _process(delta):
	timer -= delta
	if timer < 0:
		add_child(bullet.instantiate())
		timer = 1
