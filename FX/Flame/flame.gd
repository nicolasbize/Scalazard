extends Node2D

@onready var left_raycast := $LeftWallRaycast
@onready var right_raycast := $RightWallRaycast

const Flame = preload("res://FX/Flame/flame.tscn")

var direction := Vector2.ZERO

func propagate():
	var flame = null
	if not left_raycast.is_colliding() and can_propagate_left():
		flame = Flame.instantiate()
		flame.direction = Vector2.LEFT
		GameState.add_to_level(flame)
		flame.global_position = global_position + Vector2.LEFT * 8
	if not right_raycast.is_colliding() and can_propagate_right():
		flame = Flame.instantiate()
		flame.direction = Vector2.RIGHT
		GameState.add_to_level(flame)
		flame.global_position = global_position + Vector2.RIGHT * 8
		
func can_propagate_left() -> bool:
	return direction == Vector2.ZERO or direction == Vector2.LEFT

func can_propagate_right() -> bool:
	return direction == Vector2.ZERO or direction == Vector2.RIGHT
