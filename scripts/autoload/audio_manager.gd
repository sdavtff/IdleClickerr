extends Node
## Efeitos sonoros e música ambiente.

const SOUND_NAMES := ["click", "coin", "build", "upgrade", "unlock", "mission", "error", "event", "research", "cash", "firework", "thunder", "complete"]

var _sounds := {}
var _players: Array[AudioStreamPlayer] = []
var _next := 0
var _music: AudioStreamPlayer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Barramentos separados para controlar volume de música e efeitos.
	for bus in ["Music", "SFX"]:
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
	_music = AudioStreamPlayer.new()
	var stream: AudioStreamWAV = load("res://assets/audio/music.wav")
	if stream.loop_mode == AudioStreamWAV.LOOP_DISABLED:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		stream.loop_end = int(stream.get_length() * stream.mix_rate)
	_music.stream = stream
	_music.volume_db = -12.0
	_music.bus = "Music"
	add_child(_music)
	SettingsManager.changed.connect(_apply_settings)
	_apply_settings()


func _apply_settings() -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(maxf(SettingsManager.music_volume, 0.0001)))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), linear_to_db(maxf(SettingsManager.sfx_volume, 0.0001)))
	if SettingsManager.music and not _music.playing:
		_music.play()
	elif not SettingsManager.music and _music.playing:
		_music.stop()


func play(name: String, pitch: float = 1.0) -> void:
	if not SettingsManager.sfx or _sounds.get(name) == null:
		return
	var p := _players[_next]
	_next = (_next + 1) % _players.size()
	p.stream = _sounds[name]
	p.pitch_scale = pitch
	p.play()
