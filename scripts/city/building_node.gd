class_name BuildingNode
extends Node2D
## Representação visual de um edifício construído, com luzes noturnas,
## sombra, obra animada (andaime, guindaste e progresso), animações de
## construção/melhoria e elementos animados (roda-gigante, turbina, fumaça).

var uid := 0
var id := ""
var level := 1
var w := 180.0
var h := 150.0
var lights: BuildingLights
var _extra: Spinner
var _scaffold: Scaffold
var constructing := false
## Direção da sombra (-1 = para a esquerda ao entardecer, +1 = para a direita de manhã)
## e intensidade (0 à noite). Atualizadas pelo CityView em passos discretos.
static var shadow_dir := 0.6
static var shadow_strength := 1.0


class Scaffold extends Node2D:
	var owner_node = null
	var progress := 0.0
	var left := 0.0
	var _acc := 0.0
	var _phase := 0.0

	func _process(delta: float) -> void:
		_phase += delta
		_acc += delta
		if _acc < 0.2:
			return
		_acc = 0.0
		var b := BuildingSystem.get_building(owner_node.uid)
		if b.is_empty():
			return
		progress = BuildingSystem.build_progress(b)
		left = float(b.get("build_left", 0.0))
		queue_redraw()

	func _draw() -> void:
		var w: float = owner_node.w
		var h: float = owner_node.h
		var out := BuildingArt.OUT
		var top := -h * (0.15 + 0.85 * progress)
		# rede de proteção e andaime
		draw_rect(Rect2(-w * 0.5, top, w, -top), Color(1.0, 0.55, 0.1, 0.22))
		var x := -w * 0.5
		while x <= w * 0.5 + 1:
			draw_line(Vector2(x, 0), Vector2(x, top), Color("8d6e63"), 3.0)
			x += w / 5.0
		var y := 0.0
		while y >= top:
			draw_line(Vector2(-w * 0.5, y), Vector2(w * 0.5, y), Color("a1887f"), 3.0)
			y -= 28.0
		# guindaste
		var mast := Vector2(w * 0.5 - 14, 0)
		var ch := maxf(h + 30.0, 140.0)
		draw_line(mast, mast - Vector2(0, ch), out, 6.0)
		draw_line(mast, mast - Vector2(0, ch), Color("ffb300"), 3.0)
		var arm := mast - Vector2(0, ch)
		var swing := sin(_phase * 0.6) * 10.0
		var tip := arm + Vector2(-w * 0.8, swing * 0.2)
		draw_line(arm + Vector2(30, 0), tip, out, 6.0)
		draw_line(arm + Vector2(30, 0), tip, Color("ffb300"), 3.0)
		var hook := Vector2(lerpf(tip.x, arm.x, 0.4) + swing, arm.y)
		draw_line(hook, hook + Vector2(0, 50), Color("455a64"), 2.0)
		draw_rect(Rect2(hook + Vector2(-14, 50), Vector2(28, 12)), Color("90a4ae"))
		# barra de progresso e tempo
		var bw := 140.0
		var bp := Vector2(-bw * 0.5, top - 46)
		draw_rect(Rect2(bp - Vector2(3, 3), Vector2(bw + 6, 30)), out)
		draw_rect(Rect2(bp, Vector2(bw, 24)), Color("eceff1"))
		draw_rect(Rect2(bp, Vector2(bw * progress, 24)), Color("ffb300"))
		var f := BuildingArt.font()
		draw_string(f, bp + Vector2(0, 18), "Obra: " + Fmt.short_duration(ceilf(left)), HORIZONTAL_ALIGNMENT_CENTER, bw, 15, out)


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
	set_constructing(not BuildingSystem.is_complete(b))


func refresh(new_level: int) -> void:
	level = new_level
	w = BuildingArt.width_of(id)
	h = BuildingArt.height_of(id, level)
	queue_redraw()
	lights.queue_redraw()


func set_constructing(on: bool) -> void:
	constructing = on
	self_modulate = Color(1, 1, 1, 0.38) if on else Color.WHITE
	lights.visible = not on
	if _extra:
		_extra.visible = not on
	if on and _scaffold == null:
		_scaffold = Scaffold.new()
		_scaffold.owner_node = self
		add_child(_scaffold)
	elif not on and _scaffold != null:
		_scaffold.queue_free()
		_scaffold = null
	queue_redraw()


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
			if SettingsManager.quality > 0:
				for cx in [62, 88]:
					var s := ChimneySmoke.new()
					s.position = Vector2(cx, -BuildingArt.height_of(id, 1) - 4)
					add_child(s)


func _draw() -> void:
	if SettingsManager.quality > 0 and not constructing and shadow_strength > 0.05:
		# sombra projetada na calçada e no gramado vizinho, seguindo o sol
		var d := shadow_dir
		var a := shadow_strength
		var dx := 26.0 * d
		draw_colored_polygon(PackedVector2Array([Vector2(-w * 0.5, 0), Vector2(w * 0.5, 0), Vector2(w * 0.5 + dx, 12), Vector2(-w * 0.5 + dx, 12)]), Color(0, 0, 0, 0.22 * a))
		var side := w * 0.5 * signf(d)
		var sh := minf(h * (0.3 + 0.35 * absf(d)), 110.0)
		var reach := (8.0 + 30.0 * absf(d)) * signf(d)
		if absf(d) > 0.1:
			draw_colored_polygon(PackedVector2Array([Vector2(side, 0), Vector2(side, -sh), Vector2(side + reach, -sh + 12), Vector2(side + reach, 0)]), Color(0, 0, 0, 0.16 * a))
	BuildingArt.draw(self, id, level, 0)
	if constructing:
		return
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
