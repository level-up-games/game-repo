extends RichTextLabel


@export var float_distance: float = 20.0
@export var float_time: float = 1.15



func show_damage(damage: int, spawn_position: Vector2, player: bool) -> void:
	text = str(damage)
	global_position = spawn_position
	
	if player == true:
		var red = Color(0.94, 0.00, 0.05, 1.00)
		var white = Color(1.00, 1.00, 1.00, 1.00)
		var black = Color(0.00, 0.00, 0.00, 1.00)
		set("theme_override_colors/default_color", red)
		set("theme_override_colors/font_outline_color", white)
		set("theme_override_colors/font_shadow_color", black)
	else:
		var red = Color(0.94, 0.00, 0.05, 1.00)
		var white = Color(1.00, 1.00, 1.00, 1.00)
		var black = Color(0.00, 0.00, 0.00, 1.00)
		set("theme_override_colors/default_color", white)
		set("theme_override_colors/font_outline_color", false)
		set("theme_override_colors/font_shadow_color", black)
	
	var tween = get_tree().create_tween()
	# move up
	tween.parallel().tween_property(self, "position:y", position.y - float_distance, float_time)
	# fade out alpha
	tween.parallel().tween_property(self, "modulate:a", 0.0, float_time)
	tween.finished.connect(func():
		queue_free())
