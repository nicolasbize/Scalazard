extends Area2D

var current_drops := 0
var last_tick_creation := Time.get_ticks_msec()
var fractional_drops := 0.0

@export var intensity := 10.0 # how many per second
@export var player : Player

@onready var shape := $CollisionShape2D

const RainDrop = preload("res://FX/Rain/rain_drop.tscn")

func _physics_process(delta):
	global_position = player.global_position - Vector2(100, 230)
	var current_time := Time.get_ticks_msec()
	var nb_drops_to_create = intensity * (current_time - last_tick_creation) / 1000.0
	if nb_drops_to_create < 1:
		fractional_drops += nb_drops_to_create
		if fractional_drops > 1:
			fractional_drops = 0.0
			create_drop()
	last_tick_creation = current_time

func create_drop():
	var drop = RainDrop.instantiate()
	get_parent().add_child(drop)
	var min_x = global_position.x
	var max_x = global_position.x + shape.shape.size.x
	drop.global_position = Vector2(randf_range(min_x, max_x), global_position.y)
