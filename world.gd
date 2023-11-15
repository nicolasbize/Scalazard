extends Node2D

@onready var ui := $UI
@onready var camera := $Camera2D
@onready var music_intro := $MusicIntro
@onready var music_theme := $MusicTheme

var current_level_scene = null
var upcoming_level : GameState.Level
var upcoming_destination_address : int
var in_transition := false

func _ready():
	load_level(GameState.current_level)
	ui.connect("in_transit", repack_level.bind())
	GameState.connect("life_change", on_player_life_change.bind())
	music_intro.connect("finished", on_intro_music_finished.bind())

func load_level(level:GameState.Level):
	if music_theme.is_playing():
		music_theme.stop()
	if level != GameState.Level.Courtyard and GameState.is_music_on:
		music_intro.play()
	upcoming_level = level
	ui.start_transition()

func on_intro_music_finished():
	music_theme.play(0)

func repack_level():
	if current_level_scene != null:
		current_level_scene.queue_free()
	current_level_scene = GameState.Levels[upcoming_level].instantiate()
	add_child(current_level_scene)
	var hero = current_level_scene.find_child("Hero", false)
	var tilemap = current_level_scene.find_child("TileMap", false)
	for portal in get_tree().get_nodes_in_group("portal"):
		for child in current_level_scene.get_children():
			if not portal.is_connected("level_transition", on_level_transition_request.bind()):
				portal.connect("level_transition", on_level_transition_request.bind())
			if portal.address_in_level == upcoming_destination_address:
				hero.global_position = portal.global_position
	camera.reset(hero, tilemap)
	ui.reset_death()
	GameState.new_life()
	ui.end_transition()
	
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
