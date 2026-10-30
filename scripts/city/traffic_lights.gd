class_name TrafficLights
extends Node2D
## Semáforos nas faixas de pedestres: ciclo verde → amarelo → vermelho.
## Os carros param antes da faixa quando não está verde.

const GREEN := 10.0
const YELLOW := 2.0
const RED := 5.0

var crossings: Array[float] = []
var phase := 0.0
var _state := -1


func _ready() -> void:
	for r in GameData.region_count():
		var x0 := GameData.region_start_x(r)
		if r > 0:
			crossings.append(x0)
		crossings.append(x0 + GameData.LOTS_PER_REGION * 0.5 * GameData.LOT_W)
	queue_redraw()


## 0 = verde, 1 = amarelo, 2 = vermelho (para os carros).
func state() -> int:
	if phase < GREEN:
		return 0
	if phase < GREEN + YELLOW:
		return 1
	return 2


func is_green() -> bool:
	return state() == 0


func advance(dt: float) -> void:
	phase = fposmod(phase + dt, GREEN + YELLOW + RED)
	var s := state()
	if s != _state:
		_state = s
		queue_redraw()


## Posição da linha de parada da próxima faixa à frente de `x` no sentido `d`.
func next_stop_x(x: float, d: float) -> float:
	var best := INF if d > 0 else -INF
	for cx in crossings:
		var stop := cx - d * 34.0
		if d > 0 and stop >= x - 1.0 and stop < best:
			best = stop
		elif d < 0 and stop <= x + 1.0 and stop > best:
			best = stop
	return best


func _draw() -> void:
	var cols := [Color("2ecc71"), Color("f1c40f"), Color("e74c3c")]
	var s := state()
	for cx in crossings:
		for side in [[GameData.ROAD_Y0 - 2, -40.0], [GameData.ROAD_Y1 + 20, 40.0]]:
			var base := Vector2(cx + side[1], side[0])
			draw_line(base, base - Vector2(0, 74), BuildingArt.OUT, 5.0)
			draw_line(base, base - Vector2(0, 74), Color("455a64"), 2.5)
			var box := Rect2(base + Vector2(-9, -106), Vector2(18, 40))
			draw_rect(box.grow(2), BuildingArt.OUT)
			draw_rect(box, Color("263238"))
			for i in 3:
				var on := (i == 0 and s == 2) or (i == 1 and s == 1) or (i == 2 and s == 0)
				var c: Color = cols[2 - i]
				draw_circle(box.position + Vector2(9, 7 + i * 13), 5, c if on else c.darkened(0.7))
				if on:
					draw_circle(box.position + Vector2(9, 7 + i * 13), 9, Color(c, 0.3))
