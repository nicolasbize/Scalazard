extends Node2D

@onready var area := $Area2D
@onready var sprite := $Sprite2D
@onready var animation_player := $AnimationPlayer

var parent : ScalableObject

func _ready():
	area.connect("mouse_entered", on_mouse_enter.bind())
	area.connect("mouse_exited", on_mouse_exit.bind())
	parent = get_parent()
	set_size()

func on_mouse_enter():
	sprite.visible = true

func on_mouse_exit():
	sprite.visible = false

func set_size():
	if parent.size == ScalableObject.Size.Small:
		animation_player.play("select_small")
	elif parent.size == ScalableObject.Size.Medium:
		animation_player.play("select_medium")
	else:
		animation_player.play("select_big")
