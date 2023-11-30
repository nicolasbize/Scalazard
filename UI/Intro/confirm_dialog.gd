extends Control

@onready var confirm_label := $MarginContainer/Panel/VBoxContainer/HBoxContainer/ConfirmLabel
@onready var return_label := $MarginContainer/Panel/VBoxContainer/HBoxContainer/ReturnLabel

signal override_save

var confirm_override := true

func _process(delta):
	if Input.is_action_just_pressed("ui_right"):
		if confirm_override:
			confirm_override = false
			GameSounds.play(GameSounds.Sound.MenuNav)
	if Input.is_action_just_pressed("ui_left"):
		if not confirm_override:
			confirm_override = true
			GameSounds.play(GameSounds.Sound.MenuNav)
	if Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("jump"):
		GameSounds.play(GameSounds.Sound.MenuSelect)
		if confirm_override:
			emit_signal("override_save")
		queue_free()
	refresh_ui()

func refresh_ui():
	confirm_label.add_theme_color_override("font_color", GameState.SELECTION_COLOR if confirm_override else GameState.DEFAULT_COLOR)
	return_label.add_theme_color_override("font_color", GameState.DEFAULT_COLOR if confirm_override else GameState.SELECTION_COLOR)
