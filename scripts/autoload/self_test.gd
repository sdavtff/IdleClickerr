extends Node
## Autoteste para builds exportados (sem o editor). Executado apenas com o
## argumento "-- --selftest". Usa arquivos de save separados, então não toca
## no progresso do jogador. Imprime "SELFTEST OK" ou "SELFTEST FALHOU".

var _fails: Array = []


func _ready() -> void:
	if not "--selftest" in OS.get_cmdline_user_args():
		queue_free()
		return
	_run.call_deferred()


func _check(cond: bool, name: String) -> void:
	print("  %s %s" % ["ok  " if cond else "FAIL", name])
	if not cond:
		_fails.append(name)


func _run() -> void:
	print("SELFTEST Idle City %s" % ProjectSettings.get_setting("application/config/version"))
	SaveSystem.use_slot("selftest")
	SaveSystem.delete_all(true)
	GameManager.new_game()
	_check(BuildingSystem.buildings.size() == 3, "novo jogo cria a vila inicial")
	EconomySystem.add_money(50000.0, false)
	var b := BuildingSystem.build("loja_conveniencia")
	_check(not b.is_empty() and not BuildingSystem.is_complete(b), "construção iniciada com tempo de obra")
	for i in 600:
		GameManager.simulate(0.1)
	_check(BuildingSystem.is_complete(b), "obra concluída com o tempo")
	_check(EconomySystem.net_ps > 0.0, "cidade gera renda (%s)" % Fmt.money_ps(EconomySystem.net_ps))
	_check(GameManager.save_game(), "salvamento grava o arquivo")
	var money := EconomySystem.money
	var count := BuildingSystem.buildings.size()
	EconomySystem.money = 0.0
	_check(GameManager.continue_game() and absf(EconomySystem.money - money) < 0.01 and BuildingSystem.buildings.size() == count, "carregamento restaura o progresso")
	var report := IdleSystem.compute(7200.0)
	_check(float(report["money"]) > 0.0, "renda offline calculada (%s em 2h)" % Fmt.money(report["money"]))
	var game: Node = load("res://scenes/Game.tscn").instantiate()
	get_tree().root.add_child(game)
	for i in 90:
		await get_tree().process_frame
	_check(game.city.building_nodes.size() == BuildingSystem.buildings.size(), "cena do jogo carrega a cidade")
	var vp := get_viewport().get_texture()
	if vp and DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		var img := vp.get_image()
		if img:
			img.save_png("user://selftest.png")
			print("  captura: ", ProjectSettings.globalize_path("user://selftest.png"))
	GameManager.stop_running()
	SaveSystem.delete_all(true)
	print("SELFTEST %s" % ("OK" if _fails.is_empty() else "FALHOU: " + ", ".join(_fails)))
	get_tree().quit(0 if _fails.is_empty() else 1)
