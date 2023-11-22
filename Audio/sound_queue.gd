class_name SoundQueue
extends Node

var next := 0
var audio_stream_players : Array[AudioStreamPlayer] = []

# note: this node needs 1 single audiostreamplayer as child to work

@export var count: int = 1 :
	get:
		return count
	set(value):
		count = value

func _ready():
	var child_stream : AudioStreamPlayer = get_child(0)
	for i in count:
		var dupe = child_stream.duplicate()
		add_child(dupe)
		audio_stream_players.append(dupe)

func play_sound():
	if (not audio_stream_players[next].playing):
		audio_stream_players[next].play()
		next += 1
		next %= audio_stream_players.size()
