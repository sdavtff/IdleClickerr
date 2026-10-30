extends Node
## Efeitos sonoros e música ambiente.

const SOUNDS := {
	"click": preload("res://assets/audio/click.wav"),
	"coin": preload("res://assets/audio/coin.wav"),
	"build": preload("res://assets/audio/build.wav"),
	"upgrade": preload("res://assets/audio/upgrade.wav"),
	"unlock": preload("res://assets/audio/unlock.wav"),
	"mission": preload("res://assets/audio/mission.wav"),
	"error": preload("res://assets/audio/error.wav"),
}
const MUSIC := preload("res://assets/audio/music.wav")

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
	_music = AudioStreamPlayer.new()
	var stream: AudioStreamWAV = MUSIC
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
	if not SettingsManager.sfx or not SOUNDS.has(name):
		return
	var p := _players[_next]
	_next = (_next + 1) % _players.size()
	p.stream = SOUNDS[name]
	p.pitch_scale = pitch
	p.play()
