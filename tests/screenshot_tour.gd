extends Node
## Ferramenta de desenvolvimento: percorre o jogo real e salva capturas de tela.
## Uso: godot --path . res://tests/ScreenshotTour.tscn -- --out=/pasta

var out_dir := "user://"
var game: Node


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out_dir = a.substr(6)
	_run()


func shot(name: String, frames := 6) -> void:
	for i in frames:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out_dir.path_join(name + ".png"))
	print("shot ", name)


func _run() -> void:
	var menu: Node = load("res://scenes/MainMenu.tscn").instantiate()
	add_child(menu)
	await shot("01_menu", 60)
	menu.queue_free()
	UI.modal_stack.clear()
	GameManager.new_game()
	game = load("res://scenes/Game.tscn").instantiate()
	add_child(game)
	await shot("02_start", 30)
	# progresso acelerado
	EconomySystem.add_money(5e8, false)
	for id in ["casa_pequena", "casa_pequena", "parque", "escola", "loja_conveniencia"]:
		BuildingSystem.build(id)
	for i in 3:
		ExpansionSystem.unlocked = i + 2
		ExpansionSystem.region_unlocked.emit(i + 1)
	for id in ["casa_moderna", "restaurante", "hospital", "delegacia", "academia", "biblioteca", "casa_moderna", "apartamento", "supermercado", "escritorio", "bombeiros", "prefeitura", "cinema", "apartamento", "fabrica", "usina_solar", "shopping", "casa_luxo", "centro_distribuicao"]:
		BuildingSystem.build(id)
	var i := 0
	for b in BuildingSystem.buildings:
		BuildingSystem.upgrade(b["uid"], [4, 9, 24, 49, 2][i % 5])
		i += 1
	for t in 400:
		GameManager.simulate(0.5)
	game.city.cam_x = 0
	game.city._apply_camera()
	await shot("03_city_vila", 40)
	game.city.cam_x = GameData.region_start_x(2) - 200
	game.city._apply_camera()
	await shot("04_city_comercio", 20)
	game.city.cam_x = GameData.region_start_x(3) + 600
	game.city._apply_camera()
	await shot("05_city_locked", 20)
	game.city.cam_x = GameData.region_start_x(1)
	game.city._apply_camera()
	game.city.day_night.t = 0.8
	await shot("06_dusk", 20)
	game.city.day_night.t = 0.97
	await shot("07_night", 20)
	game.city.day_night.t = 0.45
	game.city._rain_left = 60
	game.city._rain_level = 1.0
	await shot("08_rain", 20)
	game.city._rain_left = 0
	game.city._rain_level = 0.0
	game.build_panel.open_panel()
	await shot("10_build", 20)
	game.build_panel.close_panel()
	game.upgrade_panel.open_panel()
	await shot("11_upgrades", 20)
	game.upgrade_panel.close_panel()
	game.info_panel.show_building(BuildingSystem.buildings[5]["uid"])
	await shot("12_info", 20)
	game.info_panel.close_panel()
	game.missions_panel.open_panel()
	await shot("13_missions", 20)
	game.missions_panel.select_tab(1)
	await shot("14_achievements", 20)
	game.missions_panel.close_panel()
	game.expansion_panel.open_panel()
	await shot("15_expansion", 20)
	game.expansion_panel.close_panel()
	game.prestige_panel.open_panel()
	await shot("16_prestige", 20)
	game.prestige_panel.close_panel()
	game.stats_panel.current_tab = 2
	game.stats_panel.open_panel()
	await shot("17_happiness", 20)
	game.stats_panel.close_panel()
	game.settings_panel.open_panel()
	await shot("18_settings", 20)
	game.settings_panel.close_panel()
	IdleSystem.last_active_time = Time.get_unix_time_from_system() - (8 * 3600 + 32 * 60)
	IdleSystem.process_absence(Time.get_unix_time_from_system())
	await shot("19_offline", 20)
	game.offline.close_panel()
	game._ask_prestige()
	await shot("20_confirm", 20)
	get_tree().quit()
