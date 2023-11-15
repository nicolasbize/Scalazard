extends Path2D

@export var speed_platform := 4000.0

@onready var path_follow := $PathFollow2D
@onready var line := $Line2D

var time_start := Time.get_ticks_msec()

func _ready():
	curve = Curve2D.new()
	curve.add_point(Vector2.ZERO, Vector2.ZERO, Vector2.ZERO)
	curve.add_point(line.points[1], Vector2.ZERO, Vector2.ZERO)
	curve.add_point(Vector2.ZERO, Vector2.ZERO, Vector2.ZERO)
	

func _physics_process(delta):
	var time_elapsed = Time.get_ticks_msec() - time_start
	var progress = min(time_elapsed / speed_platform, 1.0)
	path_follow.progress_ratio = progress
	if progress >= 1.0:
		time_start = Time.get_ticks_msec()
