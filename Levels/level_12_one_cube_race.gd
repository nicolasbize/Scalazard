extends Node2D

@export var wall_speed := 25.0

@onready var entrance_trigger := $EntranceTrigger
@onready var spike_wall := $SpikeWall
@onready var elevator := $Elevator1
@onready var elevator_trigger := $ElevatorTrigger
@onready var traps := [$Trap3, $Trap4, $Trap5, $Trap6, $Trap7]

var wall_velocity := Vector2.ZERO
var level_completed := false

func _ready():
	entrance_trigger.connect("press", start_spike_wall.bind())
	elevator_trigger.connect("press", on_elevator_press.bind())
	if GameState.difficulty == GameState.Difficulty.Easy:
		wall_speed = 20.0
	elif GameState.difficulty == GameState.Difficulty.Hard:
		wall_speed = 35.0
	
func _physics_process(delta):
	if wall_velocity != Vector2.ZERO:
		if spike_wall.position.x < 1800:
			spike_wall.position += wall_velocity * delta
		elif not level_completed:
			level_completed = true
			GameState.emit_signal("hit_received")
			for trap in traps:
				trap.stop_firing()

func on_elevator_press():
	elevator.start()

func start_spike_wall():
	wall_velocity = Vector2.RIGHT * wall_speed
