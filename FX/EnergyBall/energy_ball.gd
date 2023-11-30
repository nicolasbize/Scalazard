extends Node2D

@export var speed_ball := 140.0

@onready var animation_player := $AnimationPlayer
@onready var ground_detection_area := $GroundDetectionArea2D

const Flame = preload("res://FX/Flame/flame.tscn")

var velocity = Vector2.ZERO

func _ready():
	GameSounds.play(GameSounds.Sound.FireballCreation)
	ground_detection_area.connect("body_entered", on_ground_collision.bind())

func on_ground_collision(body):
	if body is TileMap and global_position.y > -64:
		var flame = Flame.instantiate()
		GameState.add_to_level(flame)
		flame.global_position = global_position + Vector2.DOWN * 16
		GameSounds.play(GameSounds.Sound.FireballExplosion)
		queue_free()

func on_start_finish():
	velocity = Vector2.DOWN
	animation_player.play("fly")

func _physics_process(delta):
	if velocity != Vector2.ZERO:
		global_position += velocity * delta * speed_ball
