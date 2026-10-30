class_name ExpansionPanel
extends ModalPanel
## Expansão da cidade: desbloqueio sequencial de novas regiões.

signal focus_region(index: int)

var _rows: Array = []


func _init() -> void:
	super()
	title = "Expansão da cidade"
	icon_name = "map"
	desired_size = Vector2(1060, 690)


func rebuild() -> void:
	UI.clear(list.content)
	_rows.clear()
	for i in GameData.region_count():
		list.content.add_child(_make_row(i))
	refresh()


func _make_row(i: int) -> Control:
	var r: Dictionary = GameData.REGIONS[i]
	var unlocked := i < ExpansionSystem.unlocked
	var is_next := i == ExpansionSystem.unlocked
	var c := UI.card(UI.C_CARD if (unlocked or is_next) else UI.C_CARD_ALT)
	var h := UI.hbox(14)
	c.add_child(h)
	var ids := []
	for d in GameData.BUILDINGS:
		if int(d["region"]) == i:
			ids.append(d)
	var thumb_id: String = ids[ids.size() - 1]["id"] if not ids.is_empty() else "casa_pequena"
	h.add_child(BuildingThumb.new().setup(thumb_id, 1, not (unlocked or is_next), 110))
	var v := UI.vbox(4)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(v)
	v.add_child(UI.label("%d. %s" % [i + 1, r["name"]], 26, UI.C_TEXT, true))
	var desc := UI.label(r["desc"], 17, UI.C_MUTED)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.custom_minimum_size = Vector2(420, 0)
	v.add_child(desc)
	var names := ", ".join(ids.map(func(d): return d["name"]))
	var nl := UI.label("Novos edifícios: " + names, 16, UI.C_BLUE.darkened(0.2))
	nl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	nl.custom_minimum_size = Vector2(420, 0)
	v.add_child(nl)
	var req := UI.label("", 17, UI.C_TEXT, true)
	v.add_child(req)
	var btn: Button
	if unlocked:
		req.text = "Desbloqueada — %d terrenos" % GameData.LOTS_PER_REGION
		req.add_theme_color_override("font_color", UI.C_GREEN)
		var go := func():
			focus_region.emit(i)
			close_panel()
		btn = UI.button("Ver no mapa", UI.C_BLUE, go, 20)
	elif is_next:
		btn = UI.button("Desbloquear", UI.C_GREEN, func(): _unlock(i), 20, true, "map")
	else:
		req.text = "Desbloqueie a região anterior primeiro"
		req.add_theme_color_override("font_color", UI.C_MUTED)
		btn = UI.button("Bloqueada", UI.C_GREY, func(): pass, 20)
		btn.disabled = true
	btn.custom_minimum_size = Vector2(220, 64)
	h.add_child(btn)
	_rows.append({"i": i, "req": req, "button": btn, "next": is_next})
	return c


func _unlock(i: int) -> void:
	if ExpansionSystem.unlock(i):
		AudioManager.play("unlock")
		GameManager.toast.emit("Nova região: " + GameData.REGIONS[i]["name"] + "!", "unlock")
		close_panel()
	else:
		AudioManager.play("error")


func refresh() -> void:
	if not visible:
		return
	for r in _rows:
		if not r["next"]:
			continue
		var req := ExpansionSystem.requirements(r["i"])
		var m_ok: bool = req["money_ok"]
		var p_ok: bool = req["pop_ok"]
		r["req"].text = "Custo: %s %s     População: %s / %s %s" % [
			Fmt.money(req["money"]), "(ok)" if m_ok else "",
			Fmt.pop(PopulationSystem.population), Fmt.pop(req["pop"]), "(ok)" if p_ok else ""]
		r["req"].add_theme_color_override("font_color", UI.C_GREEN if (m_ok and p_ok) else UI.C_RED.darkened(0.1))
		r["button"].disabled = not (m_ok and p_ok)
