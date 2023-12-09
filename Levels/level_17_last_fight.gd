extends Node2D

signal boss_fight_start
signal boss_fight_end
signal boss_life_change

@export var slowdown_duration := 2000

@onready var dracula := $Dracula
@onready var cinematic_player_area := $CinematicPlayerDetectionArea
@onready var dracula_speech_bubble := $DraculaSpeechBubble
@onready var dracula_speech_label := $DraculaSpeechBubble/Panel/Label
@onready var player_speech_bubble := $PlayerSpeechBubble
@onready var player_speech_label := $PlayerSpeechBubble/Panel/Label
@onready var left_trigger := $LeftTrigger
@onready var left_connector := $LeftConnector
@onready var right_trigger := $RightTrigger
@onready var right_connector := $RightConnector
@onready var electric_lightning := $ElectricLightning
@onready var vampire_boss := $VampireBoss
@onready var player_detection_area := $PlayerDetectionArea
@onready var traps = [$Trap, $Trap2, $Trap3]
@onready var door = $Door

signal game_complete

var player = null
var time_slow_down := -1
var completed_level := false
var current_step := -1
var can_travel_next_step := true
var time_between_cinematic_ticks := 500
var cinematic_ticks = Time.get_ticks_msec()
var ready_for_end := false

func _ready():
	if GameState.visited_dracula_ending:
		dracula.queue_free()
		cinematic_player_area.monitoring = false
	else:
		cinematic_player_area.connect("body_entered", on_player_start_cinematic.bind())
		dracula.connect("cinematic_finish", on_dracula_leave.bind())
	vampire_boss.connect("die", on_boss_death.bind())
	vampire_boss.connect("hit", on_boss_hit.bind())
	player_detection_area.connect("body_entered", on_player_enter.bind())

func on_boss_hit(old_health, new_health):
	var enemy_health_tick = 100.0 / vampire_boss.max_life_boss
	emit_signal("boss_life_change", enemy_health_tick * old_health, enemy_health_tick * new_health)
	
func on_player_start_cinematic(body):
	player = body
	cinematic_ticks = Time.get_ticks_msec()
	get_viewport().get_camera_2d().lock_to_target(Vector2(-700, -90))
	player.frozen = true
	cinematic_next_step()

func in_cinematic() -> bool:
	return player != null and player.frozen

func cinematic_next_step():
	current_step += 1
	cinematic_ticks = Time.get_ticks_msec()
	match current_step:
		0:
			dracula_speech_bubble.visible = true
			dracula_speech_bubble.global_position = dracula.global_position + Vector2.UP * 33
			dracula_speech_label.text = "Well well, what have we here..."
		1:
			dracula_speech_bubble.visible = false
			player_speech_bubble.visible = true
			player_speech_bubble.global_position = player.global_position + Vector2.UP * 33
			player_speech_label.text = "Your time is coming to an end!"
		2:
			dracula_speech_bubble.visible = true
			dracula_speech_label.text = "Your sword cannot hurt me!"
			player_speech_bubble.visible = false
		3:
			can_travel_next_step = false
			dracula_speech_bubble.visible = false
			dracula.disappear_east()

func on_dracula_leave():
	get_viewport().get_camera_2d().unlock()
	player.frozen = false
	GameState.visited_dracula_ending = true
	cinematic_player_area.monitoring = false

func _process(delta):
	if in_cinematic():
		if Input.is_action_just_pressed("jump") and (Time.get_ticks_msec() - cinematic_ticks) > time_between_cinematic_ticks:
			cinematic_next_step()
	else:
		left_connector.is_charged = left_trigger.pressed
		right_connector.is_charged = right_trigger.pressed
		var was_visible = electric_lightning.visible
		electric_lightning.visible = left_connector.is_charged and right_connector.is_charged
		if not was_visible and electric_lightning.visible:
			GameSounds.play(GameSounds.Sound.ElectricCharge)
		elif not electric_lightning.visible:
			GameSounds.stop(GameSounds.Sound.ElectricCharge)
		if vampire_boss != null:
			vampire_boss.can_be_electrified = electric_lightning.visible
		if completed_level and (Time.get_ticks_msec() - time_slow_down > slowdown_duration):
			Engine.time_scale = 1
			emit_signal("boss_fight_end")
			for fireball in get_tree().get_nodes_in_group("projectile"):
				fireball.queue_free()
			if not ready_for_end:
				ready_for_end = true
				emit_signal("game_complete")

func on_player_enter(body):
	player_detection_area.set_deferred("monitoring", false)
	get_viewport().get_camera_2d().lock_to_target(Vector2(0, -96))
	vampire_boss.player = body
	for trap in traps:
		trap.start_firing()
	door.close()
	GameMusic.play_track(GameMusic.Track.Boss, false)
	emit_signal("boss_fight_start")

func on_boss_death():
	for trap in traps:
		trap.stop_firing()
	completed_level = true
	GameMusic.stop()
	GameSounds.play(GameSounds.Sound.Earthquake)
	GameSounds.play(GameSounds.Sound.Earthquake, true)
	GameSounds.play(GameSounds.Sound.Earthquake, true)
	time_slow_down = Time.get_ticks_msec()
	Engine.time_scale = 0.1

