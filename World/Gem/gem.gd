extends Node2D

@onready var gem_sprite := $GemSprite
@onready var ray := $Ray
@onready var circle := $Circle

signal gain_gem

var color_map = ["83ff70", "70cfff", "ff70e5", "fffa70", "ff7070"]
var color : TreasureChest.Content = TreasureChest.Content.GreenGem

func _ready():
	gem_sprite.frame = color
	ray.modulate = Color(color_map[color])
	circle.modulate = Color(color_map[color])
	
func on_appear_end():
	emit_signal("gain_gem")
