class_name MissionsPanel
extends ModalPanel
## Missões ativas (recompensas em dinheiro e bônus) e conquistas permanentes.

var _mission_rows: Array = []
var _ach_rows: Array = []


func _init() -> void:
	super()
	title = "Missões e Conquistas"
	icon_name = "missions"
	desired_size = Vector2(1000, 680)


func _ready() -> void:
	super()
	set_tabs(["Missões", "Conquistas"])
	MissionSystem.missions_changed.connect(func():
		if visible:
			rebuild())


func rebuild() -> void:
	UI.clear(list.content)
	_mission_rows.clear()
	_ach_rows.clear()
	if current_tab == 0:
		_build_missions()
	else:
		_build_achievements()
	refresh()


func _build_missions() -> void:
	var done := MissionSystem.claimed.size()
	var total := GameData.MISSIONS.size()
	var head := UI.hbox(10)
	list.content.add_child(head)
	head.add_child(UI.label("Progresso da campanha: %d / %d" % [done, total], 20, UI.C_MUTED, true))
	head.add_child(UI.spacer())
	head.add_child(UI.label("Bônus de missões: +%d%% renda" % int(round(MissionSystem.run_bonus * 100)), 20, UI.C_GREEN, true))
	list.content.add_child(UI.progress(done, total, UI.C_BLUE))
	if MissionSystem.all_done():
		list.content.add_child(UI.label("Todas as missões foram concluídas! Use o prestígio para recomeçar mais forte.", 22, UI.C_TEXT))
		return
	for m in MissionSystem.active_missions():
		var c := UI.card()
		list.content.add_child(c)
		var h := UI.hbox(14)
		c.add_child(h)
		h.add_child(UI.icon_rect("missions", 64))
		var v := UI.vbox(6)
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(v)
		v.add_child(UI.label(m["text"], 24, UI.C_TEXT, true))
		var reward := "Recompensa: " + Fmt.money(float(m["reward"]))
		if m.has("bonus"):
			reward += "  +  %d%% de renda permanente nesta cidade" % int(round(float(m["bonus"]) * 100))
		v.add_child(UI.label(reward, 18, Color("b7791f"), true))
		var bar := UI.progress(0, float(m["target"]))
		v.add_child(bar)
		var prog_l := UI.label("", 16, UI.C_MUTED)
		v.add_child(prog_l)
		var id: String = m["id"]
		var btn := UI.button("Coletar", UI.C_ORANGE, func(): _claim(id), 22)
		btn.custom_minimum_size = Vector2(170, 64)
		h.add_child(btn)
		_mission_rows.append({"m": m, "bar": bar, "label": prog_l, "button": btn})


func _claim(id: String) -> void:
	if MissionSystem.claim(id):
		AudioManager.play("mission")
	else:
		AudioManager.play("error")


func _build_achievements() -> void:
	var n := MissionSystem.achievements.size()
	list.content.add_child(UI.label("Conquistadas: %d / %d   —   cada conquista dá +2%% de renda para sempre (bônus atual: +%d%%)" % [n, GameData.ACHIEVEMENTS.size(), n * 2], 19, UI.C_MUTED, true))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	grid.mouse_filter = Control.MOUSE_FILTER_PASS
	list.content.add_child(grid)
	for a in GameData.ACHIEVEMENTS:
		var got := MissionSystem.achievements.has(a["id"])
		var c := UI.card(Color("fff6dc") if got else UI.C_CARD_ALT)
		c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(c)
		var h := UI.hbox(10)
		c.add_child(h)
		var ic := UI.icon_rect("trophy" if got else "lock", 52)
		if not got:
			ic.modulate = Color(1, 1, 1, 0.6)
		h.add_child(ic)
		var v := UI.vbox(2)
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(v)
		v.add_child(UI.label(a["name"], 21, UI.C_TEXT if got else UI.C_MUTED, true))
		v.add_child(UI.label(a["desc"], 16, UI.C_MUTED))
		if not got:
			var p := MissionSystem.achievement_progress(a)
			v.add_child(UI.progress(p, float(a["target"]), UI.C_ORANGE))


func refresh() -> void:
	if not visible or current_tab != 0:
		return
	for r in _mission_rows:
		var m: Dictionary = r["m"]
		var p := MissionSystem.progress(m)
		var target := float(m["target"])
		r["bar"].value = clampf(p, 0, target)
		p = minf(p, target)
		var fmt_p := Fmt.money(p) if m["type"] in ["earn", "income"] else Fmt.num(floor(p))
		var fmt_t := Fmt.money(target) if m["type"] in ["earn", "income"] else Fmt.num(target)
		if m["type"] == "happy":
			fmt_p = Fmt.percent(p)
			fmt_t = Fmt.percent(target)
		r["label"].text = "%s / %s" % [fmt_p, fmt_t]
		var ready := MissionSystem.is_complete(m)
		r["button"].disabled = not ready
		r["button"].text = "Coletar" if ready else "Em andamento"
