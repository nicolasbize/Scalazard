extends Node2D

@export var time_between_enemies := 1.5
@export var number_enemies := 5
@export var number_shakes := 3

@onready var player_detection_area := $PlayerDetectionArea
@onready var door := $PrisonBars
@onready var timer := $Timer
@onready var enemy_spawns := [$EnemySpawn, $EnemySpawn2, $EnemySpawn3]
@onready var treasure_chest := $TreasureChest

const Ghoul = preload("res://Entities/Ghoul/ghoul.tscn")

var timed_out_count := 0
var ghouls = []
var completed_level := false

func _ready():
	if GameState.current_gems[treasure_chest.content]:
		treasure_chest.visible = true
		treasure_chest.is_opened = true
	else:
		player_detection_area.connect("body_entered", on_player_enter.bind())
	timer.connect("timeout", on_timer_timeout.bind())

func _process(delta):
	if not completed_level and is_enemy_defeated():
		completed_level = true
		treasure_chest.visible = true
		door.open()
		get_viewport().get_camera_2d().unlock()

func is_enemy_defeated() -> bool:
	var defeated = false
	if ghouls.size() == number_enemies:
		defeated = true
		for ghoul in ghouls:
			if ghoul != null and ghoul.current_life > 0:
				defeated = false
	return defeated

func on_timer_timeout():
	if timed_out_count < number_shakes:
		timed_out_count += 1
		GameState.emit_signal("hit_received")
		GameSounds.play(GameSounds.Sound.Earthquake)
		timer.start(.5)
	elif timed_out_count < number_shakes + number_enemies:
		timed_out_count += 1
		var ghoul := Ghoul.instantiate()
		GameState.add_to_level(ghoul)
		enemy_spawns.shuffle()
		ghoul.global_position = enemy_spawns[0].global_position
		ghouls.append(ghoul)
		timer.start(time_between_enemies)

func on_player_enter(player):
	door.close()
	player_detection_area.set_deferred("monitoring", false)
	get_viewport().get_camera_2d().lock_to_target(Vector2(704, -64))
	timer.start(3)
