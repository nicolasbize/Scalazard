extends Node2D

@onready var water_damage_area := $WaterDamageArea
@onready var platform_area := $Platform/PlayerDetectionArea
@onready var gem_doors := [$GemDoorGreen, $GemDoorBlue, $GemDoorPurple, $GemDoorYellow]

const ticks_between_water_damage := 1200
var last_damage_tick = Time.get_ticks_msec()
var player_in_water = null

func _ready():
	water_damage_area.connect("body_entered", on_player_enter_water.bind())
	water_damage_area.connect("body_exited", on_player_exit_water.bind())
	platform_area.connect("body_entered", on_player_enter_platform.bind())
	

func _process(delta):
	if player_in_water != null and not player_in_water.can_swim():
		if Time.get_ticks_msec() - last_damage_tick > ticks_between_water_damage:
			last_damage_tick = Time.get_ticks_msec()
			player_in_water.on_player_hit(1, 0)
			
func on_player_exit_water(player):
	player_in_water = null
	last_damage_tick = Time.get_ticks_msec()

func on_player_enter_water(player):
	player_in_water = player
	last_damage_tick = Time.get_ticks_msec()

func on_player_enter_platform(player):
	for i in range(GameState.current_gems.size()):
		if GameState.current_gems[i] and not GameState.gems_inserted[i]:
			gem_doors[i].start()
			GameState.gems_inserted[i] = true
