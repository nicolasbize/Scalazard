extends Node2D

@onready var wall_detection_area := $WallDetectionArea
@onready var damage_area := $DamageDealerArea
@onready var particles := $GPUParticles2D
@onready var sprite := $Sprite2D

const fire_impact = preload("res://FX/Fireball/fire_impact_fx.tscn")

var parent_trap = null
var velocity = Vector2.ZERO

var landed := false
var initialized := false

func _ready():
	wall_detection_area.connect("body_entered", on_body_enter.bind())
	damage_area.connect("area_entered", on_damage_enter.bind())

func _physics_process(delta):
	if not initialized:
		initialized = true
		if velocity.x < 0:
			sprite.rotation_degrees = 180
			particles.process_material.angle_min = 180
			particles.process_material.angle_max = 180
		else:
			sprite.rotation_degrees = 0
			particles.process_material.angle_min = 0
			particles.process_material.angle_max = 0
	if landed:
		velocity = Vector2.ZERO
		particles.one_shot = true 
		if not particles.emitting:
			queue_free()
	position += velocity * delta
	

func initialize(vel:Vector2, trap: StaticBody2D):
	parent_trap = trap
	velocity = vel

func on_damage_enter(area):
	landed = true

func on_body_enter(body):
	if body != parent_trap:
		landed = true
		var impact = fire_impact.instantiate()
		GameState.add_to_level(impact)
		impact.emitting = true
		if sign(velocity.x) > 0:
			impact.rotation_degrees = 180
		impact.global_position = global_position
		
		
