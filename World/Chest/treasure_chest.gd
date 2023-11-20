class_name TreasureChest
extends Node2D

enum Content {GreenGem, BlueGem, PurpleGem, YellowGem, LifePotion}

signal open

@export var content : Content = Content.GreenGem

@onready var chest_sprite := $ChestSprite
@onready var player_area := $PlayerDetectionArea

var player = null
var is_opened := false

func _ready():
	if content != TreasureChest.Content.LifePotion and GameState.current_gems[content]:
		is_opened = true
	player_area.connect("body_entered", on_player_enter.bind())
	player_area.connect("body_exited", on_player_exit.bind())

func on_player_enter(body):
	player = body

func on_player_exit(body):
	player = null

func _process(delta):
	if is_opened:
		chest_sprite.frame = 1
	else:
		chest_sprite.frame = 0
	if not is_opened and player != null and player.can_pickup() and Input.is_action_just_pressed("crouch"):
		is_opened = true
		player.get_item(content)
		emit_signal("open")

