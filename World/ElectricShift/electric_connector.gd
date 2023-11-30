extends Node2D

@onready var animation_player := $AnimationPlayer

var is_charged := false

func _process(delta):
	if is_charged:
		animation_player.play("charge")
	else:
		animation_player.play("idle")
