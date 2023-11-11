extends Sprite2D

@onready var raycast_left := $RaycastLeft
@onready var raycast_right := $RaycastRight
@onready var raycast_up := $RaycastUp
@onready var raycast_down := $RaycastDown

const BigBox = preload("res://Entities/ResizableBox/big_box.tscn")

func _physics_process(delta):
	if raycast_left.is_colliding():
		position.x += 1
	if raycast_right.is_colliding():
		position.x -= 1
	if raycast_up.is_colliding():
		position.y += 1
	if raycast_down.is_colliding():
		position.y -= 1

func on_complete():
	var bigbox = BigBox.instantiate()
	get_parent().add_child(bigbox)
	bigbox.global_position = global_position + Vector2.UP * 14
	call_deferred("queue_free")
