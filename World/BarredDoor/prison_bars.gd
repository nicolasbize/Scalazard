class_name Door
extends Node2D

enum State {Open, Closed}

@export var state := State.Open

@onready var sprite := $Sprite2D
@onready var collision_shape := $StaticBody2D/CollisionShape2D
@onready var animation_player := $AnimationPlayer

# Called when the node enters the scene tree for the first time.
func _ready():
	if state == State.Closed:
		sprite.offset = Vector2.ZERO
		collision_shape.disabled = false

func open():
	if state == State.Closed:
		animation_player.play("open")
		state = State.Open

func close():
	if state == State.Open:
		animation_player.play("close")
		state = State.Closed

