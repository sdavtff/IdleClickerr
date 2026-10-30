class_name PrestigePanel
extends ModalPanel
## Prestígio: explica o que será reiniciado, confirma e oferece a loja de
## melhorias permanentes compradas com Estrelas de Prestígio.

signal prestige_requested

var _gain_l: Label
var _req_l: Label
var _do_btn: Button
var _stars_l: Label
var _shop_rows: Array = []


func _init() -> void:
	super()
	title = "Prestígio"
	icon_name = "star"
	desired_size = Vector2(1080, 690)


func _ready() -> void:
	super()
	set_tabs(["Renascer a cidade", "Loja de legado"])


func rebuild() -> void:
	UI.clear(list.content)
	_shop_rows.clear()
	if current_tab == 0:
		_build_main()
	else:
		_build_shop()
	refresh()


func _build_main() -> void:
	var top := UI.card(Color("fff6dc"))
	list.content.add_child(top)
	var h := UI.hbox(16)
	top.add_child(h)
	h.add_child(UI.icon_rect("star", 84))
	var v := UI.vbox(4)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(v)
	_stars_l = UI.label("", 26, UI.C_TEXT, true)
	v.add_child(_stars_l)
	v.add_child(UI.label("Cada estrela conquistada dá +5% de renda permanente (mesmo depois de gasta na loja).", 17, UI.C_MUTED))
	var gain_card := UI.card()
	list.content.add_child(gain_card)
	var gv := UI.vbox(8)
	gain_card.add_child(gv)
	_gain_l = UI.label("", 26, Color("b7791f"), true)
	gv.add_child(_gain_l)
	_req_l = UI.label("", 18, UI.C_MUTED)
	_req_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_req_l.custom_minimum_size = Vector2(600, 0)
	gv.add_child(_req_l)
	var cols := UI.hbox(14)
	list.content.add_child(cols)
	cols.add_child(_info_card("SERÁ REINICIADO", Color("fdecea"), UI.C_RED, [
		"Dinheiro atual", "Todos os edifícios e seus níveis", "Regiões desbloqueadas",
		"População e felicidade", "Missões e bônus de missões", "Pesquisas, banco e eventos"]))
	cols.add_child(_info_card("SERÁ MANTIDO", Color("e8f6ee"), UI.C_GREEN, [
		"Estrelas de prestígio e seus bônus", "Melhorias da loja de legado",
		"Conquistas (+2% renda cada)", "Desafios diários e semanais", "Estatísticas gerais"]))
	_do_btn = UI.button("RENASCER A CIDADE", UI.C_ORANGE, func(): prestige_requested.emit(), 26, true, "star")
	_do_btn.custom_minimum_size = Vector2(0, 74)
	list.content.add_child(_do_btn)


func _info_card(head: String, bg: Color, col: Color, items: Array) -> Control:
	var c := UI.card(bg)
	c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var v := UI.vbox(4)
	c.add_child(v)
	v.add_child(UI.label(head, 20, col.darkened(0.2), true))
	for it in items:
		v.add_child(UI.label("•  " + it, 17, UI.C_TEXT))
	return c


func _build_shop() -> void:
	_stars_l = UI.label("", 24, UI.C_TEXT, true)
	list.content.add_child(_stars_l)
	for u in GameData.PRESTIGE_UPGRADES:
		var c := UI.card()
		list.content.add_child(c)
		var h := UI.hbox(14)
		c.add_child(h)
		h.add_child(UI.icon_rect("star", 56))
		var v := UI.vbox(2)
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(v)
		var name_l := UI.label("", 23, UI.C_TEXT, true)
		v.add_child(name_l)
		v.add_child(UI.label(u["desc"], 17, UI.C_MUTED))
		var id: String = u["id"]
		var btn := UI.button("", UI.C_PURPLE, func(): _buy(id), 20)
		btn.custom_minimum_size = Vector2(220, 60)
		h.add_child(btn)
		_shop_rows.append({"u": u, "name": name_l, "button": btn})


func _buy(id: String) -> void:
	if PrestigeSystem.buy(id):
		AudioManager.play("upgrade")
		GameManager.save_game()
	else:
		AudioManager.play("error")
	refresh()


func refresh() -> void:
	if not visible:
		return
	var mult := PrestigeSystem.income_mult()
	if _stars_l:
		_stars_l.text = "Estrelas: %d disponíveis  |  %d conquistadas  |  Renda x%s" % [PrestigeSystem.stars, PrestigeSystem.stars_total, Fmt.num(mult)]
	if current_tab == 0 and _gain_l:
		var gain := PrestigeSystem.stars_on_reset()
		var after := (1.0 + GameData.STAR_INCOME_BONUS * (PrestigeSystem.stars_total + gain)) * (1.0 + 0.1 * PrestigeSystem.level("marketing"))
		_gain_l.text = "Ao renascer agora você ganha: %d estrela%s\nMultiplicador de renda: x%s  »  x%s" % [gain, "" if gain == 1 else "s", Fmt.num(mult), Fmt.num(after)]
		var reqs := []
		if ExpansionSystem.unlocked < GameData.PRESTIGE_MIN_REGIONS:
			reqs.append("Desbloqueie o %s (região %d)." % [GameData.REGIONS[GameData.PRESTIGE_MIN_REGIONS - 1]["name"], GameData.PRESTIGE_MIN_REGIONS])
		if gain < 1:
			reqs.append("Ganhe pelo menos R$ 1 mi nesta cidade (ganho atual: %s)." % Fmt.money(EconomySystem.total_earned))
		var next_star := pow(gain + 1, 2) * GameData.PRESTIGE_DIVISOR
		var base := "Estrelas = raiz quadrada do dinheiro ganho nesta cidade ÷ R$ 1 mi. Próxima estrela em %s ganhos." % Fmt.money(next_star)
		_req_l.text = ("Requisitos: " + " ".join(reqs) + "\n" if not reqs.is_empty() else "") + base
		_do_btn.disabled = not PrestigeSystem.can_prestige()
	for r in _shop_rows:
		var u: Dictionary = r["u"]
		var lv := PrestigeSystem.level(u["id"])
		r["name"].text = "%s  (%d/%d)" % [u["name"], lv, int(u["max"])]
		var btn: Button = r["button"]
		if lv >= int(u["max"]):
			btn.text = "MÁXIMO"
			btn.disabled = true
		else:
			var cost := PrestigeSystem.upgrade_cost(u["id"])
			btn.text = "Comprar\n%d estrela%s" % [cost, "" if cost == 1 else "s"]
			btn.disabled = PrestigeSystem.stars < cost
