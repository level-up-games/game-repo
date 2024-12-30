extends Node2D



@onready var bg_music = get_node("Menu Music")



func _ready():
	pass 


func _process(delta):
	pass


func _on_menu_music_finished():
	bg_music.play()


func _on_start_pressed():
	get_tree().change_scene_to_file("res://AreaMaps/AbandonedCity/Scenes/abandoned_city_1.tscn")
