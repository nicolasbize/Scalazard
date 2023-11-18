class_name Player
extends CharacterBody2D

@onready var sprite := $Sprite2D
@onready var animation_player := $AnimationPlayer
@onready var box_detector := $BoxDetector
@onready var laser_start := $LaserStart
@onready var pickup_area := $PickupArea
@onready var carried_box := $CarriedBox
@onready var casting_ray := $CastingRay
@onready var damage_receiver_area := $DamageReceiverArea
@onready var damage_dealer_area := $DamageDealerArea
@onready var water_detection_area := $WaterDetectionArea
@onready var camera_target := $CameraTarget
@onready var sfx_swing := $SFXSwing
@onready var sfx_jump := $SFXJump
@onready var sfx_hit := $SFXHit

@export var gravity := 850.0
@export var max_fall_velocity := 400.0
@export var acceleration := 500.0
@export var max_velocity := 120.0
@export var max_velocity_carrying := 90.0
@export var max_velocity_in_water := 60.0
@export var max_run_velocity := 180.0
@export var friction := 700.0
@export var air_friction := 20.0
@export var jump_force := 290.0
@export var knockback_duration := 100.0
@export var knockback_intensity := 20.0
@export var push_strength := 30.0
@export var min_time_between_hits := 1000.0 # 1sec
@export var grace_period_jump := 150.0

const BeamSpell = preload("res://FX/BeamSpell/beam_spell.tscn")
const SmallBox = preload("res://Entities/ResizableBox/small_box.tscn")
const BigBox = preload("res://Entities/ResizableBox/big_box.tscn")
const HeroSpark = preload("res://FX/HitSpark/hero_spark.tscn")
const BoxResize = preload("res://Entities/ResizableBox/box_resize.tscn")
const WaterSplash = preload("res://FX/Splash/water_spash.tscn")
const Gem = preload("res://World/Gem/gem.tscn")

enum State {Idle, Running, Jumping, StartFalling, Falling, Casting, Attacking, Pushing, Carrying, CarryingIdle, Hurting, Dying, Dead, Resting, Healing, Pickup}
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
	State.Dying: "dying",
	State.Dead: "dead",
	State.Resting: "rest",
	State.Healing: "heal",
	State.Pickup: "pickup",
}
var state:State = State.Idle
var target_box = null
var laser = null
var impulse = null
var is_carrying := false
var time_since_last_attack := Time.get_ticks_msec()
var time_since_last_hit := Time.get_ticks_msec()
var attack_anim := "slash_1"
var pickable_target = null
var knockback := Vector2.ZERO
var knockback_start := Time.get_ticks_msec()
var was_on_floor := false
var last_time_on_floor := Time.get_ticks_msec()
var current_gem_reference = null
var current_gem_index := -1

func _ready():
	pickup_area.connect("area_entered", on_player_enter_pickable.bind())
	pickup_area.connect("area_exited", on_player_exit_pickable.bind())
	damage_receiver_area.connect("hit", on_player_hit.bind())

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
	return ![State.Casting, State.Hurting, State.Dying, State.Dead, State.Resting, State.Attacking, State.Pickup].has(state)

func can_run() -> bool:
	return can_move() and is_on_floor() and [State.Running, State.Idle].has(state)

func can_cast() -> bool:
	return is_on_floor() and [State.Running, State.Idle].has(state)

func move(delta):
	carried_box.visible = is_carrying
	if is_on_floor():
		last_time_on_floor = Time.get_ticks_msec()
	apply_gravity(delta)
	if can_move():
		var input_axis = Input.get_axis("move_left", "move_right")
		if is_moving(input_axis):
			apply_acceleration(delta, input_axis)
			sprite.scale.x = sign(input_axis)
			casting_ray.scale.x = sign(input_axis)
			box_detector.scale.x = sign(input_axis)
			damage_dealer_area.scale.x = sign(input_axis)
			laser_start.position.x = sign(input_axis) * abs(laser_start.position.x)
			carried_box.position.x = sign(input_axis) * abs(carried_box.position.x)
			if is_on_floor():
				if is_carrying:
					state = State.Carrying
				elif target_box != null:
					state = State.Pushing
					var dir = (target_box.position - position).normalized()
					target_box.move_and_collide(Vector2.RIGHT * dir * delta * push_strength)
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

	if knockback != Vector2.ZERO:
		var knockback_val = min((Time.get_ticks_msec() - knockback_start) / knockback_duration, 1.0)
		knockback = knockback.lerp(Vector2.ZERO, knockback_val)
		velocity += knockback

	if state != State.Dead:
		move_and_slide()
	camera_target.position.x = lerpf(0.0, 20.0, velocity.x / get_max_velocity())
	
	check_poison()
	
	# land on water?
	if not was_on_floor and is_on_floor():
		check_splash()
	was_on_floor = is_on_floor()

func play_animations() -> void:
	if state == State.Attacking: # multiple anims
		animation_player.play(attack_anim)
	else:
		animation_player.play(anim_states[state])

func check_poison():
	if in_water() and water_detection_area.get_overlapping_areas()[0].get_parent().liquid_type == WaterBody.LiquidType.Poison:
		on_player_hit(1, 0.0)

func can_pickup() -> bool:
	return is_on_floor() and (state == State.Idle or state == State.Running)

func pickup_check():
	if can_pickup() and Input.is_action_just_pressed("crouch") and pickable_target != null:
		velocity.x = 0
		pickable_target.queue_free()
		is_carrying = true

func get_item(item):
	state = State.Pickup
	velocity = Vector2.ZERO
	current_gem_reference = Gem.instantiate()
	GameState.add_to_level(current_gem_reference)
	current_gem_reference.set_color(item)
	current_gem_reference.global_position = global_position + Vector2.UP * 16
	current_gem_reference.connect("gain_gem", on_gain_gem.bind(item))
	current_gem_index = item

func on_system_message_callback():
	state = State.Idle
	GameState.gain_gem_power(current_gem_index)
	if current_gem_reference != null:
		current_gem_reference.queue_free()
		current_gem_reference = null

func on_gain_gem(item):
	GameState.show_system_message(["You just found one of the crystals!", "You feel stronger!"], on_system_message_callback.bind())

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
	return [State.Idle, State.Running, State.Jumping, State.StartFalling, State.Falling].has(state)

func attack_check():
	if can_attack() and Input.is_action_just_pressed("attack"):
		state = State.Attacking
		if Time.get_ticks_msec() - time_since_last_attack < 500:
			attack_anim = "slash_2"
			sfx_swing.get_child(0).play_sound()
		else:
			attack_anim = "slash_1"
			time_since_last_attack = Time.get_ticks_msec()
			sfx_swing.get_child(1).play_sound()

func get_direction() -> float:
	return sprite.scale.x

func find_cast_target():
	if casting_ray.is_colliding():
		var collider = casting_ray.get_collider()
		if collider.is_in_group("shrinkable") or collider.is_in_group("expandable"):	
			var collision_point : Vector2 = to_local(casting_ray.get_collider().global_position)
			var beam_spell = BeamSpell.instantiate()
			laser_start.add_child(beam_spell)
			collision_point.x -= laser_start.position.x
			collision_point.y = 0
			beam_spell.cast_to(casting_ray.get_collider())
	else:
		pass
		# todo play fizz sound
	

func is_pushing():
	return target_box != null and not is_carrying

func is_moving(input_axis):
	return input_axis != 0

func apply_gravity(delta):
	if not is_on_floor():
		velocity.y = move_toward(velocity.y, max_fall_velocity, gravity * delta)

func apply_acceleration(delta, input_axis):
	var max = get_max_velocity()
	if is_moving(input_axis):
		velocity.x = move_toward(velocity.x, input_axis * max, acceleration * delta)

func get_max_velocity() -> float:
	var max = max_velocity
	if is_carrying:
		max = max_velocity_carrying
	if in_water():
		max = max_velocity_in_water
	return max

func apply_friction(delta):
	if is_on_floor():
		velocity.x = move_toward(velocity.x, 0, friction * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, air_friction * delta)

func jump_check():
	var force = jump_force
	if is_carrying:
		force = jump_force * 0.85
	var elapsed_since_on_floor = Time.get_ticks_msec() - last_time_on_floor
	if (is_on_floor() or elapsed_since_on_floor < grace_period_jump) and Input.is_action_just_pressed("jump"):
		if Input.is_action_pressed("crouch") and not state == State.Casting:
			position.y += 1
		else:
			jump(force)
	if not is_on_floor():
		# limit down speed
		if Input.is_action_just_released("jump") and velocity.y < -jump_force / 2:
			velocity.y = -jump_force / 2

func splash():
	var liquid_color : Color = water_detection_area.get_overlapping_areas()[0].get_parent().get_color()
	var splash = WaterSplash.instantiate()
	GameState.add_to_level(splash)
	splash.process_material.color_ramp.gradient.colors[0] = liquid_color
	splash.process_material.color_ramp.gradient.colors[1] = liquid_color.lightened(0.4)
	splash.global_position = global_position

func on_player_hit(dmg:int, direction_knockback: float):
	if GameState.current_life > 0 and (Time.get_ticks_msec() - time_since_last_hit) > min_time_between_hits:
		time_since_last_hit = Time.get_ticks_msec()
		GameState.deal_hero_damage(dmg)
		if GameState.current_life > 0:
			state = State.Hurting
		else:
			state = State.Dying
			velocity.x = 0
			damage_receiver_area.set_deferred("monitorable", false)
			damage_dealer_area.set_deferred("monitoring", false)
		create_wound_fx(direction_knockback)

func create_wound_fx(direction_knockback: float):
	knockback = Vector2(direction_knockback * knockback_intensity, 0)
	knockback_start = Time.get_ticks_msec()
	var hero_spark = HeroSpark.instantiate()
	add_child(hero_spark)
	hero_spark.position = Vector2.UP * 16
	GameState.emit_signal("hit_received")
	
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
	sfx_jump.play_sound()
	check_splash()

func check_splash():
	if in_water():
		splash()

func in_water() -> bool:
	return water_detection_area.has_overlapping_areas()

func on_start_falling():
	state = State.Falling

func on_finish_dying():
	state = State.Dead

func on_stop_action():
	state = State.Idle
