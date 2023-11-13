extends Node2D

@onready var damage_receiver_area := $DamageReceiverArea
@onready var sprite := $Sprite2D

const HitSpark = preload("res://FX/HitSpark/hit_spark.tscn")

func _ready():
	damage_receiver_area.connect("hit", on_hit.bind())

func on_hit(dmg:int, direction_knockback:float) -> void:
	var hit_spark = HitSpark.instantiate()
	get_parent().add_child(hit_spark)
	hit_spark.global_position = sprite.global_position + Vector2(direction_knockback * 16, -32)
	hit_spark.scale.x = direction_knockback
	GameState.emit_signal("hit_received")
	queue_free()
