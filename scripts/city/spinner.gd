class_name Spinner
extends Node2D
## Elemento giratório: roda-gigante ou pás de turbina eólica.
## Só atualiza quando está visível na tela.

var kind := "ferris"
var angle := 0.0
const CABIN_COLORS := [Color("e53935"), Color("fdd835"), Color("43a047"), Color("1e88e5"), Color("8e24aa"), Color("fb8c00"), Color("00acc1"), Color("d81b60")]


func _process(delta: float) -> void:
	var sx := get_global_transform_with_canvas().origin.x
	if sx < -200 or sx > get_viewport_rect().size.x + 200:
		return
	angle += delta * (0.35 if kind == "ferris" else 2.4)
	queue_redraw()


func _draw() -> void:
	var out := BuildingArt.OUT
	if kind == "ferris":
		var r := 96.0
		draw_arc(Vector2.ZERO, r, 0, TAU, 48, out, 7.0)
		draw_arc(Vector2.ZERO, r, 0, TAU, 48, Color("eceff1"), 4.0)
		for i in 8:
			var a := angle + i * TAU / 8.0
			var p := Vector2(cos(a), sin(a)) * r
			draw_line(Vector2.ZERO, p, Color("b0bec5"), 2.0)
		for i in 8:
			var a := angle + i * TAU / 8.0
			var p := Vector2(cos(a), sin(a)) * r
			draw_rect(Rect2(p.x - 10, p.y + 2, 20, 16), out)
			draw_rect(Rect2(p.x - 8, p.y + 4, 16, 12), CABIN_COLORS[i])
			draw_rect(Rect2(p.x - 5, p.y + 6, 10, 5), Color("bbdefb"))
		draw_circle(Vector2.ZERO, 10, out)
		draw_circle(Vector2.ZERO, 7, Color("ffca28"))
	else:
		for i in 3:
			var a := angle + i * TAU / 3.0
			var d := Vector2(cos(a), sin(a))
			var n := Vector2(-d.y, d.x)
			var pts := PackedVector2Array([n * 4, d * 58 + n * 2, d * 60, d * 58 - n * 3, -n * 4])
			draw_colored_polygon(pts, Color("f5f5f5"))
			pts.append(pts[0])
			draw_polyline(pts, out, 2.0, true)
		draw_circle(Vector2.ZERO, 7, out)
		draw_circle(Vector2.ZERO, 5, Color("eceff1"))
