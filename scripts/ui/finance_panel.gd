class_name FinancePanel
extends ModalPanel
## Painel financeiro: receitas por categoria, impostos, banco (investimentos e
## empréstimos), relatório e histórico de ganhos e gastos.

const CAT_LABELS := {"res": "Impostos residenciais", "com": "Comércio", "biz": "Empresas e indústria", "fun": "Lazer", "esp": "Especiais", "pub": "Serviços públicos"}
const LEDGER_LABELS := {
	"ops": ["Renda da cidade", true], "rewards": ["Recompensas", true], "invest": ["Resgates de investimentos", true],
	"loan_in": ["Empréstimos recebidos", true], "build": ["Construções", false], "upgrade": ["Melhorias", false],
	"expansion": ["Expansões", false], "accelerate": ["Obras aceleradas", false], "upkeep": ["Manutenção", false],
	"loan_out": ["Pagamento de empréstimos", false], "invest_out": ["Aplicações em investimentos", false],
}

var _labels := {}
var _tax_buttons: Array[Button] = []
var _inv_rows: Array = []
var _loan_l: Label
var _loan_take: Button
var _loan_pay: Button
var _chart: Control
var _amount_index := 1
var _amount_buttons: Array[Button] = []
const AMOUNTS := [0.1, 0.25, 0.5, 1.0]


class Chart extends Control:
	func _draw() -> void:
		var hist: Array = EconomySystem.history
		var r := Rect2(Vector2.ZERO, size)
		draw_rect(r, Color("f4f7fb"))
		draw_rect(r, Color("d0d7e2"), false, 2.0)
		if hist.size() < 2:
			draw_string(UI.font_semi, Vector2(0, size.y * 0.5), "O histórico aparece após alguns minutos de jogo.", HORIZONTAL_ALIGNMENT_CENTER, size.x, 18, UI.C_MUTED)
			return
		var max_v := 1.0
		for hpt in hist:
			max_v = maxf(max_v, maxf(float(hpt["income"]), float(hpt["expense"])))
		for key in [["income", UI.C_GREEN], ["expense", UI.C_RED]]:
			var pts := PackedVector2Array()
			for i in hist.size():
				var x := 10.0 + (size.x - 20.0) * i / float(hist.size() - 1)
				var y := size.y - 24.0 - (size.y - 44.0) * float(hist[i][key[0]]) / max_v
				pts.append(Vector2(x, y))
			draw_polyline(pts, key[1], 3.0, true)
		draw_string(UI.font_semi, Vector2(12, 20), "Máx: " + Fmt.money_ps(max_v), HORIZONTAL_ALIGNMENT_LEFT, -1, 15, UI.C_MUTED)
		draw_string(UI.font_semi, Vector2(12, size.y - 6), "Últimos %d min" % int(hist.size() * EconomySystem.HISTORY_INTERVAL / 60.0), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, UI.C_MUTED)
		draw_string(UI.font_semi, Vector2(size.x - 260, 20), "— Receitas", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, UI.C_GREEN)
		draw_string(UI.font_semi, Vector2(size.x - 140, 20), "— Despesas", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, UI.C_RED)


func _init() -> void:
	super()
	title = "Finanças"
	icon_name = "bank"
	desired_size = Vector2(1100, 690)


func _ready() -> void:
	super()
	set_tabs(["Resumo", "Banco da cidade", "Relatório"])


func rebuild() -> void:
	UI.clear(list.content)
	_labels.clear()
	_tax_buttons.clear()
	_inv_rows.clear()
	_amount_buttons.clear()
	_chart = null
	match current_tab:
		0:
			_build_summary()
		1:
			_build_bank()
		2:
			_build_report()
	refresh()


func _line(parent: Control, key: String, size := 20, bold := false) -> void:
	var h := UI.hbox(10)
	parent.add_child(h)
	var n := UI.label("", size, UI.C_MUTED, bold)
	n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(n)
	var v := UI.label("", size, UI.C_TEXT, true)
	h.add_child(v)
	_labels[key] = [n, v]


func _put(key: String, name_text: String, value: String, col := UI.C_TEXT) -> void:
	if _labels.has(key):
		_labels[key][0].text = name_text
		_labels[key][1].text = value
		_labels[key][1].add_theme_color_override("font_color", col)


func _build_summary() -> void:
	var cols := UI.hbox(14)
	list.content.add_child(cols)
	var left := UI.card()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cols.add_child(left)
	var lv := UI.vbox(6)
	left.add_child(lv)
	lv.add_child(UI.label("Receitas por categoria", 22, UI.C_TEXT, true))
	for c in ["res", "com", "biz", "fun", "esp"]:
		_line(lv, "in_" + c, 19)
	_line(lv, "income", 21, true)
	var right := UI.card()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cols.add_child(right)
	var rv := UI.vbox(6)
	right.add_child(rv)
	rv.add_child(UI.label("Despesas", 22, UI.C_TEXT, true))
	for c in ["pub", "fun", "esp", "biz"]:
		_line(rv, "up_" + c, 19)
	_line(rv, "loanpay", 19)
	_line(rv, "expense", 21, true)
	_line(rv, "net", 23, true)
	var tax := UI.card(Color("eef7ee"))
	list.content.add_child(tax)
	var tv := UI.vbox(8)
	tax.add_child(tv)
	tv.add_child(UI.label("Impostos residenciais", 22, UI.C_TEXT, true))
	tv.add_child(UI.label("Impostos mais altos aumentam a arrecadação, mas deixam os moradores menos felizes.", 17, UI.C_MUTED))
	var row := UI.hbox(10)
	tv.add_child(row)
	for i in GameData.TAX_LEVELS.size():
		var idx := i
		var t: Dictionary = GameData.TAX_LEVELS[i]
		var happy_txt := ("+%d%%" % int(t["happy"])) if t["happy"] > 0 else ("%d%%" % int(t["happy"]) if t["happy"] < 0 else "0%")
		var b := UI.button("%s\nx%s  |  felic. %s" % [t["name"], Fmt.num(t["mult"]), happy_txt], UI.C_GREY, func(): _set_tax(idx), 17)
		b.custom_minimum_size = Vector2(0, 70)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(b)
		_tax_buttons.append(b)


func _set_tax(i: int) -> void:
	EconomySystem.set_tax_level(i)
	HappinessSystem.recompute()
	AudioManager.play("cash")
	refresh()


func _build_bank() -> void:
	var loan := UI.card(Color("fff6dc"))
	list.content.add_child(loan)
	var lv := UI.vbox(8)
	loan.add_child(lv)
	lv.add_child(UI.label("Empréstimo", 22, UI.C_TEXT, true))
	_loan_l = UI.label("", 18, UI.C_MUTED)
	_loan_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_loan_l.custom_minimum_size = Vector2(600, 0)
	lv.add_child(_loan_l)
	var lr := UI.hbox(10)
	lv.add_child(lr)
	_loan_take = UI.button("", UI.C_ORANGE, _take_loan, 19)
	_loan_take.custom_minimum_size = Vector2(0, 62)
	_loan_take.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lr.add_child(_loan_take)
	_loan_pay = UI.button("", UI.C_GREEN, _repay, 19)
	_loan_pay.custom_minimum_size = Vector2(0, 62)
	_loan_pay.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lr.add_child(_loan_pay)
	var inv := UI.card()
	list.content.add_child(inv)
	var iv := UI.vbox(8)
	inv.add_child(iv)
	iv.add_child(UI.label("Investimentos", 22, UI.C_TEXT, true))
	var ar := UI.hbox(8)
	iv.add_child(ar)
	ar.add_child(UI.label("Valor a aplicar:", 18, UI.C_MUTED))
	for i in AMOUNTS.size():
		var idx := i
		var b := UI.button("%d%%" % int(AMOUNTS[i] * 100), UI.C_GREY, func(): _set_amount(idx), 18, false)
		b.custom_minimum_size = Vector2(86, 46)
		ar.add_child(b)
		_amount_buttons.append(b)
	ar.add_child(UI.spacer())
	_labels["inv_limit"] = [UI.label("", 16, UI.C_MUTED), null]
	ar.add_child(_labels["inv_limit"][0])
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	grid.mouse_filter = Control.MOUSE_FILTER_PASS
	iv.add_child(grid)
	for d in GameData.INVESTMENTS:
		var id: String = d["id"]
		var b := UI.button("", UI.C_BLUE, func(): _invest(id), 17)
		b.custom_minimum_size = Vector2(0, 66)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(b)
		_inv_rows.append({"new": id, "button": b})
	iv.add_child(UI.label("Aplicações ativas (máx. %d)" % GameData.MAX_INVESTMENTS, 19, UI.C_TEXT, true))
	if EconomySystem.investments.is_empty():
		iv.add_child(UI.label("Nenhuma aplicação no momento.", 17, UI.C_MUTED))
	for i in EconomySystem.investments.size():
		var idx := i
		var inv_d: Dictionary = EconomySystem.investments[i]
		var row := UI.hbox(10)
		iv.add_child(row)
		var l := UI.label("", 18, UI.C_TEXT)
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(l)
		var cb := UI.button("Resgatar", UI.C_GREEN, func(): _collect(idx), 18)
		cb.custom_minimum_size = Vector2(170, 52)
		row.add_child(cb)
		_inv_rows.append({"active": inv_d, "label": l, "button": cb})
	_style_amounts()


func _set_amount(i: int) -> void:
	_amount_index = i
	_style_amounts()
	refresh()


func _style_amounts() -> void:
	for i in _amount_buttons.size():
		UI.color_button(_amount_buttons[i], UI.C_PURPLE if i == _amount_index else UI.C_GREY)


func _invest_amount() -> float:
	return minf(EconomySystem.money * AMOUNTS[_amount_index], EconomySystem.invest_limit())


func _invest(id: String) -> void:
	if EconomySystem.invest(id, _invest_amount()):
		AudioManager.play("cash")
		rebuild()
	else:
		AudioManager.play("error")


func _collect(i: int) -> void:
	var got := EconomySystem.collect_investment(i)
	if got >= 0.0:
		AudioManager.play("cash")
		GameManager.toast.emit("Investimento resgatado: " + Fmt.money(got), "info")
		rebuild()


func _take_loan() -> void:
	if EconomySystem.take_loan(EconomySystem.loan_limit()):
		AudioManager.play("cash")
	else:
		AudioManager.play("error")
	refresh()


func _repay() -> void:
	if EconomySystem.repay_loan():
		AudioManager.play("cash")
	else:
		AudioManager.play("error")
	refresh()


func _build_report() -> void:
	_chart = Chart.new()
	_chart.custom_minimum_size = Vector2(0, 220)
	_chart.mouse_filter = Control.MOUSE_FILTER_IGNORE
	list.content.add_child(_chart)
	var cols := UI.hbox(14)
	list.content.add_child(cols)
	for side in [true, false]:
		var c := UI.card()
		c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cols.add_child(c)
		var v := UI.vbox(4)
		c.add_child(v)
		v.add_child(UI.label("Ganhos nesta cidade" if side else "Gastos nesta cidade", 21, UI.C_TEXT, true))
		for k in LEDGER_LABELS.keys():
			if LEDGER_LABELS[k][1] == side:
				_line(v, "lg_" + k, 17)


func refresh() -> void:
	if not visible:
		return
	var e := EconomySystem
	match current_tab:
		0:
			for c in ["res", "com", "biz", "fun", "esp"]:
				_put("in_" + c, CAT_LABELS[c], Fmt.money_ps(float(e.income_by_cat.get(c, 0.0))), UI.C_GREEN.darkened(0.2))
			_put("income", "Receita total", Fmt.money_ps(e.income_ps), UI.C_GREEN.darkened(0.2))
			for c in ["pub", "fun", "esp", "biz"]:
				_put("up_" + c, "Manutenção: " + CAT_LABELS[c], "-" + Fmt.money_ps(float(e.upkeep_by_cat.get(c, 0.0))), UI.C_RED)
			_put("loanpay", "Parcela do empréstimo", "-" + Fmt.money_ps(e.loan_payment_ps), UI.C_RED)
			_put("expense", "Despesa total", "-" + Fmt.money_ps(e.expense_ps), UI.C_RED)
			_put("net", "Lucro líquido", Fmt.money_ps(e.net_ps), UI.C_GREEN if e.net_ps >= 0 else UI.C_RED)
			for i in _tax_buttons.size():
				UI.color_button(_tax_buttons[i], UI.C_GREEN if i == e.tax_level else UI.C_GREY)
		1:
			if e.loan_balance > 0.0:
				_loan_l.text = "Dívida atual: %s. %d%% do lucro é usado automaticamente para pagar (%s)." % [Fmt.money(e.loan_balance), int(GameData.LOAN_REPAY_SHARE * 100), Fmt.money_ps(e.loan_payment_ps)]
			else:
				_loan_l.text = "Pegue até %s agora (cerca de 30 min de renda). Juros fixos de %d%%. O pagamento é automático com parte do lucro." % [Fmt.money(e.loan_limit()), int(GameData.LOAN_INTEREST * 100)]
			_loan_take.text = "Pegar empréstimo\n%s" % Fmt.money(e.loan_limit())
			_loan_take.disabled = e.loan_balance > 0.0
			_loan_pay.text = "Quitar dívida\n%s" % Fmt.money(e.loan_balance)
			_loan_pay.disabled = e.loan_balance <= 0.0 or not e.can_afford(e.loan_balance)
			if _labels.has("inv_limit"):
				_labels["inv_limit"][0].text = "Aplicar: %s (limite %s)" % [Fmt.money(_invest_amount()), Fmt.money(e.invest_limit())]
			for r in _inv_rows:
				if r.has("new"):
					var d := GameData.investment_def(r["new"])
					r["button"].text = "%s\n%s" % [d["name"], d["desc"]]
					r["button"].disabled = e.investments.size() >= GameData.MAX_INVESTMENTS or _invest_amount() < 1.0
				else:
					var inv: Dictionary = r["active"]
					var d2 := GameData.investment_def(inv["id"])
					var ready := e.is_matured(inv)
					if ready:
						r["label"].text = "%s: %s  »  %s" % [d2["name"], Fmt.money(inv["amount"]), Fmt.money(float(inv["amount"]) * (1.0 + float(inv["rate"])))]
					else:
						r["label"].text = "%s: %s  —  pronto em %s" % [d2["name"], Fmt.money(inv["amount"]), Fmt.short_duration(e.investment_left(inv))]
					r["button"].disabled = not ready
		2:
			if _chart:
				_chart.queue_redraw()
			for k in LEDGER_LABELS.keys():
				_put("lg_" + k, LEDGER_LABELS[k][0], Fmt.money(float(e.ledger.get(k, 0.0))), UI.C_GREEN.darkened(0.2) if LEDGER_LABELS[k][1] else UI.C_RED)
