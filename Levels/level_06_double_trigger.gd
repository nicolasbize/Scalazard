extends Node2D


@onready var fire_trigger := $FireTrigger
@onready var stop_fire_trigger := $StopFireTrigger
@onready var fire_traps := [$FireTrap1, $FireTrap2]


func _ready():
	fire_trigger.connect("press", on_fire_trigger_press.bind())
	stop_fire_trigger.connect("press", on_stop_trigger_press.bind())

func on_fire_trigger_press():
	if not stop_fire_trigger.pressed:
		for trap in fire_traps:
			trap.start_firing()

func on_stop_trigger_press():
	for trap in fire_traps:
		trap.stop_firing()
