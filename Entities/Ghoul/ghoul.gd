extends CharacterBody2D

@export var current_life := 2
@export var knockback_duration := 200.0
@export var knockback_intensity := 120.0
@export var vulnerable_to_attacks := true

@onready var player_detection_area := $PlayerDetectionArea
@onready var player_in_reach_area := $PlayerInReachArea
@onready var attack_area := $AttackArea
@onready var damage_dealer_area := $DamageDealerArea
@onready var animation_player := $AnimationPlayer
@onready var sprite := $Sprite2D
@onready var right_leg_raycast := $RightLegRaycast
@onready var left_leg_raycast := $LeftLegRaycast
@onready var right_arm_raycast := $RightArmRaycast
@onready var left_arm_raycast := $LeftArmRaycast
@onready var damage_receiver_area := $DamageReceiverArea
@onready var sfx_hit := $SFXHit

const SPEED = 300.0
const jump_height := 110.0
const jump_intensity := 240.0
const speed_run := 80.0
const speed_walk := 30.0
const acceleration := 800.0
const gravity := 400.0
const friction := 100.0
const rest_after_jump := 1500.0
const duration_idle := 3000.0
const duration_walk := 8000.0

enum State {Idle, Jumping, Running, Attacking, Hurt, Dying, Dead}
var state = State.Idle
var player = null
var direction := 1.0
var time_since_landing := Time.get_ticks_msec()
var time_since_action := Time.get_ticks_msec()
var knockback := Vector2.ZERO
var knockback_start := Time.get_ticks_msec()

const HitSpark = preload("res://FX/HitSpark/hit_spark.tscn")

var anim_states := {
	State.Idle: "idle",
	State.Running: "run",
	State.Jumping: "jump",
	State.Attacking: "attack",
	State.Hurt: "hurt",
	State.Dying: "dying",
	State.Dead: "dead",
}

func _ready():
	player_detection_area.connect("body_entered", on_player_enter.bind())
	player_detection_area.connect("body_exited", on_player_exit.bind())
	attack_area.connect("body_entered", on_player_hittable.bind())
	damage_receiver_area.connect("hit", on_enemy_hit.bind())


func on_enemy_hit(dmg:int, direction_knockback:float) -> void:
	var knock = knockback_intensity
	if not vulnerable_to_attacks:
		knock *= 1.5
	if state == State.Jumping or state == State.Attacking:
		velocity = Vector2(-velocity.x / 2, velocity.y)
	knockback = Vector2(direction_knockback * knock, 0)
	knockback_start = Time.get_ticks_msec()
	if vulnerable_to_attacks or dmg > 5:
		current_life -= dmg
		state = State.Hurt
		var hit_spark = HitSpark.instantiate()
		get_parent().add_child(hit_spark)
		hit_spark.global_position = global_position + Vector2.UP * 16 + Vector2.RIGHT * direction_knockback * 16
		hit_spark.rotation_degrees = randf_range(-10.0, 10.0)
		hit_spark.scale.x = direction_knockback
		GameState.emit_signal("hit_received")
	time_since_landing = Time.get_ticks_msec()
	sfx_hit.play_sound()
	play_animation()

func on_player_hittable(body):
	state = State.Attacking

func on_player_exit(body):
	player = null

func on_player_enter(body):
	player = body
	state = State.Running

func _physics_process(delta):
	damage_dealer_area.monitoring = current_life > 0
	damage_receiver_area.monitorable = current_life > 0
	sprite.material.set_shader_parameter("is_active", !vulnerable_to_attacks)
	if current_life <= 0:
		if abs(velocity.x) > 100:
			velocity.x = sign(velocity.x) * 100
		velocity.x = move_toward(velocity.x, 0, 2 * friction * delta)
		if state != State.Dying and state != State.Hurt:
			state = State.Dead
		move_and_slide()
	else:
		if state == State.Jumping or state == State.Attacking:
			if is_on_floor():
				state = State.Running
				time_since_landing = Time.get_ticks_msec()
		else:
			if player != null:
				direction = sign(player.global_position.x - global_position.x)
				velocity.x =  move_toward(velocity.x, direction * speed_run, acceleration * delta)
				if state == State.Running and player_in_reach_area.has_overlapping_bodies():
					check_jump()
			else:
				if state == State.Idle and Time.get_ticks_msec() - time_since_action > duration_idle:
					state = State.Running
					time_since_action = Time.get_ticks_msec()
				elif state == State.Running:
					var can_go = can_keep_walking()
					if can_go:
						velocity.x = move_toward(velocity.x, direction * speed_walk, acceleration * delta)
					elif not can_go or (Time.get_ticks_msec() - time_since_action > duration_walk):
						direction = -direction
						state = State.Idle
						
	if knockback != Vector2.ZERO:
		var knockback_val = min((Time.get_ticks_msec() - knockback_start) / knockback_duration, 1.0)
		knockback = knockback.lerp(Vector2.ZERO, knockback_val)
		velocity += knockback

	if not is_on_floor():
		velocity.y += gravity * delta
	elif state == State.Dead:
		velocity.x = move_toward(velocity.x, 0, friction * delta)
	
	sprite.scale.x = direction
	player_in_reach_area.scale.x = direction
	attack_area.scale.x = direction
	damage_dealer_area.scale.x = direction
	move_and_slide()
	play_animation()

func check_jump():
	if Time.get_ticks_msec() - time_since_landing > rest_after_jump:
		state = State.Jumping
		var dir = sign(player.global_position.x - global_position.x)
		velocity = Vector2(jump_intensity * dir, -jump_height)

func can_keep_walking() -> bool:
	if direction > 0:
		return right_leg_raycast.is_colliding() and not right_arm_raycast.is_colliding()
	else:
		return left_leg_raycast.is_colliding() and not left_arm_raycast.is_colliding()

func play_animation():
	animation_player.play(anim_states[state])

func on_finish_dying():
	state = State.Dead
	velocity.x = 0

func on_finish_hurt():
	if is_on_floor():
		state = State.Running
	else:
		state = State.Jumping
