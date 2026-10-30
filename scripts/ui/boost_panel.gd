class_name BoostPanel
extends ModalPanel
## Bônus temporários (incentivo gratuito a cada 3 horas, bônus ativos) e
## recompensa diária em sequência de 7 dias.

var _free_l: Label
var _free_btns: Array[Button] = []
var _active_l: Label
var _login_btn: Button
var _login_l: Label


func _init() -> void:
	super()
	title = "Bônus e recompensas"
	icon_name = "gift"
	desired_size = Vector2(1080, 660)


func _ready() -> void:
	super()
	set_tabs(["Bônus temporários", "Recompensa diária"])


func rebuild() -> void:
	UI.clear(list.content)
	_free_btns.clear()
	if current_tab == 0:
		_build_boosts()
	else:
		_build_login()
	refresh()


func _build_boosts() -> void:
	var act := UI.card(Color("fff3e0"))
	list.content.add_child(act)
	var av := UI.vbox(6)
	act.add_child(av)
	av.add_child(UI.label("Bônus ativos", 22, UI.C_TEXT, true))
	_active_l = UI.label("", 19, UI.C_TEXT)
	_active_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_active_l.custom_minimum_size = Vector2(700, 0)
	av.add_child(_active_l)
	var free := UI.card()
	list.content.add_child(free)
	var fv := UI.vbox(8)
	free.add_child(fv)
	fv.add_child(UI.label("Incentivo da prefeitura (grátis)", 22, UI.C_TEXT, true))
	_free_l = UI.label("", 18, UI.C_MUTED)
	fv.add_child(_free_l)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	grid.mouse_filter = Control.MOUSE_FILTER_PASS
	fv.add_child(grid)
	for id in GameData.BOOSTS.keys():
		var def := GameData.boost_def(id)
		var bid: String = id
		var b := UI.button("%s\n%s" % [def["name"], def["desc"]], Color("e8590c"), func(): _claim_free(bid), 18, true, def["icon"])
		b.custom_minimum_size = Vector2(0, 70)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(b)
		_free_btns.append(b)
	var tip := UI.label("Dica: moedas flutuantes douradas (brilhantes) dão bônus surpresa de 3 minutos. A recompensa diária também dá bônus. Bônus não multiplicam a renda offline.", 16, UI.C_MUTED)
	tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tip.custom_minimum_size = Vector2(700, 0)
	list.content.add_child(tip)


func _claim_free(id: String) -> void:
	if BoostSystem.claim_free(id):
		AudioManager.play("boost")
		GameManager.toast.emit("Bônus ativado: " + GameData.boost_def(id)["name"], "event")
	else:
		AudioManager.play("error")
	refresh()


func _build_login() -> void:
	_login_l = UI.label("", 19, UI.C_TEXT, true)
	list.content.add_child(_login_l)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.mouse_filter = Control.MOUSE_FILTER_PASS
	list.content.add_child(row)
	var next := BoostSystem.next_login_day()
	var available := BoostSystem.login_available()
	for i in GameData.LOGIN_REWARDS.size():
		var day := i + 1
		var is_today := day == next and available
		var done := day < next
		if not available:
			var claimed_day := ((BoostSystem.login_streak - 1) % GameData.LOGIN_REWARDS.size()) + 1
			done = day <= claimed_day
		var c := UI.card(Color("fff3e0") if is_today else (Color("e8f6ee") if done else UI.C_CARD_ALT))
		c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		c.custom_minimum_size = Vector2(0, 200)
		row.add_child(c)
		var v := UI.vbox(4)
		c.add_child(v)
		v.add_child(UI.label("Dia %d" % day, 20, UI.C_TEXT, true, HORIZONTAL_ALIGNMENT_CENTER))
		var icon := "check" if done else ("star" if day == 7 else "gift")
		var ic := UI.icon_rect(icon, 48)
		ic.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		v.add_child(ic)
		for r in GameData.LOGIN_REWARDS[i]:
			var l := UI.label(BoostSystem.describe_reward(r), 14, UI.C_MUTED, false, HORIZONTAL_ALIGNMENT_CENTER)
			l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			l.custom_minimum_size = Vector2(110, 0)
			v.add_child(l)
	_login_btn = UI.button("", UI.C_GREEN, _claim_login, 24, true, "gift")
	_login_btn.custom_minimum_size = Vector2(0, 74)
	list.content.add_child(_login_btn)
	var tip := UI.label("Volte todos os dias para manter a sequência. Se perder um dia, ela recomeça do dia 1.", 16, UI.C_MUTED)
	list.content.add_child(tip)


func _claim_login() -> void:
	var day := BoostSystem.next_login_day()
	var rewards := BoostSystem.claim_login()
	if rewards.is_empty():
		AudioManager.play("error")
		return
	AudioManager.play("login")
	var parts := []
	for r in rewards:
		parts.append(BoostSystem.describe_reward(r))
	GameManager.toast.emit("Recompensa do dia %d: %s" % [day, ", ".join(parts)], "achievement")
	rebuild()


func refresh() -> void:
	if not visible:
		return
	if current_tab == 0:
		var lines := []
		for id in BoostSystem.active.keys():
			lines.append("%s — %s  (resta %s)" % [GameData.boost_def(id)["name"], GameData.boost_def(id)["desc"], Fmt.short_duration(BoostSystem.time_left(id))])
		_active_l.text = "\n".join(lines) if not lines.is_empty() else "Nenhum bônus ativo no momento."
		var wait := BoostSystem.free_ready_in()
		_free_l.text = "Escolha um bônus de %d minutos. Disponível a cada 3 horas." % int(GameData.FREE_BOOST_SECONDS / 60.0) if wait <= 0.0 else "Próximo incentivo em %s." % Fmt.short_duration(wait)
		for b in _free_btns:
			b.disabled = wait > 0.0
	else:
		var avail := BoostSystem.login_available()
		_login_l.text = "Sequência atual: %d dia%s" % [BoostSystem.login_streak, "" if BoostSystem.login_streak == 1 else "s"]
		_login_btn.text = "Receber recompensa do dia %d" % BoostSystem.next_login_day() if avail else "Volte amanhã para a próxima recompensa"
		_login_btn.disabled = not avail
