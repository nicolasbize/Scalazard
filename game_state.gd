extends Node

signal life_change(current_life:int, max_life:int)
signal hit_received()
signal system_message(text:String)

enum Level {Prototype, Courtyard, Entrance, EastTower, SacrificeChamber}
var Levels = {
	Level.Prototype: preload("res://Levels/level-prototype.tscn"),
	Level.Courtyard: preload("res://Levels/level_01_courtyard.tscn"),
	Level.Entrance: preload("res://Levels/level_02_entrance.tscn"),
	Level.EastTower: preload("res://Levels/level_03_east_tower.tscn"),
	Level.SacrificeChamber: preload("res://Levels/level_04_sacrifice_chamber.tscn"),
}

var current_level := Level.Entrance
var is_music_on := true

var callback_after_pause : Callable
var max_life := 3
var current_life := 3
var current_gems = [false, false, false, false, false]

var screen_shake := true

func deal_hero_damage(dmg:int) -> void:
	current_life -= dmg
	if current_life < 0:
		current_life = 0
	emit_signal("life_change", current_life, max_life)

func gain_gem_power(gem_index:int) -> void:
	current_gems[gem_index] = true
	max_life += 1
	current_life = max_life
	emit_signal("life_change", current_life, max_life)

func new_life() -> void:
	current_life = max_life
	emit_signal("life_change", current_life, max_life)

func add_to_level(obj) -> void:
	var level = get_tree().get_first_node_in_group("level")
	level.add_child(obj)

func show_system_message(text:Array[String], callback:Callable) -> void:
	get_tree().paused = true
	callback_after_pause = callback
	emit_signal("system_message", text)

func resume_play() -> void:
	get_tree().paused = false
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
