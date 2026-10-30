class_name CityGround
extends Node2D
## Chão de uma região: gramado, calçadas, rua com faixas, árvores de fundo e
## placa de boas-vindas. Um nó por região (permite descarte fora da tela).

var region := 0
var x0 := 0.0
var x1 := 0.0


func setup(p_region: int, from_x: float, to_x: float) -> void:
	region = p_region
	x0 = from_x
	x1 = to_x
	queue_redraw()


func _draw() -> void:
	var r: Dictionary = GameData.REGIONS[clampi(region, 0, GameData.region_count() - 1)]
	var grass: Color = r["grass"]
	var w := x1 - x0
	var gy := GameData.GROUND_Y
	# gramado atrás dos edifícios
	draw_rect(Rect2(x0, gy - 30, w, 30), grass)
	draw_rect(Rect2(x0, gy - 30, w, 4), grass.lightened(0.15))
	# árvores e arbustos entre os terrenos
	var rng := RandomNumberGenerator.new()
	rng.seed = 77 + region
	var lot_start := int((x0 - GameData.WORLD_MARGIN) / GameData.LOT_W)
	var lot_end := int(ceil((x1 - GameData.WORLD_MARGIN) / GameData.LOT_W))
	for lot in range(lot_start, lot_end + 1):
		var bx := GameData.WORLD_MARGIN + lot * GameData.LOT_W
		if bx < x0 - 1 or bx > x1 + 1:
			continue
		var s := rng.randf_range(0.8, 1.15)
		var tone := grass.darkened(rng.randf_range(0.15, 0.3))
		BuildingArt.tree(self, 0, bx, gy - 6, s, tone)
	# calçada
	draw_rect(Rect2(x0, gy, w, GameData.ROAD_Y0 - gy), Color("d9d4cb"))
	draw_rect(Rect2(x0, gy, w, 3), Color("ece8e0"))
	var tile := 40.0
	var tx := floorf(x0 / tile) * tile
	while tx < x1:
		draw_line(Vector2(tx, gy + 3), Vector2(tx, GameData.ROAD_Y0 - 4), Color("c4beb3"), 2.0)
		tx += tile
	draw_rect(Rect2(x0, GameData.ROAD_Y0 - 5, w, 5), Color("9e9a92"))
	# rua
	var ry0 := GameData.ROAD_Y0
	var ry1 := GameData.ROAD_Y1
	draw_rect(Rect2(x0, ry0, w, ry1 - ry0), Color("4a4f5c"))
	draw_rect(Rect2(x0, ry0, w, 4), Color("3d414c"))
	var mid := (ry0 + ry1) * 0.5
	var dx := floorf(x0 / 70.0) * 70.0
	while dx < x1:
		draw_rect(Rect2(dx, mid - 2, 38, 4), Color("f5d76e"))
		dx += 70.0
	draw_rect(Rect2(x0, ry0 + 6, w, 2), Color(1, 1, 1, 0.35))
	draw_rect(Rect2(x0, ry1 - 8, w, 2), Color(1, 1, 1, 0.35))
	# meio-fio e calçada da frente
	draw_rect(Rect2(x0, ry1, w, 5), Color("9e9a92"))
	draw_rect(Rect2(x0, ry1 + 5, w, 18), Color("d9d4cb"))
	draw_rect(Rect2(x0, ry1 + 23, w, 200), grass.darkened(0.05))
	# flores e cercas na frente
	var fx := x0 + rng.randf_range(10, 60)
	while fx < x1:
		if rng.randf() < 0.5:
			BuildingArt.bush(self, 0, fx, ry1 + 50, rng.randf_range(24, 46), grass.darkened(0.1), [Color("ff7eb3"), Color("ffeb3b"), Color("ffffff")][rng.randi() % 3])
		else:
			for i in 5:
				var px := fx + i * 10.0
				draw_rect(Rect2(px, ry1 + 30, 5, 22), Color("f5f0e6"))
			draw_rect(Rect2(fx - 2, ry1 + 36, 50, 4), Color("f5f0e6"))
		fx += rng.randf_range(90, 180)
	# placa da região
	if region > 0 or x0 > 0.0:
		var sx := GameData.region_start_x(region)
		if sx >= x0 and sx <= x1:
			_region_sign(sx, ry1 + 22, r["name"])


func _region_sign(x: float, y: float, title: String) -> void:
	var f := BuildingArt.font()
	var tw := f.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, 18).x + 26
	draw_line(Vector2(x, y), Vector2(x, y - 10), BuildingArt.OUT, 4.0)
	draw_rect(Rect2(x - tw * 0.5 - 3, y + 4, tw + 6, 34), BuildingArt.OUT)
	draw_rect(Rect2(x - tw * 0.5, y + 7, tw, 28), Color("2e7d4f"))
	draw_rect(Rect2(x - tw * 0.5 + 3, y + 10, tw - 6, 22), Color(0, 0, 0, 0), false, 1.5)
	draw_string(f, Vector2(x - tw * 0.5, y + 28), title, HORIZONTAL_ALIGNMENT_CENTER, tw, 18, Color.WHITE)
