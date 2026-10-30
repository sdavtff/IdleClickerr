extends Node
## Cena principal do jogo: monta a cidade, o HUD e os menus, liga os sinais
## e inicia a simulação (incluindo a recompensa offline).

var city: CityView
var hud: HUD
var ui_root: Control
var build_panel: BuildPanel
var upgrade_panel: UpgradePanel
var info_panel: BuildingInfoPanel
var missions_panel: MissionsPanel
var expansion_panel: ExpansionPanel
var prestige_panel: PrestigePanel
var settings_panel: SettingsPanel
var stats_panel: StatsPanel
var confirm: ConfirmDialog
var offline: OfflinePopup
var _refresh_acc := 0.0


func _ready() -> void:
	city = CityView.new()
	add_child(city)
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	ui_root = Control.new()
	ui_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_root.theme = UI.make_theme()
	layer.add_child(ui_root)
	hud = HUD.new()
	hud.day_night = city.day_night
	ui_root.add_child(hud)

	build_panel = _panel(BuildPanel.new())
	upgrade_panel = _panel(UpgradePanel.new())
	info_panel = _panel(BuildingInfoPanel.new())
	missions_panel = _panel(MissionsPanel.new())
	expansion_panel = _panel(ExpansionPanel.new())
	prestige_panel = _panel(PrestigePanel.new())
	settings_panel = _panel(SettingsPanel.new())
	stats_panel = _panel(StatsPanel.new())
	offline = _panel(OfflinePopup.new())
	confirm = _panel(ConfirmDialog.new())

	hud.open_build.connect(func(): build_panel.open_panel())
	hud.open_upgrades.connect(func(): upgrade_panel.open_panel())
	hud.open_missions.connect(func(): missions_panel.open_panel())
	hud.open_expansion.connect(func(): expansion_panel.open_panel())
	hud.open_prestige.connect(func(): prestige_panel.open_panel())
	hud.open_settings.connect(func(): settings_panel.open_panel())
	hud.open_stats.connect(func(tab):
		stats_panel.current_tab = tab
		stats_panel.open_panel()
		stats_panel._style_tabs())

	city.building_tapped.connect(func(uid): info_panel.show_building(uid))
	city.empty_lot_tapped.connect(func(_lot): build_panel.open_panel())
	city.locked_region_tapped.connect(func(_r): expansion_panel.open_panel())
	upgrade_panel.building_selected.connect(func(uid): info_panel.show_building(uid))
	expansion_panel.focus_region.connect(func(i): city.focus_x(GameData.region_start_x(i) + 600.0))
	info_panel.demolish_requested.connect(_ask_demolish)
	prestige_panel.prestige_requested.connect(_ask_prestige)
	settings_panel.menu_requested.connect(_go_menu)
	settings_panel.reset_requested.connect(_ask_reset)
	build_panel.built.connect(_on_built_from_menu)
	IdleSystem.offline_reward_ready.connect(func(report): offline.show_report(report))
	offline.collected.connect(func(amount):
		if amount > 0.0:
			city.effects.float_text(city.camera.position + Vector2(city.view_size().x * 0.5, 300), "+" + Fmt.money(amount), Color("ffe14d"), 40))
	BuildingSystem.building_built.connect(func(_b): _refresh_structure())
	BuildingSystem.building_removed.connect(func(_u): _refresh_structure())
	BuildingSystem.buildings_reset.connect(_refresh_structure)
	ExpansionSystem.region_unlocked.connect(func(_i): _refresh_structure())
	GameManager.city_reset.connect(_refresh_structure)

	GameManager.start_running()
	if not IdleSystem.pending.is_empty() and not offline.visible:
		offline.show_report(IdleSystem.pending)


func _panel(p):
	ui_root.add_child(p)
	return p


func _process(delta: float) -> void:
	_refresh_acc += delta
	if _refresh_acc < 0.25:
		return
	_refresh_acc = 0.0
	var top := UI.top_modal()
	if top != null and top.has_method("refresh"):
		top.refresh()


func _refresh_structure() -> void:
	if upgrade_panel.visible:
		upgrade_panel.rebuild()
	if build_panel.visible:
		build_panel.refresh()


func _on_built_from_menu(b: Dictionary) -> void:
	var def := GameData.get_def(b["id"])
	GameManager.toast.emit("Nova construção: %s (terreno %d)" % [def["name"], int(b["lot"]) + 1], "info")
	if BuildingSystem.free_lot_count() <= 0:
		build_panel.close_panel()


func _ask_demolish(uid: int) -> void:
	var b := BuildingSystem.get_building(uid)
	if b.is_empty():
		return
	var def := GameData.get_def(b["id"])
	var do_it := func():
		info_panel.close_panel()
		BuildingSystem.demolish(uid)
		AudioManager.play("build", 0.7)
	confirm.ask("Demolir edifício?", "%s (nível %d) será removido e o terreno ficará livre. Você recebe %s de volta (25%% do custo base). Os níveis serão perdidos." % [def["name"], int(b["level"]), Fmt.money(BuildingSystem.demolish_refund(b))], "Demolir", do_it)


func _ask_prestige() -> void:
	if not PrestigeSystem.can_prestige():
		AudioManager.play("error")
		return
	var gain := PrestigeSystem.stars_on_reset()
	var do_it := func():
		var g := GameManager.do_prestige()
		prestige_panel.close_panel()
		AudioManager.play("unlock")
		GameManager.toast.emit("Cidade renascida! +%d estrelas de prestígio." % g, "achievement")
	confirm.ask("Renascer a cidade?", "Você ganhará %d estrela%s de prestígio (+%d%% de renda permanente).\n\nSERÁ REINICIADO: dinheiro, edifícios, níveis, regiões, população e missões.\nSERÁ MANTIDO: estrelas, loja de legado, conquistas e estatísticas.\n\nEsta ação não pode ser desfeita." % [gain, "" if gain == 1 else "s", gain * 5], "Renascer", do_it, UI.C_ORANGE)


func _ask_reset() -> void:
	var do_it := func():
		GameManager.new_game()
		city._on_city_reset()
		settings_panel.close_panel()
		GameManager.toast.emit("Um novo começo!", "info")
	confirm.ask("Apagar todo o progresso?", "Isto apaga a cidade, o prestígio, as conquistas e as estatísticas. Não pode ser desfeito.", "Apagar tudo", do_it)


func _go_menu() -> void:
	GameManager.stop_running()
	UI.modal_stack.clear()
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		var top := UI.top_modal()
		if top != null:
			top.close_panel()
		else:
			settings_panel.open_panel()
