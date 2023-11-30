extends Node

@export var time_to_transition := 1000.0

@onready var active_music := $ActiveMusic

const trackMainMenu = preload("res://Assets/Music/main-menu.mp3")
const trackIntro = preload("res://Assets/Music/intro.mp3")
const trackGameplayIntro = preload("res://Assets/Music/torn-of-hope_Intro.mp3")
const trackGameplay = preload("res://Assets/Music/torn-of-hope.mp3")
const trackBossIntro = preload("res://Assets/Music/boss-fight_Intro.mp3")
const trackBoss = preload("res://Assets/Music/boss-fight.mp3")
const trackItemGain = preload("res://Assets/Music/item-gain.mp3")

enum Track {None, MainMenu, Intro, Gameplay, Boss, ItemGain}
const trackStreams = {
	Track.None: null,
	Track.MainMenu: [trackMainMenu],
	Track.Intro: [trackIntro],
	Track.Gameplay: [trackGameplayIntro, trackGameplay],
	Track.Boss: [trackBossIntro, trackBoss],
	Track.ItemGain: [trackItemGain],
}

var upcoming_track := Track.None
var is_fading_out := false
var is_fading_in := false
var ticks_since_fade_start := -1

func get_currently_playing() -> Track:
	if active_music.stream == null:
		return Track.None
	for track in trackStreams.keys():
		if track != Track.None and trackStreams[track].has(active_music.stream):
			return track
	return Track.None

func play_track(track: Track, is_fade: bool = true) -> void:
	if get_currently_playing() != track:
		if not is_fade:
			active_music.stop()
			active_music.stream = trackStreams[track][0]
			active_music.volume_db = 0
			active_music.play()
		else:
			upcoming_track = track
			is_fading_out = true
			ticks_since_fade_start = Time.get_ticks_msec()

func stop(is_fade: bool = true) -> void:
	if not is_fade:
		active_music.stop()
		active_music.stream = null
	else:
		is_fading_out = true
		ticks_since_fade_start = Time.get_ticks_msec()

func _ready():
	active_music.connect("finished", on_next_music_enqueue.bind())
	
func on_next_music_enqueue():
	var finished_music := get_currently_playing()
	if trackStreams[finished_music].size() > 1:
		active_music.stream = trackStreams[finished_music][1]
		active_music.play()

func _process(delta):
	if is_fading_out:
		var elapsed = Time.get_ticks_msec() - ticks_since_fade_start
		if elapsed < time_to_transition:
			var volume := lerpf(0, 1, elapsed / time_to_transition)
			active_music.volume_db = linear_to_db(1 - volume)
		else:
			active_music.stop()
			is_fading_out = false
			active_music.stream = null
			if upcoming_track != Track.None:
				active_music.stream = trackStreams[upcoming_track][0]
				active_music.play()
				is_fading_in = true
				ticks_since_fade_start = Time.get_ticks_msec()
				upcoming_track = Track.None
	elif is_fading_in:
		var elapsed = Time.get_ticks_msec() - ticks_since_fade_start
		if elapsed < time_to_transition:
			var volume := lerpf(0.0, 1.0, elapsed / time_to_transition)
			active_music.volume_db = linear_to_db(volume)
		else:
			is_fading_in = false
		
		

#
#enum Track {None, MainMenu, Intro, Gameplay, GameplayLoop, Boss, BossLoop, ItemGain}
#var track_defs = {}
#var is_fadeinout := false
#var ticks_since_fade_start := -1

#func _ready():
#	active_music.connect("finished", on_next_music_enqueue.bind())
#	track_defs = {
#		Track.None: null,
#		Track.MainMenu: main_menu_loop,
#		Track.Intro: intro,
#		Track.Gameplay: main_theme_intro,
#		Track.GameplayLoop: main_theme_loop,
#		Track.Boss: boss_fight_intro,
#		Track.BossLoop: boss_fight_loop,
#		Track.ItemGain: item_gain,
#	}
#	main_theme_intro.connect("finished", on_main_theme_transition.bind())
#	boss_fight_intro.connect("finished", on_boss_theme_transition.bind())

#func _process(delta):
#	if is_fadeinout:
#		var elapsed = Time.get_ticks_msec() - ticks_since_fade_start
#		if currently_playing != Track.None: # fading out
#			if elapsed < time_to_transition:
#				var volume := lerpf(0, 1, elapsed / time_to_transition)
#				track_defs[currently_playing].volume_db = linear_to_db(1 - volume)
#			else:
#				track_defs[currently_playing].stop()
#				ticks_since_fade_start = Time.get_ticks_msec()
#				currently_playing = Track.None				
#		elif upcoming_track != Track.None:
#			track_defs[upcoming_track].volume_db = linear_to_db(0)
#			track_defs[upcoming_track].play(0)
#			if elapsed < time_to_transition:
#				var volume := lerpf(0.0, 1.0, elapsed / time_to_transition)
#				track_defs[upcoming_track].volume_db = linear_to_db(volume)
#			else:
#				currently_playing = upcoming_track
#				upcoming_track = Track.None
#				is_fadeinout = false
#
#func on_main_theme_transition():
#	if main_theme_intro.volume_db == 0: # make sure we weren't fading it out
#		main_theme_loop.volume_db = 0 # normal volume
#		main_theme_loop.play()
#		currently_playing = Track.GameplayLoop
#
#func on_boss_theme_transition():
#	if boss_fight_intro.volume_db == 0:
#		boss_fight_loop.volume_db = 0
#		boss_fight_loop.play()
#		currently_playing = Track.BossLoop
#
#func is_track_playing(track: Track) -> bool:
#	if track == Track.MainMenu:
#		return main_menu_loop.playing
#	elif track == Track.Boss:
#		return boss_fight_intro.playing or boss_fight_loop.playing
#	elif track == Track.Intro:
#		return intro.playing
#	elif track == Track.Gameplay:
#		return main_theme_intro.playing or main_theme_loop.playing
#	return false
#
#func play(track: Track, fade_inout: bool = true):
#	if not is_track_playing(track):
#		if fade_inout:
#			ticks_since_fade_start = Time.get_ticks_msec()
#			is_fadeinout = true
#			upcoming_track = track
#		else:
#			is_fadeinout = false
#			if currently_playing != Track.None:
#				track_defs[currently_playing].stop()
#			currently_playing = track
#			track_defs[track].play()
#
#func stop(fade_inout: bool = true):
#	if currently_playing != Track.None:
#		if fade_inout:
#			ticks_since_fade_start = Time.get_ticks_msec()
#			is_fadeinout = true
#			upcoming_track = Track.None
#		else:
#			track_defs[currently_playing].stop()
