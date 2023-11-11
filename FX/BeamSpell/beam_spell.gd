extends Node2D

@onready var line := $Line2D
@onready var circle := $Circle

func cast(cast_point: Vector2):
	line.points[1] = cast_point
	if cast_point.x > 0:
		line.points[0].x = 7
	else:
		line.points[0].x = -7
	var tween = get_tree().create_tween()
	tween.tween_property(circle, "scale", Vector2.ONE, 0.1)
	tween.tween_property(line, "width", 8, 0.1).set_trans(Tween.TRANS_CUBIC)
	tween.set_parallel(false)
	tween.tween_interval(0.3)
	tween.tween_property(line, "width", 0, 0.1)
	tween.tween_property(circle, "scale", Vector2.ZERO, 0.1)
	tween.tween_callback(queue_free)
		
