extends Node

signal life_change(current_life:int, max_life:int)
signal hit_received()

var max_life := 3
var current_life := 3

var screen_shake := true

func deal_hero_damage(dmg:int) -> void:
	current_life -= dmg
	if current_life < 0:
		current_life = 0
	emit_signal("life_change", current_life, max_life)

func add_max_life() -> void:
	max_life += 1
	current_life = max_life
	emit_signal("life_change", current_life, max_life)

