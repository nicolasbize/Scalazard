extends Camera2D

@export var player : CharacterBody2D
@export var tilemap : TileMap
@export var view_distance := 30.0
@export var shake_intensity := 10.0
@export var shake_decay_rate := 10.0

var target_destination := Vector2.ZERO
var shake_strength := 0.0

func _ready():
	GameState.hit_received.connect(screen_shake.bind())

func reset(hero, map):
	position_smoothing_enabled = false
	player = hero
	tilemap = map
	set_limits()
	calculate_target_destination()
	global_position = target_destination
	position_smoothing_enabled = true

func set_limits():
	var used = tilemap.get_used_rect()
	limit_left = min(used.position.x * 16, limit_left)
	limit_right = max(used.end.x * 16, limit_right)
	limit_bottom = max(used.end.y * 16, limit_bottom)
	limit_top = min(used.position.y * 16, limit_top)
	
func _physics_process(delta):
	if player != null:
		calculate_target_destination()
		global_position = target_destination
		shake_strength = lerpf(shake_strength, 0.0, shake_decay_rate * delta)
		offset = get_random_offset()
	
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
	shake_strength = shake_intensity
