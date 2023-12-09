extends Node2D

signal boss_fight_start
signal boss_fight_end
signal boss_life_change

@export var number_shakes := 4
@export var slowdown_duration := 2000

@onready var player_detection_area := $PlayerDetectionArea
@onready var treasure_chest := $TreasureChest
@onready var timer := $Timer
@onready var boss := $SkeletonBoss
@onready var traps := [$Trap, $Trap2]

var level_started := false
var completed_level := false
var timed_out_count := 0
var player = null
var time_slow_down := -1

func _ready():
	if GameState.current_gems[treasure_chest.content]:
		treasure_chest.visible = true
		treasure_chest.is_opened = true
		for trap in traps:
			trap.queue_free()
	else:
		player_detection_area.connect("body_entered", on_player_enter.bind())
		boss.connect("hit", on_boss_hit.bind())
		boss.connect("die", on_boss_die.bind())
	timer.connect("timeout", on_timer_timeout.bind())
	
func _process(delta):
	if completed_level and (Time.get_ticks_msec() - time_slow_down > slowdown_duration):
		Engine.time_scale = 1
		emit_signal("boss_fight_end")
		for fireball in get_tree().get_nodes_in_group("projectile"):
			fireball.queue_free()

func on_boss_hit(old_health, new_health):
	var enemy_health_tick = 100.0 / boss.max_life_boss
	emit_signal("boss_life_change", enemy_health_tick * old_health, enemy_health_tick * new_health)

func on_player_enter(body):
	player = body
	player_detection_area.set_deferred("monitoring", false)
	get_viewport().get_camera_2d().lock_to_target(Vector2(528, 0))
	for trap in traps:
		trap.start_firing()
	boss.start_fight(player)
	GameMusic.play_track(GameMusic.Track.Boss, false)
	emit_signal("boss_fight_start")

func on_timer_timeout():
	if timed_out_count < number_shakes:
		timed_out_count += 1
		GameState.emit_signal("hit_received")
		GameSounds.play(GameSounds.Sound.Earthquake)
		timer.start(.5)
	else:
		level_started = true
		boss.start_fight(player)

func on_boss_die():
	treasure_chest.visible = true
	completed_level = true
	for trap in traps:
		trap.stop_firing()
	get_viewport().get_camera_2d().unlock()
	GameMusic.stop()
	GameSounds.play(GameSounds.Sound.Earthquake)
	GameSounds.play(GameSounds.Sound.Earthquake, true)
	time_slow_down = Time.get_ticks_msec()
	Engine.time_scale = 0.1
