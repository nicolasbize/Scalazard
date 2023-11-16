extends GPUParticles2D

var time_start := Time.get_ticks_msec()

func _physics_process(delta):
	var elapsed := Time.get_ticks_msec() - time_start
	if elapsed > lifetime * 2000:
		queue_free()
