extends Node2D

@onready var timer := $Timer

func _ready():
	timer.connect("timeout", on_timer_timeout.bind())

func on_timer_timeout():
	GameSounds.play(GameSounds.Sound.OutsideRain)
	
func _exit_tree():
	GameSounds.stop(GameSounds.Sound.OutsideRain)
