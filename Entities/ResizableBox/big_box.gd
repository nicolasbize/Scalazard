extends RigidBody2D

@onready var raycast_left := $RaycastLeft
@onready var raycast_right := $RaycastRight
@onready var raycast_up := $RaycastUp
@onready var raycast_down := $RaycastDown

var is_growing := true

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	if is_growing:
		if raycast_left.is_colliding():
			position.x += 1
		if raycast_right.is_colliding():
			position.x -= 1
		if raycast_up.is_colliding():
			position.y += 1
		if raycast_down.is_colliding():
			position.y -= 1

func on_finish_growth():
	is_growing = false
