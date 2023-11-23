extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready():
	GameSounds.play(GameSounds.Sound.OutsideRain)
	
func _exit_tree():
	GameSounds.stop(GameSounds.Sound.OutsideRain)
