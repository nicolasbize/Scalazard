class_name Player
extends CharacterBody2D

@onready var sprite := $Sprite2D
@onready var animation_player := $AnimationPlayer
@onready var box_detector := $BoxDetector
@onready var laser_start := $LaserStart
@onready var pickup_area := $PickupArea
@onready var carried_box := $CarriedBox
@onready var casting_ray := $CastingRay

@export var gravity := 850.0
@export var max_fall_velocity := 400.0
@export var acceleration := 500.0
@export var max_velocity := 100.0
@export var max_run_velocity := 180.0
@export var friction := 700.0
@export var air_friction := 20.0
@export var jump_force := 280.0

const Laser = preload("res://laser.tscn")
const Impulse = preload("res://impulse.tscn")
const BeamSpell = preload("res://beam_spell.tscn")
const SmallBox = preload("res://small_box.tscn")
const BigBox = preload("res://big_box.tscn")
const BigToSmall = preload("res://big_to_small.tscn")
const SmallToBig = preload("res://small_to_big.tscn")

enum State {Idle, Running, Jumping, StartFalling, Falling, Casting, Attacking, Pushing, Carrying, CarryingIdle, Hurting, Dying, Dead, Resting, Healing}
var anim_states = {
	State.Idle: "idle",
	State.Running: "run",
	State.Jumping: "jump",
	State.StartFalling: "start_fall",
	State.Falling: "falling",
	State.Casting: "cast",
	State.Pushing: "push",
	State.CarryingIdle: "carry_idle",
	State.Carrying: "carry",
	State.Hurting: "hurt",
	State.Dying: "die",
	State.Dead: "die",
	State.Resting: "rest",
	State.Healing: "heal",
}
var state:State = State.Idle
var target_box = null
var laser = null
var impulse = null
var is_carrying := false
var time_since_last_attack = Time.get_ticks_msec()
var attack_anim := "slash_1"
var pickable_target = null

func _ready():
	pickup_area.connect("area_entered", on_player_enter_pickable.bind())
	pickup_area.connect("area_exited", on_player_exit_pickable.bind())

func _physics_process(delta):
	if box_detector.is_colliding():
		target_box = box_detector.get_collider()
	else:
		target_box = null
	move(delta)

func on_player_enter_pickable(area:Area2D):
	pickable_target = area.get_parent()

func on_player_exit_pickable(area:Area2D):
	pickable_target = null

func can_move() -> bool:
	return ![State.Casting, State.Dying, State.Dead, State.Resting, State.Attacking].has(state)

func can_run() -> bool:
	return can_move() and is_on_floor() and [State.Running, State.Idle].has(state)

func can_cast() -> bool:
	return is_on_floor() and [State.Running, State.Idle].has(state)

func move(delta):
	carried_box.visible = is_carrying
	apply_gravity(delta)
	if can_move():
		var input_axis = Input.get_axis("move_left", "move_right")
		if is_moving(input_axis):
			apply_acceleration(delta, input_axis)
			sprite.scale.x = sign(input_axis)
			casting_ray.scale.x = sign(input_axis)
			box_detector.scale.x = sign(input_axis)
			laser_start.position.x = sign(input_axis) * abs(laser_start.position.x)
			carried_box.position.x = sign(input_axis) * abs(carried_box.position.x)
			if is_on_floor():
				if is_carrying:
					state = State.Carrying
				elif target_box != null:
					state = State.Pushing
					var dir = (target_box.position - position).normalized()
					target_box.move_and_collide(Vector2.RIGHT * dir * delta * 20.0)
				else:
					state = State.Running
		else:
			apply_friction(delta)
			if is_on_floor():
				if is_carrying:
					state = State.CarryingIdle
				else:
					state = State.Idle
		if not is_on_floor() and velocity.y > 0 and state != State.Falling:
			state = State.StartFalling
		jump_check()
		cast_check()
		attack_check()
		pickup_check()
	play_animations()
	var prev_position = global_position
	move_and_slide()

func play_animations() -> void:
	if state == State.Attacking: # multiple anims
		animation_player.play(attack_anim)
	else:
		animation_player.play(anim_states[state])
		
func can_pickup() -> bool:
	return is_on_floor() and (state == State.Idle or state == State.Running)

func pickup_check():
	if can_pickup() and Input.is_action_just_pressed("crouch") and pickable_target != null:
		pickable_target.queue_free()
		is_carrying = true

func cast_check():
	if Input.is_action_just_pressed("cast"):
		if is_carrying:
			throw_box()
		elif can_cast():
			cast()
			velocity.x = 0

func cast():
	state = State.Casting

func can_attack() -> bool:
	return state == State.Idle or state == State.Running

func attack_check():
	if can_attack() and Input.is_action_just_pressed("attack"):
		state = State.Attacking
		if Time.get_ticks_msec() - time_since_last_attack < 500:
			attack_anim = "slash_2"
		else:
			attack_anim = "slash_1"
			time_since_last_attack = Time.get_ticks_msec()
		
func find_cast_target():
	if casting_ray.is_colliding():
		var collision_point : Vector2 = to_local(casting_ray.get_collision_point())
		var beam_spell = BeamSpell.instantiate()
		laser_start.add_child(beam_spell)
#		beam_spell.rotation_degrees = 0 if (sprite.scale.x > 0) else 180
		collision_point.x -= laser_start.position.x
		collision_point.y = 0
		beam_spell.cast(collision_point)
		if casting_ray.get_collider().is_in_group("shrinkable"):
			var big_to_small = BigToSmall.instantiate()
			get_parent().add_child(big_to_small)
			big_to_small.global_position = casting_ray.get_collider().global_position
			casting_ray.get_collider().queue_free()
		elif casting_ray.get_collider().is_in_group("expandable"):
			var small_to_big = SmallToBig.instantiate()
			get_parent().add_child(small_to_big)
			small_to_big.global_position = casting_ray.get_collider().global_position
			casting_ray.get_collider().queue_free()
	else:
		pass
		# todo play fizz sound
	
#
#func start_impulse():
#	state = State.Impulse
#	impulse = Impulse.instantiate()
#	impulse.connect("complete", on_impulse_complete.bind())
#	if laser_start.position.x > 0:
#		impulse.dir = 1.0
#	else:
#		impulse.dir = -1.0
#	get_parent().add_child(impulse)
#	impulse.global_position = global_position

#func on_laser_complete(box):
#	finish_laser()
#	if box.is_in_group("shrinkable"):
#		var smallbox = SmallBox.instantiate()
#		get_parent().add_child(smallbox)
#		smallbox.global_position = box.global_position
#		box.queue_free()
#
#func on_impulse_complete(box):
#	finish_impulse()
#	if box.is_in_group("expandable"):
#		var bigbox = BigBox.instantiate()
#		get_parent().add_child(bigbox)
#		bigbox.global_position = box.global_position
#		box.queue_free()

func is_pushing():
	return target_box != null and not is_carrying

func is_moving(input_axis):
	return input_axis != 0

func apply_gravity(delta):
	if not is_on_floor():
		velocity.y = move_toward(velocity.y, max_fall_velocity, gravity * delta)

func apply_acceleration(delta, input_axis):
	var max = max_velocity
	if is_carrying:
		max = max_velocity / 2
	if is_moving(input_axis):
		velocity.x = move_toward(velocity.x, input_axis * max, acceleration * delta)

func apply_friction(delta):
	if is_on_floor():
		velocity.x = move_toward(velocity.x, 0, friction * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, air_friction * delta)

func jump_check():
	var force = jump_force
	if is_carrying:
		force = jump_force * 0.85
	if is_on_floor() and Input.is_action_just_pressed("jump"):
		if Input.is_action_pressed("crouch"):
			position.y += 1
		else:
			jump(force)
	if not is_on_floor():
		if Input.is_action_just_released("jump") and velocity.y < -jump_force / 2:
			velocity.y = -jump_force / 2

func throw_box():
	is_carrying = false
	var smallbox = SmallBox.instantiate()
	get_parent().add_child(smallbox)
	smallbox.global_position = carried_box.global_position
	if not Input.is_action_pressed("crouch"):
		var dir = 1.0
		if laser_start.position.x < 0:
			dir = -1.0
		smallbox.apply_impulse(Vector2(160 * dir, -20))

func jump(force, create_effect = true):
	velocity.y = -force
	state = State.Jumping

func on_start_falling():
	state = State.Falling

func on_stop_action():
	state = State.Idle
