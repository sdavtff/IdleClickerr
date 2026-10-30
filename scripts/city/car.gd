class_name Car
extends Node2D
## Veículo que circula pela rua. As rodas giram como nós filhos (sem redesenho)
## e os faróis ficam numa camada de luz noturna.

const TYPES := ["sedan", "hatch", "van", "taxi", "bus", "truck", "sport", "pickup"]
const COLORS := [Color("e53935"), Color("1e88e5"), Color("43a047"), Color("fdd835"), Color("8e24aa"), Color("fb8c00"), Color("eceff1"), Color("37474f"), Color("00acc1"), Color("d81b60")]

var kind := "sedan"
var color := Color.RED
var dir := 1.0
var speed := 120.0
var base_speed := 120.0
var length := 90.0
var lane := 0
var wheels: Array[Node2D] = []
var lights: Node2D


class Wheel extends Node2D:
	var r := 10.0
	func _draw() -> void:
		draw_circle(Vector2.ZERO, r + 2, BuildingArt.OUT)
		draw_circle(Vector2.ZERO, r, Color("263238"))
		draw_circle(Vector2.ZERO, r * 0.5, Color("b0bec5"))
		for i in 3:
			var a := i * TAU / 3.0
			draw_line(Vector2.ZERO, Vector2(cos(a), sin(a)) * r * 0.5, Color("546e7a"), 2.0)


class Headlights extends Node2D:
	var car = null
	func _draw() -> void:
		var l: float = car.length
		var front := Vector2(l * 0.5 - 4, -16)
		draw_colored_polygon(PackedVector2Array([front, front + Vector2(130, -14), front + Vector2(130, 22)]), Color(1, 0.95, 0.7, 0.22))
		draw_circle(front, 7, Color(1, 0.97, 0.8, 0.9))
		draw_circle(Vector2(-l * 0.5 + 4, -16), 6, Color(1, 0.2, 0.2, 0.85))


func randomize_car(rng: RandomNumberGenerator, p_lane: int, p_dir: float) -> void:
	lane = p_lane
	dir = p_dir
	var roll := rng.randf()
	if roll < 0.06:
		kind = "bus"
	elif roll < 0.12:
		kind = "truck"
	else:
		kind = TYPES[rng.randi() % TYPES.size()]
		if kind == "bus" or kind == "truck":
			kind = "sedan"
	color = COLORS[rng.randi() % COLORS.size()]
	if kind == "taxi":
		color = Color("ffca28")
	match kind:
		"bus":
			length = 160.0
			color = [Color("1e88e5"), Color("43a047"), Color("e53935")][rng.randi() % 3]
		"truck":
			length = 140.0
		"van":
			length = 104.0
		"sport":
			length = 92.0
		"hatch":
			length = 76.0
		"pickup":
			length = 100.0
		_:
			length = 90.0
	base_speed = rng.randf_range(95, 150) * (0.75 if kind in ["bus", "truck"] else 1.0)
	speed = base_speed
	scale = Vector2(dir, 1)
	_build_wheels()
	queue_redraw()
	if lights:
		lights.queue_redraw()


func _ready() -> void:
	lights = Headlights.new()
	lights.car = self
	lights.add_to_group("night_lights")
	add_child(lights)


func _build_wheels() -> void:
	for wh in wheels:
		wh.queue_free()
	wheels.clear()
	var r := 10.0 if kind not in ["bus", "truck"] else 12.0
	var xs := [-length * 0.32, length * 0.32]
	if kind == "truck":
		xs = [-length * 0.36, -length * 0.2, length * 0.34]
	for x in xs:
		var wh := Wheel.new()
		wh.r = r
		wh.position = Vector2(x, -r)
		add_child(wh)
		wheels.append(wh)


func advance(delta: float) -> void:
	position.x += dir * speed * delta
	var spin := speed * delta / 10.0
	for wh in wheels:
		wh.rotation += spin


func _draw() -> void:
	var l := length
	var out := BuildingArt.OUT
	var hl := l * 0.5
	match kind:
		"bus":
			_body([-hl, -10, -hl, -62, hl - 6, -62, hl, -54, hl, -10], color)
			for i in 6:
				_glass(Rect2(-hl + 10 + i * 24, -56, 18, 20))
			draw_rect(Rect2(-hl, -32, l, 5), Color(1, 1, 1, 0.8))
			_label("CIDADE", -hl, hl, -16, 12, Color.WHITE)
		"truck":
			_body([-hl, -12, -hl, -62, hl * 0.3, -62, hl * 0.3, -12], Color("eceff1"))
			_label("IDLE LOG", -hl, hl * 0.3, -32, 13, Color("ef6c00"))
			_body([hl * 0.34, -12, hl * 0.34, -46, hl * 0.78, -46, hl, -30, hl, -12], color)
			_glass(Rect2(hl * 0.6, -42, hl * 0.28, 12))
		"van":
			_body([-hl, -10, -hl, -52, hl * 0.45, -52, hl, -30, hl, -10], color)
			_glass(Rect2(hl * 0.2, -46, hl * 0.4, 14))
			_glass(Rect2(-hl + 10, -46, l * 0.3, 14))
		"sport":
			_body([-hl, -10, -hl, -24, -hl * 0.3, -32, hl * 0.25, -32, hl, -20, hl, -10], color)
			_glass(Rect2(-hl * 0.15, -29, hl * 0.4, 9))
		"pickup":
			_body([-hl, -10, -hl, -30, -hl * 0.05, -30, -hl * 0.05, -46, hl * 0.45, -46, hl * 0.7, -30, hl, -28, hl, -10], color)
			_glass(Rect2(hl * 0.05, -42, hl * 0.35, 11))
		_:
			var roof := -44.0 if kind != "hatch" else -46.0
			var back := -hl * 0.55 if kind != "hatch" else -hl * 0.85
			_body([-hl, -10, -hl, -26, back, -28, -hl * 0.3, roof, hl * 0.3, roof, hl * 0.55, -28, hl, -24, hl, -10], color)
			_glass(Rect2(-hl * 0.25, roof + 4, hl * 0.25, 11))
			_glass(Rect2(hl * 0.05, roof + 4, hl * 0.3, 11))
			if kind == "taxi":
				draw_rect(Rect2(-12, roof - 8, 24, 8), out)
				draw_rect(Rect2(-10, roof - 6, 20, 5), Color.WHITE)
				for i in 5:
					draw_rect(Rect2(-hl + 8 + i * 12, -22, 6, 5), Color("212121") if i % 2 == 0 else Color.WHITE)
	# farol e lanterna (dia)
	draw_rect(Rect2(hl - 6, -24, 5, 6), Color("fff59d"))
	draw_rect(Rect2(-hl + 1, -24, 5, 6), Color("e53935"))


## Texto sempre legível, mesmo com o veículo espelhado.
func _label(txt: String, x0: float, x1: float, y: float, size: int, col: Color) -> void:
	if dir < 0:
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(-1, 1))
		var t := x0
		x0 = -x1
		x1 = -t
	draw_string(BuildingArt.font(), Vector2(x0, y), txt, HORIZONTAL_ALIGNMENT_CENTER, x1 - x0, size, col)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _body(arr: Array, col: Color) -> void:
	var pts := BuildingArt.pv(arr)
	draw_colored_polygon(pts, col)
	var closed := pts.duplicate()
	closed.append(pts[0])
	draw_polyline(closed, BuildingArt.OUT, 3.0, true)
	draw_line(Vector2(arr[0] + 4, -14), Vector2(arr[arr.size() - 2] - 4, -14), col.darkened(0.25), 3.0)


func _glass(r: Rect2) -> void:
	draw_rect(r.grow(1.5), BuildingArt.OUT)
	draw_rect(r, Color("bfe6fa"))
	draw_rect(Rect2(r.position + Vector2(2, 2), Vector2(r.size.x * 0.3, r.size.y - 4)), Color(1, 1, 1, 0.6))
