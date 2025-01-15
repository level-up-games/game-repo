extends Node2D


@onready var bg_music = get_node("Menu Music")



func _ready():
	pass 


func _process(delta):
	pass


func _on_menu_music_finished():
	bg_music.play()


func _on_start_pressed():
	FadeScreen.fade_transition(1, 1, 2, "res://AreaMaps/AbandonedCity/Scenes/abandoned_city_1.tscn")
