extends StaticBody2D

@onready var timer := $Timer
@onready var nosel_position := $NoselPosition
@onready var player_detection_area := $PlayerDetectionArea

@export var frequency_secs := 1.0
@export var delay_secs := 0.0
@export var fireball_speed := 150.0
@export var firing := true

const Fireball = preload("res://FX/Fireball/fireball.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	timer.connect("timeout", on_timer_timeout.bind())
	if GameState.difficulty == GameState.Difficulty.Easy:
		frequency_secs *= 1.2
		fireball_speed *= 0.8
	elif GameState.difficulty == GameState.Difficulty.Hard:
		frequency_secs *= .8
		fireball_speed *= 1.2
	if firing:
		start_firing()

func on_timer_timeout():
	if firing:
		launch_fire()

func fire_once():
	launch_fire()
	firing = false

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
	if player_detection_area.has_overlapping_bodies():
		GameSounds.play(GameSounds.Sound.Fireball)
	
