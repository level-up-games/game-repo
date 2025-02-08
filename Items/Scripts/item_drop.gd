extends CharacterBody2D


const SPEED = 2000.0
const ACCELERATION = 10000

@onready var vis_notifier: VisibleOnScreenNotifier2D = $VisibleOnScreenNotifier

@export var item_name = ""
@export var item_quantity = 1

var player: CharacterBody2D = null
var being_picked_up = false



func _ready():
	vis_notifier.screen_entered.connect(_on_screen_entered)
	vis_notifier.screen_exited.connect(_on_screen_exited)
	
	if item_name != "":
		$Sprite2D.texture = load(Global.item_data[item_name]["texture_path"])


func _physics_process(delta: float) -> void:
	if being_picked_up == true:
		var direction = global_position.direction_to(player.global_position)
		velocity = velocity.move_toward(direction * SPEED, ACCELERATION * delta)
		
		var distance = global_position.distance_to(player.global_position)
		if distance < 50:
			Global.add_item(item_name, item_quantity)
			queue_free()
	move_and_slide()


func pick_up_item(body) -> void:
	player = body
	being_picked_up = true


func _on_screen_exited() -> void:
	set_process(false)
	set_physics_process(false)

func _on_screen_entered() -> void:
	set_process(true)
	set_physics_process(true)
