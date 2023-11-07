class_name ScalableObject
extends Node2D

enum Size {Small, Medium, Large}

@export var size : Size = Size.Medium
@export var charge_time := 1000

@onready var sprite := $Sprite2D
@onready var mouse_area := $MouseArea2D
@onready var rest_timer := $RestTimer

var hovered := false
var is_charging := false
var is_sizing := false
var charge_start_time := -1
var origin_offset : Vector2

func _ready():
	mouse_area.connect("mouse_entered", on_mouse_enter.bind())
	mouse_area.connect("mouse_exited", on_mouse_exit.bind())
	rest_timer.connect("timeout", on_rest_timeout.bind())
	origin_offset = sprite.offset

func _physics_process(delta):
	if is_sizing:
		sprite.material.set_shader_parameter("is_active", false);
	else:
		sprite.material.set_shader_parameter("is_active", hovered);
		if not hovered or not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			is_charging = false
		else:
			if not is_charging:
				is_charging = true
				charge_start_time = Time.get_ticks_msec()
			else:
				if Time.get_ticks_msec() - charge_start_time > charge_time:
					sizeup()

		if is_charging:
			sprite.offset = origin_offset + Vector2(randf_range(-1, 1), randf_range(-1, 1))

func on_mouse_enter():
	hovered = true

func on_mouse_exit():
	hovered = false

func sizeup():
	is_charging = false
	is_sizing = true
	var tween = create_tween().set_parallel(true)
	sprite.material.set_shader_parameter("is_active", false);
	tween.tween_property(sprite, "scale:x", scale.x * 2, 0.2)
	tween.tween_property(sprite, "scale:y", scale.y * 2, 0.2).set_trans(Tween.TRANS_BOUNCE)
	tween.tween_interval(1)
	tween.tween_callback(stop_motion)

func stop_motion():
	rest_timer.start()

func on_rest_timeout():
	is_sizing = false
