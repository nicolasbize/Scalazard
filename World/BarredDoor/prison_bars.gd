class_name Door
extends Node2D

enum State {Open, Closed}

@export var state := State.Open

@onready var sprite := $Sprite2D
@onready var collision_shape := $StaticBody2D/CollisionShape2D
@onready var animation_player := $AnimationPlayer

func _ready():
	if state == State.Closed:
		animation_player.play("closed")
	else:
		animation_player.play("opened")

func open():
	if state == State.Closed:
		animation_player.play("open")
		state = State.Open
		GameSounds.play(GameSounds.Sound.DoorOpen)

func set_opened():
	state = State.Open
	animation_player.play("opened")

func set_closed():
	state = State.Closed
	animation_player.play("closed")

func close():
	if state == State.Open:
		animation_player.play("close")
		state = State.Closed
		GameSounds.play(GameSounds.Sound.DoorClose)

