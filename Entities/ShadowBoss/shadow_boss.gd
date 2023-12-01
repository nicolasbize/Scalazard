extends CharacterBody2D

signal die
signal hit

const HitSpark = preload("res://FX/HitSpark/hit_spark.tscn")
const Thunder := preload("res://FX/Thunder/thunder.tscn")

@onready var sprite := $Sprite2D
@onready var animation_player := $AnimationPlayer
@onready var player_in_reach_area := $PlayerInReachArea
@onready var damage_receiver_area := $DamageReceiverArea
@onready var damage_dealer_area := $DamageDealerArea

@export var max_life_boss := 3
@export var current_life := 3
@export var walk_speed := 70.0
@export var acceleration := 600.0
@export var friction := 200.0
@export var time_attack := 2000

var player = null
var direction := 1.0
var time_since_last_hit := -1
var time_between_hits := 1500
var time_start_attack = -1
var ticks_since_last_thunder := -1
var max_ticks_between_thunder := 4000

enum State {Idle, Running, Jumping, Landing, Attacking, Hurt, Dying, Dead, Casting}
var state = State.Idle

const anim_states = {
	State.Idle: "idle",
	State.Running: "run",
	State.Jumping: "jump",
	State.Casting: "cast",
	State.Landing: "land",
	State.Attacking: "attack",
	State.Hurt: "hurt",
	State.Dying: "dying",
	State.Dead: "dead",
}

func _ready():
	damage_receiver_area.connect("hit", on_enemy_hit.bind())
	if GameState.difficulty == GameState.Difficulty.Easy:
		max_life_boss = 2
		current_life = 2
	elif GameState.difficulty == GameState.Difficulty.Hard:
		max_life_boss = 3
		current_life = 3

func _physics_process(delta):
	if player != null:
		if can_move():
			if abs(player.global_position.y - global_position.y) < 20:
				direction = -1 if global_position.x > player.global_position.x else 1
				sprite.scale.x = direction * 2
				damage_receiver_area.scale.x = direction
				damage_dealer_area.scale.x = direction
				player_in_reach_area.scale.x = direction
				
				if player_in_reach_area.has_overlapping_bodies():
					velocity.x = move_toward(velocity.x, 0, 3 * friction * delta)
				else:
					velocity.x = move_toward(velocity.x, direction * walk_speed, acceleration * delta)
				if velocity.x != 0:
					state = State.Running
				else:
					if player_in_reach_area.has_overlapping_bodies() and can_attack():
						state = State.Attacking
						time_start_attack = Time.get_ticks_msec()
					else:
						state = State.Idle
			elif Time.get_ticks_msec() - ticks_since_last_thunder > max_ticks_between_thunder:
				velocity.x = move_toward(velocity.x, 0, friction * delta)
				if velocity.x == 0:
					cast()
		else:
			velocity.x = move_toward(velocity.x, 0, friction * delta)

	move_and_slide()
	play_animation()

func play_animation():
	animation_player.play(anim_states[state])

func can_move() -> bool:
	return state == State.Idle or state == State.Running

func can_attack() -> bool:
	return true

func cast() -> void:
	ticks_since_last_thunder = Time.get_ticks_msec()
	state = State.Casting
	var thunder := Thunder.instantiate()
	GameState.add_to_level(thunder)
	thunder.global_position = Vector2(player.global_position.x - 16, -208)

func start_fight(body):
	player = body

func on_enemy_hit(dmg:int, direction_knockback:float) -> void:
	if Time.get_ticks_msec() - time_since_last_hit > time_between_hits:
		time_since_last_hit = Time.get_ticks_msec()
		current_life -= 1 if dmg > 5 else 0
		emit_signal("hit", current_life + 1, current_life)
		if dmg > 5:
			# delete closest boxresize
			var boxresizes = get_tree().get_nodes_in_group("boxresize")
			if boxresizes.size() > 1:
				print("ohh no")
			else:
				boxresizes[0].queue_free()
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

func on_finish_attack() -> void:
	state = State.Idle

func on_finish_hurt() -> void:
	state = State.Idle

func on_finish_dying() -> void:
	state = State.Dead
	emit_signal("die")

func on_finish_casting() -> void:
	state = State.Idle
