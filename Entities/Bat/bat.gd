extends Node2D

@export var fly_speed_min := 0.2
@export var fly_speed_max := 0.3
@export var current_life := 1

@onready var paths := [$PathLeft/Path2D/PathFollow2D, $PathRight/Path2D/PathFollow2D]
@onready var player_detection_areas := [$PathLeft/PlayerDetectionArea, $PathRight/PlayerDetectionArea]
@onready var wall_detection_areas := [$PathLeft/WallDetectionArea, $PathRight/WallDetectionArea]
@onready var animal := $Animal
@onready var sprite := $Animal/Sprite2D
@onready var damage_receiver_area := $Animal/DamageReceiverArea
@onready var damage_dealer_area := $Animal/DamageDealerArea
@onready var animation_player := $Animal/AnimationPlayer
@onready var sfx_hit := $SFXHit

const HitSpark = preload("res://FX/HitSpark/hit_spark.tscn")

enum State {Idle, StartFlying, Fly, Dying}

var state = State.Idle
var anim_states = {
	State.Idle: "idle",
	State.StartFlying: "start_fly",
	State.Fly: "fly",
	State.Dying: "die",
}
var current_path_index := -1
var fly_speed := 0.0

func _ready():
	damage_receiver_area.connect("hit", on_enemy_hit.bind())

func _physics_process(delta):
	damage_dealer_area.monitoring = current_life > 0
	if state == State.Idle:
		if GameState.current_life > 0:
			var index_valid_path = get_valid_path()
			if index_valid_path > -1:
				state = State.StartFlying
				current_path_index = index_valid_path
	elif current_path_index > -1:
		if current_path_index == 0:
			sprite.scale.x = -1.0
		else:
			sprite.scale.x = 1.0
		var progress = delta * fly_speed
		if paths[current_path_index].progress_ratio + progress > 1.0:
			paths[current_path_index].progress_ratio = 1.0
			reset_at_current_position()
		else:
			paths[current_path_index].progress_ratio += progress
			animal.global_position = paths[current_path_index].get_child(0).global_position
	animation_player.play(anim_states[state])

func reset_at_current_position():
	state = State.Idle
	paths[current_path_index].progress_ratio = 0.0
	current_path_index = -1
	global_position = animal.global_position
	animal.position = Vector2.ZERO

func on_end_start_fly():
	state = State.Fly
	fly_speed = randf_range(fly_speed_min, fly_speed_max)

func on_enemy_hit(dmg:int, direction_knockback:float) -> void:
	damage_dealer_area.set_deferred("monitoring", false)
	damage_receiver_area.set_deferred("monitorable", false)
	current_life -= dmg
	state = State.Dying
	current_path_index = -1
	var hit_spark = HitSpark.instantiate()
	get_parent().add_child(hit_spark)
	hit_spark.global_position = sprite.global_position + Vector2.RIGHT * direction_knockback * 16
	hit_spark.scale.x = direction_knockback
	GameState.emit_signal("hit_received")
	sfx_hit.play_sound()
	
func get_valid_path() -> int:
	for i in range(0, player_detection_areas.size()):
		var player_detection_area : Area2D = player_detection_areas[i]
		var wall_detection_area : Area2D = wall_detection_areas[i]
		if player_detection_area.has_overlapping_bodies() and not wall_detection_area.has_overlapping_bodies():
			return i
	return -1
