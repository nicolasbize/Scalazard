extends Node2D

@export var number_shakes := 4
@export var max_ticks_between_thunder := 3000

@onready var player_detection_area := $PlayerDetectionArea
@onready var prison_bars_animation_player := $PrisonBars/AnimationPlayer
@onready var treasure_chest := $TreasureChest
@onready var timer := $Timer
@onready var thunder_timer := $ThunderTimer
@onready var player_too_close_to_skeleton_area := $SkeletonKing/PlayerDetectionArea
@onready var skeleton_king := $SkeletonKing
@onready var skeleton_animation_player := $SkeletonKing/AnimationPlayer
@onready var skeleton_sprite := $SkeletonKing/Sprite2D
@onready var spawns := [$Spawn1, $Spawn2, $Spawn3, $Spawn4, $Spawn5, $Spawn6]
@onready var trap := $Trap

var level_started := false
var completed_level := false
var timed_out_count := 0
var previous_spawn : Node2D = null
var current_spawn_index := 0
var player = null
var nb_thunders := 1
var life_boss := 1
var ticks_since_last_thunder := Time.get_ticks_msec()

const Thunder := preload("res://FX/Thunder/thunder.tscn")
const HitSpark := preload("res://FX/HitSpark/hit_spark.tscn")

func _ready():
	if GameState.current_gems[TreasureChest.Content.PurpleGem]:
		treasure_chest.visible = true
		treasure_chest.is_opened = true
		skeleton_king.queue_free()
		trap.queue_free()
	else:
		player_detection_area.connect("body_entered", on_player_enter.bind())
		player_too_close_to_skeleton_area.connect("body_entered", on_player_close.bind())
		skeleton_king.connect("teleporting", on_skeleton_teleporting.bind())
		skeleton_king.connect("teleported", on_skeleton_teleported.bind())
		skeleton_king.connect("hit", on_skeleton_hit.bind())
		skeleton_king.connect("cast", attack_player.bind())
		previous_spawn = spawns[0]
	timer.connect("timeout", on_timer_timeout.bind())

func _process(delta):
	if level_started and not completed_level and (Time.get_ticks_msec() - ticks_since_last_thunder) > max_ticks_between_thunder:
		ticks_since_last_thunder = Time.get_ticks_msec()
		skeleton_animation_player.play("cast")

func on_player_close(body):
	skeleton_animation_player.play("teleport")

func on_skeleton_teleported():
	if Time.get_ticks_msec() - ticks_since_last_thunder > max_ticks_between_thunder:
		ticks_since_last_thunder = Time.get_ticks_msec()
		skeleton_animation_player.play("cast")

func on_skeleton_teleporting():
	var spawn = null
	while spawn == null:
		current_spawn_index = (current_spawn_index + 1) % spawns.size()
		spawn = spawns[current_spawn_index]
		var big_box_detector := spawn.get_child(0) as Area2D
		if big_box_detector.has_overlapping_bodies() or spawn == previous_spawn:
			spawn = null
		if spawn != null and spawn.get_child_count() > 1:
			var viable_platform_detector := spawn.get_child(1) as Area2D
			if viable_platform_detector.has_overlapping_bodies():
				var platform : CollapsingPlatform = viable_platform_detector.get_overlapping_bodies()[0].get_parent()
				if platform.state == CollapsingPlatform.State.Collapsed:
					spawn = null
	previous_spawn = spawn
	skeleton_king.global_position = spawn.global_position
	skeleton_sprite.scale.x = 1 if skeleton_king.global_position.x < -500 else -1
	skeleton_animation_player.play("reappear")
	
func attack_player():
	var thunder := Thunder.instantiate()
	GameState.add_to_level(thunder)
	thunder.global_position = Vector2(player.global_position.x, -208)
	GameState.emit_signal("hit_received")
	

func on_player_enter(body):
	player = body
	prison_bars_animation_player.play("close")
	player_detection_area.set_deferred("monitoring", false)
	get_viewport().get_camera_2d().lock_to_target(Vector2(-490, -96))
	timer.start(3)

func is_enemy_defeated() -> bool:
	return false

func on_timer_timeout():
	if timed_out_count < number_shakes:
		timed_out_count += 1
		GameState.emit_signal("hit_received")
		timer.start(.5)
	else:
		level_started = true
		trap.start_firing()

func on_skeleton_hit():
	life_boss -= 1
	GameState.emit_signal("hit_received")
	var hit_spark = HitSpark.instantiate()
	GameState.add_to_level(hit_spark)
	hit_spark.global_position = skeleton_king.global_position + Vector2.UP * 16
	if life_boss == 0:
		treasure_chest.visible = true
		completed_level = true
		trap.stop_firing()
		skeleton_king.queue_free()
		prison_bars_animation_player.play("open")
		get_viewport().get_camera_2d().unlock()
	else:
		on_skeleton_teleporting()
