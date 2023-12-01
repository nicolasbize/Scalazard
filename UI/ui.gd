extends CanvasLayer

signal in_transit
signal end_fade

@onready var life_container := $GameUI/VBoxContainer/HBoxContainer/LifeContainer
@onready var transition_animation := $TransitionScreen/AnimationPlayer
@onready var death_animation := $DeathScreen/AnimationPlayer
@onready var text_animation := $GameUI/VBoxContainer/MarginContainer/AnimationPlayer
@onready var system_label := $GameUI/VBoxContainer/MarginContainer/TextPanel/SystemLabel
@onready var fade_animation := $FadeToBlackScreen/AnimationPlayer
@onready var enemy_life_container := $GameUI/VBoxContainer/HBoxContainer/EnemyLifeContainer
@onready var enemy_health_bar := $GameUI/VBoxContainer/HBoxContainer/EnemyLifeContainer/EnemyHealthBar

@export var speed_typing := 2000

const FullHeart := preload("res://UI/full_heart.tscn")
const EmptyHeart := preload("res://UI/empty_heart.tscn")

var message_queue : Array[String] = [""]
var message_index := 0
var is_showing_messages := false
var original_enemy_health := 100.0
var target_enemy_health := 100.0
var enemy_health_change_start_ticks := -1
var enemy_health_change_duration := 300.0
var is_changing_enemy_health := false

# Called when the node enters the scene tree for the first time.
func _ready():
	GameState.connect("life_change", on_life_change.bind())
	GameState.connect("system_message", on_system_message.bind())
	refresh_life_ui()
	hide_enemy_bar()

func _process(delta):
	if is_showing_messages and is_input_pressed():
		show_next_text()
	if is_changing_enemy_health:
		var progress = clampf((Time.get_ticks_msec() - enemy_health_change_start_ticks) / enemy_health_change_duration, 0.0, 1.0)
		if progress >= 1.0:
			is_changing_enemy_health = false
		else:
			var health_size = lerpf(original_enemy_health, target_enemy_health, progress)
			enemy_health_bar.size.x = floor(health_size)

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

func show_enemy_bar():
	enemy_health_bar.size.x = 100
	enemy_life_container.visible = true

func update_enemy_health(old_health:int, new_health:int) -> void:
	original_enemy_health = old_health as float
	target_enemy_health = new_health as float
	enemy_health_change_start_ticks = Time.get_ticks_msec()
	is_changing_enemy_health = true

func hide_enemy_bar():
	enemy_life_container.visible = false

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
	
func fade_to_black():
	fade_animation.play("fade_to_black")

func on_end_fade():
	emit_signal("end_fade")
