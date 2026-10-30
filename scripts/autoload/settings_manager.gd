extends Node
## Configurações do jogador (salvas separadamente do progresso).

signal changed

const PATH := "user://settings.cfg"
const QUALITY_NAMES := ["Baixa", "Média", "Alta"]

var sfx := true
var music := true
var music_volume := 0.7
var sfx_volume := 0.9
var day_night := true
var weather := true
## 0 = baixa, 1 = média, 2 = alta.
var quality := 2
var battery_saver := false
var floating_text := true
var notifications := true

## Compatibilidade com a 1.0 (antes havia apenas "alta qualidade" ligado/desligado).
var high_quality: bool:
	get:
		return quality >= 2


func _ready() -> void:
	load_settings()
	apply_fps()


func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		return
	sfx = bool(cfg.get_value("audio", "sfx", true))
	music = bool(cfg.get_value("audio", "music", true))
	music_volume = clampf(float(cfg.get_value("audio", "music_volume", 0.7)), 0.0, 1.0)
	sfx_volume = clampf(float(cfg.get_value("audio", "sfx_volume", 0.9)), 0.0, 1.0)
	day_night = bool(cfg.get_value("video", "day_night", true))
	weather = bool(cfg.get_value("video", "weather", true))
	if cfg.has_section_key("video", "quality"):
		quality = clampi(int(cfg.get_value("video", "quality", 2)), 0, 2)
	else:
		quality = 2 if bool(cfg.get_value("video", "high_quality", true)) else 1
	battery_saver = bool(cfg.get_value("video", "battery_saver", false))
	floating_text = bool(cfg.get_value("video", "floating_text", true))
	notifications = bool(cfg.get_value("game", "notifications", true))


func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "sfx", sfx)
	cfg.set_value("audio", "music", music)
	cfg.set_value("audio", "music_volume", music_volume)
	cfg.set_value("audio", "sfx_volume", sfx_volume)
	cfg.set_value("video", "day_night", day_night)
	cfg.set_value("video", "weather", weather)
	cfg.set_value("video", "quality", quality)
	cfg.set_value("video", "battery_saver", battery_saver)
	cfg.set_value("video", "floating_text", floating_text)
	cfg.set_value("game", "notifications", notifications)
	cfg.save(PATH)


func set_value(key: String, v) -> void:
	set(key, v)
	save_settings()
	apply_fps()
	changed.emit()


## 30 FPS em economia de bateria ou qualidade baixa; 60 FPS caso contrário.
func apply_fps() -> void:
	Engine.max_fps = 30 if (battery_saver or quality == 0) else 60


func pedestrian_count() -> int:
	return [6, 11, 16][quality]


func cars_per_lane() -> int:
	return [2, 3, 4][quality]
