class_name LotMarkers
extends Node2D
## Terrenos vazios ("À venda") e a área bloqueada da próxima região.

func refresh() -> void:
	queue_redraw()


func _draw() -> void:
	var f := BuildingArt.font()
	var unlocked_lots := ExpansionSystem.unlocked * GameData.LOTS_PER_REGION
	for lot in unlocked_lots:
		if not BuildingSystem.building_at_lot(lot).is_empty():
			continue
		var cx := GameData.lot_center_x(lot)
		var gy := GameData.GROUND_Y
		draw_rect(Rect2(cx - 100, gy - 14, 200, 14), Color("b58b5e"))
		draw_rect(Rect2(cx - 100, gy - 14, 200, 3), Color("c9a074"))
		for i in 6:
			draw_circle(Vector2(cx - 80 + i * 32, gy - 8), 3, Color("8d6e4a"))
		# placa
		draw_line(Vector2(cx - 30, gy - 12), Vector2(cx - 30, gy - 56), BuildingArt.OUT, 4.0)
		draw_rect(Rect2(cx - 72, gy - 92, 84, 42), BuildingArt.OUT)
		draw_rect(Rect2(cx - 69, gy - 89, 78, 36), Color("fffdf5"))
		draw_string(f, Vector2(cx - 69, gy - 74), "TERRENO", HORIZONTAL_ALIGNMENT_CENTER, 78, 13, Color("2e7d32"))
		draw_string(f, Vector2(cx - 69, gy - 58), "Toque aqui", HORIZONTAL_ALIGNMENT_CENTER, 78, 12, Color("546e7a"))
		draw_circle(Vector2(cx + 40, gy - 30), 16, Color(1, 1, 1, 0.5))
		draw_string(f, Vector2(cx + 24, gy - 22), "+", HORIZONTAL_ALIGNMENT_CENTER, 32, 26, Color("2e7d32"))
	var next := ExpansionSystem.next_region()
	if next < 0:
		return
	var rx := GameData.region_start_x(next)
	var gy2 := GameData.GROUND_Y
	# cerca de obra
	var x := rx + 10.0
	while x < rx + GameData.LOTS_PER_REGION * GameData.LOT_W:
		draw_rect(Rect2(x, gy2 - 60, 8, 60), Color("8d6e63"))
		x += 48.0
	var end := rx + GameData.LOTS_PER_REGION * GameData.LOT_W
	for yy in [gy2 - 50, gy2 - 26]:
		draw_rect(Rect2(rx + 6, yy, end - rx - 12, 10), BuildingArt.OUT)
		var sx := rx + 8.0
		var i := 0
		while sx < end - 8:
			draw_rect(Rect2(sx, yy + 2, minf(24, end - 8 - sx), 6), Color("ffb300") if i % 2 == 0 else Color("37474f"))
			sx += 24.0
			i += 1
	# placa de bloqueio
	var cx := rx + 200.0
	draw_line(Vector2(cx, gy2), Vector2(cx, gy2 - 150), BuildingArt.OUT, 6.0)
	draw_rect(Rect2(cx - 150, gy2 - 290, 300, 150), BuildingArt.OUT)
	draw_rect(Rect2(cx - 145, gy2 - 285, 290, 140), Color("fff8e1"))
	draw_rect(Rect2(cx - 145, gy2 - 285, 290, 34), Color("ef6c00"))
	draw_string(f, Vector2(cx - 145, gy2 - 260), "EM BREVE", HORIZONTAL_ALIGNMENT_CENTER, 290, 20, Color.WHITE)
	var reg: Dictionary = GameData.REGIONS[next]
	draw_string(f, Vector2(cx - 145, gy2 - 222), reg["name"], HORIZONTAL_ALIGNMENT_CENTER, 290, 24, Color("37474f"))
	draw_string(f, Vector2(cx - 145, gy2 - 192), Fmt.money(float(reg["cost"])) + "  -  " + Fmt.pop(float(reg["pop"])) + " moradores", HORIZONTAL_ALIGNMENT_CENTER, 290, 15, Color("6d4c41"))
	draw_string(f, Vector2(cx - 145, gy2 - 162), "Toque para expandir", HORIZONTAL_ALIGNMENT_CENTER, 290, 15, Color("2e7d32"))


func locked_sign_rect() -> Rect2:
	var next := ExpansionSystem.next_region()
	if next < 0:
		return Rect2()
	var cx := GameData.region_start_x(next) + 200.0
	return Rect2(cx - 160, GameData.GROUND_Y - 300, 320, 300)
