extends Node2D

@export var current_life := 1

@onready var player_detection_areas := $PlayerDetectionArea
@onready var sprite := $Sprite2D
@onready var damage_receiver_area := $DamageReceiverArea
@onready var damage_dealer_area := $DamageDealerArea
@onready var animation_player := $AnimationPlayer

const HitSpark = preload("res://FX/HitSpark/hit_spark.tscn")

enum State {Idle, StartFlying, Fly, Dying}

var state = State.Idle
var anim_states = {
	State.Idle: "idle",
	State.StartFlying: "start_fly",
	State.Fly: "fly",
	State.Dying: "die",
}
var fly_speed := 60.0
var time_since_arrived := Time.get_ticks_msec()
var player = null
var direction := Vector2.ZERO
var velocity := Vector2.ZERO

func _ready():
	damage_receiver_area.connect("hit", on_enemy_hit.bind())
	player_detection_areas.connect("body_entered", on_player_enter.bind())
	if GameState.difficulty == GameState.Difficulty.Easy:
		fly_speed = 40.0
	elif GameState.difficulty == GameState.Difficulty.Hard:
		fly_speed = 70.0

func on_player_enter(body):
	player = body

func _physics_process(delta):
	damage_dealer_area.monitoring = current_life > 0
	if player != null:
		if state == State.Idle:
			state = State.StartFlying
		direction = (player.global_position + Vector2.UP * 24 - global_position).normalized()
		sprite.scale.x = 1 if direction.x > 0 else -1
		velocity = direction * fly_speed * delta
		global_position += velocity
	animation_player.play(anim_states[state])

func on_enemy_hit(dmg:int, direction_knockback:float) -> void:
	damage_dealer_area.set_deferred("monitoring", false)
	damage_receiver_area.set_deferred("monitorable", false)
	current_life -= dmg
	state = State.Dying
	var hit_spark = HitSpark.instantiate()
	get_parent().add_child(hit_spark)
	hit_spark.global_position = sprite.global_position + Vector2.DOWN * 16
	hit_spark.scale.x = direction_knockback
	GameState.emit_signal("hit_received")
	GameSounds.play(GameSounds.Sound.EnemyHit, true)
	
func on_end_start_fly():
	state = State.Fly
