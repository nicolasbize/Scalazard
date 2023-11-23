extends Node2D

@onready var spark_location := $SparkLocation

const ThunderImpactFx = preload("res://FX/Thunder/thunder_impact_fx.tscn")

func on_start_thunder():
	GameSounds.play(GameSounds.Sound.Thunder)

func on_finish_thunder():
	var thunder_spark := ThunderImpactFx.instantiate()
	GameState.add_to_level(thunder_spark)
	thunder_spark.global_position = spark_location.global_position
	thunder_spark.emitting = true
