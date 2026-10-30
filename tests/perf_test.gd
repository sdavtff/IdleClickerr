extends Node
## Desempenho: compara quadros/s de uma cena vazia com a cidade cheia
## (80 edifícios, festival, carros e pedestres) em cada qualidade gráfica.
## Uso: godot --headless --path . res://tests/PerfTest.tscn

var game: Node


func fps_for(label: String) -> float:
	for f in 30:
		await get_tree().process_frame
	var best := 0.0
	for rep in 3:
		var t := Time.get_ticks_usec()
		var frames := 0
		while Time.get_ticks_usec() - t < 1000000:
			if game:
				game.city.cam_x = fposmod(game.city.cam_x + 12.0, GameData.world_width() - 2000.0)
				game.city._apply_camera()
			await get_tree().process_frame
			frames += 1
		best = maxf(best, frames)
	print("%s: %d quadros/s" % [label, best])
	return best


func _ready() -> void:
	Engine.max_fps = 0
	var base := await fps_for("cena vazia (referência)")
	BuildingSystem.instant_build = true
	GameManager.new_game()
	ExpansionSystem.unlocked = 8
	EconomySystem.money = 1e15
	var ids := GameData.BUILDINGS.map(func(d): return d["id"])
	var i := 0
	while BuildingSystem.free_lot() >= 0 and i < 400:
		BuildingSystem.build(ids[i % ids.size()])
		i += 1
	game = load("res://scenes/Game.tscn").instantiate()
	add_child(game)
	EventSystem.start("festival")
	for q in [2, 1, 0]:
		SettingsManager.quality = q
		SettingsManager.changed.emit()
		Engine.max_fps = 0
		var fps := await fps_for("cidade cheia, qualidade " + SettingsManager.QUALITY_NAMES[q])
		print("  custo extra por quadro: %.2f ms | nós: %d | memória: %.1f MB" % [maxf(0.0, 1000.0 / fps - 1000.0 / base),
			Performance.get_monitor(Performance.OBJECT_NODE_COUNT), Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0])
	SettingsManager.quality = 2
	SettingsManager.apply_fps()
	SaveSystem.delete_all()
	get_tree().quit()
