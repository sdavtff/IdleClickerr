class_name BuildingArt
extends RefCounted
## Arte vetorial cartoon dos edifícios. Cada edifício tem seu próprio desenho.
## Origem: centro da base do edifício (y negativo para cima).
## mode 0 = estrutura (dia), mode 1 = luzes noturnas (janelas, letreiros).

const OUT := Color("2a2f45")
const GLASS := Color("a9dcf5")
const GLASS_D := Color("74b6dc")
const LIT := Color("ffd76b")
const LIT_SOFT := Color(1.0, 0.85, 0.42, 0.28)
const WHITE := Color("fbfbf7")
const GOLD := Color("f5c242")

## Altura base e crescimento por marco de nível (andares extras).
const HEIGHTS := {
	"casa_pequena": [122, 0], "casa_moderna": [138, 0], "casa_luxo": [150, 0],
	"apartamento": [228, 18], "condominio": [296, 18], "arranha_ceu_res": [360, 16],
	"torre_megacity": [392, 14], "padaria": [140, 0], "loja_conveniencia": [128, 0],
	"restaurante": [146, 0], "supermercado": [140, 0], "shopping": [205, 0],
	"hotel": [316, 18], "escritorio": [262, 18], "fabrica": [176, 0],
	"centro_distribuicao": [140, 0], "usina_solar": [160, 0], "empresa_tecnologia": [282, 16],
	"banco": [222, 0], "centro_empresarial": [350, 16], "bolsa_valores": [372, 14],
	"escola": [170, 0], "biblioteca": [158, 0], "hospital": [232, 14],
	"delegacia": [162, 0], "bombeiros": [196, 0], "prefeitura": [236, 0],
	"centro_medico": [300, 14], "universidade": [266, 0], "central_seguranca": [330, 14],
	"complexo_hospitalar": [372, 14], "parque": [118, 0], "academia": [160, 0],
	"cinema": [186, 0], "centro_entretenimento": [212, 0], "estadio": [205, 0],
	"parque_diversoes": [262, 0],
}

static var _font: Font


static func font() -> Font:
	if _font == null:
		_font = load("res://assets/fonts/Fredoka-Bold.woff")
	return _font


static func tier_of(level: int) -> int:
	var t := 0
	for m in GameData.LEVEL_MILESTONES:
		if level >= m:
			t += 1
	return t


static func height_of(id: String, level: int) -> float:
	var h: Array = HEIGHTS.get(id, [150, 0])
	return float(h[0]) + float(h[1]) * tier_of(level)


static func width_of(id: String) -> float:
	return float(GameData.get_def(id).get("w", 180))


static func draw(ci: CanvasItem, id: String, level: int, mode: int) -> void:
	var t := tier_of(level)
	var h := height_of(id, level)
	var w := width_of(id)
	match id:
		"casa_pequena":
			_b_casa_pequena(ci, mode, t, h, w)
		"casa_moderna":
			_b_casa_moderna(ci, mode, t, h, w)
		"casa_luxo":
			_b_casa_luxo(ci, mode, t, h, w)
		"apartamento":
			_b_apartamento(ci, mode, t, h, w)
		"condominio":
			_b_condominio(ci, mode, t, h, w)
		"arranha_ceu_res":
			_b_arranha_ceu_res(ci, mode, t, h, w)
		"torre_megacity":
			_b_torre_megacity(ci, mode, t, h, w)
		"padaria":
			_b_padaria(ci, mode, t, h, w)
		"loja_conveniencia":
			_b_loja_conveniencia(ci, mode, t, h, w)
		"restaurante":
			_b_restaurante(ci, mode, t, h, w)
		"supermercado":
			_b_supermercado(ci, mode, t, h, w)
		"shopping":
			_b_shopping(ci, mode, t, h, w)
		"hotel":
			_b_hotel(ci, mode, t, h, w)
		"escritorio":
			_b_escritorio(ci, mode, t, h, w)
		"fabrica":
			_b_fabrica(ci, mode, t, h, w)
		"centro_distribuicao":
			_b_centro_distribuicao(ci, mode, t, h, w)
		"usina_solar":
			_b_usina_solar(ci, mode, t, h, w)
		"empresa_tecnologia":
			_b_empresa_tecnologia(ci, mode, t, h, w)
		"banco":
			_b_banco(ci, mode, t, h, w)
		"centro_empresarial":
			_b_centro_empresarial(ci, mode, t, h, w)
		"bolsa_valores":
			_b_bolsa_valores(ci, mode, t, h, w)
		"escola":
			_b_escola(ci, mode, t, h, w)
		"biblioteca":
			_b_biblioteca(ci, mode, t, h, w)
		"universidade":
			_b_universidade(ci, mode, t, h, w)
		"hospital":
			_b_hospital(ci, mode, t, h, w)
		"centro_medico":
			_b_centro_medico(ci, mode, t, h, w)
		"complexo_hospitalar":
			_b_complexo_hospitalar(ci, mode, t, h, w)
		"delegacia":
			_b_delegacia(ci, mode, t, h, w)
		"bombeiros":
			_b_bombeiros(ci, mode, t, h, w)
		"central_seguranca":
			_b_central_seguranca(ci, mode, t, h, w)
		"prefeitura":
			_b_prefeitura(ci, mode, t, h, w)
		"parque":
			_b_parque(ci, mode, t, h, w)
		"academia":
			_b_academia(ci, mode, t, h, w)
		"cinema":
			_b_cinema(ci, mode, t, h, w)
		"centro_entretenimento":
			_b_centro_entretenimento(ci, mode, t, h, w)
		"estadio":
			_b_estadio(ci, mode, t, h, w)
		"parque_diversoes":
			_b_parque_diversoes(ci, mode, t, h, w)
		_:
			_tower(ci, mode, -w * 0.5, -h, w, h, Color("c0c8d8"), 4, id.hash())
	_tier_decor(ci, mode, t, id, h, w)


# =============================================================================
# Primitivas
# =============================================================================

static func box(ci: CanvasItem, m: int, x: float, y: float, w: float, h: float, col: Color, shade := true) -> void:
	if m != 0:
		return
	ci.draw_rect(Rect2(x - 3, y - 3, w + 6, h + 3), OUT)
	ci.draw_rect(Rect2(x, y, w, h), col)
	if shade:
		ci.draw_rect(Rect2(x + w * 0.8, y, w * 0.2, h), col.darkened(0.1))
		ci.draw_rect(Rect2(x, y, w, minf(5.0, h)), col.lightened(0.2))


static func flat(ci: CanvasItem, m: int, x: float, y: float, w: float, h: float, col: Color) -> void:
	if m == 0:
		ci.draw_rect(Rect2(x, y, w, h), col)


static func pv(arr: Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in range(0, arr.size(), 2):
		out.append(Vector2(arr[i], arr[i + 1]))
	return out


static func poly(ci: CanvasItem, m: int, arr: Array, col: Color, outline := true) -> void:
	if m != 0:
		return
	var p := pv(arr)
	ci.draw_colored_polygon(p, col)
	if outline:
		var closed := p.duplicate()
		closed.append(p[0])
		ci.draw_polyline(closed, OUT, 3.0, true)


static func circle(ci: CanvasItem, m: int, c: Vector2, r: float, col: Color, outline := true) -> void:
	if m != 0:
		return
	if outline:
		ci.draw_circle(c, r + 2.5, OUT)
	ci.draw_circle(c, r, col)


static func _seed_lit(x: float, y: float, salt: int) -> bool:
	var hsh := absi(int(x * 73.0) * 31 + int(y * 37.0) * 17 + salt * 13)
	return (hsh % 100) < 68


static func window(ci: CanvasItem, m: int, x: float, y: float, w: float, h: float, salt := 0, frame := WHITE) -> void:
	if m == 0:
		ci.draw_rect(Rect2(x - 2.5, y - 2.5, w + 5, h + 5), OUT)
		ci.draw_rect(Rect2(x - 1, y - 1, w + 2, h + 2), frame)
		ci.draw_rect(Rect2(x + 1, y + 1, w - 2, h - 2), GLASS)
		ci.draw_rect(Rect2(x + 1, y + h * 0.55, w - 2, h * 0.45 - 1), GLASS_D)
		ci.draw_colored_polygon(pv([x + 2, y + 2, x + w * 0.45, y + 2, x + 2, y + h * 0.5]), Color(1, 1, 1, 0.55))
		if w >= 16:
			ci.draw_line(Vector2(x + w * 0.5, y + 1), Vector2(x + w * 0.5, y + h - 1), frame, 2.0)
	elif _seed_lit(x, y, salt):
		ci.draw_rect(Rect2(x - 4, y - 4, w + 8, h + 8), LIT_SOFT)
		ci.draw_rect(Rect2(x, y, w, h), LIT)
		ci.draw_rect(Rect2(x, y + h * 0.6, w, h * 0.4), LIT.darkened(0.12))


static func window_grid(ci: CanvasItem, m: int, x0: float, y0: float, x1: float, y1: float, cols: int, rows: int, ww: float, wh: float, salt := 0, frame := WHITE) -> void:
	if cols <= 0 or rows <= 0:
		return
	var sx := (x1 - x0 - ww * cols) / float(cols + 1)
	var sy := (y1 - y0 - wh * rows) / float(rows + 1)
	for r in rows:
		for c in cols:
			window(ci, m, x0 + sx + c * (ww + sx), y0 + sy + r * (wh + sy), ww, wh, salt, frame)


static func glass_grid(ci: CanvasItem, m: int, x0: float, y0: float, x1: float, y1: float, cols: int, floor_h: float, tint: Color, salt := 0) -> void:
	## Fachada de vidro contínua com divisões e janelas acesas à noite.
	var rows := int((y1 - y0) / floor_h)
	var cw := (x1 - x0) / float(cols)
	if m == 0:
		ci.draw_rect(Rect2(x0, y0, x1 - x0, y1 - y0), tint)
		for r in rows + 1:
			ci.draw_line(Vector2(x0, y0 + r * floor_h), Vector2(x1, y0 + r * floor_h), tint.darkened(0.35), 2.0)
		for c in range(1, cols):
			ci.draw_line(Vector2(x0 + c * cw, y0), Vector2(x0 + c * cw, y1), tint.darkened(0.25), 1.5)
		# reflexos diagonais
		var p := pv([x0 + (x1 - x0) * 0.1, y1, x0 + (x1 - x0) * 0.35, y1, x0 + (x1 - x0) * 0.75, y0, x0 + (x1 - x0) * 0.5, y0])
		ci.draw_colored_polygon(p, Color(1, 1, 1, 0.13))
	else:
		for r in rows:
			for c in cols:
				var x := x0 + c * cw + 3
				var y := y0 + r * floor_h + 3
				if _seed_lit(x, y, salt):
					ci.draw_rect(Rect2(x, y, cw - 6, floor_h - 6), Color(1.0, 0.86, 0.5, 0.85))


static func door(ci: CanvasItem, m: int, x: float, y: float, w: float, h: float, col: Color) -> void:
	if m == 0:
		ci.draw_rect(Rect2(x - 3, y - 3, w + 6, h + 3), OUT)
		ci.draw_rect(Rect2(x, y, w, h), col)
		ci.draw_rect(Rect2(x + 4, y + 5, w - 8, h * 0.35), col.lightened(0.35))
		ci.draw_circle(Vector2(x + w - 6, y + h * 0.6), 2.5, GOLD)
	else:
		ci.draw_rect(Rect2(x - 6, y - 6, w + 12, h + 6), Color(1, 0.85, 0.45, 0.22))


static func glass_door(ci: CanvasItem, m: int, x: float, y: float, w: float, h: float) -> void:
	if m == 0:
		ci.draw_rect(Rect2(x - 3, y - 3, w + 6, h + 3), OUT)
		ci.draw_rect(Rect2(x, y, w, h), GLASS_D)
		ci.draw_line(Vector2(x + w * 0.5, y), Vector2(x + w * 0.5, y + h), OUT, 2.0)
		ci.draw_colored_polygon(pv([x + 2, y + 2, x + w * 0.4, y + 2, x + 2, y + h * 0.4]), Color(1, 1, 1, 0.5))
	else:
		ci.draw_rect(Rect2(x, y, w, h), Color(1, 0.88, 0.55, 0.9))


static func awning(ci: CanvasItem, m: int, x: float, y: float, w: float, h: float, c1: Color, c2: Color) -> void:
	if m != 0:
		return
	var stripes := int(maxf(4.0, w / 16.0))
	var sw := w / stripes
	ci.draw_colored_polygon(pv([x - 6, y + h, x + w + 6, y + h, x + w, y, x, y]), OUT)
	for i in stripes:
		var col := c1 if i % 2 == 0 else c2
		var xa := x + i * sw
		var sh0 := -4.0 + 8.0 * i / stripes
		var sh1 := -4.0 + 8.0 * (i + 1) / stripes
		ci.draw_colored_polygon(pv([xa + sh0, y + h - 2, xa + sw + sh1, y + h - 2, xa + sw, y + 2, xa, y + 2]), col)
	for i in stripes:
		var col := c1 if i % 2 == 0 else c2
		ci.draw_circle(Vector2(x - 3 + (i + 0.5) * (w + 6) / stripes, y + h), (w + 6) / stripes * 0.5, OUT)
		ci.draw_circle(Vector2(x - 3 + (i + 0.5) * (w + 6) / stripes, y + h - 1), (w + 6) / stripes * 0.5 - 2, col)


static func signboard(ci: CanvasItem, m: int, x: float, y: float, w: float, h: float, bg: Color, fg: Color, text: String, size := 18) -> void:
	if m == 0:
		ci.draw_rect(Rect2(x - 3, y - 3, w + 6, h + 6), OUT)
		ci.draw_rect(Rect2(x, y, w, h), bg)
		ci.draw_rect(Rect2(x, y, w, 3), bg.lightened(0.25))
	else:
		ci.draw_rect(Rect2(x - 7, y - 7, w + 14, h + 14), Color(bg.lightened(0.4), 0.3))
		ci.draw_rect(Rect2(x, y, w, h), bg.lightened(0.15))
	var col := fg if m == 0 else fg.lightened(0.3)
	ci.draw_string(font(), Vector2(x, y + h * 0.5 + size * 0.36), text, HORIZONTAL_ALIGNMENT_CENTER, w, size, col)


static func roof_tri(ci: CanvasItem, m: int, x0: float, x1: float, y: float, h: float, col: Color) -> void:
	poly(ci, m, [x0, y, (x0 + x1) * 0.5, y - h, x1, y], col)
	if m == 0:
		ci.draw_line(Vector2(x0 + 4, y - 4), Vector2((x0 + x1) * 0.5, y - h + 4), col.lightened(0.25), 3.0)


static func tree(ci: CanvasItem, m: int, x: float, y: float, s := 1.0, col := Color("4caf50")) -> void:
	if m != 0:
		return
	ci.draw_rect(Rect2(x - 5 * s, y - 26 * s, 10 * s, 26 * s), OUT)
	ci.draw_rect(Rect2(x - 3 * s, y - 26 * s, 6 * s, 26 * s), Color("8d5a3b"))
	for c in [[0, -46, 18], [-12, -36, 14], [12, -36, 14]]:
		ci.draw_circle(Vector2(x + c[0] * s, y + c[1] * s), (c[2] + 2.5) * s, OUT)
	for c in [[0, -46, 18], [-12, -36, 14], [12, -36, 14]]:
		ci.draw_circle(Vector2(x + c[0] * s, y + c[1] * s), c[2] * s, col)
	ci.draw_circle(Vector2(x - 5 * s, y - 52 * s), 6 * s, col.lightened(0.25))


static func bush(ci: CanvasItem, m: int, x: float, y: float, w: float, col := Color("5cb85c"), flowers := Color("ff7eb3")) -> void:
	if m != 0:
		return
	var n := int(maxf(2.0, w / 14.0))
	for i in n:
		ci.draw_circle(Vector2(x + (i + 0.5) * w / n, y - 8), 11, OUT)
	for i in n:
		ci.draw_circle(Vector2(x + (i + 0.5) * w / n, y - 8), 9, col)
		if i % 2 == 0:
			ci.draw_circle(Vector2(x + (i + 0.5) * w / n + 2, y - 12), 2.5, flowers)


static func text(ci: CanvasItem, pos: Vector2, s: String, size: int, col: Color, width := -1.0) -> void:
	ci.draw_string(font(), pos, s, HORIZONTAL_ALIGNMENT_CENTER, width, size, col)


static func _tower(ci: CanvasItem, m: int, x: float, y: float, w: float, h: float, col: Color, cols: int, salt: int) -> void:
	box(ci, m, x, y, w, h, col)
	var rows := int((h - 30) / 34.0)
	window_grid(ci, m, x + 4, y + 10, x + w - 4, y + h - 20, cols, rows, 16, 20, salt)


## Ponto do telhado onde ficam os enfeites de nível: [x, deslocamento a partir do topo, largura plana].
const ROOFS := {
	"casa_pequena": [0, 0, 0], "casa_moderna": [-10, 0, 140], "casa_luxo": [0, 8, 160],
	"apartamento": [-20, 0, 120], "condominio": [-52, 0, 84], "arranha_ceu_res": [0, 6, 112],
	"torre_megacity": [0, 40, 110], "padaria": [0, 8, 156], "loja_conveniencia": [0, 0, 160],
	"restaurante": [0, 4, 168], "supermercado": [0, 0, 212], "shopping": [0, 44, 212],
	"hotel": [-4, 0, 152], "escritorio": [0, 0, 148], "fabrica": [-22, 50, 120],
	"centro_distribuicao": [0, 0, 216], "usina_solar": [-73, 98, 62], "empresa_tecnologia": [-27, -32, 0],
	"banco": [0, 0, 0], "centro_empresarial": [-57, 0, 82], "bolsa_valores": [0, 2, 0],
	"escola": [0, 18, 0], "biblioteca": [0, 0, 0], "universidade": [0, 12, 0],
	"hospital": [0, 20, 184], "centro_medico": [-21, 14, 130], "complexo_hospitalar": [36, -34, 0],
	"delegacia": [0, 26, 164], "bombeiros": [75, 0, 42], "central_seguranca": [0, 40, 172],
	"prefeitura": [0, 22, 0], "academia": [0, 16, 164], "cinema": [0, 36, 172],
	"centro_entretenimento": [0, 0, 120],
}


## Detalhes extras nos níveis 10, 25, 50, 75 e 100, presos ao telhado.
static func _tier_decor(ci: CanvasItem, m: int, t: int, id: String, h: float, _w: float) -> void:
	if t <= 0 or not ROOFS.has(id):
		return
	var r: Array = ROOFS[id]
	var ax := float(r[0])
	var ay := -h + float(r[1])
	var rw := float(r[2])
	var ant := Vector2(ax + rw * 0.3, ay) if rw > 0 else Vector2(ax, ay)
	var ant_h := 26.0
	if m == 0:
		ci.draw_line(ant, ant - Vector2(0, ant_h), OUT, 3.0)
		ci.draw_circle(ant - Vector2(0, ant_h + 1), 4, Color("e74c3c"))
		if rw >= 60:
			box(ci, m, ax - rw * 0.35, ay - 10, 20, 10, Color("aab4c3"))
	if t >= 2 and m == 0:
		if rw > 0:
			ci.draw_rect(Rect2(ax - rw * 0.5 + 4, ay - 4, rw - 8, 4), GOLD)
		else:
			ci.draw_circle(ant, 6, GOLD)
	if t >= 3 and m == 0:
		var fx := ax - rw * 0.1 if rw > 0 else ax
		var fy := ay if rw > 0 else ay - ant_h
		var fh := 40.0 if rw > 0 else 18.0
		ci.draw_line(Vector2(fx, fy), Vector2(fx, fy - fh), OUT, 3.0)
		ci.draw_colored_polygon(pv([fx, fy - fh, fx + 26, fy - fh + 7, fx, fy - fh + 14]), Color("2ecc71"))
		ci.draw_circle(Vector2(fx + 9, fy - fh + 7), 3.5, GOLD)
	if t >= 4:
		var tip := ant - Vector2(0, ant_h + 1)
		if m == 0:
			ci.draw_circle(tip, 6, Color("ff5252"))
		else:
			ci.draw_circle(tip, 14, Color(1, 0.3, 0.3, 0.45))
			ci.draw_circle(tip, 6, Color(1, 0.5, 0.5))
	if t >= 5:
		var c := Vector2(ax - rw * 0.5 - 4, ay - 18) if rw > 0 else Vector2(ax - 30, ay - 10)
		var pts := []
		for i in 10:
			var rr := 13.0 if i % 2 == 0 else 6.0
			var a := -PI / 2 + i * PI / 5
			pts.append(c.x + cos(a) * rr)
			pts.append(c.y + sin(a) * rr)
		poly(ci, m, pts, GOLD)
		if m == 1:
			ci.draw_circle(c, 20, Color(1, 0.85, 0.3, 0.35))


# =============================================================================
# Residenciais
# =============================================================================

static func _b_casa_pequena(ci: CanvasItem, m: int, t: int, h: float, w: float) -> void:
	box(ci, m, 30, -h + 12, 16, 34, Color("b5523b"))
	box(ci, m, -58, -76, 116, 76, Color("f7e6c0"))
	roof_tri(ci, m, -72, 72, -74, h - 74, Color("dc5a4e"))
	window(ci, m, -48, -58, 26, 24, 1)
	window(ci, m, 22, -58, 26, 24, 2)
	door(ci, m, -12, -46, 24, 46, Color("4f7cc9"))
	if m == 0:
		ci.draw_circle(Vector2(0, -92), 9, OUT)
		ci.draw_circle(Vector2(0, -92), 7, Color("fff3c4"))
	bush(ci, m, -74, 0, 22)
	bush(ci, m, 54, 0, 20)


static func _b_casa_moderna(ci: CanvasItem, m: int, t: int, h: float, w: float) -> void:
	box(ci, m, -82, -74, 164, 74, Color("f4f4ef"))
	box(ci, m, -72, -h + 6, 124, h - 80, Color("dfe4ea"))
	box(ci, m, 18, -h + 6, 34, h - 80, Color("c68b59"), false)
	if m == 0:
		for i in 6:
			ci.draw_line(Vector2(20, -h + 14 + i * 9), Vector2(50, -h + 14 + i * 9), Color("a8714a"), 2.0)
	box(ci, m, -80, -h, 140, 8, Color("5b6475"), false)
	window(ci, m, -72, -62, 74, 44, 3)
	window(ci, m, -62, -h + 20, 64, 34, 4)
	door(ci, m, 26, -56, 28, 56, Color("8a5a3c"))
	if m == 0:
		ci.draw_rect(Rect2(-76, -78, 132, 4), OUT)
		ci.draw_rect(Rect2(-76, -96, 132, 18), Color(0.7, 0.88, 1.0, 0.4))
		ci.draw_rect(Rect2(-76, -96, 132, 3), OUT)
	bush(ci, m, 62, 0, 20)


static func _b_casa_luxo(ci: CanvasItem, m: int, t: int, h: float, w: float) -> void:
	box(ci, m, -96, -90, 192, 90, Color("f5ecdc"))
	poly(ci, m, [-106, -88, -80, -h + 8, 80, -h + 8, 106, -88], Color("5d6d8a"))
	if m == 0:
		ci.draw_rect(Rect2(-100, -92, 200, 5), GOLD)
	for x in [-86, -58, 36, 64]:
		window(ci, m, x, -80, 22, 28, 5)
		window(ci, m, x, -40, 22, 28, 6)
	poly(ci, m, [-36, -90, 0, -122, 36, -90], Color("f5ecdc"))
	for x in [-30, -12, 8, 26]:
		box(ci, m, x, -88, 8, 88, WHITE, false)
	door(ci, m, -10, -44, 20, 44, Color("6b3f26"))
	tree(ci, m, -100, 0, 0.75, Color("43a047"))
	if m == 0:
		ci.draw_rect(Rect2(46, -6, 50, 6), Color("4fc3f7"))


static func _b_apartamento(ci: CanvasItem, m: int, t: int, h: float, w: float) -> void:
	var brick := Color("c45d42")
	box(ci, m, -76, -h + 10, 152, h - 10, brick)
	box(ci, m, -82, -h, 164, 12, brick.darkened(0.3), false)
	if m == 0:
		for i in int((h - 40) / 12):
			var y := -h + 26 + i * 12
			ci.draw_line(Vector2(-74, y), Vector2(58, y), brick.darkened(0.12), 1.0)
	var rows := int((h - 70) / 38.0)
	for r in rows:
		var y := -h + 24 + r * 38
		for c in 3:
			window(ci, m, -62 + c * 44, y, 26, 26, 7)
		if m == 0:
			ci.draw_rect(Rect2(-66, y + 28, 132, 3), OUT)
	box(ci, m, -30, -48, 60, 48, Color("8f3f2b"), false)
	glass_door(ci, m, -14, -42, 28, 42)
	awning(ci, m, -36, -60, 72, 14, Color("2e7d32"), WHITE)
	# caixa d'água
	box(ci, m, 30, -h - 30, 30, 22, Color("8d6e63"))
	if m == 0:
		ci.draw_line(Vector2(34, -h - 8), Vector2(34, -h), OUT, 3.0)
		ci.draw_line(Vector2(56, -h - 8), Vector2(56, -h), OUT, 3.0)


static func _b_condominio(ci: CanvasItem, m: int, t: int, h: float, w: float) -> void:
	var c1 := Color("eef3f4")
	var teal := Color("26a69a")
	box(ci, m, -94, -h, 84, h, c1)
	box(ci, m, 10, -h + 44, 84, h - 44, c1)
	box(ci, m, -12, -96, 24, 96, Color("cfd8dc"), false)
	for tx in [[-94, -h], [10, -h + 44]]:
		var rows := int((-tx[1] - 50) / 32.0)
		for r in rows:
			var y: float = tx[1] + 14 + r * 32
			window(ci, m, tx[0] + 10, y, 26, 20, 8)
			window(ci, m, tx[0] + 46, y, 26, 20, 9)
			flat(ci, m, tx[0] + 2, y + 22, 80, 5, teal)
	box(ci, m, -14, -120, 28, 14, teal, false)
	glass_door(ci, m, -10, -40, 20, 40)
	poly(ci, m, [-98, -h, -52, -h - 18, -6, -h], teal)


static func _b_arranha_ceu_res(ci: CanvasItem, m: int, t: int, h: float, w: float) -> void:
	var top := -h + 44
	box(ci, m, -80, top, 160, h - 44, Color("4f8fc6"))
	glass_grid(ci, m, -74, top + 8, 62, -40, 5, 22, Color("5aa0d8"), 10)
	box(ci, m, -56, -h + 6, 112, 40, Color("3b78ad"))
	glass_grid(ci, m, -50, -h + 12, 50, -h + 42, 4, 15, Color("5aa0d8"), 11)
	if m == 0:
		ci.draw_line(Vector2(0, -h + 6), Vector2(0, -h - 40), OUT, 4.0)
		ci.draw_line(Vector2(0, -h + 6), Vector2(0, -h - 40), Color("cfd8dc"), 2.0)
	else:
		ci.draw_circle(Vector2(0, -h - 40), 9, Color(1, 0.3, 0.3, 0.5))
	box(ci, m, -80, -40, 160, 40, Color("e3e9ef"), false)
	glass_door(ci, m, -20, -36, 40, 36)
	window(ci, m, -66, -32, 34, 24, 12)
	window(ci, m, 32, -32, 34, 24, 13)


static func _b_torre_megacity(ci: CanvasItem, m: int, t: int, h: float, w: float) -> void:
	var bw := 190.0
	var tw := 110.0
	var top := -h + 40
	poly(ci, m, [-bw / 2, 0, bw / 2, 0, tw / 2, top, -tw / 2, top], Color("6c4fd1"))
	var floors := int((h - 60) / 20.0)
	for f in floors:
		var y0 := -20.0 - f * 20.0
		var k := (-y0) / (h - 40)
		var half := lerpf(bw / 2, tw / 2, k) - 8
		if f % 5 == 4:
			flat(ci, m, -half - 4, y0 - 6, half * 2 + 8, 6, Color("43a047"))
			if m == 0:
				for i in 4:
					ci.draw_circle(Vector2(-half + 10 + i * (half * 2 - 20) / 3.0, y0 - 10), 6, Color("66bb6a"))
			continue
		var n := int(half * 2 / 22.0)
		for i in n:
			var x := -half + 4 + i * 22.0
			if m == 0:
				ci.draw_rect(Rect2(x, y0 + 4 - 20, 16, 12), Color("9f8cf0"))
			elif _seed_lit(x, y0, 14):
				ci.draw_rect(Rect2(x, y0 + 4 - 20, 16, 12), Color(0.75, 0.95, 1.0, 0.95))
	if m == 0:
		ci.draw_arc(Vector2(0, top - 10), 50, PI, TAU, 24, OUT, 7.0)
		ci.draw_arc(Vector2(0, top - 10), 50, PI, TAU, 24, Color("b39ddb"), 4.0)
		ci.draw_line(Vector2(0, top), Vector2(0, top - 80), OUT, 4.0)
	else:
		ci.draw_arc(Vector2(0, top - 10), 50, PI, TAU, 24, Color(0.6, 0.9, 1.0, 0.9), 4.0)
		ci.draw_circle(Vector2(0, top - 80), 10, Color(0.6, 0.9, 1.0, 0.6))
	glass_door(ci, m, -22, -40, 44, 40)


# =============================================================================
# Comerciais
# =============================================================================

static func _b_padaria(ci: CanvasItem, m: int, t: int, h: float, w: float) -> void:
	box(ci, m, -72, -h + 18, 144, h - 18, Color("f3d9a4"))
	box(ci, m, -78, -h + 8, 156, 12, Color("8d5a3b"), false)
	window(ci, m, -56, -h + 30, 30, 24, 15)
	window(ci, m, 26, -h + 30, 30, 24, 16)
	signboard(ci, m, -44, -h + 62 - 6, 88, 22, Color("8d5a3b"), Color("ffe0a3"), "PADARIA", 16)
	awning(ci, m, -70, -68, 140, 16, Color("e53935"), WHITE)
	window(ci, m, -62, -48, 62, 40, 17)
	if m == 0:
		for i in 3:
			ci.draw_circle(Vector2(-50 + i * 19, -16), 8, OUT)
			ci.draw_circle(Vector2(-50 + i * 19, -16), 6, Color("d9a05b"))
	door(ci, m, 18, -52, 30, 52, Color("a1683a"))


static func _b_loja_conveniencia(ci: CanvasItem, m: int, t: int, h: float, w: float) -> void:
	box(ci, m, -80, -h + 20, 160, h - 20, Color("eef6ef"))
	signboard(ci, m, -80, -h, 160, 30, Color("2e9e5b"), WHITE, "LOJA 24H", 20)
	window(ci, m, -70, -72, 92, 60, 18)
	glass_door(ci, m, 32, -66, 38, 66)
	if m == 0:
		ci.draw_rect(Rect2(-64, -28, 80, 12), Color("ef5350"))
		ci.draw_rect(Rect2(-60, -46, 22, 16), Color("ffca28"))
		ci.draw_rect(Rect2(-32, -46, 22, 16), Color("42a5f5"))
	flat(ci, m, -80, -h + 30, 160, 6, Color("ffca28"))


static func _b_restaurante(ci: CanvasItem, m: int, t: int, h: float, w: float) -> void:
	box(ci, m, -78, -h + 12, 156, h - 12, Color("a63d40"))
	box(ci, m, -84, -h + 4, 168, 10, Color("6d2427"), false)
	for x in [-64, -18, 28]:
		window(ci, m, x, -h + 26, 34, 28, 19, Color("f6e7c8"))
	signboard(ci, m, -62, -h + 64, 124, 22, Color("f6e7c8"), Color("a63d40"), "RESTAURANTE", 15)
	awning(ci, m, -76, -64, 152, 14, Color("2e7d32"), Color("f6e7c8"))
	window(ci, m, -66, -46, 48, 36, 20, Color("f6e7c8"))
	door(ci, m, -4, -50, 28, 50, Color("6d2427"))
	# mesa com guarda-sol
	if m == 0:
		ci.draw_line(Vector2(56, 0), Vector2(56, -40), OUT, 3.0)
		ci.draw_colored_polygon(pv([36, -38, 76, -38, 56, -52]), Color("ffb300"))
		ci.draw_rect(Rect2(44, -16, 24, 4), OUT)
		ci.draw_line(Vector2(56, -14), Vector2(56, 0), OUT, 2.0)


static func _b_supermercado(ci: CanvasItem, m: int, t: int, h: float, w: float) -> void:
	box(ci, m, -106, -h + 28, 212, h - 28, Color("f7f6f0"))
	signboard(ci, m, -106, -h, 212, 34, Color("f57c00"), WHITE, "SUPERMERCADO", 20)
	for i in 4:
		window(ci, m, -98 + i * 34, -78, 28, 50, 21)
	glass_door(ci, m, 42, -70, 52, 70)
	flat(ci, m, -106, -h + 34, 212, 6, Color("4caf50"))
	if m == 0:
		for i in 2:
			var x := -96 + i * 30
			ci.draw_rect(Rect2(x, -20, 22, 12), OUT)
			ci.draw_rect(Rect2(x + 2, -18, 18, 8), Color("b0bec5"))
			ci.draw_circle(Vector2(x + 4, -4), 3, OUT)
			ci.draw_circle(Vector2(x + 18, -4), 3, OUT)


static func _b_shopping(ci: CanvasItem, m: int, t: int, h: float, w: float) -> void:
	var body := Color("ead9f6")
	box(ci, m, -106, -h + 44, 212, h - 44, body)
	circle(ci, m, Vector2(0, -h + 46), 44, Color("9fd8f5"))
	if m == 0:
		for i in 5:
			var a := PI + (i + 1) * PI / 6.0
			ci.draw_line(Vector2(0, -h + 46), Vector2(0, -h + 46) + Vector2(cos(a), sin(a)) * 44, Color("6aa9cc"), 2.0)
		ci.draw_rect(Rect2(-46, -h + 44, 92, 4), OUT)
	else:
		ci.draw_circle(Vector2(0, -h + 46), 40, Color(1, 0.9, 0.6, 0.5))
	glass_grid(ci, m, -34, -h + 50, 34, -50, 3, 26, Color("8fcbea"), 22)
	for side in [-1, 1]:
		var x0 := -98.0 if side < 0 else 42.0
		window_grid(ci, m, x0, -h + 54, x0 + 56, -60, 2, 3, 18, 22, 23)
	signboard(ci, m, -60, -86, 120, 26, Color("d81b60"), WHITE, "SHOPPING", 18)
	glass_door(ci, m, -30, -54, 60, 54)


static func _b_hotel(ci: CanvasItem, m: int, t: int, h: float, w: float) -> void:
	var body := Color("f1e3c8")
	box(ci, m, -74, -h + 10, 140, h - 10, body)
	box(ci, m, -80, -h, 152, 14, Color("b8860b"), false)
	var rows := int((h - 90) / 30.0)
	window_grid(ci, m, -70, -h + 20, 60, -h + 20 + rows * 30, 4, rows, 18, 18, 24)
	box(ci, m, 70, -h + 40, 24, 170, Color("c62828"))
	var letters := "HOTEL"
	for i in letters.length():
		var col := WHITE if m == 0 else Color(1, 0.95, 0.7)
		if m == 1:
			ci.draw_circle(Vector2(82, -h + 64 + i * 32), 14, Color(1, 0.4, 0.3, 0.3))
		text(ci, Vector2(70, -h + 72 + i * 32), letters[i], 22, col, 24)
	for i in 3:
		text(ci, Vector2(-40 + i * 24, -h + 4), "*", 22, GOLD if m == 0 else Color(1, 0.9, 0.5), 20)
	awning(ci, m, -46, -62, 92, 16, Color("c62828"), Color("c62828").lightened(0.2))
	glass_door(ci, m, -24, -46, 48, 46)


# =============================================================================
# Empresariais e industriais
# =============================================================================

static func _b_escritorio(ci: CanvasItem, m: int, t: int, h: float, w: float) -> void:
	box(ci, m, -74, -h, 148, h, Color("6f8fae"))
	glass_grid(ci, m, -66, -h + 12, 58, -60, 4, 26, Color("8cb3d6"), 25)
	box(ci, m, -74, -60, 148, 60, Color("e0e6ec"), false)
	signboard(ci, m, -56, -58, 112, 18, Color("37474f"), WHITE, "ESCRITÓRIOS", 13)
	glass_door(ci, m, -22, -36, 44, 36)
	box(ci, m, -50, -h - 14, 30, 14, Color("90a4ae"))


static func _b_fabrica(ci: CanvasItem, m: int, t: int, h: float, w: float) -> void:
	# chaminés
	for cx in [62, 88]:
		box(ci, m, cx - 9, -h, 18, h, Color("a1503a"))
		flat(ci, m, cx - 9, -h + 6, 18, 6, WHITE)
		flat(ci, m, cx - 9, -h + 20, 18, 6, WHITE)
	box(ci, m, -108, -100, 172, 100, Color("bcb4a6"))
	for i in 4:
		var x0 := -108 + i * 43.0
		poly(ci, m, [x0, -100, x0, -126, x0 + 43, -100], Color("8e9aa8"))
		flat(ci, m, x0 + 3, -120, 6, 18, GLASS)
	window_grid(ci, m, -104, -94, 60, -64, 5, 1, 20, 16, 26)
	if m == 0:
		ci.draw_rect(Rect2(-40, -58, 64, 58), OUT)
		for i in 7:
			ci.draw_rect(Rect2(-37, -55 + i * 8, 58, 6), Color("ffb300") if i % 2 == 0 else Color("455a64"))
	else:
		ci.draw_rect(Rect2(-37, -55, 58, 55), Color(1, 0.75, 0.3, 0.35))
	signboard(ci, m, -100, -60, 50, 18, Color("37474f"), Color("ffca28"), "FÁBRICA", 11)


static func _b_centro_distribuicao(ci: CanvasItem, m: int, t: int, h: float, w: float) -> void:
	box(ci, m, -108, -h + 26, 216, h - 26, Color("5c84bf"))
	if m == 0:
		for i in 17:
			ci.draw_line(Vector2(-104 + i * 12.5, -h + 30), Vector2(-104 + i * 12.5, -60), Color("4a6fa5"), 2.0)
	signboard(ci, m, -108, -h, 216, 28, Color("ef6c00"), WHITE, "LOGÍSTICA", 18)
	for i in 3:
		var x := -100 + i * 52.0
		box(ci, m, x, -56, 42, 56, Color("cfd8dc"), false)
		if m == 0:
			for j in 6:
				ci.draw_line(Vector2(x + 2, -50 + j * 9), Vector2(x + 40, -50 + j * 9), Color("90a4ae"), 2.0)
		else:
			ci.draw_rect(Rect2(x, -56, 42, 8), Color(1, 0.85, 0.5, 0.6))
	# caminhão
	if m == 0:
		ci.draw_rect(Rect2(58, -42, 46, 32), OUT)
		ci.draw_rect(Rect2(60, -40, 42, 28), WHITE)
		ci.draw_rect(Rect2(44, -30, 16, 20), OUT)
		ci.draw_rect(Rect2(46, -28, 13, 16), Color("e53935"))
		for x in [52, 92]:
			ci.draw_circle(Vector2(x, -8), 7, OUT)
			ci.draw_circle(Vector2(x, -8), 3, Color("9e9e9e"))


static func _b_usina_solar(ci: CanvasItem, m: int, t: int, h: float, w: float) -> void:
	box(ci, m, -104, -62, 62, 62, Color("f5f5f5"))
	window(ci, m, -96, -50, 22, 18, 27)
	door(ci, m, -68, -40, 20, 40, Color("78909c"))
	flat(ci, m, -104, -62, 62, 8, Color("43a047"))
	for i in 3:
		var x := -34 + i * 44.0
		if m == 0:
			ci.draw_line(Vector2(x + 18, 0), Vector2(x + 18, -24), OUT, 3.0)
		poly(ci, m, [x, -22, x + 40, -38, x + 44, -30, x + 4, -14], Color("1e3a6e"))
		if m == 0:
			for j in 3:
				ci.draw_line(Vector2(x + 10 + j * 10, -18 - j * 4 - 1), Vector2(x + 13 + j * 10, -26 - j * 4 - 1), Color("5c8ae6"), 1.5)
	# torre da turbina (pás animadas em outro nó)
	if m == 0:
		ci.draw_colored_polygon(pv([56, 0, 66, 0, 63, -h + 8, 59, -h + 8]), OUT)
		ci.draw_colored_polygon(pv([58, 0, 64, 0, 62, -h + 8, 60, -h + 8]), WHITE)


static func _b_empresa_tecnologia(ci: CanvasItem, m: int, t: int, h: float, w: float) -> void:
	box(ci, m, 40, -160, 54, 160, WHITE)
	window_grid(ci, m, 42, -150, 92, -60, 2, 3, 14, 18, 28)
	box(ci, m, -94, -h + 30, 134, h - 30, Color("2fa8b9"))
	if m == 0:
		ci.draw_circle(Vector2(-27, -h + 34), 69, OUT)
		ci.draw_circle(Vector2(-27, -h + 34), 66, Color("2fa8b9"))
		ci.draw_rect(Rect2(-100, -h + 34, 146, 80), Color("2fa8b9"))
	glass_grid(ci, m, -86, -h + 40, 32, -54, 4, 24, Color("53c4d3"), 29)
	if m == 0:
		ci.draw_arc(Vector2(-27, -h + 34), 62, PI, TAU, 24, Color("8ee3ef"), 3.0)
	circle(ci, m, Vector2(67, -134), 14, Color("ff4081"))
	if m == 0:
		ci.draw_circle(Vector2(63, -138), 5, Color("ffd740"))
		ci.draw_circle(Vector2(72, -130), 4, Color("40c4ff"))
	signboard(ci, m, -64, -50, 74, 22, Color("263238"), Color("40c4ff"), "TECH", 18)
	glass_door(ci, m, 50, -44, 36, 44)


static func _b_banco(ci: CanvasItem, m: int, t: int, h: float, w: float) -> void:
	var stone := Color("ebe5d8")
	box(ci, m, -86, -172, 172, 172, stone)
	poly(ci, m, [-96, -172, 0, -h, 96, -172], stone.darkened(0.06))
	text(ci, Vector2(-30, -186), "R$", 22, Color("b8860b") if m == 0 else Color(1, 0.85, 0.4), 60)
	box(ci, m, -92, -176, 184, 12, stone.darkened(0.15), false)
	signboard(ci, m, -54, -160, 108, 22, Color("1b5e20"), GOLD, "BANCO", 18)
	for i in 5:
		var x := -74 + i * 34.0
		box(ci, m, x, -132, 14, 116, WHITE)
		flat(ci, m, x - 3, -136, 20, 6, stone.darkened(0.2))
	window(ci, m, -60, -104, 22, 50, 30)
	window(ci, m, 38, -104, 22, 50, 31)
	door(ci, m, -14, -60, 28, 44, Color("5d4037"))
	box(ci, m, -96, -16, 192, 8, stone.darkened(0.12), false)
	box(ci, m, -102, -8, 204, 8, stone.darkened(0.2), false)


static func _b_centro_empresarial(ci: CanvasItem, m: int, t: int, h: float, w: float) -> void:
	var dark := Color("34495e")
	box(ci, m, -98, -h, 82, h, dark)
	box(ci, m, 16, -h + 34, 82, h - 34, dark)
	glass_grid(ci, m, -92, -h + 8, -22, -40, 3, 20, Color("4a6a8a"), 32)
	glass_grid(ci, m, 22, -h + 42, 92, -40, 3, 20, Color("4a6a8a"), 33)
	box(ci, m, -16, -h * 0.55, 32, 22, Color("b0bec5"))
	if m == 0:
		for x in [-57, 57]:
			ci.draw_line(Vector2(x, -h + (0 if x < 0 else 34)), Vector2(x, -h - 36 + (0 if x < 0 else 34)), OUT, 3.0)
	else:
		ci.draw_circle(Vector2(-57, -h - 36), 8, Color(1, 0.3, 0.3, 0.6))
		ci.draw_circle(Vector2(57, -h - 2), 8, Color(1, 0.3, 0.3, 0.6))
	box(ci, m, -98, -40, 196, 40, Color("cfd8dc"), false)
	glass_door(ci, m, -20, -36, 40, 36)
	signboard(ci, m, -92, -34, 64, 18, dark, Color("80d8ff"), "CORP", 13)


static func _b_bolsa_valores(ci: CanvasItem, m: int, t: int, h: float, w: float) -> void:
	var navy := Color("263c55")
	box(ci, m, -82, -h + 50, 164, h - 50, navy)
	glass_grid(ci, m, -76, -h + 56, 70, -150, 5, 22, Color("3c5a7d"), 34)
	circle(ci, m, Vector2(0, -h + 50), 48, GOLD)
	if m == 0:
		ci.draw_rect(Rect2(-52, -h + 50, 104, 6), OUT)
		ci.draw_line(Vector2(0, -h + 2), Vector2(0, -h - 20), OUT, 4.0)
	# letreiro de cotações
	if m == 0:
		ci.draw_rect(Rect2(-86, -146, 172, 30), OUT)
		ci.draw_rect(Rect2(-83, -143, 166, 24), Color("111111"))
	else:
		ci.draw_rect(Rect2(-90, -150, 180, 38), Color(0.3, 1, 0.5, 0.18))
	text(ci, Vector2(-83, -125), "IDC +2,4%  CTY +1,8%", 13, Color("69f0ae") if m == 1 else Color("2e7d32"), 166)
	box(ci, m, -82, -116, 164, 116, Color("eceff1"))
	for i in 4:
		box(ci, m, -70 + i * 40, -100, 14, 100, WHITE, false)
	signboard(ci, m, -60, -114, 120, 18, navy, GOLD, "BOLSA", 14)
	door(ci, m, -14, -50, 28, 50, Color("455a64"))


# =============================================================================
# Serviços públicos
# =============================================================================

static func _cross(ci: CanvasItem, m: int, c: Vector2, s: float, col: Color) -> void:
	if m == 0:
		ci.draw_rect(Rect2(c.x - s * 0.5 - 3, c.y - s * 1.5 - 3, s + 6, s * 3 + 6), OUT)
		ci.draw_rect(Rect2(c.x - s * 1.5 - 3, c.y - s * 0.5 - 3, s * 3 + 6, s + 6), OUT)
	var cc := col if m == 0 else col.lightened(0.3)
	if m == 1:
		ci.draw_circle(c, s * 2.6, Color(col, 0.25))
	ci.draw_rect(Rect2(c.x - s * 0.5, c.y - s * 1.5, s, s * 3), cc)
	ci.draw_rect(Rect2(c.x - s * 1.5, c.y - s * 0.5, s * 3, s), cc)


static func _b_escola(ci: CanvasItem, m: int, t: int, h: float, w: float) -> void:
	var body := Color("f2b84b")
	box(ci, m, -96, -124, 192, 124, body)
	poly(ci, m, [-40, -122, 0, -152, 40, -122], body.darkened(0.12))
	circle(ci, m, Vector2(0, -132), 11, WHITE)
	if m == 0:
		ci.draw_line(Vector2(0, -132), Vector2(0, -139), OUT, 2.0)
		ci.draw_line(Vector2(0, -132), Vector2(5, -132), OUT, 2.0)
	window_grid(ci, m, -94, -116, -26, -10, 2, 2, 22, 30, 35)
	window_grid(ci, m, 26, -116, 94, -10, 2, 2, 22, 30, 36)
	signboard(ci, m, -32, -116, 64, 20, Color("1565c0"), WHITE, "ESCOLA", 14)
	door(ci, m, -18, -54, 36, 54, Color("1565c0"))
	if m == 0:
		ci.draw_line(Vector2(-104, 0), Vector2(-104, -h), OUT, 3.0)
		ci.draw_colored_polygon(pv([-103, -h, -78, -h + 8, -103, -h + 16]), Color("43a047"))


static func _b_biblioteca(ci: CanvasItem, m: int, t: int, h: float, w: float) -> void:
	var stone := Color("dcd1bf")
	box(ci, m, -82, -118, 164, 118, stone)
	poly(ci, m, [-90, -116, 0, -h, 90, -116], stone.darkened(0.08))
	if m == 0:
		ci.draw_colored_polygon(pv([-16, -128, 0, -124, 0, -140, -16, -144]), WHITE)
		ci.draw_colored_polygon(pv([16, -128, 0, -124, 0, -140, 16, -144]), Color("f5f5f5"))
		ci.draw_line(Vector2(0, -124), Vector2(0, -140), OUT, 2.0)
	signboard(ci, m, -60, -114, 120, 20, Color("6d4c41"), Color("ffe0b2"), "BIBLIOTECA", 14)
	for i in 4:
		box(ci, m, -66 + i * 40, -88, 12, 80, WHITE, false)
	window(ci, m, -46, -78, 22, 40, 37)
	window(ci, m, 24, -78, 22, 40, 38)
	door(ci, m, -10, -48, 20, 40, Color("6d4c41"))
	box(ci, m, -88, -8, 176, 8, stone.darkened(0.15), false)


static func _b_universidade(ci: CanvasItem, m: int, t: int, h: float, w: float) -> void:
	var sand := Color("d7b48e")
	box(ci, m, -26, -228, 52, 80, sand.darkened(0.05))
	circle(ci, m, Vector2(0, -228), 26, Color("5c8a72"))
	if m == 0:
		ci.draw_rect(Rect2(-29, -230, 58, 6), OUT)
		ci.draw_line(Vector2(0, -254), Vector2(0, -h), OUT, 3.0)
	circle(ci, m, Vector2(0, -192), 13, WHITE)
	box(ci, m, -108, -150, 216, 150, sand)
	for r in 2:
		for c in 6:
			var x := -98 + c * 34.0
			var y := -136 + r * 56.0
			window(ci, m, x, y, 20, 32, 39)
			if m == 0:
				ci.draw_circle(Vector2(x + 10, y), 12, OUT)
				ci.draw_circle(Vector2(x + 10, y), 9.5, GLASS)
	signboard(ci, m, -66, -76, 132, 20, Color("4e342e"), Color("ffe0b2"), "UNIVERSIDADE", 13)
	door(ci, m, -16, -50, 32, 50, Color("4e342e"))


static func _b_hospital(ci: CanvasItem, m: int, t: int, h: float, w: float) -> void:
	box(ci, m, -92, -h + 20, 184, h - 20, WHITE)
	flat(ci, m, -92, -h + 20, 184, 10, Color("4fc3f7"))
	signboard(ci, m, -44, -h, 88, 22, WHITE, Color("1e88e5"), "HOSPITAL", 15)
	_cross(ci, m, Vector2(-60, -h + 52), 10, Color("e53935"))
	var rows := int((h - 110) / 32.0)
	window_grid(ci, m, -38, -h + 34, 88, -h + 34 + rows * 32, 4, rows, 20, 18, 40)
	window_grid(ci, m, -88, -h + 80, -36, -h + 80 + maxi(rows - 1, 1) * 32, 2, maxi(rows - 1, 1), 18, 18, 41)
	box(ci, m, -60, -62, 120, 10, Color("1e88e5"), false)
	glass_door(ci, m, -26, -50, 52, 50)
	flat(ci, m, -92, -8, 184, 8, Color("b0bec5"))


static func _b_centro_medico(ci: CanvasItem, m: int, t: int, h: float, w: float) -> void:
	box(ci, m, -96, -h + 24, 150, h - 24, Color("f3fbfb"))
	box(ci, m, 54, -150, 44, 150, Color("26a69a"))
	glass_grid(ci, m, -88, -h + 34, 44, -70, 4, 24, Color("b2ebf2"), 42)
	window_grid(ci, m, 56, -140, 96, -60, 1, 3, 20, 18, 43)
	# heliponto
	if m == 0:
		ci.draw_rect(Rect2(-86, -h + 14, 130, 10), OUT)
		ci.draw_rect(Rect2(-84, -h + 16, 126, 6), Color("455a64"))
	text(ci, Vector2(-80, -h + 12), "H", 20, Color("ffca28"), 114)
	_cross(ci, m, Vector2(76, -170), 9, Color("2e7d32"))
	signboard(ci, m, -80, -66, 120, 18, Color("00897b"), WHITE, "CENTRO MÉDICO", 12)
	glass_door(ci, m, -40, -44, 48, 44)


static func _b_complexo_hospitalar(ci: CanvasItem, m: int, t: int, h: float, w: float) -> void:
	box(ci, m, -102, -h * 0.62, 70, h * 0.62, Color("e8f5e9"))
	window_grid(ci, m, -98, -h * 0.62 + 10, -36, -50, 2, int(h * 0.62 / 32), 18, 18, 44)
	box(ci, m, -28, -h + 30, 128, h - 30, WHITE)
	if m == 0:
		ci.draw_circle(Vector2(36, -h + 32), 66, OUT)
		ci.draw_circle(Vector2(36, -h + 32), 63, WHITE)
		ci.draw_rect(Rect2(-25, -h + 32, 122, 60), WHITE)
	glass_grid(ci, m, -20, -h + 50, 92, -50, 4, 22, Color("c8e6c9"), 45)
	_cross(ci, m, Vector2(36, -h + 4), 12, Color("43a047"))
	box(ci, m, -36, -h * 0.45, 12, 20, Color("a5d6a7"), false)
	signboard(ci, m, -14, -48, 100, 18, Color("2e7d32"), WHITE, "COMPLEXO", 13)
	glass_door(ci, m, 16, -28, 40, 28)


static func _b_delegacia(ci: CanvasItem, m: int, t: int, h: float, w: float) -> void:
	box(ci, m, -82, -136, 164, 136, WHITE)
	flat(ci, m, -82, -136, 164, 40, Color("2f5fa8"))
	signboard(ci, m, -48, -128, 96, 24, Color("1a3f7a"), WHITE, "POLÍCIA", 16)
	# sirene
	box(ci, m, -14, -h + 6, 12, 10, Color("e53935"), false)
	box(ci, m, 2, -h + 6, 12, 10, Color("1e88e5"), false)
	if m == 1:
		ci.draw_circle(Vector2(-8, -h + 11), 16, Color(1, 0.2, 0.2, 0.45))
		ci.draw_circle(Vector2(8, -h + 11), 16, Color(0.2, 0.5, 1, 0.45))
	if m == 0:
		ci.draw_rect(Rect2(-20, -h + 16, 40, 4), OUT)
	window_grid(ci, m, -82, -92, -22, -20, 2, 2, 18, 22, 46)
	window_grid(ci, m, 22, -92, 82, -20, 2, 2, 18, 22, 47)
	door(ci, m, -14, -52, 28, 52, Color("2f5fa8"))
	flat(ci, m, -82, -8, 164, 8, Color("90a4ae"))


static func _b_bombeiros(ci: CanvasItem, m: int, t: int, h: float, w: float) -> void:
	var red := Color("c0392b")
	box(ci, m, 54, -h, 42, h, red.darkened(0.1))
	window_grid(ci, m, 56, -h + 10, 94, -100, 1, 3, 18, 18, 48)
	box(ci, m, -98, -124, 152, 124, red)
	signboard(ci, m, -86, -118, 128, 22, WHITE, red, "BOMBEIROS", 15)
	for i in 2:
		var x := -88 + i * 68.0
		if m == 0:
			ci.draw_rect(Rect2(x - 3, -84, 64, 84), OUT)
			ci.draw_circle(Vector2(x + 29, -60), 32, OUT)
			ci.draw_rect(Rect2(x, -60, 58, 60), Color("eceff1"))
			ci.draw_circle(Vector2(x + 29, -60), 29, Color("eceff1"))
			if i == 0:
				ci.draw_rect(Rect2(x + 6, -40, 46, 34), Color("e53935"))
				ci.draw_rect(Rect2(x + 10, -36, 18, 12), GLASS)
				ci.draw_circle(Vector2(x + 16, -6), 6, OUT)
				ci.draw_circle(Vector2(x + 42, -6), 6, OUT)
			else:
				for j in 6:
					ci.draw_line(Vector2(x, -80 + j * 13), Vector2(x + 58, -80 + j * 13), Color("b0bec5"), 2.0)
		else:
			ci.draw_rect(Rect2(x, -60, 58, 60), Color(1, 0.8, 0.5, 0.35))


static func _b_central_seguranca(ci: CanvasItem, m: int, t: int, h: float, w: float) -> void:
	var navy := Color("2d4a7a")
	box(ci, m, -86, -h + 40, 172, h - 40, navy)
	if m == 0:
		ci.draw_line(Vector2(0, -h + 40), Vector2(0, -h + 14), OUT, 5.0)
		ci.draw_arc(Vector2(0, -h + 14), 30, PI + 0.3, TAU - 0.3, 20, OUT, 8.0)
		ci.draw_arc(Vector2(0, -h + 14), 30, PI + 0.3, TAU - 0.3, 20, Color("cfd8dc"), 5.0)
	var rows := int((h - 110) / 26.0)
	for r in rows:
		var y := -h + 52 + r * 26.0
		if m == 0:
			ci.draw_rect(Rect2(-78, y, 156, 14), Color("1d3357"))
		elif r % 3 != 1:
			ci.draw_rect(Rect2(-78, y, 156, 14), Color(0.4, 0.95, 1.0, 0.75))
	box(ci, m, -86, -56, 172, 56, Color("cfd8dc"), false)
	signboard(ci, m, -66, -54, 132, 18, navy, Color("80d8ff"), "SEGURANÇA", 13)
	glass_door(ci, m, -22, -32, 44, 32)


static func _b_prefeitura(ci: CanvasItem, m: int, t: int, h: float, w: float) -> void:
	var stone := Color("f1ede2")
	box(ci, m, -36, -178, 72, 40, stone.darkened(0.04))
	circle(ci, m, Vector2(0, -158), 12, WHITE)
	if m == 0:
		ci.draw_line(Vector2(0, -158), Vector2(0, -166), OUT, 2.0)
		ci.draw_line(Vector2(0, -158), Vector2(6, -158), OUT, 2.0)
	circle(ci, m, Vector2(0, -178), 36, Color("5b8db8"))
	if m == 0:
		ci.draw_rect(Rect2(-40, -180, 80, 6), OUT)
		ci.draw_line(Vector2(0, -214), Vector2(0, -h), OUT, 3.0)
		ci.draw_colored_polygon(pv([1, -h, 26, -h + 7, 1, -h + 14]), Color("2e7d32"))
		ci.draw_circle(Vector2(10, -h + 7), 3, Color("ffd600"))
	box(ci, m, -106, -142, 212, 142, stone)
	poly(ci, m, [-60, -142, 0, -170, 60, -142], stone.darkened(0.08))
	signboard(ci, m, -66, -136, 132, 20, Color("2e4a7d"), GOLD, "PREFEITURA", 15)
	for i in 6:
		box(ci, m, -86 + i * 32, -108, 12, 92, WHITE, false)
	window(ci, m, -70, -96, 16, 40, 49)
	window(ci, m, 54, -96, 16, 40, 50)
	door(ci, m, -14, -56, 28, 40, Color("6d4c41"))
	box(ci, m, -112, -16, 224, 8, stone.darkened(0.12), false)
	box(ci, m, -116, -8, 232, 8, stone.darkened(0.2), false)


# =============================================================================
# Lazer
# =============================================================================

static func _lamp(ci: CanvasItem, m: int, x: float, hgt: float) -> void:
	if m == 0:
		ci.draw_line(Vector2(x, 0), Vector2(x, -hgt), OUT, 4.0)
		ci.draw_circle(Vector2(x, -hgt), 6, OUT)
		ci.draw_circle(Vector2(x, -hgt), 4, Color("fff9c4"))
	else:
		ci.draw_circle(Vector2(x, -hgt), 18, Color(1, 0.9, 0.5, 0.35))
		ci.draw_circle(Vector2(x, -hgt), 5, Color(1, 0.95, 0.7))


static func _b_parque(ci: CanvasItem, m: int, t: int, h: float, w: float) -> void:
	if m == 0:
		ci.draw_rect(Rect2(-110, -10, 220, 10), Color("66bb6a"))
		ci.draw_rect(Rect2(-40, -6, 80, 6), Color("d7ccc8"))
	tree(ci, m, -84, -4, 1.25, Color("43a047"))
	tree(ci, m, 84, -4, 1.1, Color("2e7d32"))
	# pinheiro
	poly(ci, m, [-48, -20, -30, -78, -12, -20], Color("388e3c"))
	# fonte
	if m == 0:
		ci.draw_rect(Rect2(-6, -38, 12, 30), OUT)
		ci.draw_rect(Rect2(-4, -38, 8, 30), Color("b0bec5"))
		ci.draw_arc(Vector2(-14, -38), 14, PI, TAU, 12, Color("81d4fa"), 3.0)
		ci.draw_arc(Vector2(14, -38), 14, PI, TAU, 12, Color("81d4fa"), 3.0)
		ci.draw_rect(Rect2(-34, -16, 68, 14), OUT)
		ci.draw_rect(Rect2(-31, -13, 62, 10), Color("4fc3f7"))
		# banco
		ci.draw_rect(Rect2(40, -22, 30, 5), Color("8d6e63"))
		ci.draw_rect(Rect2(40, -30, 30, 4), Color("8d6e63"))
		ci.draw_line(Vector2(43, -17), Vector2(43, -8), OUT, 2.0)
		ci.draw_line(Vector2(67, -17), Vector2(67, -8), OUT, 2.0)
	_lamp(ci, m, 30, 70)
	bush(ci, m, -110, 0, 30, Color("66bb6a"), Color("ffeb3b"))


static func _b_academia(ci: CanvasItem, m: int, t: int, h: float, w: float) -> void:
	box(ci, m, -82, -h + 16, 164, h - 16, Color("37474f"))
	signboard(ci, m, -64, -h, 128, 26, Color("aeea00"), Color("263238"), "ACADEMIA", 17)
	window(ci, m, -72, -116, 144, 48, 51)
	window(ci, m, -72, -58, 92, 48, 52)
	if m == 0:
		for i in 3:
			var x := -52 + i * 46.0
			ci.draw_rect(Rect2(x, -95, 24, 4), OUT)
			ci.draw_rect(Rect2(x - 4, -101, 6, 16), OUT)
			ci.draw_rect(Rect2(x + 22, -101, 6, 16), OUT)
	glass_door(ci, m, 32, -56, 40, 56)


static func _b_cinema(ci: CanvasItem, m: int, t: int, h: float, w: float) -> void:
	var purple := Color("7b3fa0")
	box(ci, m, -86, -150, 172, 150, purple)
	box(ci, m, -18, -h, 36, 50, purple.darkened(0.15))
	text(ci, Vector2(-18, -h + 30), "*", 26, GOLD, 36)
	if m == 0:
		ci.draw_rect(Rect2(-80, -106, 160, 40), OUT)
		ci.draw_rect(Rect2(-77, -103, 154, 34), Color("fff8e1"))
	else:
		ci.draw_rect(Rect2(-86, -112, 172, 52), Color(1, 0.9, 0.5, 0.3))
	text(ci, Vector2(-77, -77), "CINEMA", 24, Color("c62828") if m == 0 else Color("ff8a80"), 154)
	for i in 14:
		var bx := -76 + i * 11.7
		if m == 0:
			ci.draw_circle(Vector2(bx + 6, -108), 2.5, Color("ffe082"))
		else:
			ci.draw_circle(Vector2(bx + 6, -108), 4, Color(1, 0.95, 0.6))
	for x in [-74, 42]:
		box(ci, m, x, -58, 32, 46, Color("fff8e1"), false)
		flat(ci, m, x + 4, -54, 24, 38, Color("e57373") if x < 0 else Color("64b5f6"))
	glass_door(ci, m, -22, -54, 44, 54)


static func _b_centro_entretenimento(ci: CanvasItem, m: int, t: int, h: float, w: float) -> void:
	var coral := Color("ff7f50")
	box(ci, m, -102, -h + 30, 204, h - 30, coral)
	poly(ci, m, [-102, -h + 30, -60, -h, 60, -h, 102, -h + 30], Color("ffb74d"))
	# telão
	if m == 0:
		ci.draw_rect(Rect2(-80, -h + 40, 160, 72), OUT)
		var cols := [Color("e91e63"), Color("9c27b0"), Color("3f51b5"), Color("00bcd4"), Color("8bc34a"), Color("ffeb3b")]
		for i in 6:
			ci.draw_rect(Rect2(-77 + i * 25.7, -h + 43, 25.7, 66), cols[i])
	else:
		ci.draw_rect(Rect2(-86, -h + 34, 172, 84), Color(0.9, 0.5, 1.0, 0.35))
		ci.draw_rect(Rect2(-77, -h + 43, 154, 66), Color(1, 0.8, 1.0, 0.7))
	signboard(ci, m, -86, -84, 172, 22, Color("4a148c"), Color("ffeb3b"), "ENTRETENIMENTO", 13)
	for i in 3:
		var x := -78 + i * 56.0
		if m == 0:
			ci.draw_circle(Vector2(x + 20, -42), 23, OUT)
			ci.draw_rect(Rect2(x - 3, -42, 46, 42), OUT)
			ci.draw_circle(Vector2(x + 20, -42), 20, GLASS_D)
			ci.draw_rect(Rect2(x, -42, 40, 42), GLASS_D)
		else:
			ci.draw_rect(Rect2(x, -42, 40, 42), Color(1, 0.85, 0.5, 0.6))


static func _b_estadio(ci: CanvasItem, m: int, t: int, h: float, w: float) -> void:
	for x in [-106, 106]:
		if m == 0:
			ci.draw_line(Vector2(x, -96), Vector2(x, -h + 14), OUT, 5.0)
			ci.draw_rect(Rect2(x - 15, -h, 30, 18), OUT)
			ci.draw_rect(Rect2(x - 12, -h + 3, 24, 12), Color("fff9c4"))
		else:
			ci.draw_circle(Vector2(x, -h + 9), 34, Color(1, 1, 0.8, 0.35))
			ci.draw_rect(Rect2(x - 12, -h + 3, 24, 12), Color(1, 1, 0.85))
	poly(ci, m, [-112, 0, -100, -112, 100, -112, 112, 0], Color("eceff1"))
	poly(ci, m, [-108, -112, -86, -134, 86, -134, 108, -112], Color("1e88e5"))
	if m == 0:
		var seat_cols := [Color("e53935"), Color("fdd835"), Color("43a047")]
		for i in 3:
			ci.draw_rect(Rect2(-98 + i * 2, -104 + i * 18, 196 - i * 4, 12), seat_cols[i])
		for i in 9:
			ci.draw_line(Vector2(-90 + i * 22.5, -50), Vector2(-90 + i * 22.5, -2), Color("b0bec5"), 3.0)
	signboard(ci, m, -50, -48, 100, 22, Color("0d47a1"), WHITE, "ESTÁDIO", 15)
	if m == 1:
		ci.draw_rect(Rect2(-96, -110, 192, 60), Color(1, 1, 0.85, 0.2))


static func _b_parque_diversoes(ci: CanvasItem, m: int, t: int, h: float, w: float) -> void:
	# estrutura da roda-gigante (a roda gira em um nó animado)
	if m == 0:
		ci.draw_line(Vector2(-40, -150), Vector2(-90, 0), OUT, 6.0)
		ci.draw_line(Vector2(-40, -150), Vector2(10, 0), OUT, 6.0)
		ci.draw_line(Vector2(-40, -150), Vector2(-90, 0), Color("b0bec5"), 3.0)
		ci.draw_line(Vector2(-40, -150), Vector2(10, 0), Color("b0bec5"), 3.0)
		# montanha-russa
		var track := PackedVector2Array()
		for i in 25:
			var x := 20.0 + i * 4.0
			track.append(Vector2(x, -60 - sin(i * 0.5) * 40 - i * 1.5))
		ci.draw_polyline(track, OUT, 6.0, true)
		ci.draw_polyline(track, Color("e53935"), 3.0, true)
		for i in range(0, 25, 4):
			ci.draw_line(track[i], Vector2(track[i].x, 0), Color("90a4ae"), 2.0)
	# tenda
	poly(ci, m, [50, -50, 82, -96, 114, -50], Color("e53935"))
	if m == 0:
		ci.draw_colored_polygon(pv([66, -50, 82, -96, 74, -50]), WHITE)
		ci.draw_colored_polygon(pv([90, -50, 82, -96, 98, -50]), WHITE)
	box(ci, m, 52, -50, 60, 50, Color("ffeb3b"))
	door(ci, m, 72, -32, 20, 32, Color("8e24aa"))
	if m == 1:
		ci.draw_circle(Vector2(82, -96), 12, Color(1, 0.9, 0.5, 0.5))
	signboard(ci, m, -104, -26, 84, 18, Color("8e24aa"), Color("ffeb3b"), "DIVERSÕES", 12)
