extends RigidBody2D

@onready var raycast_left := $RaycastLeft
@onready var raycast_right := $RaycastRight
@onready var raycast_up := $RaycastUp
@onready var raycast_down := $RaycastDown
@onready var top_box_detection_area := $TopBoxDetectionArea
@onready var animation_player := $AnimationPlayer

var is_growing := false

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

func highlight():
	animation_player.play("targeted")

func stop_highlight():
	animation_player.play("RESET")

func has_box_on_top() -> bool:
	return top_box_detection_area.has_overlapping_bodies()

func get_box_on_top():
	return top_box_detection_area.get_overlapping_bodies()[0]
