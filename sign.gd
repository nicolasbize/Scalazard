extends Node2D

@export var text : String

@onready var indicator_sprite := $IndicatorSprite
@onready var area := $Area2D
@onready var label := $Label
@onready var timer := $Timer

# Called when the node enters the scene tree for the first time.
func _ready():
	area.connect("body_entered", on_player_enter.bind())
	area.connect("body_exited", on_player_exit.bind())
	timer.connect("timeout", on_timer_timeout.bind())

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func on_player_enter(player):
	player.current_sign_indicator = self
	indicator_sprite.visible = true
	
func on_player_exit(player):
	player.current_sign_indicator = null
	indicator_sprite.visible = false
	label.visible = false

func on_timer_timeout():
	label.visible = false

func display_text():
	label.text = text
	label.visible = true
	timer.start()
