class_name BeamSpell
extends Node2D

@onready var circle := $Circle
@onready var beam := $Beam

const BoxResize = preload("res://Entities/ResizableBox/box_resize.tscn")

var time_start_cast := Time.get_ticks_msec()
var resizing := false
const time_to_initiate := 100.0
const time_to_beam := time_to_initiate + 200.0
const time_to_debeam := time_to_beam + 300.0
const time_to_end := time_to_debeam + 100.0
const width_end := 6

var target = null

func cast_to(resizable_object: Node2D) -> void:
	target = resizable_object
	time_start_cast = Time.get_ticks_msec()

func _physics_process(delta):
	var time_elapsed = Time.get_ticks_msec() - time_start_cast
	if target != null:
		var init_progress : float = min(time_elapsed / time_to_initiate, 1.0)
		circle.scale = circle.scale.lerp(Vector2.ONE, init_progress)
		if init_progress >= 1.0:
			var beam_direction : Vector2 = (target.global_position - global_position).normalized()
			var beam_distance : float = (target.global_position - global_position).length()
			var beam_progress : float = min(time_elapsed / time_to_beam, 1.0)
			beam.scale.x = lerpf(0, beam_distance, beam_progress)
			beam.rotation = beam_direction.angle()
			if beam_progress >= 1.0:
				if not resizing:
					resize_box()
	elif resizing:
		var beam_disappear : float = min(time_elapsed / time_to_debeam, 1.0)
		beam.scale.x = lerpf(beam.scale.x, 0.0, beam_disappear)
		if beam_disappear <= 1.0:
			var end_progress : float = min(time_elapsed / time_to_end, 1.0)
			circle.scale = circle.scale.lerp(Vector2.ZERO, end_progress)

func resize_box():
	resizing = true
	var box_resize : BoxResize = BoxResize.instantiate()
	if target.is_in_group("shrinkable"):
		box_resize.size_mode = 1
		
	elif target.is_in_group("expandable"):
		box_resize.size_mode = 0
	GameState.add_to_level(box_resize)
	box_resize.global_position = target.global_position
	target.queue_free()
	
