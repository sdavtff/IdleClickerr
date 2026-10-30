class_name CityEffects
extends Node2D
## Efeitos leves desenhados num único nó: textos flutuantes, poeira de obra,
## brilhos de melhoria e moedas bônus flutuantes.

var texts: Array = []
var particles: Array = []
var bubbles: Array = []
var _time := 0.0
var _had_content := false


func float_text(pos: Vector2, txt: String, col := Color("ffe14d"), size := 22) -> void:
	if texts.size() > 14:
		texts.pop_front()
	texts.append({"p": pos, "t": txt, "c": col, "s": size, "life": 0.0, "max": 1.4})


func dust(pos: Vector2, width: float) -> void:
	for i in 18:
		particles.append({"p": pos + Vector2(randf_range(-width * 0.5, width * 0.5), randf_range(-6, 0)),
			"v": Vector2(randf_range(-60, 60), randf_range(-70, -20)), "r": randf_range(6, 13),
			"c": Color(0.85, 0.78, 0.65, 0.85), "life": 0.0, "max": randf_range(0.6, 1.0), "g": 40.0})


func sparkle(pos: Vector2, width: float, height: float) -> void:
	for i in 16:
		particles.append({"p": pos + Vector2(randf_range(-width * 0.5, width * 0.5), randf_range(-height, 0)),
			"v": Vector2(randf_range(-20, 20), randf_range(-80, -30)), "r": randf_range(3, 6),
			"c": [Color("fff176"), Color("ffffff"), Color("80deea")][randi() % 3], "life": 0.0, "max": randf_range(0.6, 1.1), "g": -10.0, "star": true})


## Explosão de fogos de artifício (com atraso opcional, em segundos).
func firework(pos: Vector2, delay := 0.0) -> void:
	var col: Color = [Color("ff5252"), Color("ffd740"), Color("69f0ae"), Color("40c4ff"), Color("e040fb")][randi() % 5]
	for i in 26:
		var a := i * TAU / 26.0
		var sp := randf_range(150, 220)
		particles.append({"p": pos, "v": Vector2(cos(a), sin(a)) * sp, "r": randf_range(3, 5), "c": col,
			"life": -delay, "max": randf_range(0.9, 1.3), "g": 90.0, "star": true})


## Moedas saltando (animação de dinheiro).
func coin_burst(pos: Vector2, count := 14) -> void:
	for i in count:
		particles.append({"p": pos, "v": Vector2(randf_range(-160, 160), randf_range(-320, -160)), "r": 9.0,
			"c": Color("ffd23f"), "life": 0.0, "max": randf_range(0.9, 1.3), "g": 520.0, "coin": true})


func confetti(pos: Vector2, count := 6) -> void:
	for i in count:
		particles.append({"p": pos + Vector2(randf_range(-80, 80), 0), "v": Vector2(randf_range(-30, 30), randf_range(40, 90)),
			"r": randf_range(3, 5), "c": [Color("ff5252"), Color("ffd740"), Color("69f0ae"), Color("40c4ff"), Color("e040fb")][randi() % 5],
			"life": 0.0, "max": randf_range(2.5, 3.5), "g": 8.0, "confetti": true})


func add_bubble(pos: Vector2, value: float) -> void:
	bubbles.append({"p": pos, "v": value, "life": 0.0, "max": 14.0, "seed": randf() * TAU})


func bubble_at(world: Vector2) -> int:
	for i in bubbles.size():
		var b: Dictionary = bubbles[i]
		if (b["p"] + Vector2(0, _bob(b))).distance_to(world) < 42.0:
			return i
	return -1


func take_bubble(i: int) -> Dictionary:
	var b: Dictionary = bubbles[i]
	bubbles.remove_at(i)
	return b


func _bob(b: Dictionary) -> float:
	return sin(_time * 2.4 + b["seed"]) * 6.0


func clear_all() -> void:
	texts.clear()
	particles.clear()
	bubbles.clear()


func _process(delta: float) -> void:
	_time += delta
	for t in texts:
		t["life"] += delta
		t["p"] = t["p"] + Vector2(0, -40.0 * delta)
	texts = texts.filter(func(t): return t["life"] < t["max"])
	for p in particles:
		p["life"] += delta
		if p["life"] < 0.0:
			continue
		p["v"] = p["v"] + Vector2(0, p["g"] * delta)
		p["p"] = p["p"] + p["v"] * delta
	particles = particles.filter(func(p): return p["life"] < p["max"])
	for b in bubbles:
		b["life"] += delta
	bubbles = bubbles.filter(func(b): return b["life"] < b["max"])
	if not (texts.is_empty() and particles.is_empty() and bubbles.is_empty()) or _had_content:
		queue_redraw()
	_had_content = not (texts.is_empty() and particles.is_empty() and bubbles.is_empty())


func _draw() -> void:
	var f := BuildingArt.font()
	for p in particles:
		if p["life"] < 0.0:
			continue
		var k: float = p["life"] / p["max"]
		var c: Color = p["c"]
		c.a *= 1.0 - k
		if p.get("coin", false):
			var pos: Vector2 = p["p"]
			draw_circle(pos, 10, Color(BuildingArt.OUT, c.a))
			draw_circle(pos, 8, c)
			draw_circle(pos + Vector2(-2, -2), 3, Color(1, 1, 0.8, c.a))
		elif p.get("confetti", false):
			var pos2: Vector2 = p["p"]
			draw_rect(Rect2(pos2 + Vector2(sin(p["life"] * 9.0) * 3.0, 0), Vector2(p["r"], p["r"] * 0.6)), c)
		elif p.get("star", false):
			var r: float = p["r"] * (1.0 - k * 0.5)
			draw_line(p["p"] - Vector2(r, 0), p["p"] + Vector2(r, 0), c, 2.0)
			draw_line(p["p"] - Vector2(0, r), p["p"] + Vector2(0, r), c, 2.0)
		else:
			draw_circle(p["p"], p["r"] * (1.0 + k), c)
	for b in bubbles:
		var p: Vector2 = b["p"] + Vector2(0, _bob(b))
		var fade: float = clampf((b["max"] - b["life"]) / 1.0, 0.0, 1.0) * clampf(b["life"] / 0.3, 0.0, 1.0)
		var pulse := 1.0 + sin(_time * 5.0) * 0.06
		draw_circle(p, 34 * pulse, Color(1, 1, 1, 0.35 * fade))
		draw_circle(p, 26, Color(BuildingArt.OUT, fade))
		draw_circle(p, 23, Color(1.0, 0.8, 0.2, fade))
		draw_circle(p, 17, Color(1.0, 0.88, 0.4, fade))
		draw_string(f, p + Vector2(-20, 7), "R$", HORIZONTAL_ALIGNMENT_CENTER, 40, 18, Color(0.75, 0.48, 0.05, fade))
		draw_arc(p, 20, -2.6, -1.6, 8, Color(1, 1, 1, 0.8 * fade), 3.0)
	for t in texts:
		var k: float = t["life"] / t["max"]
		var a := 1.0 - maxf(0.0, (k - 0.6) / 0.4)
		var pos: Vector2 = t["p"]
		var size: int = t["s"]
		var w := f.get_string_size(t["t"], HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
		draw_string_outline(f, pos - Vector2(w * 0.5, 0), t["t"], HORIZONTAL_ALIGNMENT_LEFT, -1, size, 6, Color(0.15, 0.17, 0.27, a))
		draw_string(f, pos - Vector2(w * 0.5, 0), t["t"], HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color(t["c"], a))
