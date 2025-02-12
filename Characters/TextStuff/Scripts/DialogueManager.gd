extends Node

# Reference to your UI CanvasLayer (or assign it via code).
@export var ui_node_path: NodePath = "/root/AbandonedCity1/Player/UserInterface"

var active_dialogue_box: Control = null


func show_readable_dialogue(dialogue_data: Dictionary) -> void:
	_clear_active_dialogue()
	var box_scene = preload("res://Characters/TextStuff/Scenes/readable_dialogue_box.tscn")
	active_dialogue_box = box_scene.instantiate()
	# Pass dialogue_data to the dialogue box.
	active_dialogue_box.setup(dialogue_data)
	# Add it to your UI (assumes ui_node_path is set to your UI CanvasLayer).
	get_node(ui_node_path).add_child(active_dialogue_box)

func show_npc_dialogue(json_path: String) -> void:
	_clear_active_dialogue()
	var dialogue_data = load_json_dialogue(json_path)
	var box_scene = preload("res://Characters/TextStuff/Scenes/npc_dialogue_box.tscn")
	active_dialogue_box = box_scene.instantiate()
	active_dialogue_box.setup(dialogue_data)
	get_node(ui_node_path).add_child(active_dialogue_box)
	print("aight")

func hide_dialogue() -> void:
	_clear_active_dialogue()

func _clear_active_dialogue() -> void:
	if active_dialogue_box and is_instance_valid(active_dialogue_box):
		active_dialogue_box.queue_free()
	active_dialogue_box = null

func load_json_dialogue(json_path: String) -> Dictionary:
	var file = FileAccess.open(json_path, FileAccess.ModeFlags.READ)
	if file:
		var text = file.get_as_text()
		var json_parser = JSON.new()
		var result = json_parser.parse_string(text)
		#if result.has("error") and result["error"] == OK: ######################
		return result#["data"]
	return {}
