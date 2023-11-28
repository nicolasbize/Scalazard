extends Node

@export var time_to_transition := 1000.0

@onready var intro := $Intro
@onready var main_menu_loop := $MainMenuLoop
@onready var main_theme_intro := $ThemeIntro
@onready var main_theme_loop := $ThemeLoop
@onready var boss_fight_intro := $BossFightIntro
@onready var boss_fight_loop := $BossFightLoop

enum Track {None, MainMenu, Intro, Gameplay, GameplayLoop, Boss, BossLoop}
var track_defs = {}
var currently_playing := Track.None
var upcoming_track := Track.None
var is_fadeinout := false
var ticks_since_fade_start := -1

func _ready():
	track_defs = {
		Track.None: null,
		Track.MainMenu: main_menu_loop,
		Track.Intro: intro,
		Track.Gameplay: main_theme_intro,
		Track.GameplayLoop: main_theme_loop,
		Track.Boss: boss_fight_intro,
		Track.BossLoop: boss_fight_loop,
	}
	main_theme_intro.connect("finished", on_main_theme_transition.bind())
	boss_fight_intro.connect("finished", on_boss_theme_transition.bind())

func _process(delta):
	if is_fadeinout:
		var elapsed = Time.get_ticks_msec() - ticks_since_fade_start
		if currently_playing != Track.None: # fading out
			if elapsed > time_to_transition:
				track_defs[currently_playing].stop()
				currently_playing = Track.None
				ticks_since_fade_start = Time.get_ticks_msec()
			else:
				var volume := lerpf(0, 1, elapsed / time_to_transition)
				track_defs[currently_playing].volume_db = linear_to_db(1 - volume)
		elif upcoming_track != Track.None:
			if not track_defs[upcoming_track].playing:
				track_defs[upcoming_track].volume_db = linear_to_db(0)
				track_defs[upcoming_track].play()
			if elapsed > time_to_transition:
				currently_playing = upcoming_track
				upcoming_track = Track.None
				is_fadeinout = false
			else:
				var volume := lerpf(0.0, 1.0, elapsed / time_to_transition)
				track_defs[upcoming_track].volume_db = linear_to_db(volume)
			
func on_main_theme_transition():
	main_theme_loop.play()
	currently_playing = Track.GameplayLoop

func on_boss_theme_transition():
	boss_fight_loop.play()
	currently_playing = Track.BossLoop

func is_track_playing(track: Track) -> bool:
	if track == Track.MainMenu:
		return main_menu_loop.playing
	elif track == Track.Boss:
		return boss_fight_intro.playing or boss_fight_loop.playing
	elif track == Track.Intro:
		return intro.playing
	elif track == Track.Gameplay:
		return main_theme_intro.playing or main_theme_loop.playing
	return false

func play(track: Track, fade_inout: bool = true):
	if not is_track_playing(track):
		if fade_inout:
			ticks_since_fade_start = Time.get_ticks_msec()
			is_fadeinout = true
			upcoming_track = track
		else:
			is_fadeinout = false
			currently_playing = track
			track_defs[track].play()

func stop(fade_inout: bool = true):
	if currently_playing != Track.None:
		if fade_inout:
			ticks_since_fade_start = Time.get_ticks_msec()
			is_fadeinout = true
			upcoming_track = Track.None
		else:
			track_defs[currently_playing].stop()
