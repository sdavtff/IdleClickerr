class_name SkyView
extends Control
## Céu em tela cheia (atrás da cidade): degradê, sol, lua, estrelas e nuvens.

var day_night: DayNight
var camera_x := 0.0
var overcast := 0.0
var _stars: Array = []
var _clouds: Array = []
var _time := 0.0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	for i in 70:
		_stars.append(Vector3(rng.randf(), rng.randf() * 0.6, rng.randf_range(0.8, 2.2)))
	for i in 7:
		_clouds.append({"x": rng.randf_range(0, 2400), "y": rng.randf_range(60, 300), "s": rng.randf_range(0.6, 1.3), "v": rng.randf_range(6, 16)})


func _process(delta: float) -> void:
	var vs := get_viewport_rect().size
	if size != vs:
		position = Vector2.ZERO
		size = vs
	_time += delta
	for c in _clouds:
		c["x"] += c["v"] * delta
	queue_redraw()


func _draw() -> void:
	if day_night == null:
		return
	var sz := size
	var cols := day_night.sky_colors()
	var top: Color = cols[0]
	var bot: Color = cols[1]
	var grey := Color(0.55, 0.6, 0.68)
	top = top.lerp(grey * Color(top.v + 0.3, top.v + 0.3, top.v + 0.3), overcast * 0.6)
	bot = bot.lerp(grey * Color(bot.v + 0.2, bot.v + 0.2, bot.v + 0.2), overcast * 0.6)
	draw_polygon(PackedVector2Array([Vector2.ZERO, Vector2(sz.x, 0), sz, Vector2(0, sz.y)]),
		PackedColorArray([top, top, bot, bot]))
	var night := day_night.night_factor()
	# estrelas
	if night > 0.05:
		for s in _stars:
			var tw := 0.6 + 0.4 * sin(_time * 2.0 + s.x * 40.0)
			draw_circle(Vector2(s.x * sz.x, s.y * sz.y), s.z, Color(1, 1, 0.9, night * tw * (1.0 - overcast)))
	# sol e lua seguem um arco
	var e := day_night.elevation()
	var sun_k := fposmod(day_night.t - 0.25, 1.0) / 0.5
	if e > -0.2:
		var p := Vector2(lerpf(sz.x * 0.08, sz.x * 0.92, clampf(sun_k, 0, 1)), sz.y * 0.75 - e * sz.y * 0.6)
		draw_circle(p, 70, Color(1, 0.9, 0.5, 0.15 * (1.0 - overcast)))
		draw_circle(p, 46, Color(1, 0.92, 0.55, 0.3 * (1.0 - overcast)))
		draw_circle(p, 32, Color(1.0, 0.86, 0.35).lerp(Color(1, 0.55, 0.3), day_night.dusk() * 0.6))
	if e < 0.2:
		var mk := fposmod(day_night.t - 0.75, 1.0) / 0.5
		var mp := Vector2(lerpf(sz.x * 0.1, sz.x * 0.9, clampf(mk, 0, 1)), sz.y * 0.75 + e * sz.y * 0.6)
		draw_circle(mp, 40, Color(0.9, 0.95, 1, 0.12))
		draw_circle(mp, 24, Color(0.95, 0.96, 1.0))
		draw_circle(mp + Vector2(9, -5), 20, top.lerp(bot, 0.3))
	# nuvens com leve paralaxe
	var cloud_col := Color(1, 1, 1, 0.92).lerp(Color(0.62, 0.66, 0.78, 0.9), night * 0.8)
	cloud_col = cloud_col.lerp(Color(0.75, 0.78, 0.84, 0.95), overcast)
	var span := sz.x + 400.0
	for c in _clouds:
		var x := fposmod(c["x"] - camera_x * 0.05, span) - 200.0
		_cloud(Vector2(x, c["y"]), c["s"], cloud_col)


func _cloud(p: Vector2, s: float, col: Color) -> void:
	draw_circle(p, 34 * s, col)
	draw_circle(p + Vector2(-38, 10) * s, 26 * s, col)
	draw_circle(p + Vector2(40, 8) * s, 28 * s, col)
	draw_circle(p + Vector2(10, -16) * s, 26 * s, col)
	draw_rect(Rect2(p + Vector2(-60, 10) * s, Vector2(122, 26) * s), col)
