extends Node2D

@onready var ui := $UI
@onready var camera := $Camera2D

const Levels = [preload("res://Levels/level-prototype.tscn")]

var current_level_scene = null
var upcoming_level_index = -1

func _ready():
	load_level(0)
	ui.connect("in_transit", repack_level.bind())
	GameState.connect("life_change", on_player_life_change.bind())

func load_level(lvl_index:int):
	upcoming_level_index = lvl_index
	ui.start_transition()

func repack_level():
	if current_level_scene != null:
		current_level_scene.queue_free()
	current_level_scene = Levels[upcoming_level_index].instantiate()
	add_child(current_level_scene)
	var hero = current_level_scene.find_child("Hero", false)
	var tilemap = current_level_scene.find_child("TileMap", false)
	camera.reset(hero, tilemap)
	ui.reset_death()
	GameState.new_life()	
	ui.end_transition()

func on_player_life_change(current_life:int, max_life:int) -> void:
	if current_life <= 0:
		ui.start_death()

func _process(delta):
	if GameState.current_life == 0 and Input.is_action_just_pressed("restart"):
		load_level(upcoming_level_index)
