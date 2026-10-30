class_name ModalPanel
extends Control
## Base para janelas modais: fundo escurecido, cartão central com título,
## botão de fechar, abas opcionais e lista rolável.

signal closed

var title := ""
var icon_name := ""
var desired_size := Vector2(1100, 640)
var card: PanelContainer
var body: VBoxContainer
var header: HBoxContainer
var tabs_row: HBoxContainer
var list: ScrollList
var title_label: Label
var _tab_buttons: Array[Button] = []
var current_tab := 0
var _center: CenterContainer
var _built := false


func _init() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false


func _ready() -> void:
	_build_frame()


func _build_frame() -> void:
	if _built:
		return
	_built = true
	var dim := ColorRect.new()
	dim.color = Color(0.05, 0.07, 0.14, 0.62)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	_center = CenterContainer.new()
	_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_center)
	card = PanelContainer.new()
	var s := UI.style(Color("f7f3ea"), 26, 4, UI.OUTLINE, 8)
	s.content_margin_left = 22
	s.content_margin_right = 22
	s.content_margin_top = 16
	s.content_margin_bottom = 18
	card.add_theme_stylebox_override("panel", s)
	_center.add_child(card)
	body = UI.vbox(12)
	card.add_child(body)
	header = UI.hbox(12)
	body.add_child(header)
	if icon_name != "":
		header.add_child(UI.icon_rect(icon_name, 48))
	title_label = UI.label(title, 34, UI.C_TEXT, true)
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title_label)
	var close := Button.new()
	close.icon = UI.icon("close")
	close.expand_icon = true
	close.custom_minimum_size = Vector2(56, 56)
	close.flat = true
	close.focus_mode = Control.FOCUS_NONE
	close.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	close.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
	close.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
	close.pressed.connect(func():
		AudioManager.play("click")
		close_panel())
	header.add_child(close)
	tabs_row = UI.hbox(8)
	tabs_row.visible = false
	body.add_child(tabs_row)
	build_top(body)
	list = ScrollList.new()
	list.modal = self
	body.add_child(list)
	resized.connect(_fit)
	_fit()


## Ponto de extensão: conteúdo fixo acima da lista.
func build_top(_parent: VBoxContainer) -> void:
	pass


## Ponto de extensão: (re)constrói o conteúdo da lista.
func rebuild() -> void:
	pass


## Ponto de extensão: atualização leve (valores e estados de botões).
func refresh() -> void:
	pass


func _fit() -> void:
	if card == null:
		return
	var vs := get_viewport_rect().size
	card.custom_minimum_size = Vector2(minf(desired_size.x, vs.x - 40.0), minf(desired_size.y, vs.y - 30.0))


func set_tabs(names: Array) -> void:
	_build_frame()
	UI.clear(tabs_row)
	_tab_buttons.clear()
	tabs_row.visible = true
	for i in names.size():
		var idx := i
		var b := UI.button(names[i], UI.C_GREY, func(): select_tab(idx), 20, false)
		b.custom_minimum_size = Vector2(0, 50)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tabs_row.add_child(b)
		_tab_buttons.append(b)
	_style_tabs()


func select_tab(i: int) -> void:
	current_tab = i
	_style_tabs()
	list.scroll_to_top()
	rebuild()


func _style_tabs() -> void:
	for i in _tab_buttons.size():
		UI.color_button(_tab_buttons[i], UI.C_BLUE if i == current_tab else UI.C_GREY)


func open_panel() -> void:
	_build_frame()
	if not visible:
		UI.modal_stack.append(self)
	visible = true
	_fit()
	_style_tabs()
	rebuild()
	card.pivot_offset = card.size * 0.5
	card.scale = Vector2(0.92, 0.92)
	modulate.a = 0.0
	var tw := create_tween().set_parallel(true)
	tw.tween_property(card, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "modulate:a", 1.0, 0.12)


func close_panel() -> void:
	if not visible:
		return
	UI.modal_stack.erase(self)
	visible = false
	closed.emit()


func _gui_input(event: InputEvent) -> void:
	# Toque fora do cartão fecha a janela.
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if card and not card.get_global_rect().has_point(event.position):
			close_panel()
			accept_event()
