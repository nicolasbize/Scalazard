extends RigidBody2D

@onready var sprite := $Sprite2D
@onready var animation_player := $AnimationPlayer
@onready var player_detection_area := $PlayerDetectionArea
@onready var right_leg_raycast := $RightLegRaycast
@onready var left_leg_raycast := $LeftLegRaycast
@onready var right_arm_raycast := $RightArmRaycast
@onready var left_arm_raycast := $LeftArmRaycast
@onready var player_in_reach_area := $PlayerInReachArea
@onready var damage_dealer_area := $DamageDealerArea
@onready var damage_receiver_area := $DamageReceiverArea
@onready var body_collider := $CollisionShape2D
@onready var death_timer := $DeathTimer

@export var speed_walk := 40.0
@export var speed_run := 70.0
@export var acceleration := 800.0
@export var friction := 100.0
@export var ms_between_hits := 1000
@export var current_life := 2
@export var knockback_duration := 200.0
@export var knockback_intensity := 30.0
@export var duration_walk := 5000
@export var duration_idle := 2000

const HitSpark = preload("res://FX/HitSpark/hit_spark.tscn")
const Pickup = preload("res://World/Pickup/pickup.tscn")

var direction := 1.0
var velocity := Vector2.ZERO
var ticks_since_last_hit := Time.get_ticks_msec()
var knockback := Vector2.ZERO
var knockback_start := Time.get_ticks_msec()
var ticks_since_last_action := Time.get_ticks_msec()

enum State {Idle, Walking, Attacking, Hurt, Dying, Dead, Disappearing}

const anim_states = {
	State.Idle: "idle",
	State.Walking: "walk",
	State.Attacking: "attack",
	State.Hurt: "hurt",
	State.Dying: "dying",
	State.Dead: "dead",
	State.Disappearing: "disappear",
}
var state := State.Walking
var player = null

func _ready():
	player_detection_area.connect("body_entered", on_player_enter.bind())
	player_detection_area.connect("body_exited", on_player_exit.bind())
	damage_receiver_area.connect("hit", on_enemy_hit.bind())
	death_timer.connect("timeout", on_death_timer_timeout.bind())
	if GameState.difficulty == GameState.Difficulty.Easy:
		speed_walk = 20.0
		speed_run = 40.0
		ms_between_hits = 2000
		current_life = 1
	elif GameState.difficulty == GameState.Difficulty.Hard:
		speed_walk = 50.0
		speed_run = 70.0
		ms_between_hits = 1000
		current_life = 3

func on_player_enter(body):
	if current_life > 0:
		player = body

func on_player_exit(body):
	if current_life > 0:
		state = State.Walking

func is_player_within_reach() -> bool:
	if current_life > 0:
		return false
	return player_in_reach_area.has_overlapping_bodies()

func on_enemy_hit(dmg:int, direction_knockback:float) -> void:
	current_life -= dmg
	if current_life > 0:
		state = State.Hurt
		knockback = Vector2(direction_knockback * knockback_intensity, 0)
	else:
		state = State.Dying
		damage_receiver_area.set_deferred("monitorable", false)
		player_detection_area.set_deferred("monitoring", false)
		set_collision_mask_value(3, false)
		player = null
		knockback = Vector2(direction_knockback * knockback_intensity / 4.0, 0)
	knockback_start = Time.get_ticks_msec()
	var hit_spark = HitSpark.instantiate()
	get_parent().add_child(hit_spark)
	hit_spark.global_position = global_position + Vector2.UP * 16
	hit_spark.rotation_degrees = randf_range(-10.0, 10.0)
	hit_spark.scale.x = direction_knockback
	GameState.emit_signal("hit_received")
	GameSounds.play(GameSounds.Sound.EnemyHit, true)

func turn_around():
	if can_act() and not is_player_a_target():
		ticks_since_last_action = Time.get_ticks_msec()
		if state == State.Idle:
			state = State.Walking
			direction *= -1
		elif state == State.Walking:
			state = State.Idle

func _physics_process(delta):
	damage_dealer_area.monitoring = current_life > 0
	if can_act():
		if is_player_a_target():
			if state == State.Walking:
				if can_keep_walking():
					if (Time.get_ticks_msec() - ticks_since_last_hit) > ms_between_hits:
						direction = sign(player.global_position.x - global_position.x)
						velocity.x = move_toward(velocity.x, direction * speed_run, acceleration * delta)
					else:
						velocity.x = move_toward(velocity.x, 0, friction * delta)
				else:
					state = State.Idle
					velocity.x = 0
					player = null
			elif state == State.Idle:
				if sign(player.global_position.x - global_position.x) != direction:
					state = State.Walking
					direction = sign(player.global_position.x - global_position.x)
					velocity.x = move_toward(velocity.x, direction * speed_run, acceleration * delta)
		else:
			if state == State.Walking:
				if can_keep_walking() and (Time.get_ticks_msec() - ticks_since_last_action) < duration_walk:
					velocity.x = move_toward(velocity.x, direction * speed_walk, acceleration * delta)
				else:
					velocity.x = 0
					turn_around()
			elif state == State.Idle:
				velocity.x = move_toward(velocity.x, 0, friction * delta)
				if (Time.get_ticks_msec() - ticks_since_last_action) > duration_idle:
					turn_around()
	elif current_life <= 0:
		velocity.x = move_toward(velocity.x, 0, friction * delta)
	
	if knockback != Vector2.ZERO:
		var knockback_val = min((Time.get_ticks_msec() - knockback_start) / knockback_duration, 1.0)
		knockback = knockback.lerp(Vector2.ZERO, knockback_val)
		velocity += knockback

	if state != State.Dead:
		position += velocity * delta
	sprite.scale.x = direction
	player_detection_area.scale.x = direction
	player_in_reach_area.scale.x = direction
	damage_dealer_area.scale.x = direction
	play_animation()

func can_act() -> bool:
	return !([State.Hurt, State.Dead, State.Dying].has(state)) and current_life > 0

func can_keep_walking() -> bool:
	if direction > 0:
		return right_leg_raycast.is_colliding() and not right_arm_raycast.is_colliding()
	else:
		return left_leg_raycast.is_colliding() and not left_arm_raycast.is_colliding()

func is_player_a_target():
	return player != null and GameState.current_life > 0 and current_life > 0

func play_animation():
	animation_player.play(anim_states[state])

func on_finish_action():
	if current_life > 0:
		if player != null:
			state = State.Walking
		else:
			state = State.Idle

func on_finish_dying():
	state = State.Dead
	velocity.x = 0
	death_timer.start(3)
	if randf() < GameState.heart_drop_rate:
		var pickup := Pickup.instantiate()
		GameState.add_to_level(pickup)
		pickup.global_position = global_position + Vector2.UP * 16

func on_death_timer_timeout():
	state = State.Disappearing
