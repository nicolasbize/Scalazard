class_name Portal
extends Area2D

enum DoorIndex {North, East, South, West}

@export var address_in_level : DoorIndex
@export var destination_level : GameState.Level
@export var destination_address : DoorIndex
@onready var spawn := $Spawn

signal level_transition

func _ready():
	connect("body_entered", on_body_enter.bind())

func on_body_enter(body):
	emit_signal("level_transition", destination_level, destination_address)

func get_spawn_location() -> Vector2:
	return spawn.global_position
