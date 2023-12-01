extends Control

signal leave
signal cancel

@onready var difficulty_options = [$MarginContainer/Panel/EasyLabel, $MarginContainer/Panel/NormalLabel, $MarginContainer/Panel/HardLabel]
@onready var selection_indicator := $SelectionIndicator

var current_menu_selected_index := 0

func _ready():
	select_entry(1, true)

func _process(delta):
	if Input.is_action_just_pressed("ui_up"):
		select_entry(-1)
	elif Input.is_action_just_pressed("ui_down"):
		select_entry(1)
	elif Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("jump"):
		GameSounds.play(GameSounds.Sound.MenuSelect)
		if current_menu_selected_index == 0:
			GameState.set_difficulty_level(GameState.Difficulty.Easy)
		elif current_menu_selected_index == 1:
			GameState.set_difficulty_level(GameState.Difficulty.Normal)
		else:
			GameState.set_difficulty_level(GameState.Difficulty.Hard)
		emit_signal("leave")
	elif Input.is_action_just_pressed("ui_cancel"):
		GameSounds.play(GameSounds.Sound.MenuSelect)
		emit_signal("cancel")
		
func select_entry(index_diff, mute_selection:bool = false) -> void:
	if (index_diff < 0) and (current_menu_selected_index == 0):
		return
	if (index_diff > 0) and (current_menu_selected_index == 2):
		return
	current_menu_selected_index += index_diff
	if not mute_selection:
		GameSounds.play(GameSounds.Sound.MenuNav)
	refresh_menu_selection()
	
func refresh_menu_selection():
	for i in difficulty_options.size():
		var color = GameState.SELECTION_COLOR if i == current_menu_selected_index else GameState.DEFAULT_COLOR
		difficulty_options[i].add_theme_color_override("font_color", color)
	selection_indicator.global_position = Vector2(49, 79 + 40 * current_menu_selected_index)
