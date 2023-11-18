extends Area2D

func is_colliding() -> bool:
	return has_overlapping_areas()

func get_push_vector() -> Vector2:
	var areas := get_overlapping_areas()
	var push_vector := Vector2.ZERO
	if is_colliding():
		var collided_area = get_overlapping_areas()[0]
		push_vector = Vector2(collided_area.global_position.x - global_position.x, 0).normalized()
	return push_vector
