extends Node

signal life_change(current_life:int, max_life:int)
signal hit_received()
signal system_message(text:String)

enum Level {Prototype, Courtyard, Entrance, EastTower, SacrificeChamber, CenterCourt, DoubleTrigger, 
SimpleCorridor, WaterCorridor, RaceCube, MageBoss, RaceAgainstFire,
OneCubeRace, SkeletonBoss, FlyAway}
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
}

var current_level := Level.FlyAway
var is_music_on := false
var visited_dracula_entrance := true
var visited_dracula_center := true
var opened_center_court_door := true


var callback_after_pause : Callable
var max_life := 3
var current_life := 3
var current_gems = [true, true, true, false] # green: float, blue: swim, purple: dodge, yellow: shield
var gems_inserted = [false, false, false, false]
var hearts_collected = {}
var screen_shake := true

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
