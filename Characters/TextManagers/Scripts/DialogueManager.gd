extends Node


var ui: CanvasLayer
var active_dialogue_box: Control = null



##### Dialogue functions #####
func show_readable_dialogue(dialogue_data: Dictionary) -> void:
	_clear_active_dialogue()
	var box_scene = preload("res://Characters/TextManagers/Scenes/readable_dialogue_box.tscn")
	active_dialogue_box = box_scene.instantiate()
	active_dialogue_box.setup(dialogue_data)
	ui.add_child(active_dialogue_box)


func show_npc_dialogue(json_path: String, npc_ref: Node) -> void:
	_clear_active_dialogue()
	var dialogue_data = load_json_dialogue(json_path)
	var box_scene = preload("res://Characters/TextManagers/Scenes/npc_dialogue_box.tscn")
	active_dialogue_box = box_scene.instantiate()
	var checkpoint = Global.npc_dialogue_checkpoints.get(npc_ref.npc_name, "start")
	active_dialogue_box.setup(dialogue_data, checkpoint, npc_ref)
	ui.add_child(active_dialogue_box)


func _clear_active_dialogue() -> void:
	if active_dialogue_box and is_instance_valid(active_dialogue_box):
		active_dialogue_box.queue_free()
	active_dialogue_box = null


##### Data functions #####
func load_json_dialogue(json_path: String) -> Dictionary:
	var file = FileAccess.open(json_path, FileAccess.ModeFlags.READ)
	
	if file:
		var text = file.get_as_text()
		var json_parser = JSON.new()
		var result = json_parser.parse_string(text)
		return result
	
	return {}
