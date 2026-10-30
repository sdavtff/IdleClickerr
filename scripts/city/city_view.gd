class_name CityView
extends Node2D
## Cidade em visão lateral com rolagem horizontal: céu, paralaxe, ruas,
## edifícios, carros, moradores, ciclo dia/noite, clima e toques.

signal building_tapped(uid: int)
signal empty_lot_tapped(lot: int)
signal locked_region_tapped(region: int)
signal bubble_collected(amount: float)

const TAP_SLOP := 14.0
const PREVIEW_LOCKED := 720.0

var day_night := DayNight.new()
var camera: Camera2D
var world: Node2D
var sky: SkyView
var rain: RainLayer
var far_layer: CityBackdrop
var mid_layers: Array[CityBackdrop] = []
var lots: LotMarkers
var buildings_root: Node2D
var peds_root: Node2D
var cars_root_far: Node2D
var cars_root_near: Node2D
var effects: CityEffects
var building_nodes := {}

var cam_x := 0.0
var cam_target := -1.0
var velocity := 0.0
var _dragging := false
var _press_pos := Vector2.ZERO
var _last_pos := Vector2.ZERO
var _moved := 0.0
var _drag_samples: Array = []

var _rng := RandomNumberGenerator.new()
var _peds: Array[Pedestrian] = []
var _cars: Array[Car] = []
var _bubble_timer := 6.0
var _floater_timer := 1.0
var _weather_timer := 150.0
var _rain_left := 0.0
var _rain_level := 0.0
var _last_tint := Color(0, 0, 0, 0)
var _tint_acc := 0.0
var _lanes: Array = [[], []]
var traffic: TrafficLights
var _confetti_acc := 0.0
var _lightning_acc := 4.0
var _last_night := -1.0


func _ready() -> void:
	_rng.randomize()
	day_night.enabled = SettingsManager.day_night
	if not day_night.enabled:
		day_night.t = 0.45
	_build_layers()
	_rebuild_buildings()
	_spawn_life()
	BuildingSystem.building_built.connect(_on_built)
	BuildingSystem.building_upgraded.connect(_on_upgraded)
	BuildingSystem.building_removed.connect(_on_removed)
	BuildingSystem.buildings_reset.connect(_rebuild_buildings)
	ExpansionSystem.region_unlocked.connect(_on_region_unlocked)
	BuildingSystem.building_completed.connect(_on_completed)
	SettingsManager.changed.connect(_on_settings)
	GameManager.city_reset.connect(_on_city_reset)
	cam_x = 0.0
	_apply_camera()


# --- Construção das camadas -------------------------------------------------------

func _build_layers() -> void:
	var sky_layer := CanvasLayer.new()
	sky_layer.layer = -10
	add_child(sky_layer)
	sky = SkyView.new()
	sky.day_night = day_night
	sky_layer.add_child(sky)

	world = Node2D.new()
	world.name = "World"
	add_child(world)

	var ww := GameData.world_width()
	far_layer = CityBackdrop.new()
	world.add_child(far_layer)
	far_layer.setup("far", 0.8, 0, -400.0, ww * 0.2 + 2600.0)

	for r in GameData.region_count():
		var from := GameData.region_start_x(r) * 0.6 - (900.0 if r == 0 else 0.0)
		var to := GameData.region_end_x(r) * 0.6 + (2400.0 if r == GameData.region_count() - 1 else 0.0)
		for lights in [false, true]:
			var mid := CityBackdrop.new()
			world.add_child(mid)
			mid.setup("mid", 0.4, r, from, to, lights)
			if lights:
				mid.add_to_group("night_lights")
			mid_layers.append(mid)

	for r in GameData.region_count():
		var g := CityGround.new()
		world.add_child(g)
		var from := GameData.region_start_x(r) - (1200.0 if r == 0 else 0.0)
		var to := GameData.region_end_x(r) + (1600.0 if r == GameData.region_count() - 1 else 0.0)
		g.setup(r, from, to)

	lots = LotMarkers.new()
	world.add_child(lots)

	buildings_root = Node2D.new()
	world.add_child(buildings_root)
	peds_root = Node2D.new()
	world.add_child(peds_root)

	for r in GameData.region_count():
		for lights in [false, true]:
			var lamps := StreetLamps.new()
			world.add_child(lamps)
			lamps.setup(GameData.region_start_x(r), GameData.region_end_x(r) - 1.0, lights)

	traffic = TrafficLights.new()
	world.add_child(traffic)
	cars_root_far = Node2D.new()
	world.add_child(cars_root_far)
	cars_root_near = Node2D.new()
	world.add_child(cars_root_near)

	effects = CityEffects.new()
	world.add_child(effects)

	var rain_layer := CanvasLayer.new()
	rain_layer.layer = 5
	add_child(rain_layer)
	rain = RainLayer.new()
	rain_layer.add_child(rain)

	camera = Camera2D.new()
	camera.anchor_mode = Camera2D.ANCHOR_MODE_FIXED_TOP_LEFT
	add_child(camera)
	camera.make_current()


func _rebuild_buildings() -> void:
	for n in building_nodes.values():
		n.queue_free()
	building_nodes.clear()
	for b in BuildingSystem.buildings:
		_add_building_node(b)
	lots.refresh()


func _add_building_node(b: Dictionary) -> BuildingNode:
	var n := BuildingNode.new()
	buildings_root.add_child(n)
	n.setup(b)
	building_nodes[int(b["uid"])] = n
	return n


func _spawn_life() -> void:
	for p in _peds:
		p.queue_free()
	for c in _cars:
		c.queue_free()
	_peds.clear()
	_cars.clear()
	_lanes = [[], []]
	var ped_count := SettingsManager.pedestrian_count()
	var cars_per_lane := SettingsManager.cars_per_lane()
	var vw := view_size().x
	for i in ped_count:
		var p := Pedestrian.new()
		peds_root.add_child(p)
		p.randomize_look(_rng)
		p.position = Vector2(cam_x + _rng.randf_range(0, vw), _ped_y())
		_peds.append(p)
	for lane in 2:
		for i in cars_per_lane:
			var c := Car.new()
			(cars_root_far if lane == 0 else cars_root_near).add_child(c)
			c.randomize_car(_rng, lane, -1.0 if lane == 0 else 1.0)
			c.position = Vector2(cam_x + (i + _rng.randf()) * (vw + 600) / cars_per_lane - 300, _lane_y(lane))
			_cars.append(c)
			_lanes[lane].append(c)


func _ped_y() -> float:
	return GameData.GROUND_Y + _rng.randf_range(10, 24)


func _lane_y(lane: int) -> float:
	return (GameData.LANE_FAR_Y if lane == 0 else GameData.LANE_NEAR_Y) + 14.0


# --- Câmera ---------------------------------------------------------------------

func view_size() -> Vector2:
	return get_viewport_rect().size


func max_cam_x() -> float:
	var end := GameData.region_end_x(ExpansionSystem.unlocked - 1)
	end += PREVIEW_LOCKED if ExpansionSystem.next_region() >= 0 else GameData.WORLD_MARGIN
	return maxf(0.0, end - view_size().x)


func _apply_camera() -> void:
	cam_x = clampf(cam_x, 0.0, max_cam_x())
	var vs := view_size()
	camera.position = Vector2(cam_x, 720.0 - vs.y)
	far_layer.update_camera(cam_x)
	for m in mid_layers:
		m.update_camera(cam_x)
	sky.camera_x = cam_x


func focus_x(world_x: float) -> void:
	cam_target = clampf(world_x - view_size().x * 0.5, 0.0, max_cam_x())
	velocity = 0.0


func focus_lot(lot: int) -> void:
	focus_x(GameData.lot_center_x(lot))


func is_x_visible(x: float, margin := 0.0) -> bool:
	return x > cam_x - margin and x < cam_x + view_size().x + margin


# --- Entrada --------------------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			_dragging = true
			_press_pos = mb.position
			_last_pos = mb.position
			_moved = 0.0
			velocity = 0.0
			cam_target = -1.0
			_drag_samples.clear()
		elif mb.pressed and (mb.button_index == MOUSE_BUTTON_WHEEL_UP or mb.button_index == MOUSE_BUTTON_WHEEL_LEFT):
			cam_target = -1.0
			velocity = -900.0
		elif mb.pressed and (mb.button_index == MOUSE_BUTTON_WHEEL_DOWN or mb.button_index == MOUSE_BUTTON_WHEEL_RIGHT):
			cam_target = -1.0
			velocity = 900.0


func _input(event: InputEvent) -> void:
	if not _dragging:
		return
	if event is InputEventMouseMotion:
		var mm := event as InputEventMouseMotion
		var dx := mm.position.x - _last_pos.x
		_last_pos = mm.position
		_moved += absf(dx) + absf(mm.relative.y) * 0.3
		if _moved > TAP_SLOP:
			cam_x -= dx
			_apply_camera()
		_drag_samples.append([Time.get_ticks_msec(), dx])
		if _drag_samples.size() > 6:
			_drag_samples.pop_front()
	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and not mb.pressed:
			_dragging = false
			if _moved <= TAP_SLOP:
				_tap(mb.position)
			else:
				var now := Time.get_ticks_msec()
				var sum := 0.0
				var oldest := now
				for s in _drag_samples:
					if now - int(s[0]) < 120:
						sum += float(s[1])
						oldest = mini(oldest, int(s[0]))
				var dt := maxf(16.0, float(now - oldest)) / 1000.0
				velocity = clampf(-sum / dt, -4000.0, 4000.0)


func _tap(screen_pos: Vector2) -> void:
	var wp := camera.position + screen_pos
	var bi := effects.bubble_at(wp)
	if bi >= 0:
		var b := effects.take_bubble(bi)
		var amount := float(b["v"])
		EconomySystem.add_money(amount, true)
		MissionSystem.on_bubble()
		effects.float_text(b["p"], "+" + Fmt.money(amount), Color("ffe14d"), 28)
		effects.sparkle(b["p"] + Vector2(0, 20), 40, 40)
		AudioManager.play("coin")
		bubble_collected.emit(amount)
		return
	for n in building_nodes.values():
		if n.hit_rect().has_point(wp):
			AudioManager.play("click")
			building_tapped.emit(n.uid)
			return
	if lots.locked_sign_rect().has_point(wp) or (ExpansionSystem.next_region() >= 0 and wp.x >= GameData.region_start_x(ExpansionSystem.next_region()) and wp.y < GameData.ROAD_Y0):
		AudioManager.play("click")
		locked_region_tapped.emit(ExpansionSystem.next_region())
		return
	if wp.y < GameData.ROAD_Y0 and wp.y > GameData.GROUND_Y - 160:
		var lot := int(floor((wp.x - GameData.WORLD_MARGIN) / GameData.LOT_W))
		if lot >= 0 and lot < BuildingSystem.unlocked_lots() and BuildingSystem.building_at_lot(lot).is_empty():
			AudioManager.play("click")
			empty_lot_tapped.emit(lot)


# --- Atualização -------------------------------------------------------------------

func _process(delta: float) -> void:
	if not _dragging:
		if cam_target >= 0.0:
			cam_x = lerpf(cam_x, cam_target, minf(1.0, delta * 5.0))
			if absf(cam_x - cam_target) < 1.0:
				cam_x = cam_target
				cam_target = -1.0
			_apply_camera()
		elif absf(velocity) > 5.0:
			cam_x += velocity * delta
			velocity *= pow(0.04, delta)
			var before := cam_x
			_apply_camera()
			if cam_x != before:
				velocity = 0.0
	day_night.advance(delta)
	_update_tint()
	_update_weather(delta)
	_update_peds(delta)
	_update_cars(delta)
	_update_bubbles(delta)


func _update_tint() -> void:
	_tint_acc += get_process_delta_time()
	if _tint_acc < 0.1:
		return
	_tint_acc = 0.0
	var tint := day_night.world_tint()
	var dark := _rain_level * 0.18
	tint = tint.darkened(dark)
	var night := clampf(day_night.night_factor() + _rain_level * 0.25, 0.0, 1.0)
	if tint.is_equal_approx(_last_tint) and absf(night - _last_night) < 0.002:
		return
	_last_tint = tint
	_last_night = night
	world.modulate = tint
	var inv := Color(1.0 / maxf(tint.r, 0.05), 1.0 / maxf(tint.g, 0.05), 1.0 / maxf(tint.b, 0.05), night)
	for n in get_tree().get_nodes_in_group("night_lights"):
		n.modulate = inv
		n.visible = night > 0.01


func _update_weather(delta: float) -> void:
	if SettingsManager.weather:
		if _rain_left > 0.0:
			_rain_left -= delta
		else:
			_weather_timer -= delta
			if _weather_timer <= 0.0:
				_weather_timer = _rng.randf_range(150, 330)
				_rain_left = _rng.randf_range(35, 75)
	else:
		_rain_left = 0.0
	var storm := EventSystem.active_id == "tempestade"
	if storm:
		_rain_left = maxf(_rain_left, 2.0)
		_lightning_acc -= delta
		if _lightning_acc <= 0.0:
			_lightning_acc = _rng.randf_range(4.0, 9.0)
			rain.flash = 1.0
			AudioManager.play("thunder", _rng.randf_range(0.8, 1.1))
	if EventSystem.active_id == "festival" and SettingsManager.quality > 0:
		_confetti_acc -= delta
		if _confetti_acc <= 0.0:
			_confetti_acc = 0.25
			effects.confetti(Vector2(cam_x + _rng.randf_range(0, view_size().x), camera.position.y + 90), 6)
	var target := 1.0 if _rain_left > 0.0 else 0.0
	_rain_level = move_toward(_rain_level, target, delta * 0.25)
	rain.intensity = _rain_level
	sky.overcast = _rain_level


func _visible_range() -> Vector2:
	var vw := view_size().x
	var unlocked_end := GameData.region_end_x(ExpansionSystem.unlocked - 1)
	return Vector2(maxf(cam_x - 60.0, 40.0), minf(cam_x + vw + 60.0, unlocked_end + 200.0))


func _update_peds(delta: float) -> void:
	var vw := view_size().x
	var rng_range := _visible_range()
	for p in _peds:
		p.step(delta)
		var x := p.position.x
		var far := x < cam_x - 250.0 or x > cam_x + vw + 250.0 or x > rng_range.y + 100.0 or x < 20.0
		if far:
			p.randomize_look(_rng)
			if x < cam_x - 2.0 * vw or x > cam_x + 3.0 * vw:
				p.position = Vector2(_rng.randf_range(rng_range.x, maxf(rng_range.x + 10.0, rng_range.y)), _ped_y())
			elif p.dir > 0:
				p.position = Vector2(maxf(cam_x - 60.0, 40.0), _ped_y())
			else:
				p.position = Vector2(minf(cam_x + vw + 60.0, rng_range.y), _ped_y())
			continue
		if p.can_enter():
			var lot := int(floor((x - GameData.WORLD_MARGIN) / GameData.LOT_W))
			var b := BuildingSystem.building_at_lot(lot)
			if not b.is_empty() and GameData.get_def(b["id"])["cat"] != "res":
				var cx := GameData.lot_center_x(lot)
				if absf(x - cx) < 3.0:
					if _rng.randf() < 0.4:
						p.enter_building(GameData.GROUND_Y + 8.0)
					else:
						p.cooldown = 2.0


func _update_cars(delta: float) -> void:
	var vw := view_size().x
	traffic.advance(delta)
	for lane in 2:
		var lane_cars: Array = _lanes[lane]
		var d := -1.0 if lane == 0 else 1.0
		# ordenação por inserção (poucos carros, sem alocação por quadro)
		for i in range(1, lane_cars.size()):
			var j := i
			while j > 0 and lane_cars[j - 1].position.x * d < lane_cars[j].position.x * d:
				var tmp = lane_cars[j - 1]
				lane_cars[j - 1] = lane_cars[j]
				lane_cars[j] = tmp
				j -= 1
		for i in lane_cars.size():
			var c: Car = lane_cars[i]
			var want := c.base_speed
			if i > 0:
				var ahead: Car = lane_cars[i - 1]
				var gap := absf(ahead.position.x - c.position.x) - (ahead.length + c.length) * 0.5
				if gap < 40.0:
					want = minf(want, ahead.speed * 0.9)
				if gap < 10.0:
					want = 0.0
			# semáforo: para antes da faixa de pedestres no vermelho/amarelo
			if not traffic.is_green():
				var front := c.position.x + d * c.length * 0.5
				var stop_x := traffic.next_stop_x(front, d)
				var dist := (stop_x - front) * d
				if dist >= 0.0 and dist < 90.0:
					want = 0.0 if dist < 70.0 else want * 0.4
			c.speed = move_toward(c.speed, want, 220.0 * delta)
			c.advance(delta)
			var out_ahead := (c.position.x > cam_x + vw + 400.0) if d > 0 else (c.position.x < cam_x - 400.0)
			var far_behind := (c.position.x < cam_x - 1600.0) if d > 0 else (c.position.x > cam_x + vw + 1600.0)
			if out_ahead or far_behind:
				var behind_edge := (cam_x - 200.0) if d > 0 else (cam_x + vw + 200.0)
				var last_x := behind_edge
				for o in lane_cars:
					if o != c:
						last_x = minf(last_x, o.position.x) if d > 0 else maxf(last_x, o.position.x)
				var spawn := minf(behind_edge, last_x - 180.0) if d > 0 else maxf(behind_edge, last_x + 180.0)
				c.randomize_car(_rng, lane, d)
				c.position = Vector2(spawn - d * _rng.randf_range(0, 400), _lane_y(lane))


func _update_bubbles(delta: float) -> void:
	_bubble_timer -= delta
	if _bubble_timer <= 0.0:
		_bubble_timer = _rng.randf_range(9.0, 17.0) * (0.45 if EventSystem.active_id in ["festival", "feira_tech"] else 1.0)
		if effects.bubbles.size() < 2:
			var candidates := []
			for n in building_nodes.values():
				if is_x_visible(n.position.x, -80.0):
					candidates.append(n)
			if not candidates.is_empty():
				var n: BuildingNode = candidates[_rng.randi() % candidates.size()]
				var value := maxf(25.0, EconomySystem.income_ps * 15.0)
				effects.add_bubble(n.position + Vector2(_rng.randf_range(-30, 30), -n.h - 50.0), value)
	if not SettingsManager.floating_text:
		return
	_floater_timer -= delta
	if _floater_timer <= 0.0:
		_floater_timer = 1.3
		var earning := []
		for n in building_nodes.values():
			if is_x_visible(n.position.x, -60.0):
				var b := BuildingSystem.get_building(n.uid)
				if not b.is_empty() and BuildingSystem.income_of(b) > 0.0:
					earning.append(b)
		if not earning.is_empty():
			var b: Dictionary = earning[_rng.randi() % earning.size()]
			var n: BuildingNode = building_nodes[int(b["uid"])]
			var amount := BuildingSystem.income_of(b) * EconomySystem.work_efficiency * EconomySystem.happiness_mult * EconomySystem.global_mult * 1.3
			effects.float_text(n.position + Vector2(0, -n.h - 14.0), "+" + Fmt.money(amount), Color("b9f6ca"), 18)


# --- Eventos dos sistemas -----------------------------------------------------------

func _on_built(b: Dictionary) -> void:
	var n := _add_building_node(b)
	effects.dust(n.position, n.w)
	lots.refresh()
	if not is_x_visible(n.position.x, -100.0):
		focus_x(n.position.x)


func _on_completed(b: Dictionary) -> void:
	var n: BuildingNode = building_nodes.get(int(b["uid"]))
	if n == null:
		return
	n.set_constructing(false)
	n.play_build_anim()
	effects.dust(n.position, n.w)
	effects.sparkle(n.position, n.w, n.h)
	if is_x_visible(n.position.x, 0.0):
		AudioManager.play("complete")


func _on_upgraded(b: Dictionary, _levels: int) -> void:
	var n: BuildingNode = building_nodes.get(int(b["uid"]))
	if n == null:
		return
	n.refresh(int(b["level"]))
	n.play_upgrade_anim()
	effects.sparkle(n.position, n.w, n.h)


func _on_removed(uid: int) -> void:
	var n: BuildingNode = building_nodes.get(uid)
	if n:
		building_nodes.erase(uid)
		effects.dust(n.position, n.w)
		n.play_remove_anim()
	lots.refresh()


func _on_region_unlocked(index: int) -> void:
	lots.refresh()
	focus_x(GameData.region_start_x(index) + 600.0)
	var center := GameData.region_start_x(index) + 600.0
	for i in 6:
		effects.firework(Vector2(center + _rng.randf_range(-500, 500), _rng.randf_range(120, 300)), i * 0.35)
	AudioManager.play("firework")


## Animação de dinheiro: moedas saltando a partir de um ponto da tela.
func coin_burst_screen(screen_pos: Vector2, count := 14) -> void:
	effects.coin_burst(camera.position + screen_pos, count)


func _on_city_reset() -> void:
	effects.clear_all()
	_rebuild_buildings()
	cam_x = 0.0
	cam_target = -1.0
	_apply_camera()


func _on_settings() -> void:
	day_night.enabled = SettingsManager.day_night
	if not day_night.enabled:
		day_night.t = 0.45
	if _peds.size() != SettingsManager.pedestrian_count() or _lanes[0].size() != SettingsManager.cars_per_lane():
		_spawn_life()
	for n in building_nodes.values():
		n.queue_redraw()
	_last_night = -1.0
