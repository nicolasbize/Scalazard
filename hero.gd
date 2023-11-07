class_name Player
extends CharacterBody2D

@onready var sprite := $Sprite2D
@onready var animation_player := $AnimationPlayer
@onready var box_detector := $BoxDetector
@onready var laser_start := $LaserStart
@onready var pickup_area := $PickupArea
@onready var carried_box := $CarriedBox

@export var gravity := 850.0
@export var max_fall_velocity := 400.0
@export var acceleration := 500.0
@export var max_velocity := 100.0
@export var max_run_velocity := 180.0
@export var friction := 700.0
@export var air_friction := 20.0
@export var jump_force := 250.0

const Laser = preload("res://laser.tscn")
const Impulse = preload("res://impulse.tscn")
const SmallBox = preload("res://small_box.tscn")
const BigBox = preload("res://big_box.tscn")

enum State {Idle, Run, JumpStart, Jump, Push, Laser, Impulse}
var state:State = State.Idle
var target_box = null
var laser = null
var impulse = null
var is_carrying := false
var current_sign_indicator = null

func _ready():
    pickup_area.connect("area_entered", on_player_pickup.bind())

func _physics_process(delta):
    if box_detector.is_colliding():
        target_box = box_detector.get_collider()
    else:
        target_box = null
    move(delta)

func on_player_pickup(area:Area2D):
    if not is_carrying:
        var box = area.get_parent()
        box.queue_free()
        is_carrying = true

func move(delta):
    carried_box.visible = is_carrying
    apply_gravity(delta)
    if state != State.Laser and state != State.Impulse:
        var input_axis = Input.get_axis("move_left", "move_right")
        if is_moving(input_axis):
            apply_acceleration(delta, input_axis)
            sprite.scale.x = sign(input_axis)
            box_detector.scale.x = sign(input_axis)
            laser_start.position.x = sign(input_axis) * abs(laser_start.position.x)
            carried_box.position.x = sign(input_axis) * abs(carried_box.position.x)
            if is_on_floor() and not is_pushing() and state != State.Run:
                state = State.Run
            elif is_on_floor() and is_pushing():
                if state != State.Push:
                    state = State.Push
                else:
                    var dir = (target_box.position - position).normalized()
                    target_box.move_and_collide(Vector2.RIGHT * dir * delta * 20.0)
            elif not is_on_floor() and state != State.Jump:
                state = State.Jump
        else:
            apply_friction(delta)
            if is_on_floor() and state != State.Idle:
                state = State.Idle
        jump_check()
        if is_on_floor() and Input.is_action_just_pressed("powerup"):
            if is_carrying:
                throw()
            else:
                start_laser()
        if is_on_floor() and not is_carrying and Input.is_action_just_pressed("powerdown"):
            velocity.x = 0
            start_impulse()
            
    elif state == State.Laser:
        if Input.is_action_just_released("powerup"):
            finish_laser()
    elif state == State.Impulse:
        if Input.is_action_just_released("powerdown"):
            finish_impulse()
    play_animation()
    
    if state != State.Laser:
        move_and_slide()

func finish_laser():
    state = State.Idle
    laser.queue_free()

func finish_impulse():
    state = State.Idle
    impulse.queue_free()

func start_laser():
    state = State.Laser
    laser = Laser.instantiate()
    laser.connect("complete", on_laser_complete.bind())
    if laser_start.position.x > 0:
        laser.dir = 1.0
    else:
        laser.dir = -1.0
    get_parent().add_child(laser)
    laser.global_position = laser_start.global_position

func start_impulse():
    state = State.Impulse
    impulse = Impulse.instantiate()
    impulse.connect("complete", on_impulse_complete.bind())
    if laser_start.position.x > 0:
        impulse.dir = 1.0
    else:
        impulse.dir = -1.0
    get_parent().add_child(impulse)
    impulse.global_position = global_position

func on_laser_complete(box):
    finish_laser()
    if box.is_in_group("shrinkable"):
        var smallbox = SmallBox.instantiate()
        get_parent().add_child(smallbox)
        smallbox.global_position = box.global_position
        box.queue_free()
        
func on_impulse_complete(box):
    finish_impulse()
    if box.is_in_group("expandable"):
        var bigbox = BigBox.instantiate()
        get_parent().add_child(bigbox)
        bigbox.global_position = box.global_position
        box.queue_free()

func play_animation():
    if state == State.JumpStart:
        animation_player.play("init_jump")
    elif state == State.Jump:
        animation_player.play("jump")
    elif state == State.Idle or state == State.Laser or state == State.Impulse:
        animation_player.play("idle")
    elif state == State.Run:
        animation_player.play("run")
    elif state == State.Push:
        animation_player.play("push")

func is_pushing():
    return target_box != null and not is_carrying

func is_moving(input_axis):
    return input_axis != 0

func apply_gravity(delta):
    if not is_on_floor():
        velocity.y = move_toward(velocity.y, max_fall_velocity, gravity * delta)

func apply_acceleration(delta, input_axis):
    var max = max_velocity
#	if Input.is_action_pressed("run"):
#		max = max_run_velocity
    if is_moving(input_axis):
        velocity.x = move_toward(velocity.x, input_axis * max, acceleration * delta)

func apply_friction(delta):
    if is_on_floor():
        velocity.x = move_toward(velocity.x, 0, friction * delta)
    else:
        velocity.x = move_toward(velocity.x, 0, air_friction * delta)

func jump_check():
    if current_sign_indicator != null and Input.is_action_just_pressed("jump"):
        current_sign_indicator.display_text()
    else:
        var force = jump_force
    #    if is_carrying:
    #        force = jump_force / 2
        if is_on_floor() and Input.is_action_just_pressed("jump"):
            jump(force)
        if not is_on_floor():
            if Input.is_action_just_released("jump") and velocity.y < -jump_force / 2:
                velocity.y = -jump_force / 2

func throw():
    is_carrying = false
    var smallbox = SmallBox.instantiate()
    get_parent().add_child(smallbox)
    smallbox.global_position = carried_box.global_position
    if not Input.is_action_pressed("crouch"):
        var dir = 1.0
        if laser_start.position.x < 0:
            dir = -1.0
        smallbox.apply_impulse(Vector2(300 * dir, -80))
        

func jump(force, create_effect = true):
    velocity.y = -force
    state = State.JumpStart

func on_end_init_jump():
    state = State.Jump
