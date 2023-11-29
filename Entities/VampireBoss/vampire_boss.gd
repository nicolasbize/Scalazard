extends Node2D

@export var player : Player

@onready var animation_player := $AnimationPlayer
@onready var sprite := $Sprite2D

enum State {Idle, Fly, Hurt, Dying, Dead, Cast}
var state := State.Idle



func on_finish_hurt():
	state = State.Idle
