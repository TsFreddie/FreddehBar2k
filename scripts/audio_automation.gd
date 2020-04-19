extends AudioStreamPlayer

var fading_in = false
var fading_out = false
var time_passed = 0.0
var time = 0.0

func _process(delta):
	if (fading_out):
		time_passed += delta
		volume_db = linear2db(1 - time_passed / time)
		if time_passed > time:
			volume_db = -80
			fading_out = false
			stop()
			
	if (fading_in):
		time_passed += delta
		volume_db = linear2db(time_passed / time)
		if time_passed > time:
			volume_db = 0
			fading_in = false

func fade_out(time):
	if (time <= 0):
		stop()
		fading_out = false
		fading_in = false
		return
		
	time_passed = 0
	fading_out = true
	volume_db = 0
	fading_in = false
	self.time = time

func fade_in(time):
	if (time <= 0):
		volume_db = 0
		play()
		fading_out = false
		fading_in = false
		return
		
	time_passed = 0
	fading_in = true
	fading_out = false
	volume_db = -80
	self.time = time
	play()
	
