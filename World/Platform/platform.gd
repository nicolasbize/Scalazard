extends Node2D

@onready var signpost := $Sign

func _process(delta):
	signpost.visible = GameState.get_nb_gems_acquired() == 0

