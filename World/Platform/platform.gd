extends Node2D

@onready var sign := $Sign

func _process(delta):
	sign.visible = GameState.get_nb_gems_acquired() == 0
