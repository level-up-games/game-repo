extends CanvasLayer



@onready var studio_logo = get_node("Studio Logo")
@onready var info = get_node("Info")

@export var time_before_start: float = 1.5
@export var logo_final_scale: float = 0.835

var logo_fade_in: bool = false
var logo_fade_out: bool = false
var logo_opacity: float = 0.0
var logo_scaling: float = 0.8

var info_fade_in: bool = false
var info_fade_out: bool = false
var info_opacity: float = 0.0

var change_scene_once: bool = true # This prevents the code from calling the scene change more than once (which would cause errors).



func _ready():
	studio_logo.modulate = Color(1, 1, 1, 0)
	info.modulate = Color(1, 1, 1, 0)
	await get_tree().create_timer(time_before_start).timeout
	logo_fade_in = true


func _process(delta):
	if logo_fade_in == true and logo_fade_out == false:
		studio_logo.modulate = Color(1, 1, 1, logo_opacity)
		studio_logo.scale = Vector2(logo_scaling, logo_scaling)
		if logo_opacity < 1:
			logo_opacity += 0.5 * delta
		if logo_scaling < logo_final_scale:
			logo_scaling += 0.01 * delta
		else:
			logo_fade_out = true
	
	if logo_fade_out == true:
		logo_scaling += 0.005 * delta
		studio_logo.scale = Vector2(logo_scaling, logo_scaling)
		if logo_opacity > 0:
			logo_opacity -= 0.5 * delta
			studio_logo.modulate = Color(1, 1, 1, logo_opacity)
		if logo_opacity <= 0:
			await get_tree().create_timer(1).timeout
			info_fade_in = true
	
	if info_fade_in == true and info_fade_out == false:
		info.modulate = Color(1, 1, 1, info_opacity)
		if info_opacity < 1:
			info_opacity += 0.5 * delta
		else:
			await get_tree().create_timer(3).timeout
			info_fade_out = true
			
	if info_fade_out == true:
		if info_opacity > 0:
			info_opacity -= 0.5 * delta
			info.modulate = Color(1, 1, 1, info_opacity)
		if info_opacity <= 0 and change_scene_once == true:
			change_scene_once = false
			await get_tree().create_timer(1.5).timeout
			get_tree().change_scene_to_file("res://0. Menus/Main Menu/Scenes/main_menu.tscn")
