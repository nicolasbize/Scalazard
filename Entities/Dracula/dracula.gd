extends Node2D

@onready var animation_player := $AnimationPlayer

signal cinematic_finish


func _process(delta):
	pass

func disappear_east():
	animation_player.play("disappear_east")

func on_finish_disappear():
	emit_signal("cinematic_finish")
