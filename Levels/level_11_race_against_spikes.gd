extends Node2D

@onready var moving_platform := $MovingPlatform
@onready var trigger_button := $TriggerButton

func _process(delta):
	if trigger_button.pressed:
		if not moving_platform.is_running:
			moving_platform.start()
		moving_platform.is_running = trigger_button.pressed
