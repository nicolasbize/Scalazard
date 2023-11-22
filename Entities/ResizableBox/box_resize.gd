class_name BoxResize
extends Node2D

@onready var animation_player := $AnimationPlayer
@onready var raycast_left := $RaycastLeft
@onready var raycast_right := $RaycastRight
@onready var raycast_up := $RaycastUp
@onready var raycast_down := $RaycastDown

@export var size_mode := SizeType.Expand

enum SizeType {Expand = 0, Shrink = 1}

const BigBox = preload("res://Entities/ResizableBox/big_box.tscn")
const SmallBox = preload("res://Entities/ResizableBox/small_box.tscn")

func _ready():
	if size_mode == SizeType.Expand:
		animation_player.play("expand")
	else:
		animation_player.play("shrink")

func _physics_process(delta):
	if size_mode == SizeType.Expand:
		if raycast_left.is_colliding():
			position.x += 1
		if raycast_right.is_colliding():
			position.x -= 1
		if raycast_up.is_colliding():
			position.y += 1
		if raycast_down.is_colliding():
			position.y -= 1

func on_complete():
	if size_mode == SizeType.Shrink:
		var smallbox = SmallBox.instantiate()
		GameState.add_to_level(smallbox)
		smallbox.global_position = global_position
	else:
		var bigbox = BigBox.instantiate()
		GameState.add_to_level(bigbox)
		bigbox.global_position = global_position + Vector2.UP * 14
	call_deferred("queue_free")
