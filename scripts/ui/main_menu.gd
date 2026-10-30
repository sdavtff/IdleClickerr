extends Control
## Menu inicial animado: Continuar, Novo jogo, Configurações e Créditos.

const GAME := "res://scenes/Game.tscn"

var _sky: SkyView
var _dn := DayNight.new()
var _scene_root: Node2D
var _cars: Array[Car] = []
var _rng := RandomNumberGenerator.new()
var _confirm: ConfirmDialog
var _settings: SettingsPanel
var _credits: ModalPanel
var _continue_btn: Button
var _buttons: VBoxContainer


func _ready() -> void:
	_rng.randomize()
	theme = UI.make_theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dn.t = 0.36
	var sky_layer := CanvasLayer.new()
	sky_layer.layer = -10
	add_child(sky_layer)
	_sky = SkyView.new()
	_sky.day_night = _dn
	sky_layer.add_child(_sky)
	_build_panorama()
	_build_ui()


func _build_panorama() -> void:
	var layer := CanvasLayer.new()
	layer.layer = -5
	add_child(layer)
	_scene_root = Node2D.new()
	layer.add_child(_scene_root)
	var ground := CityGround.new()
	_scene_root.add_child(ground)
	ground.setup(1, -400, 3000)
	var ids := ["casa_pequena", "padaria", "hospital", "apartamento", "hotel", "escola", "arranha_ceu_res", "cinema", "torre_megacity", "parque", "shopping", "casa_moderna"]
	var x := 120.0
	for id in ids:
		var n := BuildingNode.new()
		_scene_root.add_child(n)
		n.setup({"uid": 0, "id": id, "lot": 0, "level": 1})
		n.position = Vector2(x, GameData.GROUND_Y)
		n.lights.visible = false
		x += BuildingArt.width_of(id) + 26.0
	for i in 5:
		var c := Car.new()
		_scene_root.add_child(c)
		var lane := i % 2
		c.randomize_car(_rng, lane, -1.0 if lane == 0 else 1.0)
		c.position = Vector2(_rng.randf_range(0, 1800), (GameData.LANE_FAR_Y if lane == 0 else GameData.LANE_NEAR_Y) + 14.0)
		c.lights.visible = false
		_cars.append(c)


func _build_ui() -> void:
	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.05, 0.1, 0.25, 0.25)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	var v := UI.vbox(10)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(v)
	var logo := GameLogo.new()
	v.add_child(logo)
	var sub := UI.outlined(UI.label("Transforme uma pequena vila em uma megacidade!", 24, Color.WHITE, true, HORIZONTAL_ALIGNMENT_CENTER), 6)
	v.add_child(sub)
	_buttons = UI.vbox(12)
	_buttons.custom_minimum_size = Vector2(420, 0)
	_buttons.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(_buttons)
	_continue_btn = _menu_btn("Continuar", UI.C_GREEN, _continue, "home")
	_menu_btn("Novo jogo", UI.C_ORANGE, _new_game, "build")
	var row := UI.hbox(12)
	_buttons.add_child(row)
	var s := UI.button("Configurações", UI.C_BLUE, func(): _settings.open_panel(), 20, false, "settings")
	s.custom_minimum_size = Vector2(0, 60)
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(s)
	var c := UI.button("Créditos", UI.C_PURPLE, func(): _credits.open_panel(), 20, false, "trophy")
	c.custom_minimum_size = Vector2(0, 60)
	c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(c)
	var version := UI.outlined(UI.label("v" + str(ProjectSettings.get_setting("application/config/version", "1.0")), 16, Color.WHITE), 4)
	version.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	version.offset_left = -110
	version.offset_top = -40
	version.offset_right = -14
	version.offset_bottom = -8
	version.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(version)

	_continue_btn.visible = GameManager.has_save()
	_confirm = ConfirmDialog.new()
	add_child(_confirm)
	_settings = SettingsPanel.new()
	_settings.in_menu = true
	add_child(_settings)
	_credits = _make_credits()
	add_child(_credits)
	# animação de entrada
	logo.pivot_offset = Vector2(360, 115)
	logo.scale = Vector2(0.3, 0.3)
	logo.modulate.a = 0.0
	_buttons.modulate.a = 0.0
	sub.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(logo, "modulate:a", 1.0, 0.2)
	tw.parallel().tween_property(logo, "scale", Vector2.ONE, 0.7).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(sub, "modulate:a", 1.0, 0.3)
	tw.tween_property(_buttons, "modulate:a", 1.0, 0.3)


func _menu_btn(text: String, col: Color, cb: Callable, icon_name: String) -> Button:
	var b := UI.button(text, col, cb, 28, false, icon_name)
	b.custom_minimum_size = Vector2(0, 76)
	_buttons.add_child(b)
	return b


func _make_credits() -> ModalPanel:
	var p := ModalPanel.new()
	p.title = "Créditos"
	p.icon_name = "trophy"
	p.desired_size = Vector2(820, 560)
	p.ready.connect(_fill_credits.bind(p))
	return p


func _fill_credits(p: ModalPanel) -> void:
	for line in [
		["Idle City", 30, true],
		["Um jogo idle de construção de cidades.", 20, false],
		["", 10, false],
		["Design, programação, arte e áudio", 22, true],
		["Criados especialmente para este projeto: arte vetorial cartoon,", 18, false],
		["ícones, efeitos sonoros e música gerados proceduralmente.", 18, false],
		["", 10, false],
		["Tecnologia", 22, true],
		["Godot Engine 4 (MIT) — godotengine.org", 18, false],
		["Fonte Fredoka — The Fredoka Project Authors (SIL Open Font License 1.1)", 18, false],
		["", 10, false],
		["Obrigado por jogar!", 24, true],
	]:
		p.list.content.add_child(UI.label(line[0], line[1], UI.C_TEXT, line[2], HORIZONTAL_ALIGNMENT_CENTER))


func _process(delta: float) -> void:
	_dn.advance(delta * 0.4)
	var vw := get_viewport_rect().size.x
	for c in _cars:
		c.advance(delta)
		if c.dir > 0 and c.position.x > vw + 200:
			c.position.x = -200 - _rng.randf_range(0, 300)
		elif c.dir < 0 and c.position.x < -200:
			c.position.x = vw + 200 + _rng.randf_range(0, 300)
	var vh := get_viewport_rect().size.y
	_scene_root.position.y = vh - 720.0


func _continue() -> void:
	if GameManager.continue_game():
		_start()
	else:
		GameManager.toast.emit("Nenhum jogo salvo válido encontrado.", "warning")
		_continue_btn.visible = false


func _new_game() -> void:
	if GameManager.has_save():
		var do_it := func():
			GameManager.new_game()
			_start()
		_confirm.ask("Começar um novo jogo?", "O jogo salvo atual (incluindo prestígio e conquistas) será apagado.", "Novo jogo", do_it)
	else:
		GameManager.new_game()
		_start()


func _start() -> void:
	AudioManager.play("build")
	UI.modal_stack.clear()
	get_tree().change_scene_to_file(GAME)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		var top := UI.top_modal()
		if top != null:
			top.close_panel()
		else:
			get_tree().quit()
