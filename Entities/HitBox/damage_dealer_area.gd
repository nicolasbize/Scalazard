extends Area2D

@export var damage = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	connect("area_entered", on_area_enter.bind())

func on_area_enter(area:Area2D):
	var parent = area.get_parent()
	# can't deal damage to yourself
	if parent != get_parent():
		parent.get_hurt(damage, sign(area.global_position.x - global_position.x))
