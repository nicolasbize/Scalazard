extends HBoxContainer

@onready var label := $Label
@onready var checkbox := $Checkbox

const empty_checkbox := preload("res://UI/Intro/checkbox-empty.png")
const filled_checkbox := preload("res://UI/Intro/checkbox-full.png")

func select() -> void:
	label.add_theme_color_override("font_color", GameState.SELECTION_COLOR)
	checkbox.modulate = GameState.SELECTION_COLOR

func deselect() -> void:
	label.add_theme_color_override("font_color", GameState.DEFAULT_COLOR)
	checkbox.modulate = GameState.DEFAULT_COLOR

func set_value(checked:bool) -> void:
	checkbox.texture = filled_checkbox if checked else empty_checkbox
