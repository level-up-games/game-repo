extends Panel


var npc_id: String = ""  # This should be set during setup.
var dialogue_data: Dictionary = {}
var current_node_key: String = "start"

var typewriter_index: int = 0
var typewriter_full_text: String = ""
var typewriter_timer: Timer = null



func setup(data: Dictionary, checkpoint, npc) -> void:
	npc_id = npc
	dialogue_data = data
	current_node_key = checkpoint
	_display_current_node()
	# add checkpoints, where a global is used to check whether to go to start or a diff place (based on checkpoint).
	# do a similar thing to the above, but checks location/progression to see where to talk from, as adjusted in the npc's scene (export?) i.e. if in_house == true...


func _display_current_node() -> void:
	if not dialogue_data.has(current_node_key):
		push_error("Dialogue node '" + current_node_key + "' not found. Available keys: " + str(dialogue_data.keys()))
		queue_free()
		return
	
	var node_data = dialogue_data[current_node_key]
	
	
	
	 #   // **Update the checkpoint if defined:**
	if node_data.has("checkpoint"):
		Global.npc_dialogue_checkpoints[npc_id] = node_data["checkpoint"]
	
	if node_data.has("action"):
		var action_callable = Callable(DialogueManager, node_data["action"])
		if action_callable.is_valid():
			action_callable.call()
	
	if node_data.has("portrait"):
		$NPCPortrait.texture = load(node_data["portrait"])
	
	_type_text(node_data.get("text", ""))
	
	_populate_options(node_data)


func _type_text(full_text: String) -> void:
	$DialogueText.clear()
	$DialogueText.parse_bbcode("")
	typewriter_full_text = full_text
	typewriter_index = 0
	
	typewriter_timer = Timer.new()
	typewriter_timer.wait_time = 0.03  # Adjust speed as desired.
	typewriter_timer.one_shot = false
	add_child(typewriter_timer)
	typewriter_timer.timeout.connect(_on_typewriter_timeout)
	typewriter_timer.call_deferred("start")


func _on_typewriter_timeout() -> void:
	if typewriter_timer == null:
		return
	
	typewriter_index += 1
	
	$DialogueText.parse_bbcode(typewriter_full_text.substr(0, typewriter_index))
	
	if typewriter_index >= typewriter_full_text.length():
		typewriter_timer.stop()
		typewriter_timer.queue_free()
		typewriter_timer = null


func _populate_options(node_data: Dictionary) -> void:
	for child in $OptionsContainer.get_children():
		child.queue_free()
	
	if node_data.has("options"):
		for option in node_data["options"]:
			var btn = Button.new()
			btn.text = option["text"]
			btn.connect("pressed", Callable(self, "_on_option_selected").bind(option))
			$OptionsContainer.add_child(btn)
	else:
		var btn = Button.new()
		btn.text = "Continue"
		btn.connect("pressed", Callable(self, "_advance_dialogue"))
		$OptionsContainer.add_child(btn)


func _on_option_selected(option: Dictionary) -> void:
	if option.has("action"):
		# e.g., call a function on a game manager.
		print("calls action now or something thru gamemanager")
	
	if option.has("next"):
		current_node_key = option["next"]
	else:
		current_node_key = ""
	
	_display_current_node()


func _advance_dialogue() -> void:
	# For nodes without options, use a "continue" button.
	var node_data = dialogue_data[current_node_key]
	
	if node_data.has("next"):
		current_node_key = node_data["next"]
	else:
		current_node_key = ""
	
	_display_current_node()


func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("Interact") and $OptionsContainer.get_child_count() == 0:
		_advance_dialogue()
