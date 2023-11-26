extends Node2D

@onready var treasure_chest := $TreasureChest


func _ready():
	if GameState.level_3_heart_collected:
		treasure_chest.is_opened = true
	else:
		treasure_chest.connect("open", on_treasure_open.bind())
		
func on_treasure_open():
	GameState.level_3_heart_collected = true
