extends Node

signal life_change(current_life:int, max_life:int)
signal hit_received()

enum Level {Prototype, Courtyard, Entrance, EastTower}
var Levels = {
	Level.Prototype: preload("res://Levels/level-prototype.tscn"),
	Level.Courtyard: preload("res://Levels/level_01_courtyard.tscn"),
	Level.Entrance: preload("res://Levels/level_02_entrance.tscn"),
	Level.EastTower: preload("res://Levels/level_03_east_tower.tscn"),
}

var current_level := Level.Entrance

var max_life := 3
var current_life := 3
var is_music_on := true

var screen_shake := true

func deal_hero_damage(dmg:int) -> void:
	current_life -= dmg
	if current_life < 0:
		current_life = 0
	emit_signal("life_change", current_life, max_life)

func increase_life() -> void:
	max_life += 1
	current_life = max_life
	emit_signal("life_change", current_life, max_life)

func new_life() -> void:
	current_life = max_life
	emit_signal("life_change", current_life, max_life)

func add_to_level(obj) -> void:
	var level = get_tree().get_first_node_in_group("level")
	level.add_child(obj)
