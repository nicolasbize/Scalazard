extends CanvasLayer

signal in_transit

@onready var life_container := $GameUI/VBoxContainer/LifeContainer
@onready var transition_animation := $TransitionScreen/AnimationPlayer
@onready var death_animation := $DeathScreen/AnimationPlayer

const FullHeart := preload("res://UI/full_heart.tscn")
const EmptyHeart := preload("res://UI/empty_heart.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	GameState.connect("life_change", on_life_change.bind())
	refresh_life_ui()

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
