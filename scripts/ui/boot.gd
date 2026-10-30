extends Control
## Tela de carregamento: mostra o logo enquanto as cenas são carregadas
## em segundo plano.

const MENU := "res://scenes/MainMenu.tscn"
const GAME := "res://scenes/Game.tscn"
const MIN_TIME := 1.4

var _bar: ProgressBar
var _tip: Label
var _elapsed := 0.0
var _done := false
const TIPS := [
	"Dica: toque nas moedas flutuantes para ganhar bônus!",
	"Dica: a cidade continua rendendo por até 24 horas offline.",
	"Dica: serviços públicos deixam os moradores mais felizes.",
	"Dica: os níveis 10, 25, 50, 75 e 100 dobram a renda.",
]


func _ready() -> void:
	theme = UI.make_theme()
	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Color("3a8fd9")
	add_child(bg)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var v := UI.vbox(24)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(v)
	var logo := GameLogo.new()
	v.add_child(logo)
	_bar = UI.progress(0, 100, UI.C_GOLD)
	_bar.custom_minimum_size = Vector2(560, 30)
	v.add_child(_bar)
	_tip = UI.outlined(UI.label(TIPS[randi() % TIPS.size()], 22, Color.WHITE, true, HORIZONTAL_ALIGNMENT_CENTER), 5)
	v.add_child(_tip)
	logo.pivot_offset = Vector2(360, 115)
	logo.scale = Vector2(0.6, 0.6)
	logo.modulate.a = 0.0
	var tw := create_tween().set_parallel(true)
	tw.tween_property(logo, "scale", Vector2.ONE, 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(logo, "modulate:a", 1.0, 0.4)
	ResourceLoader.load_threaded_request(MENU)
	ResourceLoader.load_threaded_request(GAME)


func _process(delta: float) -> void:
	if _done:
		return
	_elapsed += delta
	var p1 := []
	var p2 := []
	var s1 := ResourceLoader.load_threaded_get_status(MENU, p1)
	var s2 := ResourceLoader.load_threaded_get_status(GAME, p2)
	var real := (float(p1[0] if p1.size() > 0 else 0.0) + float(p2[0] if p2.size() > 0 else 0.0)) * 50.0
	var timed := clampf(_elapsed / MIN_TIME, 0.0, 1.0) * 100.0
	_bar.value = minf(real, timed)
	var ok := s1 == ResourceLoader.THREAD_LOAD_LOADED and s2 == ResourceLoader.THREAD_LOAD_LOADED
	var failed := s1 == ResourceLoader.THREAD_LOAD_FAILED or s1 == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE
	if failed:
		_done = true
		get_tree().change_scene_to_file(MENU)
		return
	if ok and _elapsed >= MIN_TIME:
		_done = true
		ResourceLoader.load_threaded_get(GAME)
		get_tree().change_scene_to_packed(ResourceLoader.load_threaded_get(MENU))
