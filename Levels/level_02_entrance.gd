extends Node2D

@onready var dracula := $Dracula
@onready var cinematic_player_area := $CinematicPlayerDetectionArea
@onready var dracula_speech_bubble := $DraculaSpeechBubble
@onready var dracula_speech_label := $DraculaSpeechBubble/Panel/Label
@onready var player_speech_bubble := $PlayerSpeechBubble
@onready var player_speech_label := $PlayerSpeechBubble/Panel/Label
@onready var treasure_chest := $TreasureChest

var current_step := -1
var player = null
var can_travel_next_step := true
var time_between_cinematic_ticks := 500
var cinematic_ticks = Time.get_ticks_msec()

func _ready():
	if GameState.visited_dracula_entrance:
		dracula.queue_free()
		cinematic_player_area.monitoring = false
	else:
		cinematic_player_area.connect("body_entered", on_player_enter.bind())
		dracula.connect("cinematic_finish", on_dracula_leave.bind())
	if GameState.hearts_collected.has(name):
		treasure_chest.is_opened = true
	else:
		treasure_chest.connect("open", on_treasure_open.bind())

func on_treasure_open():
	GameState.hearts_collected[name] = true

func _process(delta):
	if in_cinematic():
		if Input.is_action_just_pressed("jump") and (Time.get_ticks_msec() - cinematic_ticks) > time_between_cinematic_ticks:
			cinematic_next_step()

func on_player_enter(body):
	player = body
	cinematic_ticks = Time.get_ticks_msec()
	get_viewport().get_camera_2d().lock_to_target(Vector2(40, -90))
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
			dracula_speech_label.text = "Aaah... Looks like we have a visitor!"
		1:
			dracula_speech_bubble.visible = false
			player_speech_bubble.visible = true
			player_speech_bubble.global_position = player.global_position + Vector2.UP * 33
			player_speech_label.text = "Dracula! Your time has come!"
		2:
			dracula_speech_bubble.visible = true
			dracula_speech_label.text = "We will not waste our time with you!"
			player_speech_bubble.visible = false
		3:
			can_travel_next_step = false
			dracula_speech_bubble.visible = false
			dracula.disappear_east()

func on_dracula_leave():
	get_viewport().get_camera_2d().unlock()
	player.frozen = false
	GameState.visited_dracula_entrance = true
	cinematic_player_area.monitoring = false
