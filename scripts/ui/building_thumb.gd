class_name BuildingThumb
extends Control
## Miniatura de um edifício (usa a mesma arte vetorial da cidade).

var building_id := ""
var level := 1
var locked := false
var bg := Color("d7ecfa")


func setup(id: String, lv := 1, is_locked := false, size_px := 110.0) -> BuildingThumb:
	building_id = id
	level = lv
	locked = is_locked
	custom_minimum_size = Vector2(size_px, size_px)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()
	return self


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	draw_rect(r, UI.OUTLINE)
	draw_rect(r.grow(-3), bg)
	draw_rect(Rect2(3, size.y * 0.78, size.x - 6, size.y * 0.22 - 3), Color("9ccc65"))
	if building_id == "":
		return
	var w := BuildingArt.width_of(building_id) + 30.0
	var h := BuildingArt.height_of(building_id, level) + 50.0
	var s := minf((size.x - 10.0) / w, (size.y * 0.8) / h)
	draw_set_transform(Vector2(size.x * 0.5, size.y * 0.84), 0.0, Vector2(s, s))
	BuildingArt.draw(self, building_id, level, 0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if locked:
		draw_rect(r.grow(-3), Color(0.15, 0.18, 0.28, 0.55))
		var ic := UI.icon("lock")
		var isz := size.x * 0.4
		draw_texture_rect(ic, Rect2((size - Vector2(isz, isz)) * 0.5, Vector2(isz, isz)), false)
