class_name ChimneySmoke
extends Node2D
## Fumaça leve saindo de chaminés (partículas desenhadas manualmente).

var puffs: Array = []
var _spawn := 0.0


func _process(delta: float) -> void:
	var sx := get_global_transform_with_canvas().origin.x
	if sx < -150 or sx > get_viewport_rect().size.x + 150:
		return
	_spawn -= delta
	if _spawn <= 0.0 and puffs.size() < 7:
		_spawn = randf_range(0.45, 0.8)
		puffs.append({"p": Vector2(randf_range(-3, 3), 0), "life": 0.0, "max": randf_range(2.6, 3.6), "r": randf_range(7, 10)})
	for p in puffs:
		p["life"] += delta
		p["p"] += Vector2(10 + p["life"] * 5, -22) * delta
	puffs = puffs.filter(func(p): return p["life"] < p["max"])
	queue_redraw()


func _draw() -> void:
	for p in puffs:
		var k: float = p["life"] / p["max"]
		var r: float = p["r"] * (1.0 + k * 1.6)
		draw_circle(p["p"], r, Color(0.86, 0.86, 0.88, 0.7 * (1.0 - k)))
