extends Node2D

@onready var traps := [$LeftFireTrap1, $LeftFireTrap2]
@onready var vertical_trap_trigger := $VerticalTrapTrigger
@onready var fire_trigger := $FireTrigger
@onready var stop_fire_trigger := $StopFireTrigger
@onready var vertical_trap := $VerticalWallTrap
@onready var treasure_chest := $TreasureChest

@export var vertical_trap_speed := 15.0

var is_vertical_trap_running := false

func _ready():
	if GameState.difficulty == GameState.Difficulty.Easy:
		vertical_trap_speed = 12.0
	elif GameState.difficulty == GameState.Difficulty.Hard:
		vertical_trap_speed = 20.0
	fire_trigger.connect("press", on_fire_trigger_press.bind())
	stop_fire_trigger.connect("press", on_stop_fire_trigger_press.bind())
	vertical_trap_trigger.connect("press", on_vertical_trap_press.bind())
	if GameState.level_14_heart_collected:
		treasure_chest.is_opened = true
	else:
		treasure_chest.connect("open", on_treasure_open.bind())

func on_treasure_open():
	GameState.level_14_heart_collected = true
	
func on_vertical_trap_press() -> void:
	is_vertical_trap_running = true
	GameSounds.play(GameSounds.Sound.DoorOpen)

func on_fire_trigger_press() -> void:
	for trap in traps:
		trap.start_firing()

func on_stop_fire_trigger_press() -> void:
	is_vertical_trap_running = false
	vertical_trap.global_position = Vector2(-1424, -384)
	fire_trigger.pressed = false
	vertical_trap_trigger.pressed = false
	for trap in traps:
		trap.stop_firing()

func _physics_process(delta):
	if is_vertical_trap_running:
		vertical_trap.global_position += Vector2.DOWN * delta * vertical_trap_speed
		if vertical_trap.global_position.y > -320:
			is_vertical_trap_running = false
			GameState.emit_signal("hit_received")
			GameSounds.play(GameSounds.Sound.Earthquake)
