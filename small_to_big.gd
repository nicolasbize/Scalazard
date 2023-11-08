extends Sprite2D

const BigBox = preload("res://big_box.tscn")

func on_complete():
	var bigbox = BigBox.instantiate()
	get_parent().add_child(bigbox)
	bigbox.global_position = global_position + Vector2.UP * 14
	call_deferred("queue_free")
