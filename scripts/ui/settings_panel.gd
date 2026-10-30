class_name SettingsPanel
extends ModalPanel
## Configurações, estatísticas gerais e opções de salvamento.

signal menu_requested
signal reset_requested
signal restore_requested(slot: int)

const TOGGLES := [
	["music", "Música"], ["sfx", "Efeitos sonoros"], ["ambience", "Som ambiente da cidade"], ["day_night", "Ciclo de dia e noite"],
	["weather", "Clima dinâmico (chuva)"], ["battery_saver", "Economia de bateria (30 FPS)"],
	["floating_text", "Textos de renda flutuantes"], ["notifications", "Notificações na tela"],
]
var _quality_btn: Button
var _toggle_btns := {}
## No menu inicial, mostra apenas as opções (sem salvar/estatísticas).
var in_menu := false
var _save_l: Label


func _init() -> void:
	super()
	title = "Configurações"
	icon_name = "settings"
	desired_size = Vector2(980, 680)


func rebuild() -> void:
	UI.clear(list.content)
	_toggle_btns.clear()
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	grid.mouse_filter = Control.MOUSE_FILTER_PASS
	list.content.add_child(grid)
	for t in TOGGLES:
		var key: String = t[0]
		var b := UI.button("", UI.C_GREEN, func(): _toggle(key), 20)
		b.custom_minimum_size = Vector2(0, 62)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(b)
		_toggle_btns[key] = [b, t[1]]
	_quality_btn = UI.button("", UI.C_BLUE, _cycle_quality, 20)
	_quality_btn.custom_minimum_size = Vector2(0, 62)
	_quality_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_child(_quality_btn)
	for vol in [["music_volume", "Volume da música"], ["sfx_volume", "Volume dos efeitos"], ["ambience_volume", "Volume do ambiente"]]:
		var key: String = vol[0]
		var row := UI.hbox(12)
		list.content.add_child(row)
		var l := UI.label(vol[1], 20, UI.C_TEXT, true)
		l.custom_minimum_size = Vector2(240, 0)
		row.add_child(l)
		var sl := HSlider.new()
		sl.min_value = 0.0
		sl.max_value = 1.0
		sl.step = 0.05
		sl.value = float(SettingsManager.get(key))
		sl.custom_minimum_size = Vector2(0, 48)
		sl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		sl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		sl.add_theme_icon_override("grabber", UI.icon("coin"))
		sl.add_theme_icon_override("grabber_highlight", UI.icon("coin"))
		var track := UI.style(Color("c9cfdb"), 8)
		track.content_margin_top = 8
		track.content_margin_bottom = 8
		sl.add_theme_stylebox_override("slider", track)
		sl.add_theme_stylebox_override("grabber_area", UI.style(UI.C_GREEN, 8))
		sl.add_theme_stylebox_override("grabber_area_highlight", UI.style(UI.C_GREEN, 8))
		sl.value_changed.connect(func(v): SettingsManager.set_value(key, v))
		row.add_child(sl)
	if in_menu:
		refresh()
		return
	var row := UI.hbox(12)
	list.content.add_child(row)
	var save := UI.button("Salvar agora", UI.C_BLUE, _save_now, 20)
	save.custom_minimum_size = Vector2(0, 60)
	save.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(save)
	var menu := UI.button("Menu principal", UI.C_PURPLE, func(): menu_requested.emit(), 20)
	menu.custom_minimum_size = Vector2(0, 60)
	menu.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(menu)
	_save_l = UI.label("", 16, UI.C_MUTED)
	list.content.add_child(_save_l)
	var stats := UI.card()
	list.content.add_child(stats)
	var sv := UI.vbox(4)
	stats.add_child(sv)
	sv.add_child(UI.label("Estatísticas gerais", 22, UI.C_TEXT, true))
	var lt := MissionSystem.lifetime
	for line in [
		"Dinheiro ganho (total): " + Fmt.money(EconomySystem.lifetime_earned),
		"Dinheiro ganho nesta cidade: " + Fmt.money(EconomySystem.total_earned),
		"Edifícios construídos: %s" % Fmt.num(float(lt["built"])),
		"Melhorias feitas: %s" % Fmt.num(float(lt["upgrades"])),
		"Maior população: " + Fmt.pop(float(lt["max_pop"])),
		"Prestígios: %d   |   Estrelas: %d" % [PrestigeSystem.prestige_count, PrestigeSystem.stars_total],
		"Conquistas: %d / %d" % [MissionSystem.achievements.size(), GameData.ACHIEVEMENTS.size()],
	]:
		sv.add_child(UI.label(line, 18, UI.C_TEXT))
	var bk := UI.card(Color("eef3fb"))
	list.content.add_child(bk)
	var bv := UI.vbox(6)
	bk.add_child(bv)
	bv.add_child(UI.label("Cópias de segurança (recuperar progresso)", 21, UI.C_TEXT, true))
	var snaps := SaveSystem.list_snapshots()
	if snaps.is_empty():
		bv.add_child(UI.label("As cópias são criadas automaticamente a cada 5 minutos de jogo.", 16, UI.C_MUTED))
	for sn in snaps:
		var row2 := UI.hbox(10)
		bv.add_child(row2)
		var dt := Time.get_datetime_dict_from_unix_time(int(sn["time"]) + int(Time.get_time_zone_from_system()["bias"]) * 60)
		var l := UI.label("%02d/%02d %02d:%02d  —  %s, %d regiões" % [dt["day"], dt["month"], dt["hour"], dt["minute"], Fmt.money(sn["money"]), int(sn["regions"])], 18, UI.C_TEXT)
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row2.add_child(l)
		var slot: int = sn["slot"]
		var rb := UI.button("Restaurar", UI.C_ORANGE, func(): restore_requested.emit(slot), 17)
		rb.custom_minimum_size = Vector2(150, 48)
		row2.add_child(rb)
	var danger := UI.button("Apagar todo o progresso", UI.C_RED, func(): reset_requested.emit(), 18, true, "demolish")
	danger.custom_minimum_size = Vector2(0, 54)
	list.content.add_child(danger)
	var credits := UI.label("Idle City v%s — feito com Godot Engine. Fonte Fredoka (SIL OFL)." % ProjectSettings.get_setting("application/config/version", "1.0"), 15, UI.C_MUTED)
	list.content.add_child(credits)
	refresh()


func _cycle_quality() -> void:
	SettingsManager.set_value("quality", (SettingsManager.quality + 1) % 3)
	refresh()


func _toggle(key: String) -> void:
	SettingsManager.set_value(key, not bool(SettingsManager.get(key)))
	refresh()


func _save_now() -> void:
	if GameManager.save_game():
		GameManager.toast.emit("Jogo salvo!", "info")
	else:
		GameManager.toast.emit("Não foi possível salvar: " + SaveSystem.last_error, "warning")
	refresh()


func refresh() -> void:
	if not visible:
		return
	for key in _toggle_btns.keys():
		var b: Button = _toggle_btns[key][0]
		var on := bool(SettingsManager.get(key))
		b.text = "%s: %s" % [_toggle_btns[key][1], "LIGADO" if on else "DESLIGADO"]
		UI.color_button(b, UI.C_GREEN if on else UI.C_GREY)
	if _quality_btn:
		_quality_btn.text = "Qualidade gráfica: %s" % SettingsManager.QUALITY_NAMES[SettingsManager.quality].to_upper()
	if _save_l != null and SaveSystem.last_save_time > 0:
		var ago := Time.get_unix_time_from_system() - SaveSystem.last_save_time
		_save_l.text = "Salvamento automático a cada 15 segundos. Último: há %s." % Fmt.short_duration(ago)
