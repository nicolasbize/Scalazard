extends Node2D

@export var wall_speed := 17.0

@onready var trigger := $BottomDoorsTrigger
@onready var door_right := $DoorRight
@onready var player_detection_area := $PlayerDetectionArea
@onready var spike_wall := $MegaFloorSpike
@onready var vertical_wall_trigger := $VerticalWallTrigger
@onready var top_wall_trap := $TopWallTrap

var wall_velocity := Vector2.ZERO
var top_wall_velocity := Vector2.ZERO

func _ready():
	if GameState.difficulty == GameState.Difficulty.Easy:
		wall_speed = 12.0
	elif GameState.difficulty == GameState.Difficulty.Hard:
		wall_speed = 20.0
	player_detection_area.connect("body_entered", on_player_enter.bind())
	vertical_wall_trigger.connect("press", on_vertical_trap.bind())

func _physics_process(delta):
	if wall_velocity != Vector2.ZERO:
		if spike_wall.position.y > -1152:
			spike_wall.position += wall_velocity * delta
	if top_wall_velocity != Vector2.ZERO:
		if top_wall_trap.global_position.y < -1200:
			top_wall_trap.global_position += top_wall_velocity * delta

func on_vertical_trap():
	top_wall_velocity = Vector2.DOWN * wall_speed
	door_right.open()

func on_player_enter(player):
	if not trigger.pressed:
		wall_velocity = Vector2.UP * wall_speed
		door_right.close()
