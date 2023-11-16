extends Node2D

@onready var sprite := $Sprite2D

func _ready():
	sprite.frame = randi_range(0, sprite.hframes - 1)

