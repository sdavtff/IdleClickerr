class_name ResearchPanel
extends ModalPanel
## Árvore de pesquisas: 6 ramos, cada um com pesquisas em sequência.

var _head: Label
var _bar: ProgressBar
var _nodes: Array = []


func _init() -> void:
	super()
	title = "Pesquisas e tecnologias"
	icon_name = "research"
	desired_size = Vector2(1180, 690)


func build_top(parent: VBoxContainer) -> void:
	var c := UI.card(Color("efe9fb"))
	parent.add_child(c)
	var v := UI.vbox(4)
	c.add_child(v)
	_head = UI.label("", 19, UI.C_TEXT, true)
	_head.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_head.custom_minimum_size = Vector2(700, 0)
	v.add_child(_head)
	_bar = UI.progress(0, 1, Color("7e57c2"))
	v.add_child(_bar)


func rebuild() -> void:
	UI.clear(list.content)
	_nodes.clear()
	for br in GameData.RESEARCH_BRANCHES:
		var row := UI.hbox(10)
		list.content.add_child(row)
		var name_l := UI.label(br[1], 19, Color("5e35b1"), true)
		name_l.custom_minimum_size = Vector2(150, 0)
		name_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		name_l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(name_l)
		for r in GameData.RESEARCH:
			if r["branch"] != br[0]:
				continue
			row.add_child(_node_card(r))
	refresh()


func _node_card(r: Dictionary) -> Control:
	var c := UI.card()
	c.custom_minimum_size = Vector2(232, 0)
	var v := UI.vbox(3)
	c.add_child(v)
	v.add_child(UI.label(r["name"], 18, UI.C_TEXT, true))
	var d := UI.label(r["desc"], 14, UI.C_MUTED)
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	d.custom_minimum_size = Vector2(200, 38)
	v.add_child(d)
	var id: String = r["id"]
	var b := UI.button("", UI.C_GREY, func(): _start(id), 15)
	b.custom_minimum_size = Vector2(0, 48)
	v.add_child(b)
	_nodes.append({"id": id, "card": c, "button": b})
	return c


func _start(id: String) -> void:
	if ResearchSystem.start(id):
		AudioManager.play("research")
	else:
		AudioManager.play("error")
	refresh()


func refresh() -> void:
	if not visible:
		return
	var rs := ResearchSystem
	var txt := "Pontos de pesquisa: %s  (+%s/s)  |  Concluídas: %d/%d" % [Fmt.num(floorf(rs.points)), Fmt.num(rs.points_per_sec), rs.done.size(), GameData.RESEARCH.size()]
	if rs.active_id != "":
		txt += "\nPesquisando: %s — faltam %s" % [GameData.research_def(rs.active_id)["name"], Fmt.short_duration(rs.active_left)]
	else:
		txt += "\nEscolha uma pesquisa. Escolas, bibliotecas e universidades geram pontos."
	_head.text = txt
	_bar.value = rs.active_progress()
	for n in _nodes:
		var r := GameData.research_def(n["id"])
		var st := rs.state_of(n["id"])
		var b: Button = n["button"]
		match st:
			"done":
				b.text = "Concluída"
				b.disabled = true
				UI.color_button(b, UI.C_GREEN)
			"active":
				b.text = "Pesquisando %d%%" % int(rs.active_progress() * 100)
				b.disabled = true
				UI.color_button(b, Color("7e57c2"))
			"locked":
				b.text = "Bloqueada"
				b.disabled = true
				UI.color_button(b, UI.C_GREY)
			_:
				b.text = "%s PP  |  %s" % [Fmt.num(float(r["cost"])), Fmt.short_duration(rs.duration_of(r))]
				b.disabled = not rs.can_start(n["id"])
				UI.color_button(b, Color("7e57c2"))
