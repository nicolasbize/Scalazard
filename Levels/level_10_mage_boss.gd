extends Node2D

@export var number_shakes := 4
@export var max_ticks_between_thunder := 3000
@export var slowdown_duration := 2000

@onready var player_detection_area := $PlayerDetectionArea
@onready var prison_bars := $PrisonBars
@onready var treasure_chest := $TreasureChest
@onready var timer := $Timer
@onready var thunder_timer := $ThunderTimer
@onready var player_too_close_area := $MageBoss/PlayerDetectionArea
@onready var mage_boss := $MageBoss
@onready var mage_animation_player := $MageBoss/AnimationPlayer
@onready var mage_sprite := $MageBoss/Sprite2D
@onready var spawns := [$Spawn1, $Spawn2, $Spawn3, $Spawn4, $Spawn5, $Spawn6]
@onready var trap := $Trap

var level_started := false
var completed_level := false
var timed_out_count := 0
var player = null
var previous_spawn : Node2D = null
var current_spawn_index := 0
var nb_thunders := 1
var life_boss := 3
var ticks_since_last_thunder := Time.get_ticks_msec()
var is_teleporting := false
var time_slow_down := -1

const Thunder := preload("res://FX/Thunder/thunder.tscn")
const HitSpark := preload("res://FX/HitSpark/hit_spark.tscn")

func _ready():
	if GameState.current_gems[treasure_chest.content]:
		treasure_chest.visible = true
		treasure_chest.is_opened = true
		mage_boss.queue_free()
		trap.queue_free()
	else:
		player_detection_area.connect("body_entered", on_player_enter.bind())
		player_too_close_area.connect("body_entered", on_player_close.bind())
		mage_boss.connect("teleporting", on_mage_teleporting.bind())
		mage_boss.connect("teleported", on_mage_teleported.bind())
		mage_boss.connect("hit", on_mage_hit.bind())
		mage_boss.connect("cast", attack_player.bind())
		previous_spawn = spawns[0]
	timer.connect("timeout", on_timer_timeout.bind())

func _process(delta):
	if level_started and not completed_level and not is_teleporting and (Time.get_ticks_msec() - ticks_since_last_thunder) > max_ticks_between_thunder:
		ticks_since_last_thunder = Time.get_ticks_msec()
		mage_animation_player.play("cast")
	if completed_level and (Time.get_ticks_msec() - time_slow_down > slowdown_duration):
		Engine.time_scale = 1

func on_player_close(body):
	mage_animation_player.play("teleport")
	is_teleporting = true
	GameSounds.play(GameSounds.Sound.BossTeleport)

func on_mage_teleported():
	if Time.get_ticks_msec() - ticks_since_last_thunder > max_ticks_between_thunder:
		ticks_since_last_thunder = Time.get_ticks_msec()
		mage_animation_player.play("cast")
	is_teleporting = false

func on_mage_teleporting():
	teleport_king()

func teleport_king(default_spawn:Node2D = null) -> void:
	var spawn = default_spawn
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
	mage_boss.global_position = spawn.global_position
	mage_sprite.scale.x = 1 if mage_boss.global_position.x < -500 else -1
	mage_animation_player.play("reappear")
	

func attack_player():
	var thunder := Thunder.instantiate()
	GameState.add_to_level(thunder)
	thunder.global_position = Vector2(player.global_position.x - 16, -208)

func on_player_enter(body):
	player = body
	prison_bars.close()
	player_detection_area.set_deferred("monitoring", false)
	get_viewport().get_camera_2d().lock_to_target(Vector2(-448, -96))
	timer.start(3)

func on_timer_timeout():
	if timed_out_count < number_shakes:
		timed_out_count += 1
		GameState.emit_signal("hit_received")
		GameSounds.play(GameSounds.Sound.Earthquake)
		timer.start(.5)
	else:
		level_started = true
		trap.start_firing()
		mage_boss.global_position = spawns[2].global_position
		GameMusic.play_track(GameMusic.Track.Boss, false)
		
func on_mage_hit():
	life_boss -= 1
	GameState.emit_signal("hit_received")
	var hit_spark = HitSpark.instantiate()
	GameState.add_to_level(hit_spark)
	hit_spark.global_position = mage_boss.global_position + Vector2.UP * 16
	if life_boss == 0:
		treasure_chest.visible = true
		completed_level = true
		trap.stop_firing()
		mage_boss.queue_free()
		prison_bars.open()
		get_viewport().get_camera_2d().unlock()
		GameMusic.stop()
		GameSounds.play(GameSounds.Sound.Earthquake)
		GameSounds.play(GameSounds.Sound.Earthquake, true)
		time_slow_down = Time.get_ticks_msec()
		Engine.time_scale = 0.1
	else:
		on_mage_teleporting()
