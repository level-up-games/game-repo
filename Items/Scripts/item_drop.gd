extends CharacterBody2D

@onready var vis_notifier: VisibleOnScreenNotifier2D = $VisibleOnScreenNotifier
@onready var player: CharacterBody2D = Global.player
@onready var label: Label = $LabelDetection/Label
@onready var label_detection: Area2D = $LabelDetection

@export var floating: bool = false
@export var max_fall_speed: float = 1000
@export var fall_gravity: float = 1000
@export var resistance: float = 500
const SPEED = 2000.0
const ACCELERATION = 10000

@export var item_name = ""
@export var item_quantity = 1
@export var bounce_on_spawn: bool = true
var being_picked_up = false
var floating_texts = {}

func _ready():
	vis_notifier.screen_entered.connect(_on_screen_entered)
	vis_notifier.screen_exited.connect(_on_screen_exited)
	
	if item_name != "":
		$Sprite2D.texture = load(Global.item_data[item_name]["texture_path"])
		label.text = "%s" % item_name
	
	if bounce_on_spawn == true:
		var angle = randf() * PI
		velocity = Vector2(200, 0).rotated(angle) + Vector2(0, -150)

func _physics_process(delta: float) -> void:
	handle_item_pick_up(delta)
	handle_gravity(delta)
	handle_movement(delta)
	
	move_and_slide()

func pick_up_item(body) -> void:
	player = body
	being_picked_up = true

	if floating_texts.has(item_name):
		var existing_label = floating_texts[item_name]
		existing_label.item_quantity += item_quantity
		existing_label.update_text()
	else:
		var floating_text_scene = preload("res://Items/Scenes/FloatingText.tscn")
		var floating_text = floating_text_scene.instantiate() as Label
		
		floating_text.item_name = item_name
		floating_text.item_quantity = item_quantity
		floating_text.update_text()
		
		var label_count = 0
		for child in player.get_children():
			if child is Label:
				label_count += 1
		
		var vertical_offset = -floating_text.size.y - (label_count * (floating_text.size.y))
		floating_text.global_position = player.global_position + Vector2(-40, vertical_offset - 200)
		
		player.add_child(floating_text)
		floating_texts[item_name] = floating_text
		
		await get_tree().create_timer(2.0).timeout
		floating_texts.erase(item_name)
		floating_text.queue_free()

func handle_item_pick_up(delta):
	if being_picked_up == true:
		var direction = global_position.direction_to(player.global_position + Vector2(0, -100))
		velocity = velocity.move_toward(direction * SPEED, ACCELERATION * delta)
		
		var distance = global_position.distance_to(player.global_position + Vector2(0, -100))
		if distance < 50:
			Global.add_item(item_name, item_quantity)
			queue_free()

func handle_gravity(delta):
	if velocity.y < max_fall_speed and floating == false and being_picked_up == false:
		velocity.y += fall_gravity * delta

func handle_movement(delta):
	velocity.x = move_toward(velocity.x, 0, resistance * delta)

func _on_screen_exited() -> void:
	set_process(false)
	set_physics_process(false)

func _on_screen_entered() -> void:
	set_process(true)
	set_physics_process(true)

func _on_label_detection_mouse_entered() -> void:
	label.visible = true

func _on_label_detection_mouse_exited() -> void:
	label.visible = false
