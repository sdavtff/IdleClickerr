class_name EventsPanel
extends ModalPanel
## Evento atual, desafios diários e metas semanais com recompensas.

var _event_l: Label
var _event_bar: ProgressBar
var _rows: Array = []


func _init() -> void:
	super()
	title = "Eventos e desafios"
	icon_name = "event"
	desired_size = Vector2(1000, 690)


func _ready() -> void:
	super()
	set_tabs(["Evento atual", "Desafios diários", "Metas semanais"])
	ChallengeSystem.challenges_changed.connect(func():
		if visible:
			rebuild())


func rebuild() -> void:
	UI.clear(list.content)
	_rows.clear()
	_event_l = null
	match current_tab:
		0:
			_build_event()
		1:
			_build_list(false)
		2:
			_build_list(true)
	refresh()


func _build_event() -> void:
	var c := UI.card(Color("fff1e6"))
	list.content.add_child(c)
	var h := UI.hbox(14)
	c.add_child(h)
	h.add_child(UI.icon_rect("event", 80))
	var v := UI.vbox(6)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(v)
	_event_l = UI.label("", 20, UI.C_TEXT)
	_event_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_event_l.custom_minimum_size = Vector2(600, 0)
	v.add_child(_event_l)
	_event_bar = UI.progress(0, 1, Color("e8590c"))
	v.add_child(_event_bar)
	list.content.add_child(UI.label("Eventos possíveis", 21, UI.C_TEXT, true))
	for e in GameData.EVENTS:
		var l := UI.label("%s  —  %s  Objetivo: %s." % [e["name"], e["desc"], e["goal_text"]], 16, UI.C_TEXT if e["good"] else UI.C_RED.darkened(0.3))
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size = Vector2(700, 0)
		list.content.add_child(l)


func _build_list(weekly: bool) -> void:
	var info := "Novas metas toda segunda-feira. Recompensa: %d min de renda + %d pontos de pesquisa + 1 estrela de prestígio." % [int(GameData.WEEKLY_REWARD_MIN), GameData.WEEKLY_REWARD_RP] if weekly else "Novos desafios todos os dias. Recompensa: %d min de renda + %d pontos de pesquisa." % [int(GameData.DAILY_REWARD_MIN), GameData.DAILY_REWARD_RP]
	var il := UI.label(info, 17, UI.C_MUTED)
	il.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	il.custom_minimum_size = Vector2(700, 0)
	list.content.add_child(il)
	var arr: Array = ChallengeSystem.weekly if weekly else ChallengeSystem.daily
	for i in arr.size():
		var idx := i
		var c := UI.card()
		list.content.add_child(c)
		var h := UI.hbox(14)
		c.add_child(h)
		h.add_child(UI.icon_rect("challenge", 60))
		var v := UI.vbox(6)
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(v)
		v.add_child(UI.label(arr[i]["text"], 22, UI.C_TEXT, true))
		var bar := UI.progress(0, float(arr[i]["target"]))
		v.add_child(bar)
		var pl := UI.label("", 16, UI.C_MUTED)
		v.add_child(pl)
		var btn := UI.button("Coletar", UI.C_ORANGE, func(): _claim(weekly, idx), 21)
		btn.custom_minimum_size = Vector2(190, 64)
		h.add_child(btn)
		_rows.append({"c": arr[i], "bar": bar, "label": pl, "button": btn, "weekly": weekly})


func _claim(weekly: bool, i: int) -> void:
	if ChallengeSystem.claim(weekly, i):
		AudioManager.play("cash")
	else:
		AudioManager.play("error")


func refresh() -> void:
	if not visible:
		return
	if current_tab == 0 and _event_l:
		var e := EventSystem.active()
		if e.is_empty():
			_event_l.text = "Nenhum evento acontecendo agora.\nPróximo evento em cerca de %s." % Fmt.short_duration(EventSystem.next_in)
			_event_bar.value = 0
		else:
			var goal := "CUMPRIDO!" if EventSystem.goal_done else "%d/%d" % [mini(EventSystem.progress, int(e["target"])), int(e["target"])]
			_event_l.text = "%s\n%s\nObjetivo: %s (%s)\nRecompensa: %s + %d pontos de pesquisa\nTermina em %s" % [e["name"], e["desc"], e["goal_text"], goal, Fmt.money(EventSystem.reward_amount(e)), int(e["reward_rp"]), Fmt.short_duration(EventSystem.left)]
			_event_bar.max_value = maxf(1.0, EventSystem.duration)
			_event_bar.value = EventSystem.left
		return
	for r in _rows:
		var c: Dictionary = r["c"]
		r["bar"].value = float(c["progress"])
		var money_kind: bool = c["kind"] == "earn_minutes"
		r["label"].text = "%s / %s" % [Fmt.money(c["progress"]) if money_kind else Fmt.num(floorf(c["progress"])), Fmt.money(c["target"]) if money_kind else Fmt.num(c["target"])]
		var btn: Button = r["button"]
		if c["claimed"]:
			btn.text = "Coletado"
			btn.disabled = true
		else:
			var ready := ChallengeSystem.is_ready(c)
			btn.text = "Coletar\n%s" % Fmt.money(ChallengeSystem.reward_money(r["weekly"])) if ready else "Em andamento"
			btn.disabled = not ready
