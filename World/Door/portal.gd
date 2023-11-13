class_name Portal
extends Area2D

enum DoorIndex {North, East, South, West}

@export var address_in_level : DoorIndex
@export var destination_level : GameState.Level
@export var destination_address : DoorIndex
@export var time_before_active_again := 5000

signal level_transition

var time_entered := Time.get_ticks_msec()

func _ready():
	time_entered = Time.get_ticks_msec()

func _physics_process(delta):
	var time_since_used = Time.get_ticks_msec() - time_entered
	if time_since_used > time_before_active_again and has_overlapping_bodies():
		use_portal()

func use_portal():
	time_entered = Time.get_ticks_msec()
	emit_signal("level_transition", destination_level, destination_address)
