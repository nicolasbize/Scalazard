extends Node2D

@export var number_shakes := 4
@export var slowdown_duration := 2000

@onready var player_detection_area := $PlayerDetectionArea
@onready var treasure_chest := $TreasureChest
@onready var timer := $Timer
@onready var boss := $ShadowBoss
@onready var traps := [$Trap, $Trap2, $Trap3]
@onready var door := $PrisonBars

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
		boss.queue_free()
	else:
		player_detection_area.connect("body_entered", on_player_enter.bind())
		boss.connect("die", on_boss_die.bind())
	timer.connect("timeout", on_timer_timeout.bind())


func on_player_enter(body):
	player = body
	door.close()
	GameMusic.play_track(GameMusic.Track.Boss, false)
	player_detection_area.set_deferred("monitoring", false)
	get_viewport().get_camera_2d().lock_to_target(Vector2(-288, -96))
	for trap in traps:
		trap.start_firing()
	boss.start_fight(player)
	
func _process(delta):
	if completed_level and (Time.get_ticks_msec() - time_slow_down > slowdown_duration):
		Engine.time_scale = 1
		
func on_timer_timeout():
	if timed_out_count < number_shakes:
		timed_out_count += 1
		GameState.emit_signal("hit_received")
		GameSounds.play(GameSounds.Sound.Earthquake)
		timer.start(.5)
	else:
		level_started = true
		boss.start_fight(player)
		GameMusic.play_track(GameMusic.Track.Boss, false)

func on_boss_die():
	treasure_chest.visible = true
	completed_level = true
	for trap in traps:
		trap.stop_firing()
	door.open()
	get_viewport().get_camera_2d().unlock()
	GameMusic.stop()
	GameSounds.play(GameSounds.Sound.Earthquake)
	GameSounds.play(GameSounds.Sound.Earthquake, true)
	time_slow_down = Time.get_ticks_msec()
	Engine.time_scale = 0.1
