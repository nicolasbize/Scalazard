class_name SoundPool
extends Node

@export var max_ticks_frequency := -1

var sound_queues : Array[SoundQueue] = []
var last_index := -1
var ticks_since_last_sound := -1

# note: this node needs at least 2 sound queues as children to work

func _ready():
	for child in get_children():
		if child is SoundQueue:
			sound_queues.append(child)

func play_random_sound(alter_pitch:bool):
	if Time.get_ticks_msec() - ticks_since_last_sound > max_ticks_frequency:
		ticks_since_last_sound = Time.get_ticks_msec()
		var index = last_index
		while index == last_index:
			index = randi_range(0, sound_queues.size() - 1)
		last_index = index
		sound_queues[index].play_sound(alter_pitch)

func stop():
	for child in get_children():
		if child is SoundQueue:
			child.stop()
	
