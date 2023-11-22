class_name DamageDealerArea
extends Area2D

@export var damage := 0

func _ready():
	connect("area_entered", on_area_enter.bind())

func on_area_enter(damage_receiver_area):
	var parent = damage_receiver_area.get_parent()
	# can't deal damage to yourself
	if parent != get_parent():
		var direction_damage = sign(damage_receiver_area.global_position.x - global_position.x)
		damage_receiver_area.emit_signal("hit", damage, direction_damage)
