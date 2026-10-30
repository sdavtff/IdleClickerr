extends Node
## Efeitos sonoros e música ambiente.

const SOUND_NAMES := ["click", "coin", "build", "upgrade", "unlock", "mission", "error"]

var _sounds := {}
var _players: Array[AudioStreamPlayer] = []
var _next := 0
var _music: AudioStreamPlayer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in 6:
		var p := AudioStreamPlayer.new()
		p.volume_db = -4.0
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
	_music.volume_db = -14.0
	add_child(_music)
	SettingsManager.changed.connect(_apply_settings)
	_apply_settings()


func _apply_settings() -> void:
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
