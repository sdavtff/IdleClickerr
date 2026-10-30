class_name BuildPanel
extends ModalPanel
## Menu de construções por categoria. A construção aparece automaticamente
## no próximo terreno livre.

signal built(b: Dictionary)

const TAB_CATS := ["res", "com", "biz", "pub", "fun", "esp"]
var _rows: Array = []
var _info: Label


func _init() -> void:
	super()
	title = "Construções"
	icon_name = "build"
	desired_size = Vector2(1180, 690)


func _ready() -> void:
	super()
	set_tabs(TAB_CATS.map(func(c): return GameData.CATEGORY_NAMES[c]))


func build_top(parent: VBoxContainer) -> void:
	_info = UI.label("", 19, UI.C_MUTED)
	parent.add_child(_info)


func open_for_category(cat: String) -> void:
	current_tab = maxi(0, TAB_CATS.find(cat))
	open_panel()
	_style_tabs()


func rebuild() -> void:
	UI.clear(list.content)
	_rows.clear()
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.mouse_filter = Control.MOUSE_FILTER_PASS
	list.content.add_child(grid)
	for def in GameData.buildings_in_category(TAB_CATS[current_tab]):
		grid.add_child(_make_card(def))
	refresh()


func _make_card(def: Dictionary) -> Control:
	var unlocked := BuildingSystem.is_def_unlocked(def)
	var c := UI.card(UI.C_CARD if unlocked else UI.C_CARD_ALT)
	c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var h := UI.hbox(12)
	c.add_child(h)
	h.add_child(BuildingThumb.new().setup(def["id"], 1, not unlocked, 128))
	var v := UI.vbox(4)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(v)
	var top := UI.hbox(6)
	v.add_child(top)
	var name_l := UI.label(def["name"], 24, UI.C_TEXT, true)
	name_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(name_l)
	var owned := UI.label("", 16, UI.C_MUTED)
	top.add_child(owned)
	var desc := UI.label(def["desc"], 16, UI.C_MUTED)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.custom_minimum_size = Vector2(330, 0)
	v.add_child(desc)
	var stats := UI.label(Describe.short_stats(def), 16, GameData.CATEGORY_COLORS[def["cat"]].darkened(0.35))
	stats.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stats.custom_minimum_size = Vector2(330, 0)
	v.add_child(stats)
	var btn := UI.button("", UI.C_GREEN, func(): _build(def["id"]), 20)
	btn.custom_minimum_size = Vector2(0, 52)
	v.add_child(btn)
	_rows.append({"id": def["id"], "button": btn, "owned": owned})
	return c


func _build(id: String) -> void:
	var check := BuildingSystem.can_build(id)
	if not check["ok"]:
		AudioManager.play("error")
		GameManager.toast.emit(check["reason"], "warning")
		return
	var b := BuildingSystem.build(id)
	if b.is_empty():
		AudioManager.play("error")
		return
	AudioManager.play("build")
	built.emit(b)
	refresh()


func refresh() -> void:
	if not visible:
		return
	var free := BuildingSystem.free_lot_count()
	_info.text = "Terrenos livres: %d de %d   |   Dinheiro: %s   |   A construção aparece no próximo terreno livre." % [
		maxi(free, 0), BuildingSystem.unlocked_lots(), Fmt.money(EconomySystem.money)]
	for r in _rows:
		var id: String = r["id"]
		var def := GameData.get_def(id)
		var btn: Button = r["button"]
		var count := BuildingSystem.count_owned(id)
		r["owned"].text = "Você tem: %d" % count if count > 0 else ""
		if not BuildingSystem.is_def_unlocked(def):
			btn.text = "Requer: " + GameData.REGIONS[def["region"]]["name"]
			btn.disabled = true
			continue
		if def.has("research") and not ResearchSystem.is_done(def["research"]):
			btn.text = "Requer pesquisa: " + GameData.research_def(def["research"])["name"]
			btn.disabled = true
			continue
		if def.get("unique", false) and count > 0:
			btn.text = "Construído (único)"
			btn.disabled = true
			continue
		var cost := BuildingSystem.build_cost(id)
		btn.text = "Construir  %s  (obra %s)" % [Fmt.money(cost), Fmt.short_duration(BuildingSystem.build_time(id))]
		var ok := EconomySystem.can_afford(cost) and free > 0
		btn.disabled = not ok
		if free <= 0:
			btn.text = "Sem terrenos — expanda a cidade"
