extends CanvasLayer

signal in_transit

@onready var life_container := $GameUI/VBoxContainer/LifeContainer
@onready var transition_animation := $TransitionScreen/AnimationPlayer
@onready var death_animation := $DeathScreen/AnimationPlayer
@onready var text_animation := $GameUI/VBoxContainer/MarginContainer/AnimationPlayer
@onready var system_label := $GameUI/VBoxContainer/MarginContainer/TextPanel/SystemLabel

@export var speed_typing := 2000

const FullHeart := preload("res://UI/full_heart.tscn")
const EmptyHeart := preload("res://UI/empty_heart.tscn")

var message_queue : Array[String] = [""]
var message_index := 0
var is_showing_messages := false

# Called when the node enters the scene tree for the first time.
func _ready():
	GameState.connect("life_change", on_life_change.bind())
	GameState.connect("system_message", on_system_message.bind())
	refresh_life_ui()

func _process(delta):
	if is_showing_messages and is_input_pressed():
		show_next_text()

func is_input_pressed() -> bool:
	return Input.is_action_just_pressed("jump") or Input.is_action_just_pressed("attack")

func on_life_change(current_life:int, max_life:int) -> void:
	refresh_life_ui()
	
func refresh_life_ui() -> void:
	for child in life_container.get_children():
		child.queue_free()
	for i in GameState.current_life:
		var full_heart = FullHeart.instantiate()
		life_container.add_child(full_heart)
	for i in (GameState.max_life - GameState.current_life):
		var empty_heart = EmptyHeart.instantiate()
		life_container.add_child(empty_heart)

func start_transition():
	transition_animation.play("in")

func on_black_screen():
	emit_signal("in_transit")

func end_transition():
	transition_animation.play("out")

func start_death():
	death_animation.play("death")

func reset_death():
	death_animation.play("RESET")

func on_system_message(text:Array[String]):
	message_queue = text
	message_index = 0
	text_animation.play("text_appear")

func on_ready_for_text():
	display_text()
	is_showing_messages = true

func show_next_text():
	message_index += 1
	if message_index < message_queue.size():
		display_text()
	else:
		text_animation.play("RESET")
		is_showing_messages = false
		GameState.resume_play()

func display_text():
	system_label.text = message_queue[message_index]
	
