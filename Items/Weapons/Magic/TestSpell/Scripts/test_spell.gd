extends Weapon
class_name MagicWeapon


##### Sequence variables #####
# Define the charge sequence as an array of dictionaries.
# For a click step: type "click"
# For a hold step: type "hold" with a "marker" (fraction of the bar)
@export var charge_sequence: Array = [
	{"action": "Attack1", "type": "click"},
	{"action": ["Attack1", "Attack2"], "type": "click"},
	{"action": "Attack2", "type": "hold", "marker": 0.5},
	{"action": "Attack3", "type": "click"},
	{"action": "Attack4", "type": "hold", "marker": 0.8}
]

@export var multi_input_timeout_duration: float = 0.15  # Seconds allowed between inputs for a multi-input step.
var multi_input_buffer: Array = []
var multi_input_elapsed: float = 0.0

##### Spell charging state variables #####
var is_charging: bool = false
var current_charge_index: int = 0
var error_count: int = 0
var charge_start_time: float = 0.0
var total_charge_time: float = 0.0

##### Hold step variables #####
@export var hold_max_time: float = 1.25
@export var hold_tolerance: float = 0.1 # Tolerance defined as a percentage.
var is_holding: bool = false
var hold_elapsed: float = 0.0
var current_hold_action: String = ""

##### Node reference variables #####
@onready var charge_bar: ProgressBar = Global.spell_bar
@onready var hold_bar: ProgressBar = $HoldBar
@onready var icon_container: HBoxContainer = $InputIconContainer
@onready var anim_player: AnimationPlayer = $AnimationPlayer



func _ready() -> void:
	Global.player.Attack1.connect(func(): on_attack_input("Attack1", true))
	Global.player.Attack1_released.connect(func(): on_attack_input("Attack1", false))
	Global.player.Attack2.connect(func(): on_attack_input("Attack2", true))
	Global.player.Attack2_released.connect(func(): on_attack_input("Attack2", false))
	Global.player.Attack3.connect(func(): on_attack_input("Attack3", true))
	Global.player.Attack3_released.connect(func(): on_attack_input("Attack3", false))
	Global.player.Attack4.connect(func(): on_attack_input("Attack4", true))
	Global.player.Attack4_released.connect(func(): on_attack_input("Attack4", false))
	
	hold_bar.visible = false
	icon_container.visible = false
	_initialize_input_icons()


func _process(delta: float) -> void:
	if is_charging and current_charge_index < charge_sequence.size():
		var current_step = charge_sequence[current_charge_index]
		if current_step["type"] == "click" and current_step["action"] is Array:
			# Only increment the timer if at least one input is registered.
			if multi_input_buffer.size() > 0:
				multi_input_elapsed += delta
				if multi_input_elapsed >= multi_input_timeout_duration:
					_register_error()
					multi_input_buffer.clear()
					multi_input_elapsed = 0.0
	
	if is_charging and is_holding:
		hold_elapsed += delta
		hold_bar.value = (hold_elapsed / hold_max_time) * hold_bar.max_value
		if hold_elapsed >= hold_max_time:
			# Time ran out without proper release.
			_flash_hold_error()
			error_count += 1
			_reset_hold()


func _initialize_input_icons() -> void:
	for child in icon_container.get_children():
		icon_container.remove_child(child)
	
	for step in charge_sequence:
		var lbl = Label.new()
		if step["action"] is Array:
			lbl.text = ", ".join(step["action"]) + (" (Hold)" if step["type"] == "hold" else "")
		else:
			lbl.text = step["action"] + (" (Hold)" if step["type"] == "hold" else "")
		lbl.add_theme_color_override("font_color", Color.WHITE)
		icon_container.add_child(lbl)
	_update_input_icons()


func _update_input_icons() -> void:
	for i in range(icon_container.get_child_count()):
		var lbl = icon_container.get_child(i) as Label
		if i == current_charge_index:
			lbl.add_theme_color_override("font_color", Color.YELLOW)
		else:
			lbl.add_theme_color_override("font_color", Color.WHITE)


func on_attack_input(action_name: String, is_pressed: bool) -> void:
	if not is_charging and is_pressed == true:
		_start_charging()
	else:
		if current_charge_index >= charge_sequence.size() and is_pressed == true:
			print(error_count)
			print(total_charge_time)
			_cast_spell()
		
		else:
			var current_step = charge_sequence[current_charge_index]
			
			if current_step["type"] == "click":
				if current_step["action"] is Array:
					# Multi-input step:
					if is_pressed:
						if action_name in current_step["action"]:
							if not (action_name in multi_input_buffer):
								multi_input_buffer.append(action_name)
						else:
							_register_error()
							multi_input_buffer.clear()
							multi_input_elapsed = 0.0
							return
						
						var expected = current_step["action"].duplicate()
						expected.sort()
						var buffer_sorted = multi_input_buffer.duplicate()
						buffer_sorted.sort()
						if expected == buffer_sorted:
							current_charge_index += 1
							_update_charge_bar()
							_update_input_icons()
							multi_input_buffer.clear()
							multi_input_elapsed = 0.0
							if current_charge_index >= charge_sequence.size():
								total_charge_time = (Time.get_ticks_msec() / 1000.0) - charge_start_time
						# Note: Button releases are ignored for multi-input steps.
				else:
					# Single click step:
					if is_pressed:
						if action_name == current_step["action"]:
							current_charge_index += 1
							_update_charge_bar()
							_update_input_icons()
							if current_charge_index >= charge_sequence.size():
								total_charge_time = (Time.get_ticks_msec() / 1000.0) - charge_start_time
						else:
							_register_error()
						
			elif current_step["type"] == "hold":
				# Hold step:
				if is_pressed and action_name == current_step["action"]:
					if not is_holding:
						is_holding = true
						hold_elapsed = 0.0
						current_hold_action = current_step["action"]
						hold_bar.value = 0
						hold_bar.visible = true
				elif is_pressed and action_name != current_step["action"]:
					_register_error()
					_reset_hold()
				else:
					if is_holding and action_name == current_hold_action:
						var hold_fraction = hold_elapsed / hold_max_time
						var marker = current_step["marker"]
						if abs(hold_fraction - marker) <= hold_tolerance:
							current_charge_index += 1
							_update_charge_bar()
							_update_input_icons()
							_reset_hold()
							if current_charge_index >= charge_sequence.size():
								total_charge_time = (Time.get_ticks_msec() / 1000.0) - charge_start_time
						else:
							_register_error()
							_reset_hold()


func _start_charging() -> void:
	is_charging = true
	current_charge_index = 0
	error_count = 0
	charge_start_time = Time.get_ticks_msec() / 1000.0
	charge_bar.value = 0
	icon_container.visible = true
	multi_input_buffer.clear()
	_update_input_icons()


func _update_charge_bar() -> void:
	var progress = float(current_charge_index) / float(charge_sequence.size())
	charge_bar.value = progress * charge_bar.max_value


func _register_error() -> void:
	if current_charge_index < icon_container.get_child_count():
		error_count += 1
		var lbl = icon_container.get_child(current_charge_index) as Label
		lbl.add_theme_color_override("font_color", Color.RED)
		var tmr = Timer.new()
		tmr.wait_time = 0.3
		tmr.one_shot = true
		add_child(tmr)
		tmr.timeout.connect(func():
			lbl.add_theme_color_override("font_color", Color.YELLOW))
		tmr.start()


func _flash_hold_error() -> void:
	# This may not fully work; equally, these colour changes are just placeholders for animations.
	hold_bar.add_theme_color_override("fg_color", Color.RED)
	var tmr = Timer.new()
	tmr.wait_time = 0.3
	tmr.one_shot = true
	add_child(tmr)
	tmr.timeout.connect(func():
		hold_bar.add_theme_color_override("fg_color", Color.WHITE))
	tmr.start()


func _reset_hold() -> void:
	is_holding = false
	hold_elapsed = 0.0
	hold_bar.value = 0
	hold_bar.visible = false


func _cast_spell() -> void:
	var projectile_scene = preload("res://Items/Weapons/Magic/TestSpell/Scenes/test_spell_projectile.tscn")
	var projectile = projectile_scene.instantiate()
	projectile.global_position = global_position + Vector2(0, -80)
	var target = get_global_mouse_position()
	var dir = (target - global_position).normalized()
	projectile.velocity = dir * 300
	get_tree().get_current_scene().add_child(projectile)
	
	_reset_charging()


func _reset_charging() -> void:
	is_charging = false
	current_charge_index = 0
	error_count = 0
	icon_container.visible = false
	charge_bar.value = 0
