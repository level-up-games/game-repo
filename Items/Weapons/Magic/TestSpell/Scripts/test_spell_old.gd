extends Weapon
#class_name MagicWeapon


# Exported sequence: each element is a string representing the required input.
@export var charge_sequence: Array = ["Attack1", "Attack2", "Attack3", "Attack1", "Attack1", "Attack4"]

# Optional: Maximum allowed charge time (in seconds). (Not used for failure here, but can be for damage scaling.)
@export var max_charge_time: float = 3.0

# Variables to track charging progress.
var is_charging: bool = false
var current_charge_index: int = 0
var charge_start_time: float = 0.0
var error_count: int = 0

# We'll track the total charge time for potential damage scaling.
var total_charge_time: float = 0.0

# References to UI nodes (assumed to be children of this weapon scene)
@onready var charge_bar: ProgressBar = $ChargeBar
@onready var icon_container: HBoxContainer = $InputIconContainer
@onready var anim_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	# Connect player's attack signals to the magic weapon's input handler.
	# Assuming the player node is accessible (e.g., via Global.player).
	Global.player.Attack1.connect(func() -> void: on_attack_input("Attack1"))
	Global.player.Attack2.connect(func() -> void: on_attack_input("Attack2"))
	Global.player.Attack3.connect(func() -> void: on_attack_input("Attack3"))
	Global.player.Attack4.connect(func() -> void: on_attack_input("Attack4"))
	
	charge_bar.visible = false
	icon_container.visible = false
	_initialize_input_icons()

# This function initializes the icon container based on the charge sequence.
func _initialize_input_icons() -> void:
	for child in icon_container.get_children():
		icon_container.remove_child(child)  # if using Godot 4's new API, or remove existing children manually. ########################################
		
	for step in charge_sequence:
		var lbl = Label.new()
		lbl.text = step  # e.g. "Attack1"
		lbl.add_theme_color_override("font_color", Color.WHITE)
		icon_container.add_child(lbl)
	_update_input_icons()

# This function updates which icon is “active” (expected next input).
func _update_input_icons() -> void:
	for i in range(icon_container.get_child_count()):
		var lbl = icon_container.get_child(i) as Label
		if i == current_charge_index:
			lbl.add_theme_color_override("font_color", Color.YELLOW)  # active input
		else:
			lbl.add_theme_color_override("font_color", Color.WHITE)

# This function is called by the player when an attack input is detected.
# You can connect the player's Attack1, Attack2, etc. signals to call this function with the action name.
func on_attack_input(action_name: String) -> void:
	if not is_charging:
		_start_charging()
	
	if is_fully_charged():
		# If already charged, cast the spell.
		_cast_spell()
	else:
		# Check if the input matches the expected step.
		var expected = charge_sequence[current_charge_index]
		if action_name == expected:
			# Correct input: advance the sequence.
			current_charge_index += 1
			_update_charge_bar()
			_update_input_icons()
			if current_charge_index >= charge_sequence.size():
				# Fully charged!
				#total_charge_time = (OS.get_ticks_msec() / 1000.0) - charge_start_time ###########################################
				charge_bar.value = charge_bar.max_value
				# Optionally provide visual feedback (e.g., flash the bar).
		else:
			# Input error: flash the current icon red.
			_flash_error_on_icon(current_charge_index)
			error_count += 1
			# The player must release inputs and retry this step.
			# (You might want to ignore further inputs until buttons are released; for simplicity, we just flash.)

func _start_charging() -> void:
	is_charging = true
	current_charge_index = 0
	error_count = 0
	#charge_start_time = OS.get_ticks_msec() / 1000.0 ##############################################
	charge_bar.value = 0
	charge_bar.visible = true
	icon_container.visible = true
	_update_input_icons()

func _update_charge_bar() -> void:
	var progress = float(current_charge_index) / float(charge_sequence.size())
	charge_bar.value = progress * charge_bar.max_value

func _flash_error_on_icon(index: int) -> void:
	if index < icon_container.get_child_count():
		var lbl = icon_container.get_child(index) as Label
		lbl.add_theme_color_override("font_color", Color.RED)
		# Create a timer to reset the color after 0.3 seconds.
		var tmr = Timer.new()
		tmr.wait_time = 0.3
		tmr.one_shot = true
		add_child(tmr)
		tmr.timeout.connect(func():
			lbl.add_theme_color_override("font_color", Color.YELLOW))
		tmr.start()

func is_fully_charged() -> bool:
	return current_charge_index >= charge_sequence.size()

# This function is called to cast the spell once the weapon is charged.
func _cast_spell() -> void:
	# For testing, we will instantiate a projectile that is fired toward the cursor.
	var projectile_scene = preload("res://Items/Weapons/Magic/TestSpell/Scenes/test_spell_projectile.tscn")
	var projectile = projectile_scene.instantiate()
	projectile.global_position = global_position  # or wherever you want it to originate from
	var target = get_global_mouse_position()
	var dir = (target - global_position).normalized()
	# Assume the projectile script has a "velocity" variable.
	projectile.velocity = dir * 300  # adjust as needed
	get_tree().get_current_scene().add_child(projectile)
	
	# (Optional) Adjust damage based on total_charge_time and error_count.
	
	_reset_charging()

func _reset_charging() -> void:
	is_charging = false
	current_charge_index = 0
	error_count = 0
	charge_bar.visible = false
	icon_container.visible = false
	charge_bar.value = 0
