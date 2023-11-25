extends CharacterBody2D

const Skewer = preload("res://World/Skewer/skewer.tscn")
const HitSpark = preload("res://FX/HitSpark/hit_spark.tscn")

@onready var sprite := $Sprite2D
@onready var animation_player := $AnimationPlayer
@onready var player_in_reach_area := $PlayerInReachArea
@onready var damage_receiver_area := $DamageReceiverArea
@onready var attack_damage_dealer_area := $AttackDamageDealerArea
@onready var damage_dealer_area := $DamageDealerArea

@export var current_life := 3
@export var walk_speed := 70.0
@export var acceleration := 600.0
@export var friction := 200.0
@export var time_charge := 500
@export var time_attack := 2000

signal die

var player = null
var time_start_charge := -1
var time_start_attack := -1
var direction := 1.0
var time_since_last_hit := -1
var time_between_hits := 300

enum State {Idle, Walking, Charging, Attacking, AttackingImpact, Shield, Hurt, Dying, Dead}
var state = State.Idle

const anim_states = {
	State.Idle: "idle",
	State.Walking: "walk",
	State.Charging: "charge",
	State.Attacking: "attack",
	State.AttackingImpact: "attack_impact",
	State.Hurt: "hurt",
	State.Dying: "dying",
	State.Dead: "dead",
}

func _ready():
	damage_receiver_area.connect("hit", on_enemy_hit.bind())
	damage_dealer_area.connect("area_entered", on_player_too_close.bind())

func on_player_too_close(player_area):
	player_area.get_parent().push_back(direction, 100)

func start_fight(body):
	player = body
	
func _physics_process(delta):
	if player != null:
		if can_move():
			direction = -1 if global_position.x > player.global_position.x else 1
			sprite.scale.x = direction * 2
			damage_receiver_area.scale.x = direction
			attack_damage_dealer_area.scale.x = direction
			player_in_reach_area.scale.x = direction
			var distance_with_player = (global_position - player.global_position).length()
			
			if player_in_reach_area.has_overlapping_bodies():
				velocity.x = move_toward(velocity.x, 0, friction * delta)
			else:
				velocity.x = move_toward(velocity.x, direction * walk_speed, acceleration * delta)
			if velocity.x != 0:
				state = State.Walking
			else:
				if player_in_reach_area.has_overlapping_bodies() and can_attack():
					state = State.Charging
					time_start_charge = Time.get_ticks_msec()
				else:
					state = State.Idle
		elif state == State.Charging:
			if Time.get_ticks_msec() - time_start_charge > time_charge:
				state = State.Attacking
				time_start_attack = Time.get_ticks_msec()
		elif state == State.AttackingImpact:
			if Time.get_ticks_msec() - time_start_attack > time_attack:
				state = State.Idle
			
	move_and_slide()
	play_animation()

func play_animation():
	animation_player.play(anim_states[state])

func is_player_behind() -> bool:
	if player == null:
		return false
	if player.global_position.x > global_position.x and direction < 0:
		return true
	if player.global_position.x < global_position.x and direction > 0:
		return true
	return false

func on_enemy_hit(dmg:int, direction_knockback:float) -> void:
	if is_player_behind() and Time.get_ticks_msec() - time_since_last_hit > time_between_hits:
		time_since_last_hit = Time.get_ticks_msec()
		current_life -= dmg
		if current_life > 0:
			state = State.Hurt
		else:
			state = State.Dying
		var hit_spark = HitSpark.instantiate()
		get_parent().add_child(hit_spark)
		hit_spark.global_position = global_position + Vector2.UP * 16
		hit_spark.rotation_degrees = randf_range(-10.0, 10.0)
		hit_spark.scale.x = direction_knockback
		GameState.emit_signal("hit_received")
		GameSounds.play(GameSounds.Sound.EnemyHit, true)

func can_move() -> bool:
	return state == State.Idle or state == State.Walking

func can_attack() -> bool:
	return true

func on_finish_action() -> void:
	state = State.Idle

func on_finish_attack() -> void:
	state = State.AttackingImpact
	var skewer = Skewer.instantiate()
	skewer.scale.x = direction
	GameState.add_to_level(skewer)
	skewer.global_position = global_position + direction * Vector2.RIGHT * 8

func on_finish_dying() -> void:
	state = State.Dead
	emit_signal("die")
