extends StaticBody2D

@onready var timer := $Timer
@onready var nosel_position := $NoselPosition

@export var frequency_secs := 1.0
@export var fireball_speed := 150.0

const Fireball = preload("res://FX/Fireball/fireball.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	timer.connect("timeout", on_timer_timeout.bind())
	timer.wait_time = frequency_secs

func on_timer_timeout():
	launch_fire()
	
func launch_fire():
	var fireball = Fireball.instantiate()
	fireball.initialize(Vector2.RIGHT * scale.x * fireball_speed, self)
	GameState.add_to_level(fireball)
	fireball.global_position = nosel_position.global_position
	
