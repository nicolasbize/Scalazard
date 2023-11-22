extends GPUParticles2D

@onready var timer := $Timer

func _ready():
	timer.connect("timeout", on_timer_timeout.bind())
	
func on_timer_timeout():
	queue_free()
