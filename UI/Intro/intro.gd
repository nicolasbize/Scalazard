extends CanvasLayer

@export var logo_wait_time := 3000

@onready var animation_player := $IntroAnimationPlayer
@onready var credits_animation_player := $CreditsAnimationPlayer
@onready var menu_options := [$MainMenu/VBoxContainer/NewGameLabel, $MainMenu/VBoxContainer/ContinueLabel, $MainMenu/VBoxContainer/OptionsLabel, $MainMenu/VBoxContainer/CreditsLabel, $MainMenu/VBoxContainer/QuitLabel]
@onready var selection_indicator := $MainMenu/SelectionIndicator

const OptionsScreen = preload("res://UI/Intro/options_screen.tscn")
const ConfirmOverride = preload("res://UI/Intro/confirm_dialog.tscn")
const PreGameIntro = preload("res://UI/Intro/pre_game_intro.tscn")

signal new_game

enum MenuOption {NewGame, Continue, Options, Credits, Quit}

var anims : Array[String] = ["godot-appear", "godot-appeared", "godot-fade", "gameoff-appear", "gameoff-appeared", "gameoff-fade", "text-appear", "text-appeared", "text-fade", "menu-appear", "menu-appeared"]
var anim_index := 0
var current_wait_time := 0
var in_menu := false
var in_credits := false
var current_menu_selected_index := 0
var options_screen = null
var confirmation_screen = null
var intro_screen = null
var continue_available := false
var skip_to_menu := false

func _ready():
	anim_index = 9 if skip_to_menu else 0
	animation_player.play(anims[anim_index])
	check_valid_save_game()
	select_entry(0, true)

func check_valid_save_game():
	if FileAccess.file_exists(GameState.SAVE_FILE_LOCATION):
		# check if valid file
		var file = FileAccess.open(GameState.SAVE_FILE_LOCATION, FileAccess.READ)
		var content = file.get_as_text()
		var game_data = str_to_var(content)
		if typeof(game_data) == TYPE_DICTIONARY and game_data.current_level > 0:
			continue_available = true
		else:
			print("invalid save file")
	else:
		print("save file not found")
		
func can_transition():
	return (anim_index < anims.size() - 1) and anims[anim_index].contains("appeared")
	
func _process(delta):
	if can_transition():
		if (Time.get_ticks_msec() - current_wait_time > logo_wait_time) or Input.is_action_just_pressed("jump") or Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("ui_cancel"):
			play_next_anim()
	elif in_credits:
		if Input.is_action_just_pressed("jump") or Input.is_action_just_pressed("ui_cancel") or Input.is_action_just_pressed("ui_accept"):
			credits_animation_player.play("stop-credits")
	elif in_menu and options_screen == null and confirmation_screen == null and intro_screen == null:
		if Input.is_action_just_pressed("ui_up"):
			select_entry(-1)
		elif Input.is_action_just_pressed("ui_down"):
			select_entry(1)
		elif Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("jump"):
			GameSounds.play(GameSounds.Sound.MenuSelect)
			enter_selection()

func select_entry(index_diff, mute_selection:bool = false) -> void:
	if (index_diff < 0) and (current_menu_selected_index == 0):
		return
	if (index_diff > 0) and (current_menu_selected_index == (menu_options.size() - 1)):
		return
	current_menu_selected_index += index_diff
	if (current_menu_selected_index == MenuOption.Continue as int) and not continue_available:
		current_menu_selected_index += index_diff
	if not mute_selection:
		GameSounds.play(GameSounds.Sound.MenuNav)
	refresh_menu_selection()

func on_stop_credits():
	in_credits = false

func enter_selection() -> void:
	if current_menu_selected_index == MenuOption.NewGame as int:
		if continue_available:
			confirmation_screen = ConfirmOverride.instantiate()
			confirmation_screen.connect("override_save", intro_new_game.bind())
			add_child(confirmation_screen)
		else:
			intro_new_game()
	elif current_menu_selected_index == MenuOption.Continue as int:
		GameState.continue_game()
		queue_free()
	elif current_menu_selected_index == MenuOption.Credits as int:
		in_credits = true
		credits_animation_player.play("credit-roll")
	elif current_menu_selected_index == MenuOption.Options as int:
		options_screen = OptionsScreen.instantiate()
		options_screen.connect("leave", on_options_leave.bind())
		add_child(options_screen)
	elif current_menu_selected_index == MenuOption.Quit as int:
		get_tree().quit()

func intro_new_game():
	intro_screen = PreGameIntro.instantiate()
	intro_screen.connect("complete", start_new_game.bind())
	add_child(intro_screen)
	
func start_new_game():
	GameState.start_game()
	queue_free()
	

func on_options_leave():
	if options_screen != null:
		options_screen.queue_free()

func refresh_menu_selection():
	for i in menu_options.size():
		var color = GameState.SELECTION_COLOR if i == current_menu_selected_index else GameState.DEFAULT_COLOR
		if i == MenuOption.Continue and not continue_available:
			color = GameState.DISABLED_COLOR
		menu_options[i].add_theme_color_override("font_color", color)
	selection_indicator.global_position = Vector2(280, 76 + 23 * current_menu_selected_index)

func play_next_anim():
	anim_index += 1
	if anim_index < anims.size() - 1:
		animation_player.play(anims[anim_index])
	else:
		in_menu = true

func on_appear_complete():
	play_next_anim()
	current_wait_time = Time.get_ticks_msec()

func on_fade_complete():
	play_next_anim()
