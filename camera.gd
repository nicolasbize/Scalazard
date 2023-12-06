extends Camera2D

@export var player : CharacterBody2D
@export var tilemap : TileMap
@export var view_distance := 30.0
@export var shake_intensity := 10.0
@export var shake_decay_rate := 10.0

var target_destination := Vector2.ZERO
var shake_strength := 0.0
var locked_target := Vector2.ZERO

func _ready():
	GameState.hit_received.connect(screen_shake.bind())

func reset(hero, map):
	unlock()
	position_smoothing_enabled = false
	player = hero
	tilemap = map
	set_limits()
	calculate_target_destination()
	global_position = player.global_position

func lock_to_target(target:Vector2) -> void:
	locked_target = target

func unlock() -> void:
	locked_target = Vector2.ZERO

func set_limits():
	var used = tilemap.get_used_rect()
	limit_left = min(used.position.x * 16, limit_left)
	limit_right = max(used.end.x * 16, limit_right)
	limit_bottom = max(used.end.y * 16, limit_bottom)
	limit_top = min(used.position.y * 16, limit_top)
	
func _physics_process(delta):
	if locked_target != Vector2.ZERO:
		global_position = locked_target
		drag_horizontal_enabled = false
		shake_strength = lerpf(shake_strength, 0.0, shake_decay_rate * delta)
		offset = get_random_offset()
	elif player != null:
		calculate_target_destination()
		drag_horizontal_enabled = true
		global_position = target_destination
		shake_strength = lerpf(shake_strength, 0.0, shake_decay_rate * delta)
		offset = get_random_offset()
		if not position_smoothing_enabled:
			position_smoothing_enabled = true
	
func get_random_offset() -> Vector2:
	return Vector2(
		randf_range(-shake_strength, shake_strength),
		randf_range(-shake_strength, shake_strength)
	)

func calculate_target_destination() -> void:
	var target = player.camera_target.global_position + Vector2.UP * 50
	target.x += view_distance * player.get_direction()
	target_destination = target
	
func screen_shake():
	if GameState.is_screen_shake_enabled:
		shake_strength = shake_intensity
