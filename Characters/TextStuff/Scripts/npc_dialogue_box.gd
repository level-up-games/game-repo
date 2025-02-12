extends Panel

@onready var npc_portrait: TextureRect = $NPCPortrait
@onready var dialogue_text: RichTextLabel = $DialogueText
@onready var options_container: VBoxContainer = $OptionsContainer

var dialogue_data: Dictionary = {}
var current_node_key: String = "start"


var typewriter_index: int = 0
var typewriter_full_text: String = ""
var typewriter_timer: Timer = null











func setup(data: Dictionary) -> void:
	dialogue_data = data
	current_node_key = "start"
	_display_current_node()
	print("aight but the better aight")

func _display_current_node() -> void:
	if not dialogue_data.has(current_node_key): ###############################################
		push_error("Dialogue node '" + current_node_key + "' not found. Available keys: " + str(dialogue_data.keys()))
		queue_free()
		return
	
	var node_data = dialogue_data[current_node_key]
	# Set NPC portrait if available.
	if node_data.has("portrait"):
		$NPCPortrait.texture = load(node_data["portrait"])
	
	print("Displaying node '", current_node_key, "' with text: '", node_data.get("text", ""), "'")
	
	
	
	# Start the typewriter effect for dialogue text.
	_type_text(node_data.get("text", ""))
	# Populate options if they exist.
	_populate_options(node_data)

func _type_text(full_text: String) -> void:
	$DialogueText.clear()  # Clear previous text.
	$DialogueText.parse_bbcode("")  # Ensure it’s empty.
	typewriter_full_text = full_text
	typewriter_index = 0

	# Create a new Timer to drive the typewriter effect.
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
	# Update the text to show the substring from 0 to typewriter_index.
	$DialogueText.parse_bbcode(typewriter_full_text.substr(0, typewriter_index))
	# Optionally, you can call dialogue_text.update() here if needed.
	
	if typewriter_index >= typewriter_full_text.length():
		typewriter_timer.stop()
		typewriter_timer.queue_free()
		typewriter_timer = null








func _populate_options(node_data: Dictionary) -> void:
	# Clear previous options.
	for child in $OptionsContainer.get_children():
		child.queue_free()
	if node_data.has("options"):
		for option in node_data["options"]:
			var btn = Button.new()
			btn.text = option["text"]
			btn.connect("pressed", Callable(self, "_on_option_selected").bind(option)) ################# changed
			$OptionsContainer.add_child(btn)
	else:
		# If no options, add a default "Continue" button.
		var btn = Button.new()
		btn.text = "Continue"
		btn.connect("pressed", Callable(self, "_advance_dialogue")) ####################### changed
		$OptionsContainer.add_child(btn)

func _on_option_selected(option: Dictionary) -> void:
	# Optionally, if the option has an action to trigger, call it.
	if option.has("action"):
		# e.g., call a function on a game manager.
		print("calls action now or something thru gamemanager")
		#GameManager.call(option["action"]) #############################################################
	# Then advance the dialogue:
	if option.has("next"):
		current_node_key = option["next"]
	else:
		# If no "next" is defined, end dialogue.
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
	# Optionally, allow closing the dialogue with a key (if no options are shown).
	if Input.is_action_just_pressed("Interact") and options_container.get_child_count() == 0:
		_advance_dialogue()
