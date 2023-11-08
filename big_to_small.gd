extends Sprite2D

const SmallBox = preload("res://small_box.tscn")

func on_complete():
	var smallbox = SmallBox.instantiate()
	get_parent().add_child(smallbox)
	smallbox.global_position = global_position
	call_deferred("queue_free")
