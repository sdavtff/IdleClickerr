class_name StatsPanel
extends ModalPanel
## Painel da cidade: economia, população e detalhamento da felicidade.

var _labels := {}
var _bars: Array = []


func _init() -> void:
	super()
	title = "Painel da cidade"
	icon_name = "income"
	desired_size = Vector2(1060, 680)


func _ready() -> void:
	super()
	set_tabs(["Economia", "População", "Felicidade", "Qualidade de vida"])


func rebuild() -> void:
	UI.clear(list.content)
	_labels.clear()
	_bars.clear()
	match current_tab:
		0:
			for k in ["money", "income", "business", "tax", "expense", "net", "eff", "happy_mult", "global", "earned"]:
				_add_line(k)
			list.content.add_child(_hint("Dica: comércios e empresas precisam de trabalhadores. Se a população for menor que os empregos, a eficiência cai."))
		1:
			for k in ["pop", "cap", "target", "growth", "jobs", "unemp"]:
				_add_line(k)
			list.content.add_child(UI.label("Necessidades dos moradores", 22, UI.C_TEXT, true))
			for n in PopulationSystem.needs():
				var c := UI.card()
				list.content.add_child(c)
				var h := UI.hbox(12)
				c.add_child(h)
				var nl := UI.label(n["name"], 20, UI.C_TEXT, true)
				nl.custom_minimum_size = Vector2(150, 0)
				h.add_child(nl)
				var bar := UI.progress(n["value"], 1.0)
				bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
				h.add_child(bar)
				var hl := UI.label(n["hint"], 15, UI.C_MUTED)
				hl.custom_minimum_size = Vector2(330, 0)
				h.add_child(hl)
				_bars.append({"need": n["name"], "bar": bar})
			list.content.add_child(_hint("A felicidade define quantos moradores aceitam viver na cidade: com 50% ou mais todas as casas ficam ocupadas, e quanto mais feliz, mais rápido ela cresce."))
		2:
			_add_line("happy")
			for f in HappinessSystem.factors:
				var c := UI.card()
				list.content.add_child(c)
				var h := UI.hbox(12)
				c.add_child(h)
				var name_l := UI.label(f["name"], 20, UI.C_TEXT, true)
				name_l.custom_minimum_size = Vector2(170, 0)
				h.add_child(name_l)
				var bar := UI.progress(maxf(0.0, f["value"]), maxf(1.0, f["max"]), UI.C_GREEN if f["value"] >= 0 else UI.C_RED)
				bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
				h.add_child(bar)
				var val := UI.label("", 20, UI.C_TEXT, true)
				val.custom_minimum_size = Vector2(130, 0)
				val.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
				h.add_child(val)
				_bars.append({"name": f["name"], "bar": bar, "label": val})
			list.content.add_child(_hint("Construa hospitais, escolas, delegacias e áreas de lazer para atender toda a população. Fábricas poluem; usinas solares limpam o ar."))
		3:
			for k in ["qol", "traffic", "transit", "pollution", "productivity"]:
				_add_line(k)
			for key in [["pop", "População", UI.C_BLUE], ["happy", "Felicidade (%)", UI.C_GREEN], ["traffic", "Trânsito (%)", UI.C_ORANGE]]:
				var chart := HistoryChart.new()
				chart.key = key[0]
				chart.title = key[1]
				chart.color = key[2]
				chart.custom_minimum_size = Vector2(0, 150)
				list.content.add_child(chart)
			list.content.add_child(_hint("Trânsito: construa terminais de ônibus, metrô e aeroporto, ou pesquise Linhas de ônibus. Poluição: usinas solares, reciclagem e pesquisas de energia. Escolas aumentam a produtividade."))
	refresh()


class HistoryChart extends Control:
	var key := "pop"
	var title := ""
	var color := Color.WHITE

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		draw_rect(r, Color("f4f7fb"))
		draw_rect(r, Color("d0d7e2"), false, 2.0)
		var hist: Array = EconomySystem.history.filter(func(h): return h.has(key))
		draw_string(UI.font_semi, Vector2(10, 22), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 17, UI.C_TEXT)
		if hist.size() < 2:
			draw_string(UI.font_semi, Vector2(0, size.y * 0.6), "O gráfico aparece após alguns minutos de jogo.", HORIZONTAL_ALIGNMENT_CENTER, size.x, 16, UI.C_MUTED)
			return
		var max_v := 1.0
		for h in hist:
			max_v = maxf(max_v, float(h[key]))
		var pts := PackedVector2Array()
		for i in hist.size():
			pts.append(Vector2(10.0 + (size.x - 20.0) * i / float(hist.size() - 1), size.y - 12.0 - (size.y - 44.0) * float(hist[i][key]) / max_v))
		draw_polyline(pts, color, 3.0, true)
		draw_string(UI.font_semi, Vector2(size.x - 230, 22), "Atual: %s" % Fmt.num(float(hist[-1][key])), HORIZONTAL_ALIGNMENT_RIGHT, 220, 16, UI.C_MUTED)


func _hint(t: String) -> Control:
	var l := UI.label(t, 17, UI.C_MUTED)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(600, 0)
	return l


func _add_line(key: String) -> void:
	var h := UI.hbox(10)
	list.content.add_child(h)
	var name_l := UI.label("", 21, UI.C_MUTED)
	name_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(name_l)
	var val := UI.label("", 22, UI.C_TEXT, true)
	h.add_child(val)
	_labels[key] = [name_l, val]


func _put(key: String, title_text: String, value: String) -> void:
	if _labels.has(key):
		_labels[key][0].text = title_text
		_labels[key][1].text = value


func refresh() -> void:
	if not visible:
		return
	var e := EconomySystem
	var ci := CityIndexSystem
	_put("qol", "Qualidade de vida (nota %s)" % ci.grade(), Fmt.percent(ci.quality_of_life))
	_put("traffic", "Trânsito: " + ci.traffic_label(), Fmt.percent(ci.traffic))
	_put("transit", "Deslocamentos / capacidade de transporte", "%s / %s" % [Fmt.pop(ci.commuters), Fmt.pop(ci.transit_capacity)])
	_put("pollution", "Poluição", Fmt.percent(ci.pollution))
	_put("productivity", "Produtividade (educação e trânsito)", "x" + Fmt.num(ci.productivity))
	_put("money", "Dinheiro atual", Fmt.money(e.money))
	_put("income", "Renda bruta", Fmt.money_ps(e.income_ps))
	_put("business", "    Comércios, empresas e lazer", Fmt.money_ps(e.business_income))
	_put("tax", "    Impostos dos moradores", Fmt.money_ps(e.tax_income))
	_put("expense", "Despesas (manutenção de serviços)", "-" + Fmt.money_ps(e.expense_ps))
	_put("net", "Lucro líquido", Fmt.money_ps(e.net_ps))
	_put("eff", "Eficiência dos trabalhadores", Fmt.percent(e.work_efficiency * 100))
	_put("happy_mult", "Multiplicador de felicidade", "x" + Fmt.num(e.happiness_mult))
	_put("global", "Multiplicadores (prestígio, missões, conquistas, prefeitura)", "x" + Fmt.num(e.global_mult))
	_put("earned", "Total ganho nesta cidade", Fmt.money(e.total_earned))
	var p := PopulationSystem
	_put("pop", "População", Fmt.pop(p.population))
	_put("cap", "Capacidade habitacional", Fmt.pop(p.capacity))
	_put("target", "Moradores dispostos a viver aqui", Fmt.pop(p.target))
	_put("growth", "Crescimento", ("+" if p.growth_per_sec >= 0 else "") + Fmt.num(p.growth_per_sec) + " /s")
	_put("jobs", "Vagas de emprego", Fmt.pop(p.jobs))
	_put("unemp", "Desemprego", "%s (%s)" % [Fmt.pop(p.unemployed()), Fmt.percent(p.unemployment_rate() * 100)])
	for b in _bars:
		if b.has("need"):
			for n in p.needs():
				if n["name"] == b["need"]:
					b["bar"].value = n["value"]
					var col := UI.C_GREEN if n["value"] >= 0.8 else (UI.C_ORANGE if n["value"] >= 0.4 else UI.C_RED)
					b["bar"].add_theme_stylebox_override("fill", UI.style(col, 9))
	_put("happy", "Felicidade: " + HappinessSystem.label(), Fmt.percent(HappinessSystem.value))
	for b in _bars:
		if b.has("need"):
			continue
		for f in HappinessSystem.factors:
			if f["name"] == b["name"]:
				b["bar"].max_value = maxf(1.0, f["max"])
				b["bar"].value = maxf(0.0, f["value"]) if f["value"] >= 0 else minf(20.0, -f["value"])
				b["label"].text = ("+" if f["value"] >= 0 else "") + Fmt.num(f["value"]) + (" / %d" % int(f["max"]) if f["max"] > 0 else "")
