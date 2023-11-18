extends Node2D


@onready var platform_area := $Platform/Sign/Area2D

func _ready():
	platform_area.connect("body_entered", on_player_enter_platform.bind())
	
func on_player_enter_platform(body):
	if GameState.get_nb_gems_acquired() > 0:
		print("yaya")
