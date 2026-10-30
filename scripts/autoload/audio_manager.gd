extends Node
## Efeitos sonoros, música (dia e noite com transição suave) e som ambiente
## da cidade (pássaros e trânsito de dia, grilos à noite).

const SOUND_NAMES := ["click", "coin", "build", "upgrade", "unlock", "mission", "error", "event", "research", "cash", "firework", "thunder", "complete", "boost", "login"]
const MUSIC_DB := -12.0
const AMBIENCE_DB := -16.0

var _sounds := {}
var _players: Array[AudioStreamPlayer] = []
var _next := 0
var _music: AudioStreamPlayer
var _music_night: AudioStreamPlayer
var _amb_day: AudioStreamPlayer
var _amb_night: AudioStreamPlayer
var _daylight := 1.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Barramentos separados para controlar volume de música, efeitos e ambiente.
	for bus in ["Music", "SFX", "Ambience"]:
		if AudioServer.get_bus_index(bus) < 0:
			AudioServer.add_bus()
			var idx := AudioServer.bus_count - 1
			AudioServer.set_bus_name(idx, bus)
			AudioServer.set_bus_send(idx, "Master")
	for i in 8:
		var p := AudioStreamPlayer.new()
		p.volume_db = -4.0
		p.bus = "SFX"
		add_child(p)
		_players.append(p)
	# Carregados em tempo de execução (o editor não precisa deles antes da importação).
	for n in SOUND_NAMES:
		_sounds[n] = load("res://assets/audio/%s.wav" % n)
	_music = _looping("music", "Music")
	_music_night = _looping("music_night", "Music")
	_amb_day = _looping("ambience_day", "Ambience")
	_amb_night = _looping("ambience_night", "Ambience")
	SettingsManager.changed.connect(_apply_settings)
	_apply_settings()


func _looping(file: String, bus: String) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	var stream: AudioStreamWAV = load("res://assets/audio/%s.wav" % file)
	if stream.loop_mode == AudioStreamWAV.LOOP_DISABLED:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		stream.loop_end = int(stream.get_length() * stream.mix_rate)
	p.stream = stream
	p.bus = bus
	add_child(p)
	return p


func _apply_settings() -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(maxf(SettingsManager.music_volume, 0.0001)))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), linear_to_db(maxf(SettingsManager.sfx_volume, 0.0001)))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Ambience"), linear_to_db(maxf(SettingsManager.ambience_volume, 0.0001)))
	_set_playing(_music, SettingsManager.music)
	_set_playing(_music_night, SettingsManager.music)
	_set_playing(_amb_day, SettingsManager.ambience)
	_set_playing(_amb_night, SettingsManager.ambience)
	_mix()


func _set_playing(p: AudioStreamPlayer, on: bool) -> void:
	if on and not p.playing:
		p.play()
	elif not on and p.playing:
		p.stop()


## Chamado pela cidade conforme o ciclo de dia e noite (0 = noite, 1 = dia).
func set_daylight(d: float) -> void:
	if absf(d - _daylight) < 0.02:
		return
	_daylight = d
	_mix()


func _mix() -> void:
	_music.volume_db = MUSIC_DB + linear_to_db(maxf(_daylight, 0.001))
	_music_night.volume_db = MUSIC_DB + linear_to_db(maxf(1.0 - _daylight, 0.001))
	_amb_day.volume_db = AMBIENCE_DB + linear_to_db(maxf(_daylight, 0.001))
	_amb_night.volume_db = AMBIENCE_DB + linear_to_db(maxf(1.0 - _daylight, 0.001))


func play(name: String, pitch: float = 1.0) -> void:
	if not SettingsManager.sfx or _sounds.get(name) == null:
		return
	var p := _players[_next]
	_next = (_next + 1) % _players.size()
	p.stream = _sounds[name]
	p.pitch_scale = pitch
	p.play()
