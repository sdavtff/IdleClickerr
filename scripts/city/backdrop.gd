class_name CityBackdrop
extends Node2D
## Camada de fundo com paralaxe. `kind` = "far" (colinas/montanhas) ou "mid"
## (silhuetas do bairro). As coordenadas locais são world_x * (1 - parallax),
## alinhando cada região do fundo com a região correspondente da cidade.

var kind := "far"
var parallax := 0.8
var region := -1
var x_from := 0.0
var x_to := 0.0
var lights_mode := false
var shapes: Array = []


func setup(p_kind: String, p_parallax: float, p_region: int, from_x: float, to_x: float, lights := false) -> void:
	kind = p_kind
	parallax = p_parallax
	region = p_region
	x_from = from_x
	x_to = to_x
	lights_mode = lights
	_generate()
	queue_redraw()


func update_camera(cam_x: float) -> void:
	position.x = cam_x * parallax


func _generate() -> void:
	shapes.clear()
	var rng := RandomNumberGenerator.new()
	rng.seed = 1000 + region * 97 + (0 if kind == "far" else 5)
	if kind == "far":
		var x := x_from
		while x < x_to:
			var w := rng.randf_range(260, 520)
			shapes.append({"x": x, "w": w, "h": rng.randf_range(90, 190), "type": "mountain" if rng.randf() < 0.35 else "hill"})
			x += w * rng.randf_range(0.45, 0.7)
		return
	var style: String = GameData.REGIONS[clampi(region, 0, GameData.region_count() - 1)]["backdrop"]
	var x2 := x_from
	while x2 < x_to:
		var s := {"x": x2}
		match style:
			"hills":
				s["type"] = "tree" if rng.randf() < 0.7 else "barn"
				s["w"] = rng.randf_range(40, 70)
				s["h"] = rng.randf_range(40, 70)
			"suburb":
				s["type"] = "house" if rng.randf() < 0.65 else "tree"
				s["w"] = rng.randf_range(50, 80)
				s["h"] = rng.randf_range(50, 80)
			"town":
				s["type"] = "block"
				s["w"] = rng.randf_range(50, 90)
				s["h"] = rng.randf_range(70, 150)
			"industry":
				s["type"] = "factory" if rng.randf() < 0.55 else "block"
				s["w"] = rng.randf_range(60, 110)
				s["h"] = rng.randf_range(60, 130)
			"city":
				s["type"] = "tower"
				s["w"] = rng.randf_range(45, 85)
				s["h"] = rng.randf_range(150, 260)
			"metro":
				s["type"] = "tower"
				s["w"] = rng.randf_range(45, 90)
				s["h"] = rng.randf_range(200, 330)
			_:
				s["type"] = "future"
				s["w"] = rng.randf_range(50, 90)
				s["h"] = rng.randf_range(220, 360)
		s["seed"] = rng.randi()
		shapes.append(s)
		x2 += s["w"] * rng.randf_range(0.75, 1.2)


func _draw() -> void:
	if kind == "far":
		_draw_far()
	else:
		_draw_mid()


func _draw_far() -> void:
	var base := 500.0
	for s in shapes:
		var x: float = s["x"]
		var w: float = s["w"]
		var h: float = s["h"]
		if s["type"] == "mountain":
			var col := Color(0.55, 0.66, 0.8)
			draw_colored_polygon(PackedVector2Array([Vector2(x, base), Vector2(x + w * 0.5, base - h - 40), Vector2(x + w, base)]), col)
			draw_colored_polygon(PackedVector2Array([Vector2(x + w * 0.5, base - h - 40), Vector2(x + w * 0.38, base - h + 4), Vector2(x + w * 0.46, base - h - 6), Vector2(x + w * 0.55, base - h + 6), Vector2(x + w * 0.62, base - h - 2)]), Color(0.94, 0.96, 1.0))
		else:
			var pts := PackedVector2Array()
			for i in 17:
				var k := i / 16.0
				pts.append(Vector2(x + k * w, base - sin(k * PI) * h))
			pts.append(Vector2(x + w, base + 40))
			pts.append(Vector2(x, base + 40))
			draw_colored_polygon(pts, Color(0.5, 0.72, 0.6))
	draw_rect(Rect2(x_from, base - 4, x_to - x_from, 60), Color(0.5, 0.72, 0.6))


func _draw_mid() -> void:
	var base := 505.0
	var col := Color(0.52, 0.64, 0.82)
	var win := Color(0.68, 0.78, 0.92)
	for s in shapes:
		var x: float = s["x"]
		var w: float = s["w"]
		var h: float = s["h"]
		var rng := RandomNumberGenerator.new()
		rng.seed = s["seed"]
		match s["type"]:
			"tree":
				if not lights_mode:
					draw_rect(Rect2(x + w * 0.45, base - h * 0.4, w * 0.1, h * 0.4), col.darkened(0.1))
					draw_circle(Vector2(x + w * 0.5, base - h * 0.6), w * 0.38, Color(0.45, 0.66, 0.6))
			"barn":
				if not lights_mode:
					draw_rect(Rect2(x, base - h * 0.6, w, h * 0.6), Color(0.7, 0.5, 0.52))
					draw_colored_polygon(PackedVector2Array([Vector2(x - 4, base - h * 0.6), Vector2(x + w * 0.5, base - h), Vector2(x + w + 4, base - h * 0.6)]), Color(0.6, 0.42, 0.45))
			"house":
				if not lights_mode:
					draw_rect(Rect2(x, base - h * 0.6, w, h * 0.6), col)
					draw_colored_polygon(PackedVector2Array([Vector2(x - 5, base - h * 0.6), Vector2(x + w * 0.5, base - h), Vector2(x + w + 5, base - h * 0.6)]), col.darkened(0.12))
				_windows(x + 6, base - h * 0.55, w - 12, h * 0.45, 8, 10, rng, win)
			"factory":
				if not lights_mode:
					draw_rect(Rect2(x, base - h * 0.55, w, h * 0.55), col)
					draw_rect(Rect2(x + w * 0.7, base - h, w * 0.12, h), col.darkened(0.08))
					for i in 3:
						draw_colored_polygon(PackedVector2Array([Vector2(x + i * w / 3.0, base - h * 0.55), Vector2(x + i * w / 3.0, base - h * 0.7), Vector2(x + (i + 1) * w / 3.0, base - h * 0.55)]), col.darkened(0.06))
				_windows(x + 6, base - h * 0.5, w - 12, h * 0.3, 8, 6, rng, win)
			"future":
				if not lights_mode:
					draw_colored_polygon(PackedVector2Array([Vector2(x, base), Vector2(x + w * 0.2, base - h), Vector2(x + w * 0.8, base - h), Vector2(x + w, base)]), col.lerp(Color(0.6, 0.55, 0.9), 0.4))
					draw_line(Vector2(x + w * 0.5, base - h), Vector2(x + w * 0.5, base - h - 40), col, 3.0)
				_windows(x + w * 0.25, base - h + 10, w * 0.5, h - 20, 7, 9, rng, Color(0.75, 0.75, 0.98))
			_:
				if not lights_mode:
					draw_rect(Rect2(x, base - h, w, h), col)
					draw_rect(Rect2(x + w * 0.75, base - h, w * 0.25, h), col.darkened(0.06))
					if s["type"] == "tower" and rng.randf() < 0.4:
						draw_line(Vector2(x + w * 0.5, base - h), Vector2(x + w * 0.5, base - h - 26), col, 2.0)
				_windows(x + 5, base - h + 8, w - 10, h - 14, 8, 10, rng, win)


func _windows(x: float, y: float, w: float, h: float, ww: float, wh: float, rng: RandomNumberGenerator, col: Color) -> void:
	var cols := int(w / (ww + 6))
	var rows := int(h / (wh + 8))
	for r in rows:
		for c in cols:
			var lit := rng.randf() < 0.45
			var p := Vector2(x + 3 + c * (ww + 6), y + 3 + r * (wh + 8))
			if lights_mode:
				if lit:
					draw_rect(Rect2(p, Vector2(ww, wh)), Color(1, 0.86, 0.5, 0.75))
			else:
				draw_rect(Rect2(p, Vector2(ww, wh)), col)
