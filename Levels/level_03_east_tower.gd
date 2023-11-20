extends Node2D

@onready var treasure_chest := $TreasureChest


func _ready():
	if GameState.hearts_collected.has(name):
		treasure_chest.is_opened = true
	else:
		treasure_chest.connect("open", on_treasure_open.bind())
		
func on_treasure_open():
	GameState.hearts_collected[name] = true
