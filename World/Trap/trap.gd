extends StaticBody2D

@onready var timer := $Timer
@onready var nosel_position := $NoselPosition

const Fireball = preload("res://FX/Fireball/fireball.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	timer.connect("timeout", on_timer_timeout.bind())


func on_timer_timeout():
	launch_fire()
	
func launch_fire():
	var fireball = Fireball.instantiate()
	fireball.initialize(Vector2.LEFT * 100, self)
	get_parent().add_child(fireball)
	fireball.global_position = nosel_position.global_position
	
