extends Node2D

signal end_activation

@onready var animation_player := $AnimationPlayer
@onready var door_sprite := $DoorSprite
@onready var light_sprite := $LightSprite
@onready var particles := $GPUParticles2D

@export var gem_color : TreasureChest.Content

var color_map = ["aaff9cf5", "9cc8fff5", "ff9cf5f5", "fffc9cf5"]

func _ready():
	door_sprite.frame = gem_color
	light_sprite.modulate = Color(color_map[gem_color])
	particles.modulate = Color(color_map[gem_color])
	if GameState.gems_inserted[gem_color]:
		start()
	else:
		particles.emitting = false

func start():
	animation_player.play("activate")
	door_sprite.frame += 4

func on_end_activate():
	emit_signal("end_activation")
