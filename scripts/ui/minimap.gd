class_name Minimap
extends Control
## Minimapa da cidade: regiões, edifícios e a área visível. Toque ou arraste
## para ir rapidamente a qualquer ponto da cidade.

signal jump(world_x: float)

var city: CityView
var _dragging := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP


func _x_to_world(x: float) -> float:
	return clampf(x / maxf(size.x, 1.0), 0.0, 1.0) * GameData.world_width()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_dragging = event.pressed
		if event.pressed:
			jump.emit(_x_to_world(event.position.x))
			accept_event()
	elif event is InputEventMouseMotion and _dragging:
		jump.emit(_x_to_world(event.position.x))
		accept_event()


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	draw_rect(r, Color(0.08, 0.11, 0.2, 0.7))
	var ww := GameData.world_width()
	var k := size.x / ww
	for i in GameData.region_count():
		var x0 := GameData.region_start_x(i) * k
		var x1 := GameData.region_end_x(i) * k
		var unlocked := i < ExpansionSystem.unlocked
		var col: Color = GameData.REGIONS[i]["grass"] if unlocked else Color(0.35, 0.38, 0.45)
		draw_rect(Rect2(x0 + 1, size.y - 10, x1 - x0 - 2, 7), col)
	for b in BuildingSystem.buildings:
		var x := GameData.lot_center_x(int(b["lot"])) * k
		var def := GameData.get_def(b["id"])
		var hgt := clampf(BuildingArt.height_of(b["id"], int(b["level"])) / 440.0, 0.15, 1.0) * (size.y - 14)
		var col: Color = GameData.CATEGORY_COLORS[def["cat"]]
		if not BuildingSystem.is_complete(b):
			col = col.darkened(0.4)
		draw_rect(Rect2(x - 1.5, size.y - 10 - hgt, 3, hgt), col)
	if city:
		var vx := city.cam_x * k
		var vw := city.view_size().x * k
		draw_rect(Rect2(vx, 1, vw, size.y - 2), Color(1, 1, 1, 0.9), false, 2.0)
	draw_rect(r, Color(1, 1, 1, 0.25), false, 1.5)
