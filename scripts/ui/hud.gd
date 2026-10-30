class_name HUD
extends Control
## Interface principal: barra superior (dinheiro, renda, população,
## felicidade, prestígio) e barra inferior com os menus. Também exibe avisos.

signal open_build
signal open_upgrades
signal open_missions
signal open_expansion
signal open_prestige
signal open_settings
signal open_stats(tab: int)

var money_l: Label
var income_l: Label
var pop_l: Label
var pop_sub_l: Label
var happy_l: Label
var happy_sub_l: Label
var happy_icon: TextureRect
var stars_l: Label
var clock_l: Label
var missions_badge: Label
var build_badge: Label
var expansion_badge: Label
var toasts: VBoxContainer
var _last_face := ""
var _shown_money := -1.0
var day_night: DayNight


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_top()
	_build_bottom()
	toasts = UI.vbox(8)
	toasts.anchor_left = 0.5
	toasts.anchor_right = 0.5
	toasts.offset_left = -300
	toasts.offset_right = 300
	toasts.offset_top = 96
	toasts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toasts.grow_horizontal = Control.GROW_DIRECTION_BOTH
	add_child(toasts)
	GameManager.stats_tick.connect(update_stats)
	GameManager.toast.connect(show_toast)
	update_stats()


func _chip(parent: Control, icon_name: String, min_w: float, on_click: Callable) -> Array:
	var p := PanelContainer.new()
	var s := UI.style(Color(0.08, 0.11, 0.2, 0.55), 18, 2, Color(1, 1, 1, 0.12))
	s.content_margin_left = 10
	s.content_margin_right = 14
	s.content_margin_top = 4
	s.content_margin_bottom = 4
	p.add_theme_stylebox_override("panel", s)
	p.custom_minimum_size = Vector2(min_w, 0)
	p.mouse_filter = Control.MOUSE_FILTER_STOP
	p.gui_input.connect(func(ev):
		if ev is InputEventMouseButton and not ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			AudioManager.play("click")
			on_click.call())
	parent.add_child(p)
	var h := UI.hbox(8)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(h)
	var ic := UI.icon_rect(icon_name, 46)
	h.add_child(ic)
	var v := UI.vbox(-6)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	h.add_child(v)
	return [v, ic]


func _build_top() -> void:
	var bar := HBoxContainer.new()
	bar.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	bar.offset_left = 10
	bar.offset_right = -10
	bar.offset_top = 8
	bar.custom_minimum_size = Vector2(0, 68)
	bar.add_theme_constant_override("separation", 10)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bar)
	var m := _chip(bar, "coin", 300, func(): open_stats.emit(0))
	money_l = UI.outlined(UI.label("R$ 0", 32, Color.WHITE, true), 6)
	m[0].add_child(money_l)
	income_l = UI.outlined(UI.label("+R$ 0/s", 19, Color("9cf2b5"), true), 5)
	m[0].add_child(income_l)
	var p := _chip(bar, "people", 170, func(): open_stats.emit(1))
	pop_l = UI.outlined(UI.label("0", 28, Color.WHITE, true), 6)
	p[0].add_child(pop_l)
	pop_sub_l = UI.outlined(UI.label("/ 0", 16, Color("cfd8ff")), 4)
	p[0].add_child(pop_sub_l)
	var h := _chip(bar, "happy", 170, func(): open_stats.emit(2))
	happy_icon = h[1]
	happy_l = UI.outlined(UI.label("0%", 28, Color.WHITE, true), 6)
	h[0].add_child(happy_l)
	happy_sub_l = UI.outlined(UI.label("", 16, Color("cfd8ff")), 4)
	h[0].add_child(happy_sub_l)
	var st := _chip(bar, "star", 110, func(): open_prestige.emit())
	stars_l = UI.outlined(UI.label("0", 28, Color.WHITE, true), 6)
	st[0].add_child(stars_l)
	st[0].add_child(UI.outlined(UI.label("estrelas", 15, Color("ffe8a3")), 4))
	bar.add_child(UI.spacer())
	clock_l = UI.outlined(UI.label("08:00", 24, Color.WHITE, true), 6)
	clock_l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bar.add_child(clock_l)
	var gear := Button.new()
	gear.icon = UI.icon("settings")
	gear.expand_icon = true
	gear.custom_minimum_size = Vector2(64, 64)
	gear.focus_mode = Control.FOCUS_NONE
	UI.color_button(gear, Color(0.2, 0.25, 0.4, 0.9))
	gear.pressed.connect(func():
		AudioManager.play("click")
		open_settings.emit())
	bar.add_child(gear)


func _build_bottom() -> void:
	var bar := HBoxContainer.new()
	bar.anchor_left = 0.0
	bar.anchor_right = 1.0
	bar.anchor_top = 1.0
	bar.anchor_bottom = 1.0
	bar.offset_top = -92
	bar.offset_bottom = -8
	bar.alignment = BoxContainer.ALIGNMENT_CENTER
	bar.add_theme_constant_override("separation", 10)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bar)
	build_badge = _menu_button(bar, "Construir", "build", UI.C_GREEN, func(): open_build.emit())
	_menu_button(bar, "Melhorias", "upgrade", UI.C_BLUE, func(): open_upgrades.emit())
	missions_badge = _menu_button(bar, "Missões", "missions", UI.C_ORANGE, func(): open_missions.emit())
	expansion_badge = _menu_button(bar, "Expansão", "map", Color("16a596"), func(): open_expansion.emit())
	_menu_button(bar, "Prestígio", "star", UI.C_PURPLE, func(): open_prestige.emit())


func _menu_button(parent: Control, text: String, icon_name: String, col: Color, cb: Callable) -> Label:
	var b := UI.button(text, col, cb, 20, false, icon_name)
	b.custom_minimum_size = Vector2(158, 82)
	b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
	b.add_theme_constant_override("icon_max_width", 40)
	b.add_theme_constant_override("outline_size", 5)
	b.add_theme_color_override("font_outline_color", col.darkened(0.45))
	parent.add_child(b)
	var badge := UI.outlined(UI.label("!", 18, Color.WHITE, true, HORIZONTAL_ALIGNMENT_CENTER), 4, Color("8b1a12"))
	var bs := UI.style(UI.C_RED, 14, 2, Color.WHITE)
	bs.content_margin_left = 6
	bs.content_margin_right = 6
	bs.content_margin_top = 0
	bs.content_margin_bottom = 0
	badge.add_theme_stylebox_override("normal", bs)
	badge.position = Vector2(126, -8)
	badge.custom_minimum_size = Vector2(30, 28)
	badge.visible = false
	b.add_child(badge)
	return badge


func update_stats() -> void:
	var money := EconomySystem.money
	if _shown_money < 0.0 or absf(money - _shown_money) > money * 0.5 + 1.0:
		_shown_money = money
	else:
		_shown_money = lerpf(_shown_money, money, 0.5)
	money_l.text = Fmt.money(_shown_money)
	money_l.add_theme_color_override("font_color", Color("ff8a80") if EconomySystem.in_deficit else Color.WHITE)
	var net := EconomySystem.net_ps
	income_l.text = ("+" if net >= 0 else "") + Fmt.money_ps(net)
	income_l.add_theme_color_override("font_color", Color("9cf2b5") if net >= 0 else Color("ff8a80"))
	pop_l.text = Fmt.pop(PopulationSystem.population)
	pop_sub_l.text = "/ " + Fmt.pop(PopulationSystem.capacity) + " moradias"
	var hv := HappinessSystem.value
	happy_l.text = Fmt.percent(hv)
	happy_l.add_theme_color_override("font_color", HappinessSystem.color().lightened(0.35))
	happy_sub_l.text = HappinessSystem.label()
	var face := "happy" if hv >= 60 else ("neutral" if hv >= 35 else "sad")
	if face != _last_face:
		_last_face = face
		happy_icon.texture = UI.icon(face)
	stars_l.text = str(PrestigeSystem.stars)
	if day_night:
		clock_l.text = day_night.clock_text()
	var ready := MissionSystem.ready_count()
	missions_badge.visible = ready > 0
	missions_badge.text = str(ready)
	expansion_badge.visible = ExpansionSystem.can_unlock(ExpansionSystem.unlocked)
	build_badge.visible = BuildingSystem.free_lot_count() > 0 and _any_affordable()


func _any_affordable() -> bool:
	for d in GameData.BUILDINGS:
		if BuildingSystem.is_def_unlocked(d) and not (d.get("unique", false) and BuildingSystem.count_owned(d["id"]) > 0):
			if EconomySystem.can_afford(BuildingSystem.build_cost(d["id"])):
				return true
	return false


func show_toast(text: String, kind: String = "info") -> void:
	var col: Color = {"mission": UI.C_ORANGE, "achievement": UI.C_GOLD.darkened(0.15), "warning": UI.C_RED,
		"unlock": UI.C_GREEN, "info": UI.C_BLUE}.get(kind, UI.C_BLUE)
	var p := PanelContainer.new()
	var s := UI.style(col, 18, 3, col.darkened(0.4), 6)
	s.content_margin_left = 18
	s.content_margin_right = 18
	s.content_margin_top = 8
	s.content_margin_bottom = 10
	p.add_theme_stylebox_override("panel", s)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var h := UI.hbox(10)
	p.add_child(h)
	var icon: String = {"mission": "missions", "achievement": "trophy", "warning": "lock", "unlock": "map"}.get(kind, "check")
	h.add_child(UI.icon_rect(icon, 34))
	var l := UI.outlined(UI.label(text, 21, Color.WHITE, true), 4, col.darkened(0.5))
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(480, 0)
	h.add_child(l)
	toasts.add_child(p)
	while toasts.get_child_count() > 3:
		var old := toasts.get_child(0)
		toasts.remove_child(old)
		old.queue_free()
	p.modulate.a = 0.0
	var tw := p.create_tween()
	tw.tween_property(p, "modulate:a", 1.0, 0.2)
	tw.tween_interval(3.0)
	tw.tween_property(p, "modulate:a", 0.0, 0.4)
	tw.tween_callback(p.queue_free)
	if kind == "mission" or kind == "achievement":
		AudioManager.play("mission")
