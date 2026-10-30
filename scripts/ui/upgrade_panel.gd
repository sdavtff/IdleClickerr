class_name UpgradePanel
extends ModalPanel
## Lista de todos os edifícios construídos com botões de melhoria
## (x1, x10, x100 ou o máximo possível).

signal building_selected(uid: int)

const MODES := [1, 10, 100, -1]
var mode_index := 0
var _rows: Array = []
var _mode_buttons: Array[Button] = []
var _summary: Label


func _init() -> void:
	super()
	title = "Melhorias"
	icon_name = "upgrade"
	desired_size = Vector2(1100, 690)


func build_top(parent: VBoxContainer) -> void:
	var h := UI.hbox(8)
	parent.add_child(h)
	h.add_child(UI.label("Comprar:", 20, UI.C_MUTED))
	for i in MODES.size():
		var idx := i
		var txt := "x%d" % MODES[i] if MODES[i] > 0 else "MÁX"
		var b := UI.button(txt, UI.C_GREY, func(): _set_mode(idx), 20, false)
		b.custom_minimum_size = Vector2(90, 46)
		h.add_child(b)
		_mode_buttons.append(b)
	h.add_child(UI.spacer())
	_summary = UI.label("", 18, UI.C_MUTED)
	h.add_child(_summary)
	_style_modes()


func _set_mode(i: int) -> void:
	mode_index = i
	_style_modes()
	refresh()


func _style_modes() -> void:
	for i in _mode_buttons.size():
		UI.color_button(_mode_buttons[i], UI.C_PURPLE if i == mode_index else UI.C_GREY)


func _levels_for(b: Dictionary) -> int:
	var m: int = MODES[mode_index]
	if m > 0:
		return mini(m, GameData.MAX_LEVEL - int(b["level"]))
	return maxi(1, BuildingSystem.affordable_levels(b, EconomySystem.money))


func rebuild() -> void:
	UI.clear(list.content)
	_rows.clear()
	var sorted := BuildingSystem.buildings.duplicate()
	sorted.sort_custom(func(a, b): return int(a["lot"]) < int(b["lot"]))
	if sorted.is_empty():
		list.content.add_child(UI.label("Nenhum edifício ainda. Construa algo primeiro!", 22, UI.C_MUTED))
	for b in sorted:
		list.content.add_child(_make_row(b))
	refresh()


func _make_row(b: Dictionary) -> Control:
	var def := GameData.get_def(b["id"])
	var c := UI.card()
	var h := UI.hbox(14)
	c.add_child(h)
	var thumb := BuildingThumb.new().setup(b["id"], int(b["level"]), false, 86)
	h.add_child(thumb)
	var v := UI.vbox(2)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(v)
	var name_l := UI.label("", 23, UI.C_TEXT, true)
	v.add_child(name_l)
	var delta := UI.label("", 18, GameData.CATEGORY_COLORS[def["cat"]].darkened(0.35))
	v.add_child(delta)
	var milestone := UI.label("", 15, UI.C_MUTED)
	v.add_child(milestone)
	var info := UI.button("Detalhes", UI.C_BLUE, func(): building_selected.emit(int(b["uid"])), 18)
	info.custom_minimum_size = Vector2(130, 58)
	h.add_child(info)
	var btn := UI.button("", UI.C_GREEN, func(): _upgrade(int(b["uid"])), 19)
	btn.custom_minimum_size = Vector2(250, 58)
	h.add_child(btn)
	_rows.append({"uid": int(b["uid"]), "name": name_l, "delta": delta, "milestone": milestone, "button": btn, "thumb": thumb})
	return c


func _upgrade(uid: int) -> void:
	var b := BuildingSystem.get_building(uid)
	if b.is_empty():
		return
	var n := _levels_for(b)
	if BuildingSystem.upgrade(uid, n) > 0:
		AudioManager.play("upgrade")
	else:
		AudioManager.play("error")
	refresh()


func refresh() -> void:
	if not visible:
		return
	_summary.text = "Edifícios: %d   |   Níveis somados: %d" % [BuildingSystem.buildings.size(), BuildingSystem.total_levels()]
	for r in _rows:
		var b := BuildingSystem.get_building(r["uid"])
		if b.is_empty():
			continue
		var def := GameData.get_def(b["id"])
		var lv := int(b["level"])
		r["name"].text = "%s  —  Nv %d" % [def["name"], lv]
		if r["thumb"].level != lv:
			r["thumb"].level = lv
			r["thumb"].queue_redraw()
		var btn: Button = r["button"]
		if not BuildingSystem.is_complete(b):
			r["delta"].text = "Em construção — faltam %s" % Fmt.short_duration(ceilf(float(b["build_left"])))
			r["milestone"].text = "Toque em Detalhes para acelerar a obra."
			btn.text = "EM OBRA"
			btn.disabled = true
			continue
		if lv >= GameData.MAX_LEVEL:
			r["delta"].text = "Nível máximo alcançado!"
			r["milestone"].text = ""
			btn.text = "MÁXIMO"
			btn.disabled = true
			continue
		var n := _levels_for(b)
		var cost := BuildingSystem.upgrade_cost(b, n)
		r["delta"].text = Describe.upgrade_delta(b, n)
		var ms := Describe.next_milestone(lv)
		r["milestone"].text = "Próximo marco: Nv %d (renda x2 e novo visual)" % ms if ms > 0 else ""
		btn.text = "+%d nível%s\n%s" % [n, "" if n == 1 else "s", Fmt.money(cost)]
		btn.disabled = not EconomySystem.can_afford(cost)
