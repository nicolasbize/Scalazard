extends Node2D

var velocity := 0.0
var force := 0.0
var height := 0.0
var target_height := 0.0
var max_depth := 0.0

func update_water(spring_constant, damp):
	height = position.y
	var x = height - target_height
	var loss = -damp * velocity
	force = -spring_constant * x + loss
	velocity += force
	position.y += velocity
	if position.y > 0:
		position.y = min(position.y, max_depth / 2.0)
	if position.y < 0:
		position.y = max(position.y, -max_depth / 2.0)

func initialize(x_pos: float, depth: float):
	position.x = x_pos
	height = position.y
	target_height = position.y
	velocity = 0.0
	max_depth = depth
	
