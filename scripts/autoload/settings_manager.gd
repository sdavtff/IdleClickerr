extends Node
## Configurações do jogador (salvas separadamente do progresso).

signal changed

const PATH := "user://settings.cfg"

var sfx := true
var music := true
var day_night := true
var weather := true
var high_quality := true
var floating_text := true


func _ready() -> void:
	load_settings()


func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		return
	sfx = bool(cfg.get_value("audio", "sfx", true))
	music = bool(cfg.get_value("audio", "music", true))
	day_night = bool(cfg.get_value("video", "day_night", true))
	weather = bool(cfg.get_value("video", "weather", true))
	high_quality = bool(cfg.get_value("video", "high_quality", true))
	floating_text = bool(cfg.get_value("video", "floating_text", true))


func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "sfx", sfx)
	cfg.set_value("audio", "music", music)
	cfg.set_value("video", "day_night", day_night)
	cfg.set_value("video", "weather", weather)
	cfg.set_value("video", "high_quality", high_quality)
	cfg.set_value("video", "floating_text", floating_text)
	cfg.save(PATH)


func set_value(key: String, v: bool) -> void:
	set(key, v)
	save_settings()
	changed.emit()
