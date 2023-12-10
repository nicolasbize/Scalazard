extends Node2D

@onready var animation_player := $AnimationPlayer
@onready var damage_receiver_area := $DamageReceiverArea
@onready var static_body := $StaticBody2D

const HitSpark := preload("res://FX/HitSpark/hero_spark.tscn")
const Pickup := preload("res://World/Pickup/pickup.tscn")

func _ready():
	damage_receiver_area.connect("hit", on_pot_hit.bind())

func on_pot_hit(dmg, dmg_direction):
	damage_receiver_area.set_deferred("monitorable", false)
	animation_player.play("break")
	GameSounds.play(GameSounds.Sound.VaseBreak)
	var pickup := Pickup.instantiate()
	GameState.add_to_level(pickup)
	pickup.global_position = global_position + Vector2.UP * 16
	static_body.queue_free()
	var hit_spark = HitSpark.instantiate()
	get_parent().add_child(hit_spark)
	hit_spark.global_position = global_position + Vector2.UP * 16 
	hit_spark.rotation_degrees = randf_range(-10.0, 10.0)
	GameState.emit_signal("hit_received")	

func on_stop_breaking():
	animation_player.play("broken")
