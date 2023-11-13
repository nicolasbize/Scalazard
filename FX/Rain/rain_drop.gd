extends Sprite2D

@export var speed := 10.0

@onready var area := $Area2D

var direction = Vector2(-1.0, 1.0)

func _ready():
	area.connect("body_entered", on_body_entered.bind())
	direction = Vector2(randf_range(-0.95, -1.05), randf_range(0.95, 1.05))
	speed = randf_range(130.0, 160.0)
	

func on_body_entered(body):
	queue_free()

func _physics_process(delta):
	position += direction * speed * delta
