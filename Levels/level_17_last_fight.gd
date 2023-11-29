extends Node2D

@onready var timer := $Timer

func _ready():
	timer.connect("timeout", on_level_start.bind())

func on_level_start():
	get_viewport().get_camera_2d().lock_to_target(Vector2(0, -96))

