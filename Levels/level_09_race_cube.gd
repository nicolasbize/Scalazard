extends Node2D

@onready var trigger_button := $TriggerButton
@onready var moving_platform := $MainMovingPlatform
@onready var platform_sprite := $MainMovingPlatform/AnimatableBody2D/Sprite2D
@onready var smallbox_detection_area := $MainMovingPlatform/AnimatableBody2D/SmallBoxDetectionArea

var small_box_anchor = Vector2.ZERO
var small_box = null
var started := false

func _ready():
	trigger_button.connect("press", on_trigger_press.bind())
	smallbox_detection_area.connect("body_entered", on_small_box_enter.bind())

func _physics_process(delta):
	if small_box != null:
		small_box.global_position = platform_sprite.global_position + small_box_anchor
	
func on_small_box_enter(box):
	if small_box == null:
		small_box = box
		small_box_anchor = box.global_position - platform_sprite.global_position

func on_trigger_press():
	moving_platform.start()
	started = true
