class_name BuildingNode
extends Node2D
## Representação visual de um edifício construído, com luzes noturnas,
## animações de construção/melhoria e elementos animados (roda-gigante,
## turbina eólica, fumaça).

var uid := 0
var id := ""
var level := 1
var w := 180.0
var h := 150.0
var lights: BuildingLights
var _extra: Spinner


func setup(b: Dictionary) -> void:
	uid = int(b["uid"])
	id = str(b["id"])
	position = Vector2(GameData.lot_center_x(int(b["lot"])), GameData.GROUND_Y)
	lights = BuildingLights.new()
	lights.owner_node = self
	lights.add_to_group("night_lights")
	add_child(lights)
	_add_extras()
	refresh(int(b["level"]))


func refresh(new_level: int) -> void:
	level = new_level
	w = BuildingArt.width_of(id)
	h = BuildingArt.height_of(id, level)
	queue_redraw()
	lights.queue_redraw()


func _add_extras() -> void:
	match id:
		"parque_diversoes":
			_extra = Spinner.new()
			_extra.kind = "ferris"
			_extra.position = Vector2(-40, -150)
			add_child(_extra)
		"usina_solar":
			_extra = Spinner.new()
			_extra.kind = "turbine"
			_extra.position = Vector2(61, -152)
			add_child(_extra)
		"fabrica":
			for cx in [62, 88]:
				var s := ChimneySmoke.new()
				s.position = Vector2(cx, -BuildingArt.height_of(id, 1) - 4)
				add_child(s)


func _draw() -> void:
	BuildingArt.draw(self, id, level, 0)
	# placa de nível
	var f := BuildingArt.font()
	var txt := "Nv %d" % level
	var tw := f.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x + 12
	var r := Rect2(-tw * 0.5, 6, tw, 18)
	var col: Color = GameData.CATEGORY_COLORS[GameData.get_def(id)["cat"]]
	draw_rect(r.grow(2), BuildingArt.OUT)
	draw_rect(r, col)
	draw_string(f, Vector2(r.position.x, r.position.y + 14), txt, HORIZONTAL_ALIGNMENT_CENTER, tw, 13, Color.WHITE)


func hit_rect() -> Rect2:
	return Rect2(position.x - w * 0.5, position.y - h - 20, w, h + 46)


func play_build_anim() -> void:
	scale = Vector2(0.6, 0.02)
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector2(1, 1), 0.55).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func play_upgrade_anim() -> void:
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector2(1.06, 1.08), 0.1)
	tw.tween_property(self, "scale", Vector2(1, 1), 0.25).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


func play_remove_anim() -> void:
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector2(1.1, 0.0), 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tw.tween_callback(queue_free)
