extends Node2D

@onready var dracula := $Dracula
@onready var cinematic_player_area := $CinematicPlayerDetectionArea
@onready var dracula_speech_bubble := $DraculaSpeechBubble
@onready var dracula_speech_label := $DraculaSpeechBubble/Panel/Label
@onready var player_speech_bubble := $PlayerSpeechBubble
@onready var player_speech_label := $PlayerSpeechBubble/Panel/Label

var current_step := -1
var player = null
var can_travel_next_step := true

func _ready():
	if GameState.visited_dracula_entrance:
		dracula.queue_free()
		cinematic_player_area.monitoring = false
	else:
		cinematic_player_area.connect("body_entered", on_player_enter.bind())
		dracula.connect("cinematic_finish", on_dracula_leave.bind())

func _process(delta):
	if in_cinematic():
		if Input.is_action_just_pressed("jump"):
			cinematic_next_step()

func on_player_enter(body):
	player = body
	get_viewport().get_camera_2d().lock_to_target(Vector2(40, -90))
	player.frozen = true
	cinematic_next_step()

func in_cinematic() -> bool:
	return player != null and player.frozen

func cinematic_next_step():
	current_step += 1
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
			dracula_speech_label.text = "I will not waste my time with you!"
			player_speech_bubble.visible = false
		3:
			can_travel_next_step = false
			dracula_speech_bubble.visible = false
			dracula.disappear_east()

func on_dracula_leave():
	get_viewport().get_camera_2d().unlock()
	player.frozen = false
