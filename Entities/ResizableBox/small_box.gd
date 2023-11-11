extends RigidBody2D

@onready var timer := $Timer
@onready var area := $Area2D

# Called when the node enters the scene tree for the first time.
func _ready():
	connect("body_entered", on_player_enter.bind())
	timer.connect("timeout", on_timer_timeout.bind())
	
func on_timer_timeout():
	area.monitorable = true
	
func on_player_enter(body):
	print(body)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
