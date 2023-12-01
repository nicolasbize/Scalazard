extends Path2D

@export var speed_platform := 4000
@export var progress_start := 0.0
@export var is_running := true
@export var one_shot := false

@onready var path_follow := $PathFollow2D
@onready var line := $Line2D

var time_start := Time.get_ticks_msec()

func _ready():
	curve = Curve2D.new()
	curve.add_point(Vector2.ZERO, Vector2.ZERO, Vector2.ZERO)
	curve.add_point(line.points[1], Vector2.ZERO, Vector2.ZERO)
	curve.add_point(Vector2.ZERO, Vector2.ZERO, Vector2.ZERO)
	calculate_progress()
	if GameState.difficulty == GameState.Difficulty.Easy:
		speed_platform *= 1.2
	elif GameState.difficulty == GameState.Difficulty.Hard:
		speed_platform *= 0.8

func start():
	is_running = true
	time_start = Time.get_ticks_msec()
	calculate_progress()

func calculate_progress():
	if progress_start != 0:
		time_start = int(Time.get_ticks_msec() - speed_platform * progress_start)
	update_platform_state()
		
func _physics_process(delta):
	if is_running:
		update_platform_state()
		
		
func update_platform_state():
	var time_elapsed = Time.get_ticks_msec() - time_start
	var progress = min(float(time_elapsed) / speed_platform, 1.0)
	path_follow.progress_ratio = progress
	if progress >= 1.0:
		if one_shot:
			is_running = false
		else:
			time_start = Time.get_ticks_msec()
	
