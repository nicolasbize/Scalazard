extends Node2D

@export var number_shakes := 4
@onready var player_detection_area := $PlayerDetectionArea
@onready var treasure_chest := $TreasureChest
@onready var timer := $Timer
@onready var boss := $SkeletonBoss
@onready var traps := [$Trap, $Trap2]

var level_started := false
var completed_level := false
var timed_out_count := 0
var player = null

func _ready():
	if GameState.current_gems[TreasureChest.Content.GreenGem]:
		treasure_chest.visible = true
		treasure_chest.is_opened = true
		for trap in traps:
			trap.queue_free()
	else:
		player_detection_area.connect("body_entered", on_player_enter.bind())
		boss.connect("die", on_boss_die.bind())
	timer.connect("timeout", on_timer_timeout.bind())
	

func on_player_enter(body):
	player = body
	player_detection_area.set_deferred("monitoring", false)
	get_viewport().get_camera_2d().lock_to_target(Vector2(570, 0))
	for trap in traps:
		trap.start_firing()
	boss.start_fight(player)
	
#	timer.start(3)

func on_timer_timeout():
	if timed_out_count < number_shakes:
		timed_out_count += 1
		GameState.emit_signal("hit_received")
		GameSounds.play(GameSounds.Sound.Earthquake)
		timer.start(.5)
	else:
		level_started = true
		boss.start_fight(player)

func on_boss_die():
	treasure_chest.visible = true
	completed_level = true
	for trap in traps:
		trap.stop_firing()
	get_viewport().get_camera_2d().unlock()
