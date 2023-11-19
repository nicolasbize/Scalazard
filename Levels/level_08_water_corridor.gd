extends Node2D

@onready var trigger_button := $TriggerButton
@onready var traps := [$Trap, $Trap2]

func _ready():
	trigger_button.connect("press", on_press_button.bind())

func on_press_button():
	for trap in traps:
		trap.start_firing()
