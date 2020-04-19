extends Node

var _audio_automation_script

var scene_audio
var scene_music_player
var scene_audio_mutex

var game_audio
var game_audio_count
var game_audio_total

var game_audio_mutex
var game_audio_loader_queue

func _ready():
	_audio_automation_script = load("res://scripts/audio_automation.gd")
	scene_audio = {}
	scene_audio_mutex = Mutex.new()
	
	game_audio = {}
	game_audio_mutex = Mutex.new()
	
	game_audio_count = 0
	game_audio_total = -1
	
	game_audio_loader_queue = []

func _get_avaliable_audio_player():
	for player in get_children():
		if (!player.playing):
			return player
			
	var new_player = AudioStreamPlayer.new()
	new_player.bus = "SoundEffects"
	new_player.set_script(_audio_automation_script)
	add_child(new_player)
	return new_player

func _load_scene_audio_safe(path: String):
	scene_audio_mutex.lock()
	if (path in scene_audio):
		var result = scene_audio[path]
		scene_audio_mutex.unlock()
		return result
	else:
		scene_audio_mutex.unlock()
		var new_audio = AudioStreamRAM.new()
		new_audio.load(path)
		if (new_audio.is_valid()):
			scene_audio_mutex.lock()
			scene_audio[path] = new_audio
			scene_audio_mutex.unlock()
			return new_audio
		else:
			scene_audio_mutex.lock()
			scene_audio[path] = null
			scene_audio_mutex.unlock()
			return null
			
func _load_game_audio_safe(path: String):
	game_audio_mutex.lock()
	if (path in game_audio):
		var result = game_audio[path]
		game_audio_mutex.unlock()
		return result
	else:
		game_audio_mutex.unlock()
		var new_audio = AudioStreamRAM.new()
		new_audio.load(path)
		if (new_audio.is_valid()):
			game_audio_mutex.lock()
			game_audio[path] = new_audio
			game_audio_mutex.unlock()
			return new_audio
		else:
			game_audio_mutex.lock()
			game_audio[path] = null
			game_audio_mutex.unlock()
			return null
	

func load_and_play_music(path: String, cross_fade = 0):
	var audio = _load_scene_audio_safe(path)
	var player = _get_avaliable_audio_player()
	player.set_stream(audio)
	player.bus = "Music"
	player.get_stream_playback().set_loop(true)
	player.fade_in(cross_fade)
	
	if (scene_music_player != null):
		scene_music_player.fade_out(cross_fade)
	
	scene_music_player = player
	
func load_and_play_sound_effect(path: String):
	var audio = _load_scene_audio_safe(path)
	var player = _get_avaliable_audio_player()
	player.set_stream(audio)
	player.bus = "SoundEffects"
	player.volume_db = 0
	player.play()

func stop_music(fade_out = 0):
	scene_music_player.fade_out(fade_out)
	scene_music_player = null

func unload_scene_audio():
	var audio_data = scene_audio.values()
	for player in get_children():
		if (player.get_stream() in audio_data):
			player.stop()
			player.set_stream(null)

	scene_audio.clear()
	
func unload_game_audio():
	var audio_data = game_audio.values()
	for player in get_children():
		if (player.get_stream() in audio_data):
			player.stop()
			player.set_stream(null)

	game_audio.clear()
