extends Node2D

@onready var area := $Sprite2D/Area2D

# Called when the node enters the scene tree for the first time.
func _ready():
	area.connect("body_entered", on_player_enter.bind())

func on_player_enter(body):
	# play sound
	GameState.increase_life()
	queue_free()
