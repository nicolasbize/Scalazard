extends Control

@export var in_game := false

@onready var music_volume_control := $TextureRect/MarginContainer/VBoxContainer/MusicVolumeControl
@onready var sound_volume_control := $TextureRect/MarginContainer/VBoxContainer/SoundVolumeControl
@onready var return_label := $TextureRect/MarginContainer/VBoxContainer/ReturnLabel
@onready var quit_label := $TextureRect/MarginContainer/VBoxContainer/QuitLabel
@onready var top_label := $TextureRect/MarginContainer/VBoxContainer/TopLabel

var menu_selected := 0
var nb_menu_items := 4 if in_game else 3

signal leave
signal quit

# Called when the node enters the scene tree for the first time.
func _ready():
	refresh_ui()
	nb_menu_items = 4 if in_game else 3

func refresh_ui():
	music_volume_control.deselect()
	sound_volume_control.deselect()
	return_label.add_theme_color_override("font_color", GameState.DEFAULT_COLOR)
	quit_label.add_theme_color_override("font_color", GameState.DEFAULT_COLOR)
	if menu_selected == 0:
		music_volume_control.select()
	elif menu_selected == 1:
		sound_volume_control.select()
	elif menu_selected == 2:
		return_label.add_theme_color_override("font_color", GameState.SELECTION_COLOR)
	else:
		quit_label.add_theme_color_override("font_color", GameState.SELECTION_COLOR)
	music_volume_control.set_value(GameState.music_volume)
	sound_volume_control.set_value(GameState.sound_volume)
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	return_label.text = "Return to Game" if in_game else "Return to Main Menu"
	top_label.text = "Pause" if in_game else "Options"
	quit_label.visible = in_game
	if Input.is_action_just_pressed("ui_up") and menu_selected > 0:
		menu_selected -= 1
		GameSounds.play(GameSounds.Sound.MenuNav)
		refresh_ui()
	elif Input.is_action_just_pressed("ui_down") and menu_selected < nb_menu_items - 1:
		menu_selected += 1
		GameSounds.play(GameSounds.Sound.MenuNav)
		refresh_ui()
	elif Input.is_action_just_pressed("ui_right") and menu_selected < 2:
		increase_volume()
	elif Input.is_action_just_pressed("ui_left") and menu_selected < 2:
		decrease_volume()
	elif (Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("jump")) and menu_selected == 2:
		GameSounds.play(GameSounds.Sound.MenuSelect)
		emit_signal("leave")
	elif (Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("jump")) and menu_selected == 3:
		GameSounds.play(GameSounds.Sound.MenuSelect)
		emit_signal("quit")
	

func increase_volume():
	if menu_selected == 0:
		GameState.increase_volume_music()
	else:
		GameState.increase_volume_sound()
	refresh_ui()

func decrease_volume():
	if menu_selected == 0:
		GameState.decrease_volume_music()
	else:
		GameState.decrease_volume_sound()
	refresh_ui()
