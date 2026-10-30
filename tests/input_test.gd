extends Node
## Testa toques reais (eventos de mouse/toque) na cena do jogo.
## Uso: godot --path . res://tests/InputTest.tscn

var game: Node
var passed := 0
var failed := 0


func check(cond: bool, name: String) -> void:
	if cond:
		passed += 1
		print("  ok   ", name)
	else:
		failed += 1
		print("  FAIL ", name)


func frames(n := 3) -> void:
	for i in n:
		await get_tree().process_frame


func press(pos: Vector2) -> void:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = true
	e.position = pos
	e.global_position = pos
	Input.parse_input_event(e)
	await frames(2)


func release(pos: Vector2) -> void:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = false
	e.position = pos
	e.global_position = pos
	Input.parse_input_event(e)
	await frames(2)


func move(from: Vector2, to: Vector2, steps := 8) -> void:
	for i in steps:
		var e := InputEventMouseMotion.new()
		var p := from.lerp(to, float(i + 1) / steps)
		e.position = p
		e.global_position = p
		e.relative = (to - from) / steps
		e.button_mask = MOUSE_BUTTON_MASK_LEFT
		Input.parse_input_event(e)
		await frames(1)


func tap(pos: Vector2) -> void:
	await press(pos)
	await release(pos)


func center_of(c: Control) -> Vector2:
	return c.get_global_rect().get_center()


func _ready() -> void:
	print("=== Teste de toques ===")
	GameManager.new_game()
	game = load("res://scenes/Game.tscn").instantiate()
	add_child(game)
	await frames(20)
	var city: CityView = game.city
	# toque num edifício abre detalhes
	var n: BuildingNode = city.building_nodes.values()[0]
	var screen := n.position - city.camera.position + Vector2(0, -40)
	await tap(screen)
	check(game.info_panel.visible, "tocar num edifício abre os detalhes")
	await tap(Vector2(20, 400))
	check(not game.info_panel.visible, "tocar fora fecha a janela")
	# arrastar move a câmera (precisa de espaço para rolar)
	ExpansionSystem.unlocked = 3
	ExpansionSystem.region_unlocked.emit(2)
	await frames(60)
	city.cam_x = 0.0
	city.cam_target = -1.0
	city._apply_camera()
	var before := city.cam_x
	await press(Vector2(900, 300))
	await move(Vector2(900, 300), Vector2(300, 300))
	await release(Vector2(300, 300))
	check(city.cam_x > before + 300.0, "arrastar rola a cidade (%d px)" % int(city.cam_x - before))
	city.cam_x = 0.0
	city._apply_camera()
	await frames(5)
	# botão Construir da barra inferior
	var build_btn: Button = null
	for b in game.hud.find_children("*", "Button", true, false):
		if b.text == "Construir":
			build_btn = b
	await tap(center_of(build_btn))
	check(game.build_panel.visible, "botão Construir abre o menu")
	EconomySystem.money = 100000.0
	await frames(15)
	var count := BuildingSystem.buildings.size()
	var buy: Button = game.build_panel._rows[0]["button"]
	# arrastar a lista começando no botão não deve comprar
	var p := center_of(buy)
	await press(p)
	await move(p, p + Vector2(0, -150))
	await release(p + Vector2(0, -150))
	await frames(5)
	check(BuildingSystem.buildings.size() == count, "arrastar a lista não compra por engano")
	game.build_panel.list.scroll_to_top()
	await frames(5)
	await tap(center_of(buy))
	check(BuildingSystem.buildings.size() == count + 1, "tocar em Construir constrói")
	game.build_panel.close_panel()
	await frames(5)
	print("=== %d passaram, %d falharam ===" % [passed, failed])
	SaveSystem.delete_all()
	get_tree().quit(1 if failed > 0 else 0)
