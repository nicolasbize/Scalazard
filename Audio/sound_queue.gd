class_name SoundQueue
extends Node

var audio_stream_players : Array[AudioStreamPlayer] = []
var current_index_playing := 0

# note: this node needs 1 single audiostreamplayer as child to work

@export var nb_backup_duplicates := 0

func _ready():
	var original_stream = get_child(0)
	audio_stream_players.append(original_stream)
	for i in nb_backup_duplicates:
		var dupe = original_stream.duplicate()
		add_child(dupe)
		audio_stream_players.append(dupe)

func play_sound(alter_pitch: bool):
	if not audio_stream_players[current_index_playing].playing:
		check_alter_pitch(audio_stream_players[current_index_playing], alter_pitch)
		audio_stream_players[current_index_playing].play()
	elif nb_backup_duplicates > 0:
		current_index_playing += 1
		current_index_playing %= audio_stream_players.size()
		if not audio_stream_players[current_index_playing].playing:
			check_alter_pitch(audio_stream_players[current_index_playing], alter_pitch)
			audio_stream_players[current_index_playing].play()
		else:
			print("ran out of duplicate streams to play for " + name)

func stop():
	audio_stream_players[current_index_playing].stop()

func check_alter_pitch(stream: AudioStreamPlayer, alter_pitch: bool) -> void:
	if alter_pitch:
		stream.pitch_scale = randf_range(0.9, 1.1)
	else:
		stream.pitch_scale = 1
