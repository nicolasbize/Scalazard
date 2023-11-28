extends Node

const World = preload("res://world.tscn")
const Intro = preload("res://UI/Intro/intro.tscn")

signal life_change(current_life:int, max_life:int)
signal hit_received()
signal system_message(text:String)

enum Level {Prototype, Courtyard, Entrance, EastTower, SacrificeChamber, CenterCourt, DoubleTrigger, 
SimpleCorridor, WaterCorridor, RaceCube, MageBoss, RaceAgainstFire,
OneCubeRace, SkeletonBoss, FlyAway, RaceToTheTop, HerosShadow}
var Levels = {
	Level.Prototype: preload("res://Levels/level-prototype.tscn"),
	Level.Courtyard: preload("res://Levels/level_01_courtyard.tscn"),
	Level.Entrance: preload("res://Levels/level_02_entrance.tscn"),
	Level.EastTower: preload("res://Levels/level_03_east_tower.tscn"),
	Level.SacrificeChamber: preload("res://Levels/level_04_sacrifice_chamber.tscn"),
	Level.CenterCourt: preload("res://Levels/level_05_center_court.tscn"),
	Level.DoubleTrigger: preload("res://Levels/level_06_double_trigger.tscn"),
	Level.SimpleCorridor: preload("res://Levels/level_07_simple_corridor.tscn"),
	Level.WaterCorridor: preload("res://Levels/level_08_water_corridor.tscn"),
	Level.RaceCube: preload("res://Levels/level_09_race_cube.tscn"),
	Level.MageBoss: preload("res://Levels/level_10_mage_boss.tscn"),
	Level.RaceAgainstFire: preload("res://Levels/level_11_race_against_fire.tscn"),
	Level.OneCubeRace: preload("res://Levels/level_12_one_cube_race.tscn"),
	Level.SkeletonBoss: preload("res://Levels/level_13_skeleton_boss.tscn"),
	Level.FlyAway: preload("res://Levels/level_14_fly_away.tscn"),
	Level.RaceToTheTop: preload("res://Levels/level_15_to_the_top.tscn"),
	Level.HerosShadow: preload("res://Levels/level_16_heros_shadow.tscn"),
}

var skip_intro := true
# game data
var current_level := Level.SkeletonBoss
var last_portal_location := Portal.DoorIndex.West
var visited_dracula_entrance := false
var visited_dracula_center := false
var opened_center_court_door := false
var max_life := 3
var current_life := 3
var current_gems = [false, false, true, false] # green: float, blue: swim, purple: dodge, yellow: shield
var gems_inserted = [false, false, false, false]
var level_2_heart_collected := false
var level_3_heart_collected := false
var level_14_heart_collected := false
var music_volume := 8
var sound_volume := 8

var screen_shake := true
var is_starting_game_from_load_file := false
var callback_after_pause : Callable

const DEFAULT_COLOR = "e0a57d"
const SELECTION_COLOR = "f2e4a2"
const DISABLED_COLOR = "cccccc"
const SAVE_FILE_LOCATION := "user://merlin.data"


func start_game():
	var world = World.instantiate()
	get_parent().add_child(world)

func continue_game():
	load_game()

func quit_to_menu():
	var intro = Intro.instantiate()
	intro.skip_to_menu = true
	get_parent().add_child(intro)

func save_game():
	var save_data = {
		"current_level": current_level,
		"last_portal_location": last_portal_location,
		"visited_dracula_entrance": visited_dracula_entrance,
		"visited_dracula_center": visited_dracula_center,
		"opened_center_court_door": opened_center_court_door,
		"max_life": max_life,
		"current_life": current_life,
		"current_gems": current_gems,
		"gems_inserted": gems_inserted,
		"level_2_heart_collected": level_2_heart_collected,
		"level_3_heart_collected": level_3_heart_collected,
		"level_14_heart_collected": level_14_heart_collected,
		"music_volume": music_volume,
		"sound_volume": sound_volume,
	}
	var file = FileAccess.open(GameState.SAVE_FILE_LOCATION, FileAccess.WRITE)
	file.store_line(var_to_str(save_data))

func load_game():
	var file = FileAccess.open(GameState.SAVE_FILE_LOCATION, FileAccess.READ)
	var content = file.get_as_text()
	var game_data = str_to_var(content)
	current_level = game_data["current_level"]
	last_portal_location = game_data["last_portal_location"]
	visited_dracula_entrance = game_data["visited_dracula_entrance"]
	visited_dracula_center = game_data["visited_dracula_center"]
	opened_center_court_door = game_data["opened_center_court_door"]
	max_life = game_data["max_life"]
	current_life = game_data["current_life"]
	current_gems = game_data["current_gems"]
	gems_inserted = game_data["gems_inserted"]
	level_2_heart_collected = game_data["level_2_heart_collected"]
	level_3_heart_collected = game_data["level_3_heart_collected"]
	level_14_heart_collected = game_data["level_14_heart_collected"]
	var world = World.instantiate()
	world.upcoming_destination_address = last_portal_location
	get_parent().add_child(world)

func increase_volume_music():
	if music_volume < 10:
		music_volume += 1
		AudioServer.set_bus_volume_db(1, linear_to_db(music_volume / 10.0))
		GameSounds.play(GameSounds.Sound.MenuNav)

func decrease_volume_music():
	if music_volume > 0:
		music_volume -= 1
		AudioServer.set_bus_volume_db(1, linear_to_db(music_volume / 10.0))
		GameSounds.play(GameSounds.Sound.MenuNav)

func increase_volume_sound():
	if sound_volume < 10:
		sound_volume += 1
		AudioServer.set_bus_volume_db(2, linear_to_db(sound_volume / 10.0))
		GameSounds.play(GameSounds.Sound.MenuNav)

func decrease_volume_sound():
	if sound_volume > 0:
		sound_volume -= 1
		AudioServer.set_bus_volume_db(2, linear_to_db(sound_volume / 10.0))
		GameSounds.play(GameSounds.Sound.MenuNav)

func deal_hero_damage(dmg:int) -> void:
	current_life -= dmg
	if current_life < 0:
		current_life = 0
	emit_signal("life_change", current_life, max_life)

func gain_treasure(treasure:TreasureChest.Content) -> void:
	if treasure == TreasureChest.Content.LifePotion:
		max_life += 1
		current_life = max_life
		emit_signal("life_change", current_life, max_life)
	else:
		current_gems[treasure] = true
		current_life = max_life
		emit_signal("life_change", current_life, max_life)

func new_life() -> void:
	current_life = max_life
	emit_signal("life_change", current_life, max_life)

func add_to_level(obj) -> void:
	var level = get_tree().get_first_node_in_group("level")
	level.call_deferred("add_child", obj)

func show_system_message(text:Array[String], callback:Callable) -> void:
#	get_tree().paused = true
	callback_after_pause = callback
	emit_signal("system_message", text)

func resume_play() -> void:
#	get_tree().paused = false
	if callback_after_pause != null:
		callback_after_pause.call()
		callback_after_pause = func():
			pass

func get_nb_gems_acquired() -> int:
	var i := 0
	for j in range(current_gems.size()):
		if current_gems[j]:
			i += 1
	return i

func has_all_gems() -> bool:
	for has_gem in current_gems:
		if not has_gem:
			return false
	return true
