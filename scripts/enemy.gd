extends CharacterBody2D

var bullet_path = preload("res://scenes/bullet.tscn")
var fire_interval = 5.0
var fire_timer = fire_interval


func _physics_process(delta: float) -> void:
	rotation = 0
	
	fire_timer -= delta
	if fire_timer <= 0:
		fire()
		fire_timer = fire_interval


func fire() -> void:
	var bullet = bullet_path.instantiate()
	bullet.dir = rotation
	bullet.position = $Node2D.position
	bullet.rotation = global_rotation
	get_parent().add_child(bullet)
