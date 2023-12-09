class_name DamageDealerArea
extends Area2D

@export var damage := 0

func _physics_process(delta):
	if monitoring and has_overlapping_areas():
		var damage_receiver_area = get_overlapping_areas()[0]
		var parent = damage_receiver_area.get_parent()
		# can't deal damage to yourself
		if parent != get_parent():
			var direction_damage = sign(damage_receiver_area.global_position.x - global_position.x)
			damage_receiver_area.test_hit(damage, direction_damage)
