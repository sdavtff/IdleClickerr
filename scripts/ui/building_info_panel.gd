class_name BuildingInfoPanel
extends ModalPanel
## Detalhes de um edifício tocado na cidade: estatísticas, melhorias e demolição.

signal demolish_requested(uid: int)

var uid := -1
var _thumb: BuildingThumb
var _stats: Label
var _level_l: Label
var _delta_l: Label
var _ms_l: Label
var _btns: Array = []


func _init() -> void:
	super()
	title = "Edifício"
	icon_name = "home"
	desired_size = Vector2(900, 600)


func show_building(p_uid: int) -> void:
	uid = p_uid
	open_panel()


func rebuild() -> void:
	UI.clear(list.content)
	_btns.clear()
	var b := BuildingSystem.get_building(uid)
	if b.is_empty():
		close_panel()
		return
	var def := GameData.get_def(b["id"])
	title_label.text = def["name"]
	var h := UI.hbox(18)
	list.content.add_child(h)
	_thumb = BuildingThumb.new().setup(b["id"], int(b["level"]), false, 230)
	h.add_child(_thumb)
	var v := UI.vbox(6)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(v)
	var cat := UI.label(GameData.CATEGORY_NAMES[def["cat"]] + "  —  " + GameData.REGIONS[def["region"]]["name"], 18, GameData.CATEGORY_COLORS[def["cat"]].darkened(0.3), true)
	v.add_child(cat)
	_level_l = UI.label("", 28, UI.C_TEXT, true)
	v.add_child(_level_l)
	var desc := UI.label(def["desc"], 18, UI.C_MUTED)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.custom_minimum_size = Vector2(420, 0)
	v.add_child(desc)
	_stats = UI.label("", 19, UI.C_TEXT)
	_stats.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_stats.custom_minimum_size = Vector2(420, 0)
	v.add_child(_stats)
	var up := UI.card(Color("eef7ee"))
	list.content.add_child(up)
	var uv := UI.vbox(8)
	up.add_child(uv)
	_delta_l = UI.label("", 20, UI.C_TEXT, true)
	uv.add_child(_delta_l)
	_ms_l = UI.label("", 16, UI.C_MUTED)
	uv.add_child(_ms_l)
	var row := UI.hbox(10)
	uv.add_child(row)
	for n in [1, 10, -1]:
		var levels: int = n
		var btn := UI.button("", UI.C_GREEN, func(): _upgrade(levels), 19)
		btn.custom_minimum_size = Vector2(0, 62)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(btn)
		_btns.append({"n": n, "button": btn})
	var bottom := UI.hbox(10)
	list.content.add_child(bottom)
	bottom.add_child(UI.spacer())
	var demo := UI.button("Demolir (+%s)" % Fmt.money(BuildingSystem.demolish_refund(b)), UI.C_RED, func(): demolish_requested.emit(uid), 18, true, "demolish")
	demo.custom_minimum_size = Vector2(0, 52)
	bottom.add_child(demo)
	refresh()


func _levels(n: int, b: Dictionary) -> int:
	if n > 0:
		return mini(n, GameData.MAX_LEVEL - int(b["level"]))
	return maxi(1, BuildingSystem.affordable_levels(b, EconomySystem.money))


func _upgrade(n: int) -> void:
	var b := BuildingSystem.get_building(uid)
	if b.is_empty():
		return
	if BuildingSystem.upgrade(uid, _levels(n, b)) > 0:
		AudioManager.play("upgrade")
	else:
		AudioManager.play("error")
	refresh()


func refresh() -> void:
	if not visible:
		return
	var b := BuildingSystem.get_building(uid)
	if b.is_empty():
		close_panel()
		return
	var def := GameData.get_def(b["id"])
	var lv := int(b["level"])
	_level_l.text = "Nível %d" % lv
	if _thumb.level != lv:
		_thumb.level = lv
		_thumb.queue_redraw()
	var lines := Describe.stats_lines(def, lv)
	if def.has("income"):
		lines.append("Eficiência dos trabalhadores: %d%%" % int(EconomySystem.work_efficiency * 100))
	_stats.text = "\n".join(lines)
	if lv >= GameData.MAX_LEVEL:
		_delta_l.text = "Nível máximo alcançado!"
		_ms_l.text = ""
		for e in _btns:
			e["button"].text = "MÁXIMO"
			e["button"].disabled = true
		return
	_delta_l.text = "Próximo nível — " + Describe.upgrade_delta(b, 1)
	var ms := Describe.next_milestone(lv)
	_ms_l.text = "Marcos nos níveis 10, 25, 50, 75 e 100: renda x2 e novo visual. Próximo: Nv %d" % ms if ms > 0 else ""
	for e in _btns:
		var n := _levels(e["n"], b)
		var cost := BuildingSystem.upgrade_cost(b, n)
		var label := "MÁX (+%d)" % n if e["n"] < 0 else "+%d" % n
		e["button"].text = "%s\n%s" % [label, Fmt.money(cost)]
		e["button"].disabled = not EconomySystem.can_afford(cost)
