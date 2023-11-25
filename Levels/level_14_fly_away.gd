extends Node2D

@onready var traps := [$LeftFireTrap1, $LeftFireTrap2]
@onready var vertical_trap_trigger := $VerticalTrapTrigger
@onready var fire_trigger := $FireTrigger
@onready var vertical_trap := $VerticalWallTrap

@export var vertical_trap_speed := 20.0

var is_vertical_trap_running := false

func _ready():
	fire_trigger.connect("press", on_fire_trigger_press.bind())
	vertical_trap_trigger.connect("press", on_vertical_trap_press.bind())

func on_vertical_trap_press() -> void:
	is_vertical_trap_running = true
	GameSounds.play(GameSounds.Sound.DoorOpen)

func on_fire_trigger_press() -> void:
	for trap in traps:
		trap.start_firing()

func _physics_process(delta):
	if is_vertical_trap_running:
		vertical_trap.global_position += Vector2.DOWN * delta * vertical_trap_speed
		if vertical_trap.global_position.y > -320:
			is_vertical_trap_running = false
			GameState.emit_signal("hit_received")
			GameSounds.play(GameSounds.Sound.Earthquake)
