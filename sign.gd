extends Node2D

@export var text : String

@onready var indicator_sprite := $IndicatorSprite
@onready var area := $Area2D
@onready var label := $Label

# Called when the node enters the scene tree for the first time.
func _ready():
	area.connect("body_entered", on_player_enter.bind())
	area.connect("body_exited", on_player_exit.bind())

func on_player_enter(player):
	display_text()
	
func on_player_exit(player):
	label.visible = false

func display_text():
	label.text = text
	label.visible = true
