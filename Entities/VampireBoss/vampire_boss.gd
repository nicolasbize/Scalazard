extends Node2D

@export var player : Player
@export var flight_speed := 60.0
@export var angle_coverage_angle_deg := 110
@export var speed_laser := 0.5
@export var current_life := 3
@export var ticks_vulnerable := 9000

@onready var animation_player := $AnimationPlayer
@onready var sprite := $Sprite2D
@onready var laser_raycast := $LaserRaycast
@onready var laser_damage_raycast := $LaserDamageRaycast
@onready var laser_line := $LaserLine
@onready var damage_receiver_area := $DamageReceiverArea
@onready var damage_dealer_area := $DamageDealerArea
@onready var ground_check := $GroundCheck
@onready var enemy_beam_source := $EnemyBeamSource

signal die

const EnergyBall = preload("res://FX/EnergyBall/energy_ball.tscn")
const HitSpark = preload("res://FX/HitSpark/hit_spark.tscn")
const JumpEffect = preload("res://FX/Jump/jump_effect.tscn")
const Explosion = preload("res://FX/Explode/explosion.tscn")

enum State {Idle, Fly, Hurt, Dying, Dead, Fireball, Laser, Vulnerable, Rising}

var state := State.Idle
var direction := 1.0
var ball_being_cast = null
var time_between_cast := 4000
var time_last_cast := -1
var angle_laser := 0.0
var angle_laser_end := 0.0
var laser_direction := 1.0
var velocity := Vector2.ZERO
var speed_laser_init := 400.0
var length_laser_init := 0.0
var is_laser_reached_wall := false
var gravity := 3.0
var max_velocity_y := 10.0
var destination := Vector2.ZERO
var time_at_destination := 1000
var time_since_vulnerable := -1
var origin_y := 0
var can_be_electrified := false
var time_last_hurt := -1
var time_between_hurts := 1000

const anim_states = {
	State.Idle: "idle",
	State.Fly: "fly",
	State.Fireball: "fireball",
	State.Laser: "laser",
	State.Hurt: "hurt",
	State.Dying: "dying",
	State.Dead: "dead",
	State.Vulnerable: "vulnerable",
	State.Rising: "laser",
}

func _ready():
	damage_receiver_area.connect("hit", on_enemy_hit.bind())
	destination = global_position
	destination = pick_new_destination()
	origin_y = global_position.y

func _physics_process(delta):
	damage_dealer_area.monitoring = current_life > 0
	damage_dealer_area.monitorable = current_life > 0
	enemy_beam_source.visible = state == State.Laser
	if player != null:
		if can_move():
			laser_line.points[1] = laser_line.points[0]
			direction = sign(destination.x - global_position.x)
			if direction == 0:
				direction = 1.0
			sprite.scale.x = direction
			global_position.x = move_toward(global_position.x, destination.x, delta * flight_speed)
			state = State.Fly
			if abs(global_position.x - destination.x) < 5:
				if can_cast():
					velocity = Vector2.ZERO
					state = State.Idle
					if randf() > 0.33:
						cast_fireball()
					else:
						cast_laser()
		elif state == State.Laser:
			laser_raycast.target_position = Vector2.DOWN.rotated(angle_laser) * 500
			if laser_raycast.is_colliding():
				if not is_laser_reached_wall:
					length_laser_init += delta * speed_laser_init
					laser_line.points[1] = (laser_raycast.get_collision_point() - laser_line.global_position).normalized() * length_laser_init
					if laser_line.points[1].length() > (laser_raycast.get_collision_point() - laser_line.global_position).length():
						is_laser_reached_wall = true
				else:
					angle_laser += speed_laser * delta * laser_direction
					laser_line.points[1] = (laser_raycast.get_collision_point() - laser_line.global_position).normalized() * 400
				laser_damage_raycast.target_position = laser_line.points[1]
				if laser_damage_raycast.is_colliding():
					stop_laser()
					player.on_player_hit(1, direction)
					
			if (laser_direction > 0 and angle_laser > angle_laser_end) or (laser_direction < 0 and angle_laser < angle_laser_end):
				stop_laser()
		elif state == State.Hurt:
			laser_line.points[1] = laser_line.points[0]		
			if abs(velocity.y) < max_velocity_y:
				velocity += Vector2.DOWN * delta * gravity
			if ground_check.is_colliding():
				velocity = Vector2.ZERO
				state = State.Vulnerable
				time_since_vulnerable = Time.get_ticks_msec()
		elif state == State.Vulnerable:
			if Time.get_ticks_msec() - time_since_vulnerable > ticks_vulnerable:
				state = State.Rising
				jump_back_top()

		if can_be_electrified and global_position.y == origin_y:
			on_enemy_hit(1, 0)
		global_position += velocity
		play_animation()

func notify_electric() -> void:
	if global_position.y == origin_y:
		on_enemy_hit(1, 0)

func on_enemy_hit(dmg:int, direction_knockback:float) -> void:
	if not can_get_hurt():
		return
	time_last_hurt = Time.get_ticks_msec()
	GameState.emit_signal("hit_received")
	var hit_spark = HitSpark.instantiate()
	GameState.add_to_level(hit_spark)
	hit_spark.global_position = global_position + Vector2.UP * 16
	if dmg > 5:
		current_life -= 1
		if current_life == 0:
			state = State.Dying
		else:
			# after getting hit by boxresize, jump back up
			jump_back_top()
	else:
		# hit by electric shock
		state = State.Hurt
		velocity = Vector2.ZERO
		GameSounds.play(GameSounds.Sound.EnemyKill)

func can_get_hurt():
	if Time.get_ticks_msec() - time_last_hurt < time_between_hurts:
		return false
	return not [State.Dying, State.Dead, State.Hurt, State.Rising].has(state)

func jump_back_top():
	state = State.Rising
	var jump_effect := JumpEffect.instantiate()
	GameState.add_to_level(jump_effect)
	jump_effect.global_position = global_position
	var tween = get_tree().create_tween()
	tween.tween_property(self, "global_position:y", origin_y, 1).set_trans(Tween.TRANS_CUBIC)
	tween.tween_callback(on_finish_jump_top)

func on_finish_jump_top():
	state = State.Idle

func stop_laser():
	state = State.Idle
	time_last_cast = Time.get_ticks_msec()
	time_between_cast = 2000
	destination = pick_new_destination()
	GameSounds.stop(GameSounds.Sound.Laser)

func can_move() -> bool:
	return state == State.Idle or state == State.Fly

func is_above_player() -> bool:
	return abs(player.global_position.x - global_position.x) < 10

func can_cast() -> bool:
	return can_move() and Time.get_ticks_msec() - time_last_cast > time_between_cast

func play_animation():
	animation_player.play(anim_states[state])

func on_finish_hurt():
	state = State.Idle

func cast_laser():
	velocity = Vector2.ZERO
	state = State.Laser
	is_laser_reached_wall = false
	laser_direction = direction
	length_laser_init = 0.0
	angle_laser = deg_to_rad(-70 if laser_direction > 0 else 70)
	angle_laser_end = angle_laser + laser_direction * deg_to_rad(angle_coverage_angle_deg)
	GameSounds.play(GameSounds.Sound.Laser)

func cast_fireball():
	velocity = Vector2.ZERO
	state = State.Fireball
	time_last_cast = Time.get_ticks_msec()
	ball_being_cast = EnergyBall.instantiate()
	GameState.add_to_level(ball_being_cast)
	ball_being_cast.global_position = global_position
	time_between_cast = 4000
	
func on_finish_casting():
	state = State.Idle
	destination = pick_new_destination()

func on_finish_dying():
	var explosion := Explosion.instantiate()
	GameState.add_to_level(explosion)
	explosion.global_position = global_position
	emit_signal("die")
	queue_free()

func pick_new_destination():
	var x := destination.x
	while abs(x - destination.x) < 100: # prevent tiny movements
		x = randf_range(-152, 128)
	return Vector2(x, origin_y)
