extends StaticBody2D

@onready var timer := $Timer
@onready var nosel_position := $NoselPosition

@export var frequency_secs := 1.0
@export var delay_secs := 0.0
@export var fireball_speed := 150.0
@export var firing := true

const Fireball = preload("res://FX/Fireball/fireball.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	timer.connect("timeout", on_timer_timeout.bind())
	if firing:
		start_firing()

func on_timer_timeout():
	if firing:
		launch_fire()

func start_firing():
	firing = true
	if delay_secs == 0:
		launch_fire()
	else:
		timer.start(delay_secs)

func stop_firing():
	firing = false
	timer.stop()

func launch_fire():
	var fireball = Fireball.instantiate()
	fireball.initialize(Vector2.RIGHT * scale.x * fireball_speed, self)
	GameState.add_to_level(fireball)
	fireball.global_position = nosel_position.global_position
	timer.start(frequency_secs)
	
