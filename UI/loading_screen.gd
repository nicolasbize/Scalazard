extends Node2D

@onready var completion_label := $Sprite2D/CompletionLabel
@onready var fx_node := $FX
@onready var beam_target := $BeamTarget

signal complete

var current_particles = null
var start_time_emission = -1

const emission_list = [
	preload("res://FX/Fireball/fire_impact_fx.tscn"),
	preload("res://FX/Thunder/thunder_impact_fx.tscn"),
	preload("res://FX/Splash/water_spash.tscn"),
	preload("res://FX/Splash/water_spash.tscn"),
	preload("res://FX/BeamSpell/beam_spell.tscn"),
]

var completed := false
var emission_index := -1

# Called when the node enters the scene tree for the first time.
func _ready():
	emit_next_fx()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if not completed:
		var current_progress = round(emission_index * 100 / emission_list.size())
		completion_label.text = str(current_progress) + "% completed"
		if current_particles is GPUParticles2D and not current_particles.emitting:
			emit_next_fx()
		elif current_particles is BeamSpell and beam_target == null:
			emit_next_fx()
	else:
		completion_label.text = "100% completed"
		
func emit_next_fx():
	emission_index += 1
	if emission_index < emission_list.size():
		current_particles = emission_list[emission_index].instantiate()
		fx_node.add_child(current_particles)
		if current_particles is GPUParticles2D:
			current_particles.one_shot = true
			current_particles.emitting = true
		elif current_particles is BeamSpell:
			current_particles.cast_to(beam_target)
		start_time_emission = Time.get_ticks_msec()
	else:
		completed = true
		emit_signal("complete")
		queue_free()
