class_name Player
extends CharacterBody2D

@onready var sprite := $Sprite2D
@onready var animation_player := $AnimationPlayer
@onready var box_detector := $BoxDetector
@onready var laser_start := $LaserStart
@onready var pickup_area := $PickupArea
@onready var carried_box := $CarriedBox
@onready var casting_ray := $CastingRay
@onready var casting_area := $CastingArea
@onready var damage_receiver_area := $DamageReceiverArea
@onready var damage_dealer_area := $DamageDealerArea
@onready var water_detection_area := $WaterDetectionArea
@onready var camera_target := $CameraTarget
@onready var sfx_swing := $SFXSwing
@onready var sfx_jump := $SFXJump
@onready var sfx_hit := $SFXHit
@onready var ground_raycast := $GroundRaycast
@onready var upper_body_wall_detection_area := $UpperBodyWallDetectionArea

@export var gravity := 850.0
@export var max_fall_velocity := 400.0
@export var acceleration := 500.0
@export var max_velocity := 120.0
@export var max_velocity_carrying := 90.0
@export var max_velocity_in_water := 60.0
@export var friction := 800.0
@export var air_friction := 20.0
@export var jump_force := 290.0
@export var knockback_duration := 100.0
@export var knockback_intensity := 20.0
@export var push_strength := 30.0
@export var min_time_between_hits := 1000.0 # 1sec
@export var grace_period_jump := 150.0
@export var float_time := 2000
@export var slide_time := 500
@export var time_between_slides := 1500

const BeamSpell = preload("res://FX/BeamSpell/beam_spell.tscn")
const SmallBox = preload("res://Entities/ResizableBox/small_box.tscn")
const BigBox = preload("res://Entities/ResizableBox/big_box.tscn")
const HeroSpark = preload("res://FX/HitSpark/hero_spark.tscn")
const BoxResize = preload("res://Entities/ResizableBox/box_resize.tscn")
const WaterSplash = preload("res://FX/Splash/water_spash.tscn")
const Gem = preload("res://World/Gem/gem.tscn")

enum State {Idle, Running, Jumping, StartFalling, Falling, Casting, Attacking, Pushing, Carrying, CarryingIdle, Hurting, Dying, Dead, Resting, Healing, Pickup, Sliding}
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
	State.Sliding: "slide",
}
var state:State = State.Idle
var pushed_box = null
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
var current_treasure : TreasureChest.Content = TreasureChest.Content.LifePotion
var is_floating := false
var time_last_jump := Time.get_ticks_msec()
var frozen := false
var last_cast_target = null
var time_start_slide := Time.get_ticks_msec()
var time_last_slide := Time.get_ticks_msec() - time_between_slides

func _ready():
	pickup_area.connect("area_entered", on_player_enter_pickable.bind())
	pickup_area.connect("area_exited", on_player_exit_pickable.bind())
	damage_receiver_area.connect("hit", on_player_hit.bind())

func _physics_process(delta):
	if box_detector.is_colliding():
		pushed_box = box_detector.get_collider()
	else:
		pushed_box = null
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
	return is_on_floor() and not is_carrying and [State.Running, State.Idle].has(state)

func can_slide() -> bool:
	if Time.get_ticks_msec() - time_last_slide < time_between_slides:
		return false
	return can_dodge() and is_on_floor() and not is_carrying and [State.Running, State.Idle].has(state)

func move(delta):
	carried_box.visible = is_carrying
	if is_on_floor():
		last_time_on_floor = Time.get_ticks_msec()
	apply_gravity(delta)
	if state == State.Sliding:
		if Time.get_ticks_msec() - time_start_slide > slide_time and not upper_body_wall_detection_area.has_overlapping_bodies():
			state = State.Idle
			time_last_slide = Time.get_ticks_msec()
			damage_receiver_area.set_deferred("monitorable", true)
	elif can_move():
		var input_axis = Input.get_axis("move_left", "move_right")
		if frozen:
			input_axis = 0
		if is_moving(input_axis):
			apply_acceleration(delta, input_axis)
			sprite.scale.x = sign(input_axis)
#			casting_ray.scale.x = sign(input_axis)
			casting_area.scale.x = sign(input_axis)
			box_detector.scale.x = sign(input_axis)
			damage_dealer_area.scale.x = sign(input_axis)
			laser_start.position.x = sign(input_axis) * abs(laser_start.position.x)
			carried_box.position.x = sign(input_axis) * abs(carried_box.position.x)
			if is_on_floor():
				if is_carrying:
					state = State.Carrying
				elif pushed_box != null:
					state = State.Pushing
					var dir = (pushed_box.position - position).normalized()
					pushed_box.move_and_collide(Vector2.RIGHT * dir * delta * push_strength)
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
		slide_check()
		cast_check()
		attack_check()
		pickup_check()
	play_animations()

	if knockback != Vector2.ZERO:
		var knockback_val = min((Time.get_ticks_msec() - knockback_start) / knockback_duration, 1.0)
		knockback = knockback.lerp(Vector2.ZERO, knockback_val)
		velocity += knockback

	if state == State.Attacking:
		apply_friction(delta)

	if state != State.Dead:
		move_and_slide()
	camera_target.position.x = lerpf(0.0, 20.0, velocity.x / get_max_velocity())
	
	check_poison()
	check_cast_highlight()
	
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

func check_cast_highlight():
	var collider = find_cast_target()
	if collider != null and collider != last_cast_target:
		if last_cast_target != null:
			last_cast_target.stop_highlight()
		last_cast_target = collider
		collider.highlight()
	elif collider == null and last_cast_target != null:
			last_cast_target.stop_highlight()
			last_cast_target = null
	

func can_pickup() -> bool:
	return is_on_floor() and (state == State.Idle or state == State.Running)

func pickup_check():
	if can_pickup() and Input.is_action_just_pressed("crouch") and pickable_target != null:
		velocity.x = 0
		pickable_target.queue_free()
		is_carrying = true

func slide_check():
	if can_slide() and Input.is_action_just_pressed("dodge"):
		velocity.x = sign(velocity.x) * max_velocity
		state = State.Sliding
		damage_receiver_area.set_deferred("monitorable", false)
		time_start_slide = Time.get_ticks_msec()

func get_item(item: TreasureChest.Content):
	state = State.Pickup
	velocity = Vector2.ZERO
	current_gem_reference = Gem.instantiate()
	current_gem_reference.color = item
	current_gem_reference.global_position = global_position + Vector2.UP * 16
	current_gem_reference.connect("gain_gem", on_gain_gem.bind(item))
	GameState.add_to_level(current_gem_reference)
	current_treasure = item

func on_system_message_callback():
	state = State.Idle
	GameState.gain_treasure(current_treasure)
	if current_gem_reference != null:
		current_gem_reference.queue_free()
		current_gem_reference = null

func on_gain_gem(item):
	if item == TreasureChest.Content.LifePotion:
		GameState.show_system_message(["You found a life potion!", "You feel stronger!"], on_system_message_callback.bind())
	elif item == TreasureChest.Content.GreenGem:
		GameState.show_system_message(["You found the green crystal!", "Your body feels lighter!"], on_system_message_callback.bind())
	elif item == TreasureChest.Content.BlueGem:
		GameState.show_system_message(["You found the blue crystal!", "Your lungs feel powerful!"], on_system_message_callback.bind())
	elif item == TreasureChest.Content.PurpleGem:
		GameState.show_system_message(["You found the purple crystal!", "Your feel more agile!", "Press c to slide and dodge"], on_system_message_callback.bind())

func cast_check():
	if Input.is_action_just_pressed("cast"):
		if is_carrying:
			throw_box()
		elif can_cast():
			cast()
			velocity.x = 0

func cast():
	state = State.Casting
	var collider = find_cast_target()
	if collider != null:
		var collision_point : Vector2 = to_local(collider.global_position)
		var beam_spell = BeamSpell.instantiate()
		laser_start.add_child(beam_spell)
		collision_point.x -= laser_start.position.x
		collision_point.y = 0
		beam_spell.cast_to(collider)

func can_attack() -> bool:
	if frozen or is_carrying:
		return false
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
	if is_carrying:
		return null
	if casting_area.has_overlapping_bodies():
		var colliders = casting_area.get_overlapping_bodies()
		var closest = 100000
		var target_box = null
		for collider in colliders:
			if (global_position - collider.global_position).length() < closest:
				target_box = collider
				closest = (global_position - collider.global_position).length()
		if target_box != null:
			var collider = target_box
			if collider.is_in_group("shrinkable") or collider.is_in_group("expandable"):
				if collider.is_in_group("shrinkable") and collider.has_box_on_top():
					collider = collider.get_box_on_top()
				if collider != null:
					casting_ray.target_position.y = collider.global_position.y - global_position.y
					casting_ray.target_position.x = collider.global_position.x - global_position.x
					if not casting_ray.is_colliding():
						return collider
	return null

func is_pushing():
	return pushed_box != null and not is_carrying

func is_moving(input_axis):
	return input_axis != 0

func apply_gravity(delta):
	if can_float() and is_floating:
		if !Input.is_action_pressed("jump") or Time.get_ticks_msec() - time_last_jump > float_time:
			is_floating = false
	if not is_on_floor():
		velocity.y = move_toward(velocity.y, max_fall_velocity, gravity * delta)
		if velocity.y > 0 and is_floating:
			velocity.y = 0

func apply_acceleration(delta, input_axis):
	var max_vel = get_max_velocity()
	if is_moving(input_axis):
		velocity.x = move_toward(velocity.x, input_axis * max_vel, acceleration * delta)

func get_max_velocity() -> float:
	var max_vel = max_velocity
	if is_carrying:
		max_vel = max_velocity_carrying
	if in_water():
		max_vel = max_velocity_in_water
	return max_vel

func apply_friction(delta):
	if is_on_floor():
		velocity.x = move_toward(velocity.x, 0, friction * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, air_friction * delta)

func jump_check():
	if frozen:
		return
	var force = jump_force
	var elapsed_since_on_floor = Time.get_ticks_msec() - last_time_on_floor
	if (is_on_floor() or elapsed_since_on_floor < grace_period_jump) and Input.is_action_just_pressed("jump"):
		if Input.is_action_pressed("crouch") and not state == State.Casting and not ground_raycast.is_colliding():
			position.y += 1
		else:
			jump(force)
	if not is_on_floor():
		# limit down speed
		if Input.is_action_just_released("jump") and velocity.y < -jump_force / 2:
			velocity.y = -jump_force / 2

func splash():
	var liquid_color : Color = water_detection_area.get_overlapping_areas()[0].get_parent().get_color()
	var water_splash = WaterSplash.instantiate()
	GameState.add_to_level(water_splash)
	water_splash.process_material.color_ramp.gradient.colors[0] = liquid_color
	water_splash.process_material.color_ramp.gradient.colors[1] = liquid_color.lightened(0.4)
	water_splash.global_position = global_position

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
	if can_float():
		time_last_jump = Time.get_ticks_msec()
		is_floating = true

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

func can_float():
	return GameState.current_gems[TreasureChest.Content.GreenGem]

func can_swim():
	return GameState.current_gems[TreasureChest.Content.BlueGem]

func can_dodge():
	return GameState.current_gems[TreasureChest.Content.PurpleGem]
