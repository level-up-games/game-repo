extends Panel

var current_item: String = ""
var hover_position: Vector2 = Vector2.ZERO

func _ready():
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS  # Work even when game paused
	var my_style = StyleBoxFlat.new()
	my_style.bg_color = Color(0.15, 0.15, 0.15, 0.9)
	my_style.border_color = Color(1, 0.8, 0.4)
	my_style.set_border_width_all(2)
	my_style.set_expand_margin_all(10)
	add_theme_stylebox_override("panel", my_style)

func show_tooltip(item_name: String):
	current_item = item_name
	var item_data = Global.item_data.get(item_name, {})
	
	if item_data.is_empty():
		return
	
	var rarity = "red"
	
	# Basic Info
	$VBoxContainer/NameLabel.set_text(item_name)
	$VBoxContainer/NameLabel.add_theme_color_override("font_color", rarity)
	$VBoxContainer/CategoryLabel.set_text("%s" % item_data.get("item_category", "Miscellaneous"))
	$VBoxContainer/DescriptionLabel.set_text(item_data.get("description", ""))

	if not Global.ui.holding_item:
		visible = true

func hide_tooltip():
	visible = false
	current_item = ""

func _process(delta):  # TODO: could be performance impacting
	if visible:
		# Position tooltip relative to mouse
		var mouse_pos = get_global_mouse_position()
		var tooltip_pos = mouse_pos + Vector2(20, 20)
		
		# Keep tooltip on screen
		var viewport_rect = get_viewport().get_visible_rect()
		if tooltip_pos.x + size.x > viewport_rect.end.x:
			tooltip_pos.x = viewport_rect.end.x - size.x
		if tooltip_pos.y + size.y > viewport_rect.end.y:
			tooltip_pos.y = viewport_rect.end.y - size.y
		
		global_position = tooltip_pos
