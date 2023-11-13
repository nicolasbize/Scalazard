class_name SoundPool
extends Node

var sound_queues : Array[SoundQueue] = []
var last_index := -1

# note: this node needs at least 2 sound queues as children to work

func _ready():
	for child in get_children():
		if child is SoundQueue:
			sound_queues.append(child)

func play_random_sound():
	var index = last_index
	while index == last_index:
		index = randi_range(0, sound_queues.size() - 1)
	last_index = index
	print(index)
	sound_queues[index].play_sound()
