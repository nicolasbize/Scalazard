extends Node2D

signal teleporting
signal teleported
signal cast
signal hit

@onready var animation_player := $AnimationPlayer
@onready var bigbox_damage_area := $BigBoxDamageArea

#TODO: most code from the level should actually live here, the boss can just become
#      aware of its surroundings and teleport as needed.

func _ready():
	bigbox_damage_area.connect("area_entered", on_damage_receive.bind())

func on_end_teleport():
	emit_signal("teleporting")

func on_reappear():
	animation_player.play("idle")
	emit_signal("teleported")

func on_damage_receive(area):
	emit_signal("hit")

func on_finish_cast_animation():
	emit_signal("cast")
	animation_player.play("idle")
