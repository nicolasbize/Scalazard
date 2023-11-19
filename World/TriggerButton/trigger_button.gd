extends Node2D

signal press

@export var one_way := false
@export var door : Door = null
@export var pressed := false

@onready var sprite := $Sprite2D
@onready var detection_area := $Area2D

func _ready():
	detection_area.connect("body_entered", on_body_enter.bind())
	if not one_way:
		detection_area.connect("body_exited", on_body_exit.bind())

func on_body_enter(body):
	if not pressed:
		pressed = true
		trigger_press_event()

func on_body_exit(body):
	pressed = false
	if door != null:
		door.close()
		
	
func trigger_press_event():
	emit_signal("press")
	if door != null:
		door.open()
	
func _process(delta):
	sprite.frame = 0
	if pressed:
		sprite.frame = 1
	
