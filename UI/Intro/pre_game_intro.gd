extends Control

signal complete

@onready var animation_player := $AnimationPlayer

var current_slide_index := 0
var can_skip := false
var animations = ["slide-1", "slide-2", "slide-3", "slide-4"]

func _process(delta):
	if Input.is_action_just_pressed("jump") or Input.is_action_just_pressed("ui_accept") and can_skip:
		on_end_slide()
		
func on_skippable():
	can_skip = true

func on_end_slide():
	can_skip = false
	current_slide_index += 1
	if current_slide_index > animations.size() - 1:
		emit_signal("complete")
		queue_free()
	else:
		animation_player.play(animations[current_slide_index])
