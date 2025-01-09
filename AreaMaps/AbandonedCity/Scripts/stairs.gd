extends Area2D


@export var destination: Area2D

var can_interact: bool = false
var moving: bool = false
var player
var cooldown: float = -1.0


func _ready():
	collision_layer = 4096
	collision_mask = 8

	self.body_entered.connect(_on_body_entered)
	self.body_exited.connect(_on_body_exited)


func _physics_process(delta):
	cooldown -= delta
	
	if can_interact == true and Input.is_action_just_pressed("Interact") and cooldown <= 0:
		cooldown = 0.5
		player.global_position = global_position
		player.velocity = Vector2(0,0)
		moving = true
		
	move_to_destination(delta)
	

func move_to_destination(delta):
	if moving == true:
		player.suspend_movement = true
		player.suspend_movement_timer = 5
		player.suspend_gravity = true
		player.visible = false
		player.collision_mask = 0
		
		player.get_node("Rays/GroundRay").collision_mask = 0
		player.get_node("Rays/CeilingRay").collision_mask = 0
		player.get_node("Rays/WallRayLeft").collision_mask = 0
		player.get_node("Rays/WallRayRight").collision_mask = 0
		var camera = player.get_node("PlayerCamera")
		camera.change_limits(-999999999, 99999999, -99999999, 99999999)

		player.global_position.x = move_toward(player.global_position.x, destination.global_position.x, 2500 * delta)
		player.global_position.y = move_toward(player.global_position.y, destination.global_position.y, 2500 * delta)
		
		if destination.can_interact == true:
			destination.cooldown = 0.5
			
			moving = false
			player.global_position = destination.global_position
			await get_tree().create_timer(0.05).timeout
			player.suspend_movement = false
			player.suspend_gravity = false
			player.visible = true
			player.collision_mask = 1
			
			player.get_node("Rays/GroundRay").collision_mask = 256
			player.get_node("Rays/CeilingRay").collision_mask = 512
			player.get_node("Rays/WallRayLeft").collision_mask = 1024
			player.get_node("Rays/WallRayRight").collision_mask = 2048


func _on_body_entered(body):
	if body.name == "Player":
		can_interact = true
		player = body
	else:
		pass


func _on_body_exited(body):
	if body.name == "Player":
		can_interact = false
	else:
		pass
