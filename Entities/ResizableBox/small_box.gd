extends RigidBody2D

@onready var animation_player := $AnimationPlayer

func highlight():
	animation_player.play("targeted")

func stop_highlight():
	animation_player.play("RESET")
