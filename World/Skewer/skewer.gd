extends Node2D

@onready var raycast := $RayCast2D

@export var ticks_between_creation := 50
@export var time_life := 1000

var ticks_start := -1
var duped := false
var dir := 1.0

func _ready():
	ticks_start = Time.get_ticks_msec()
	dir = scale.x
	GameSounds.play(GameSounds.Sound.Chop)

func _physics_process(delta):
	var elapsed = Time.get_ticks_msec() - ticks_start
	if not duped and not raycast.is_colliding() and elapsed > ticks_between_creation:
		create_duplicate()
	if elapsed > time_life:
		queue_free()

func create_duplicate():
	duped = true
	var dupe = duplicate()
	GameState.add_to_level(dupe)
	dupe.global_position = global_position + Vector2.RIGHT * dir * 8
	
