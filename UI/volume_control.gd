extends HBoxContainer

@onready var label := $Label
@onready var volume_dots := []

const square_texture := preload("res://UI/Intro/square.png")
const dot_texture := preload("res://UI/Intro/dot.png")

func select() -> void:
	label.add_theme_color_override("font_color", GameState.SELECTION_COLOR)
	var dots = get_dots()
	for dot in dots:
		dot.modulate = GameState.SELECTION_COLOR

func deselect() -> void:
	label.add_theme_color_override("font_color", GameState.DEFAULT_COLOR)
	var dots = get_dots()
	for dot in dots:
		dot.modulate = GameState.DEFAULT_COLOR

func set_value(value:int) -> void:
	var dots = get_dots()
	for i in dots.size():
		if i < value:
			dots[i].texture = square_texture
		else:
			dots[i].texture = dot_texture
			
func get_dots() -> Array[TextureRect]:
	var dots :Array[TextureRect] = []
	for child in get_children():
		if child is TextureRect:
			dots.append(child)
	return dots
