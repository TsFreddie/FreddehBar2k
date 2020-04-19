extends Reference
class_name Chart

var title: String = ""
var subtitle: String = ""
var artist: String = ""
var subartists: Array = []
var genre: String = ""
var mode_hint: String = "beat-7k"
var chart_name: String = "Unique"
var level: int = 0
var bpm: float = 1
var judge_rank: float = 100
var total: float = 100
var back_image = null
var eyecatch_image = null
var banner_image = null
var preview_music = null
var resolution: int = 240

var chart_path: String = ""

var visible_notes = []
var line_notes = []
var stop_notes = []
var bpm_notes = []

var audios = []
var audio_slices = []

static func has(obj, field, type = null):
	if (typeof(obj) != TYPE_DICTIONARY):
		return false
	if (type == null):
		return field in obj && obj[field] != null
	return field in obj && typeof(obj[field]) == type
	
static func default_to(obj, field, default = null, type = null):
	return obj[field] if has(obj, field, type) else default
	

static func _compare_y(a, b):
	if typeof(a) == TYPE_INT || typeof(a) == TYPE_REAL:
		return a <= b.y
	if typeof(b) == TYPE_INT || typeof(b) == TYPE_REAL:
		return a.y <= b
	return a.y <= b.y
	
func find_bpm_at(pulse) -> float:
	var index = bpm_notes.bsearch_custom(pulse, self, "_compare_y", true) - 1
	return bpm_notes[index]

func read_bmson(path: String) -> bool:
	var bmsonFile = File.new()
	bmsonFile.open(path, File.READ)
	chart_path = path.get_base_dir()
	var bmsonString = bmsonFile.get_as_text()
	bmsonFile.close()
	var parseResult = JSON.parse(bmsonString)
	
	if (parseResult.error != OK):
		return false
	
	var bmson = parseResult.result

	if (typeof(bmson) != TYPE_DICTIONARY):
		return false

	# Parsing Info
	if !has(bmson, "info", TYPE_DICTIONARY):
		return false
	
	var info = bmson.info
	title = default_to(info, "title", "", TYPE_STRING)
	subtitle = default_to(info, "subtitle", "", TYPE_STRING)
	artist = default_to(info, "artist", "", TYPE_STRING)
	subartists = default_to(info, "subartists", [], TYPE_ARRAY)
	genre = default_to(info, "genre", "", TYPE_ARRAY)
	mode_hint = default_to(info, "mode_hint", "beat-7k", TYPE_STRING)
	chart_name = default_to(info, "chart_name", "Unique", TYPE_STRING)
	level = default_to(info, "level", 0, TYPE_REAL)
	total = default_to(info, "total", 100, TYPE_REAL)
	back_image = default_to(info, "back_image", null, TYPE_STRING)
	eyecatch_image = default_to(info, "eyecatch_image", null, TYPE_STRING)
	banner_image = default_to(info, "banner_image", null, TYPE_STRING)
	preview_music = default_to(info, "preview_music", null, TYPE_STRING)
	resolution = default_to(info, "resolution", 240, TYPE_REAL)
	bpm = default_to(info, "initBPM" if has(info, "initBPM") else "init_bpm", 0, TYPE_REAL)
	judge_rank = default_to(info, "judgeRank" if has(info, "judgeRank") else "judge_rank", 100, TYPE_REAL)
	bpm_notes.append({"y": 0, "bpm": bpm, "t": 0})
	# Parsing BPM events [TODO: parse and add timing]
	
	
	# Parsing Notes
	var channels = default_to(bmson, "soundChannel" if has(bmson, "soundChannel") else "sound_channels", null, TYPE_ARRAY)
	if (channels == null):
		return false
	
	var audio_index = {null: -1}
	
	for channel in channels:
		var channel_file = default_to(channel, "name", null, TYPE_STRING)
		var audio_id = -1
		if (channel_file in audio_index):
			audio_id = audio_index[channel_file]
		else:
			audio_id = audios.size()
			audios.append(channel_file)
			audio_index[channel_file] = audio_id
	
		var notes = default_to(channel, "notes", null, TYPE_ARRAY)
		if (notes == null):
			continue
		
		# TODO: add notes
		var prev_note = null
		for note in notes:
			var y = default_to(note, "y", null, TYPE_REAL)
			if (y == null):
				continue
				
			note["y"] = int(y)
			note["x"] = int(default_to(note, "x", 0, TYPE_REAL))
			note["l"] = int(default_to(note, "l", 0, TYPE_REAL))
			note["c"] = int(default_to(note, "c", false, TYPE_BOOL))
			
			var bpm = find_bpm_at(note)
			var spb = 60 / bpm.bpm

			# TODO: better timing
			var t = ((y - bpm.y) / resolution * spb + bpm.t)
			note["t"] = t
			note["a"] = audio_id
			
			if (prev_note == null):
				note["offset"] = t
				note["aa"] = 0
			else:
				note["offset"] = prev_note.offset if note.c else t
				note["aa"] = t - note.offset
				prev_note["al"] = t - prev_note.t
				visible_notes.append(prev_note)
				
			prev_note = note
		
		if (prev_note != null):
			prev_note.al = -1
			visible_notes.append(prev_note)

	return true


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
