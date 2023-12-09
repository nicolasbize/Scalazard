class_name DamageReceiverArea
extends Area2D

@export var cooldown := 300

var time_since_last_overlap := 0

signal hit(damage:int, direction:float)

func test_hit(dmg, dmg_sender):
	var elapsed = Time.get_ticks_msec() - time_since_last_overlap
	if elapsed > cooldown:
		emit_signal("hit", dmg, dmg_sender)
		time_since_last_overlap = Time.get_ticks_msec()
