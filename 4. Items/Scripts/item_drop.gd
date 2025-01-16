extends CharacterBody2D


const SPEED = 2000.0
const ACCELERATION = 10000

var item_name
var item_quantity  # TODO: do this

var player: CharacterBody2D = null
var being_picked_up = false


func _ready() -> void:
	item_name = "Coin"


# TODO: refactor to a base class
func _physics_process(delta: float) -> void:
	if being_picked_up == true:
		var direction = global_position.direction_to(player.global_position + Vector2(0, -90))
		velocity = velocity.move_toward(direction * SPEED, ACCELERATION * delta)
		# TODO: maybe go directly to spot no matter what
		
		var distance = global_position.distance_to(player.global_position + Vector2(0, -90))
		if distance < 50:  # TODO: maybe find better number
			Global.add_item(item_name, 1)  # TODO: maybe change num when picking up stack?
			queue_free()
	move_and_slide()


func pick_up_item(body) -> void:
	player = body
	being_picked_up = true
