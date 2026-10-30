class_name StreetLamps
extends Node2D
## Postes de iluminação na calçada de uma região. Com `lights_mode`, desenha
## apenas o brilho noturno (fica no grupo "night_lights").

var x0 := 0.0
var x1 := 0.0
var lights_mode := false


func setup(from_x: float, to_x: float, lights := false) -> void:
	x0 = from_x
	x1 = to_x
	lights_mode = lights
	if lights:
		add_to_group("night_lights")
	queue_redraw()


func _draw() -> void:
	var y := GameData.ROAD_Y0 - 3
	var x := ceilf((x0 - GameData.WORLD_MARGIN) / GameData.LOT_W) * GameData.LOT_W + GameData.WORLD_MARGIN
	while x <= x1:
		var top := Vector2(x + 18, y - 104)
		if lights_mode:
			draw_colored_polygon(PackedVector2Array([top + Vector2(-6, 6), top + Vector2(6, 6), top + Vector2(40, 104), top + Vector2(-40, 104)]), Color(1, 0.9, 0.55, 0.16))
			draw_circle(top + Vector2(0, 4), 22, Color(1, 0.88, 0.5, 0.35))
			draw_circle(top + Vector2(0, 4), 7, Color(1, 0.96, 0.75))
		else:
			draw_line(Vector2(x, y), Vector2(x, y - 108), BuildingArt.OUT, 6.0)
			draw_line(Vector2(x, y), Vector2(x, y - 108), Color("546e7a"), 3.0)
			draw_line(Vector2(x, y - 106), top + Vector2(0, -2), BuildingArt.OUT, 5.0)
			draw_line(Vector2(x, y - 106), top + Vector2(0, -2), Color("546e7a"), 2.5)
			draw_rect(Rect2(top.x - 10, top.y - 4, 20, 8), BuildingArt.OUT)
			draw_rect(Rect2(top.x - 6, top.y + 3, 12, 4), Color("fff59d"))
			draw_rect(Rect2(x - 5, y - 6, 10, 6), BuildingArt.OUT)
		x += GameData.LOT_W
