extends Node2D

@onready var signpost := $Sign

func _process(delta):
	signpost.visible = GameState.get_nb_gems_acquired() != 4
	if GameState.get_nb_gems_acquired() == 0:
		signpost.text = "Hmm... Each of these doors seems to have a socket"
	elif GameState.get_nb_gems_acquired() == 3:
		signpost.text = "I need to find the last crystal!"
	else:
		var missing_crystals := 4 - GameState.get_nb_gems_acquired()
		signpost.text = "I still need to find " + str(missing_crystals) + " more crystals"

