extends Node2D

signal boss_fight_start
signal boss_fight_end
signal boss_life_change

@export var time_between_enemies := 1.5
@export var number_enemies := 5
@export var number_shakes := 3
@export var slowdown_duration := 2000

@onready var player_detection_area := $PlayerDetectionArea
@onready var door := $PrisonBars
@onready var timer := $Timer
@onready var enemy_spawn_timer := $EnemySpawnTimer
@onready var enemy_spawns := [$EnemySpawn, $EnemySpawn2, $EnemySpawn3]
@onready var treasure_chest := $TreasureChest

const Ghoul = preload("res://Entities/Ghoul/ghoul.tscn")

var timed_out_count := 0
var ghouls = []
var completed_level := false
var enemies_killed := 0
var time_slow_down := -1
var enemies_spawned := 0

func _ready():
	
	if GameState.difficulty == GameState.Difficulty.Easy:
		number_enemies = 4
	elif GameState.difficulty == GameState.Difficulty.Hard:
		number_enemies = 7
	if GameState.current_gems[treasure_chest.content]:
		treasure_chest.visible = true
		treasure_chest.is_opened = true
	else:
		player_detection_area.connect("body_entered", on_player_enter.bind())
	timer.connect("timeout", on_timer_timeout.bind())
	enemy_spawn_timer.connect("timeout", instantiate_ghouls.bind())
	GameMusic.stop()

func _process(delta):
	if not completed_level and is_enemy_defeated():
		completed_level = true
		treasure_chest.visible = true
		door.open()
		get_viewport().get_camera_2d().unlock()
	if completed_level and (Time.get_ticks_msec() - time_slow_down > slowdown_duration):
		Engine.time_scale = 1
		emit_signal("boss_fight_end")

func is_enemy_defeated() -> bool:
	return enemies_killed == number_enemies

func on_timer_timeout():
	if timed_out_count < number_shakes:
		timed_out_count += 1
		GameState.emit_signal("hit_received")
		GameSounds.play(GameSounds.Sound.Earthquake)
		timer.start(.5)
	elif timed_out_count < number_shakes + number_enemies:
		start_level()

func start_level():
	GameMusic.play_track(GameMusic.Track.Boss, false)
	emit_signal("boss_fight_start")
	instantiate_ghouls()

func instantiate_ghouls():
	if enemies_spawned < number_enemies:
		enemies_spawned += 1
		var ghoul := Ghoul.instantiate()
		ghoul.connect("die", on_ghoul_die.bind())
		GameState.add_to_level(ghoul)
		enemy_spawns.shuffle()
		ghoul.global_position = enemy_spawns[0].global_position
		ghouls.append(ghoul)
		if enemies_spawned < number_enemies:
			enemy_spawn_timer.start(time_between_enemies)
	

func on_ghoul_die():
	enemies_killed += 1
	var enemy_health_tick = 100.0 / number_enemies
	var old_health = enemy_health_tick * (number_enemies - enemies_killed + 1)
	var new_health = enemy_health_tick * (number_enemies - enemies_killed)
	emit_signal("boss_life_change", old_health, new_health)
	if is_enemy_defeated():
		GameMusic.stop()
		GameSounds.play(GameSounds.Sound.Earthquake)
		GameSounds.play(GameSounds.Sound.Earthquake, true)
		time_slow_down = Time.get_ticks_msec()
		Engine.time_scale = 0.1

func on_player_enter(player):
	door.close()
	player_detection_area.set_deferred("monitoring", false)
	get_viewport().get_camera_2d().lock_to_target(Vector2(704, -64))
	timer.start(3)
