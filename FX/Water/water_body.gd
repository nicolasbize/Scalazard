class_name WaterBody
extends Node2D

@export var stiffness := 0.01
@export var dampening := 0.03
@export var spread := 0.0002
@export var precision := 5
@export var ticks_between_waves := 300
@export var liquid_type : LiquidType = LiquidType.Water

@onready var water_polygon := $WaterPolygon
@onready var player_detection_area := $PlayerDetectionArea
@onready var water_shape := $PlayerDetectionArea/CollisionShape2D

enum LiquidType {Water, Poison}

const WaterSpring = preload("res://FX/Water/water_spring.tscn")
const water_tints = {
	LiquidType.Water: Color("2b696d"),
	LiquidType.Poison: Color("366b4c"),
}

var springs = []
var passes := 8
var target_height := 0.0
var bottom := 0.0
var depth := 0.0
var width := 0.0
var distance_between_springs := 0.0
var spring_amount := 3
var time_since_last_wave := Time.get_ticks_msec()

func _ready():
	depth = water_shape.shape.size.y
	width = water_shape.shape.size.x
	bottom = target_height + depth
	spring_amount = floori(width / precision)
	distance_between_springs = width / spring_amount

	water_polygon.material.set_shader_parameter("tint", water_tints[liquid_type])
	
	for i in range(spring_amount):
		var x_pos := distance_between_springs * i
		var spring := WaterSpring.instantiate()
		add_child(spring)
		springs.append(spring)
		spring.initialize(x_pos, depth)
	

func _physics_process(delta):
	for water_spring in springs:
		water_spring.update_water(stiffness, dampening)
	# movement of neighbors
	var left_deltas = []
	var right_deltas = []
	
	for water_spring in springs:
		left_deltas.append(0)
		right_deltas.append(0)
	
	for j in range(passes):
		for i in range(springs.size()):
			if i > 0:
				left_deltas[i] = spread * (springs[i].height - springs[i-1].height)
				springs[i-1].velocity += left_deltas[i]
			if i < springs.size()-1:
				right_deltas[i] = spread * (springs[i].height - springs[i+1].height)
				springs[i+1].velocity += right_deltas[i]
	draw_water_body()
	check_player_splash()

func check_player_splash():
	if player_detection_area.has_overlapping_bodies():
		var player = player_detection_area.get_overlapping_bodies()[0]
		var elapsed = Time.get_ticks_msec() - time_since_last_wave
		if elapsed > ticks_between_waves:
			time_since_last_wave = Time.get_ticks_msec()
			var spring_index = roundi(spring_amount * (player.global_position.x - global_position.x) / width)
			splash(spring_index, 5)

func get_color() -> Color:
	return water_tints[liquid_type]

func draw_water_body():
	var surface_points := []
	for i in range(springs.size()):
		surface_points.append(springs[i].position)
	var first_index := 0
	var last_index := surface_points.size() - 1
	var water_polygon_points := surface_points

	water_polygon_points.append(Vector2(surface_points[last_index].x, bottom))
	water_polygon_points.append(Vector2(surface_points[first_index].x, bottom))
	water_polygon_points = PackedVector2Array(water_polygon_points)
	water_polygon.set_polygon(water_polygon_points)
	

func splash(index, speed):
	if index >= 0 and index < springs.size():
		springs[index].velocity += speed
		
