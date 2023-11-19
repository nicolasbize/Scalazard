extends Node2D

@export var ms_before_collapse := 1000
@export var ms_before_fix := 2000
@export var one_way := false

@onready var player_detection_area := $PlayerDetectionArea
@onready var sprite := $Sprite2D
@onready var collider := $StaticBody2D/CollisionShape2D

enum State { Stable, Collapsed }

var state = State.Stable
var time_on_enter := Time.get_ticks_msec()
var time_on_collapse := Time.get_ticks_msec()
var entered = false
var landed = false
var player = null

# Called when the node enters the scene tree for the first time.
func _ready():
	player_detection_area.connect("body_entered", on_body_enter.bind())
	player_detection_area.connect("body_exited", on_body_exit.bind())


func on_body_exit(body):
	player = null
	entered = false

func on_body_enter(body):
	entered = true
	player = body
	
func _physics_process(delta):
	if entered and not landed:
		if abs(player.velocity.y) < 0.1:
			landed = true
			time_on_enter = Time.get_ticks_msec()
	if landed and (Time.get_ticks_msec() - time_on_enter) > ms_before_collapse:
		if state == State.Stable:
			state = State.Collapsed
			if not one_way:
				time_on_collapse = Time.get_ticks_msec()
		elif state == State.Collapsed and (Time.get_ticks_msec() - time_on_collapse) > ms_before_fix:
			state = State.Stable
			entered = false
			landed = false
	if state == State.Stable:
		sprite.frame = 0
		player_detection_area.set_deferred("monitoring", true)
		collider.set_deferred("disabled", false) 
	else:
		sprite.frame = 1
		player_detection_area.set_deferred("monitoring", false)
		collider.set_deferred("disabled", true) 
		
