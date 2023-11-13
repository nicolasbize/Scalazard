extends Node2D

@onready var line := $Line2D
@onready var circle := $Circle
@onready var end_beam := $EndBeam

const width_end := 6

func cast(cast_point: Vector2):
	var direction = 1.0
	line.points[1] = cast_point
	end_beam.position.x = line.points[1].x
	if cast_point.x > 0:
		line.points[0].x = 7
		line.points[1].x -= width_end
		end_beam.position.x -= width_end
	else:
		line.points[0].x = -7
		direction = -1.0
		end_beam.scale.x = -1.0
		line.points[1].x += width_end
		end_beam.position.x += 4
	
	var tween = get_tree().create_tween()
	tween.tween_property(circle, "scale", Vector2.ONE, 0.1)
	tween.tween_property(end_beam, "scale:x", direction, 0.1).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(line, "width", 8, 0.1).set_trans(Tween.TRANS_CUBIC)
	
	tween.set_parallel(false)
	tween.tween_interval(0.3)
	tween.tween_property(end_beam, "scale:x", 0, 0.1).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(line, "width", 0, 0.1)
	tween.tween_property(circle, "scale", Vector2.ZERO, 0.1)
	tween.tween_callback(queue_free)
		
