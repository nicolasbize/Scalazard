extends Node2D

@onready var gem_sprite := $GemSprite
@onready var ray := $Ray
@onready var circle := $Circle

signal gain_gem

var color_map = ["83ff70", "70cfff", "ff7070", "fffa70", "ff70e5"]

func set_color(gem_index:int) -> void:
	gem_sprite.frame = gem_index
	ray.modulate = Color(color_map[gem_index])
	circle.modulate = Color(color_map[gem_index])
	

func on_appear_end():
	emit_signal("gain_gem")
