extends Node2D

signal gotoboss

@onready var water_damage_area := $WaterDamageArea
@onready var platform_area := $Platform/PlayerDetectionArea
@onready var platform_particles := $Platform/GPUParticles2D
@onready var gem_doors := [$GemDoorGreen, $GemDoorBlue, $GemDoorPurple, $GemDoorYellow]
@onready var dracula := $Dracula
@onready var cinematic_player_area := $CinematicPlayerDetectionArea
@onready var dracula_speech_bubble := $DraculaSpeechBubble
@onready var dracula_speech_label := $DraculaSpeechBubble/Panel/Label
@onready var player_speech_bubble := $PlayerSpeechBubble
@onready var player_speech_label := $PlayerSpeechBubble/Panel/Label
@onready var top_right_door_trigger := $TriggerButton
@onready var prison_bars := $PrisonBars
@onready var platform_timer := $PlatformTimer
@onready var teleport_lines := [$GreenLine, $BlueLine, $PurpleLine, $YellowLine]

const ticks_between_water_damage := 1200
var last_damage_tick = Time.get_ticks_msec()
var player_in_water = null
var current_step := -1
var player = null
var can_travel_next_step := true
var time_between_cinematic_ticks := 500
var cinematic_ticks = Time.get_ticks_msec()
var teleport_line_destinations := [Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO]
var teleport_line_duration := 1000.0
var teleport_line_start := -1.0
var teleporting_lines := false

func _ready():
	water_damage_area.connect("body_entered", on_player_enter_water.bind())
	water_damage_area.connect("body_exited", on_player_exit_water.bind())
	platform_area.connect("body_entered", on_player_enter_platform.bind())
	platform_timer.connect("timeout", on_attempt_teleport.bind())
	if GameState.opened_center_court_door:
		prison_bars.set_opened()
	top_right_door_trigger.connect("press", on_player_open_top_right.bind())
	if GameState.visited_dracula_center:
		dracula.queue_free()
		cinematic_player_area.monitoring = false
		platform_particles.emitting = true
	else:
		cinematic_player_area.connect("body_entered", on_player_enter_cinematic.bind())
		dracula.connect("cinematic_finish", on_dracula_leave.bind())

func on_player_open_top_right():
	GameState.opened_center_court_door = true

func _process(delta):
	if in_cinematic():
		if Input.is_action_just_pressed("jump") and (Time.get_ticks_msec() - cinematic_ticks) > time_between_cinematic_ticks:
			cinematic_next_step()
	
	if teleporting_lines:
		var elapsed = Time.get_ticks_msec() - teleport_line_start
		var progress = min(1.0, elapsed / teleport_line_duration)
		if progress >= 1.0:
			teleporting_lines = false
			platform_timer.start()
		else:
			for i in range(teleport_lines.size()):
				var line = teleport_lines[i]
				line.points[1] = lerp(line.points[0], teleport_line_destinations[i], progress)
	
	if player_in_water != null and not player_in_water.can_swim():
		if Time.get_ticks_msec() - last_damage_tick > ticks_between_water_damage:
			last_damage_tick = Time.get_ticks_msec()
			player_in_water.on_player_hit(1, 0)
			
func on_player_exit_water(body):
	player_in_water = null
	last_damage_tick = Time.get_ticks_msec()

func on_player_enter_water(body):
	player_in_water = body
	last_damage_tick = Time.get_ticks_msec()

func on_player_enter_platform(body):
	if player == null:
		player = body
		player.connect("finish_teleport", on_transition_to_boss.bind())
	var gem_inserted := false
	for i in range(GameState.current_gems.size()):
		if GameState.current_gems[i] and not GameState.gems_inserted[i]:
			gem_doors[i].start()
			GameState.gems_inserted[i] = true
			gem_inserted = true
	if gem_inserted:
		GameSounds.play(GameSounds.Sound.PowerUp)
	if GameState.has_all_gems():
		show_teleport_lines()
		player.frozen = true

func show_teleport_lines():
	teleport_line_start = Time.get_ticks_msec()
	teleporting_lines = true
	for i in range(teleport_lines.size()):
		var line = teleport_lines[i]
		teleport_line_destinations[i] = line.points[1]
		line.points[1] = line.points[0]
		line.visible = true

func on_player_enter_cinematic(body):
	cinematic_ticks = Time.get_ticks_msec()
	player = body
	get_viewport().get_camera_2d().lock_to_target(Vector2(360, -90))
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
			dracula_speech_label.text = "Do you really think you can stop us?!"
		1:
			dracula_speech_bubble.visible = false
			player_speech_bubble.visible = true
			player_speech_bubble.global_position = player.global_position + Vector2.UP * 33
			player_speech_label.text = "There's only one way to find out..."
		2:
			dracula_speech_bubble.visible = true
			dracula_speech_label.text = "What a pity! Your kind is so weak!"
			player_speech_bubble.visible = false
		3:
			dracula_speech_label.text = "We will make a feast of you!"
		4:
			can_travel_next_step = false
			dracula_speech_bubble.visible = false
			dracula.disappear_up()
			GameSounds.play(GameSounds.Sound.Warp)

func on_dracula_leave():
	get_viewport().get_camera_2d().unlock()
	player.frozen = false
	cinematic_player_area.monitoring = false
	GameState.visited_dracula_center = true
	platform_particles.emitting = true

func on_attempt_teleport():
	player.teleport()
	GameSounds.play(GameSounds.Sound.Warp)

func on_transition_to_boss():
	emit_signal("gotoboss")
