extends Node2D

@onready var ui := $UI
@onready var camera := $Camera2D

var current_level_scene = null
var upcoming_level : GameState.Level
var upcoming_destination_address := -1
var in_transition := false
var option_screen = null

const OptionsScreen = preload("res://UI/Intro/options_screen.tscn")

func _ready():
	ui.connect("in_transit", repack_level.bind())
	GameState.connect("life_change", on_player_life_change.bind())
	load_level(GameState.current_level)

func load_level(level:GameState.Level):
	upcoming_level = level
	ui.start_transition()

func repack_level():
	if current_level_scene != null:
		current_level_scene.queue_free()
	current_level_scene = GameState.Levels[upcoming_level].instantiate()
	add_child(current_level_scene)
	GameState.current_level = upcoming_level
	var hero = current_level_scene.find_child("Hero", false)
	var tilemap = current_level_scene.find_child("TileMap", false)
	for child in current_level_scene.get_children():
		if child.is_in_group("portal"):
			if not child.is_connected("level_transition", on_level_transition_request.bind()):
				child.connect("level_transition", on_level_transition_request.bind())
			if child.address_in_level == upcoming_destination_address:
				hero.global_position = child.get_spawn_location()
				GameState.last_portal_location = upcoming_destination_address
	camera.reset(hero, tilemap)
	if GameState.current_life <= 0:
		ui.reset_death()
		GameState.new_life()
	ui.end_transition()
	if is_special_level(upcoming_level) or GameState.has_all_gems():
		GameMusic.stop()
	else:
		GameMusic.play(GameMusic.Track.Gameplay)
	if upcoming_level != GameState.Level.Courtyard or GameState.is_starting_game_from_load_file:
		GameState.save_game()
	in_transition = false

func is_special_level(level: GameState.Level) -> bool:
	return [GameState.Level.Courtyard, GameState.Level.MageBoss, GameState.Level.SacrificeChamber, GameState.Level.SkeletonBoss, GameState.Level.HerosShadow].has(level)

func on_level_transition_request(destination_level: GameState.Level, destination_address: Portal.DoorIndex):
	if not in_transition:
		in_transition = true
		upcoming_destination_address = destination_address
		load_level(destination_level)

func on_player_life_change(current_life:int, max_life:int) -> void:
	if current_life <= 0:
		ui.start_death()

func _process(delta):
	if GameState.current_life == 0 and Input.is_action_just_pressed("restart"):
		load_level(upcoming_level)
	if Input.is_action_just_pressed("ui_cancel") and option_screen == null:
		pause_game()
		
func pause_game():
	option_screen = OptionsScreen.instantiate()
	option_screen.in_game = true
	option_screen.connect("leave", on_return_to_game.bind())
	option_screen.connect("quit", on_leave_game.bind())
	ui.add_child(option_screen)
	get_tree().paused = true

func on_return_to_game():
	option_screen.queue_free()
	get_tree().paused = false

func on_leave_game():
	option_screen.queue_free()
	option_screen = null
	get_tree().paused = false
	GameState.quit_to_menu()
	queue_free()
