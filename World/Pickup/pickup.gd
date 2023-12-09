extends Node2D

@export var cooldown_before_pickup := 1000

@onready var area := $Area2D

var start_life := -1

# Called when the node enters the scene tree for the first time.
func _ready():
	area.connect("body_entered", on_player_enter.bind())
	start_life = Time.get_ticks_msec()

func on_player_enter(body):
	var elapsed = Time.get_ticks_msec() - start_life
	if elapsed > cooldown_before_pickup and GameState.can_increase_life():
		GameSounds.play(GameSounds.Sound.LifeUp)
		GameState.increase_life()
		queue_free()
