class_name RainLayer
extends Node2D
## Chuva em espaço de tela (clima dinâmico opcional).

var intensity := 0.0
## Clarão de raio (1 = máximo), decai sozinho.
var flash := 0.0
var drops: Array = []
const MAX_DROPS := 110


func _process(delta: float) -> void:
	var sz := get_viewport_rect().size
	var wanted := int([40, 80, MAX_DROPS][SettingsManager.quality] * intensity)
	while drops.size() < wanted:
		drops.append(Vector3(randf() * sz.x, randf() * sz.y, randf_range(700, 950)))
	while drops.size() > wanted:
		drops.pop_back()
	for i in drops.size():
		var d: Vector3 = drops[i]
		d.y += d.z * delta
		d.x -= d.z * 0.18 * delta
		if d.y > sz.y:
			d.y = randf_range(-40, 0)
			d.x = randf() * (sz.x + 100)
		drops[i] = d
	flash = maxf(0.0, flash - delta * 2.5)
	visible = intensity > 0.01 or flash > 0.0
	if visible:
		queue_redraw()


func _draw() -> void:
	if flash > 0.0:
		draw_rect(Rect2(Vector2.ZERO, get_viewport_rect().size), Color(1, 1, 1, flash * 0.55))
	var c := Color(0.8, 0.88, 1.0, 0.45 * clampf(intensity * 1.5, 0, 1))
	for d in drops:
		draw_line(Vector2(d.x, d.y), Vector2(d.x + 4, d.y - 18), c, 1.5)
