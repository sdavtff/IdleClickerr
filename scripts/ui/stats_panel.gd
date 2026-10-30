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
	set_tabs(["Economia", "População", "Felicidade"])


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
			for k in ["pop", "cap", "target", "growth", "jobs", "ratio"]:
				_add_line(k)
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
	refresh()


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
	_put("ratio", "Trabalhadores por vaga", Fmt.percent(minf(9.99, p.available_jobs_ratio()) * 100))
	_put("happy", "Felicidade: " + HappinessSystem.label(), Fmt.percent(HappinessSystem.value))
	for b in _bars:
		for f in HappinessSystem.factors:
			if f["name"] == b["name"]:
				b["bar"].max_value = maxf(1.0, f["max"])
				b["bar"].value = maxf(0.0, f["value"]) if f["value"] >= 0 else minf(20.0, -f["value"])
				b["label"].text = ("+" if f["value"] >= 0 else "") + Fmt.num(f["value"]) + (" / %d" % int(f["max"]) if f["max"] > 0 else "")
