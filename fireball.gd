extends Node2D

@onready var area := $Area2D

var parent_trap = null
var velocity = Vector2.ZERO

func _ready():
	area.connect("body_entered", on_body_enter.bind())

func _physics_process(delta):
	position += velocity * delta

func initialize(vel:Vector2, trap: StaticBody2D):
	parent_trap = trap
	velocity = vel

func on_body_enter(body):
	if body != parent_trap:
		queue_free()
