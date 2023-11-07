extends Line2D

signal complete

@export var speed := 300.0
@onready var raycast := $RayCast2D

var can_grow := true
var size := 0.0
var dir := 1.0
var ticks_colliding := 0

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	can_grow = not raycast.is_colliding()
	if can_grow:
		ticks_colliding = Time.get_ticks_msec()
		size = size + dir * delta * speed
		points[1].x = size
		raycast.target_position.x = size
	else:
		var time_collision = Time.get_ticks_msec() - ticks_colliding
		if time_collision > 300:
			emit_signal("complete", raycast.get_collider())
	
