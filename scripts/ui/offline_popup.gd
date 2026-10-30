class_name OfflinePopup
extends ModalPanel
## Tela "Bem-vindo de volta!" com a renda acumulada enquanto o jogador esteve fora.

signal collected(amount: float)

var _time_l: Label
var _money_l: Label
var _extra_l: Label
var _btn: Button


func _init() -> void:
	super()
	title = "BEM-VINDO DE VOLTA!"
	icon_name = "clock"
	desired_size = Vector2(860, 600)


func show_report(report: Dictionary) -> void:
	_build_frame()
	open_panel()
	_time_l.text = "Você ficou ausente por " + Fmt.duration(float(report.get("raw_seconds", report["seconds"]))) + "."
	_money_l.text = Fmt.money(float(report["money"]))
	var extra := []
	if report.get("capped", false):
		extra.append("A cidade acumula renda por no máximo 24 horas.")
	if int(report.get("buildings_done", 0)) > 0:
		extra.append("%d obra(s) concluída(s)." % int(report["buildings_done"]))
	var rd: Array = report.get("research_done", [])
	if not rd.is_empty():
		extra.append("Pesquisa concluída: " + ", ".join(rd))
	if int(report.get("investments", 0)) > 0:
		extra.append("%d investimento(s) prontos para resgate no Banco." % int(report["investments"]))
	var bc: Dictionary = report.get("by_cat", {})
	if not bc.is_empty():
		var parts := []
		for k in [["res", "Impostos"], ["com", "Comércio"], ["biz", "Empresas"], ["fun", "Lazer"], ["esp", "Especiais"]]:
			if float(bc.get(k[0], 0.0)) > 0.0:
				parts.append("%s %s" % [k[1], Fmt.money(bc[k[0]])])
		if not parts.is_empty():
			extra.append("  |  ".join(parts))
	var pa := float(report.get("pop_after", 0))
	var pb := float(report.get("pop_before", 0))
	if pa - pb >= 1.0:
		extra.append("+%s novos moradores chegaram." % Fmt.pop(pa - pb))
	_extra_l.text = "\n".join(extra)


func rebuild() -> void:
	if _time_l != null:
		return
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_time_l = UI.label("", 23, UI.C_TEXT, false, HORIZONTAL_ALIGNMENT_CENTER)
	list.content.add_child(_time_l)
	list.content.add_child(UI.label("Dinheiro acumulado:", 22, UI.C_MUTED, false, HORIZONTAL_ALIGNMENT_CENTER))
	var h := UI.hbox(12)
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	list.content.add_child(h)
	h.add_child(UI.icon_rect("coin", 70))
	_money_l = UI.outlined(UI.label("", 52, UI.C_GOLD, true), 10)
	h.add_child(_money_l)
	_extra_l = UI.label("", 18, UI.C_MUTED, false, HORIZONTAL_ALIGNMENT_CENTER)
	_extra_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_extra_l.custom_minimum_size = Vector2(700, 0)
	list.content.add_child(_extra_l)
	_btn = UI.button("COLETAR RECOMPENSAS", UI.C_GREEN, _collect, 26, false, "coin")
	_btn.custom_minimum_size = Vector2(0, 78)
	list.content.add_child(_btn)


func _collect() -> void:
	var amount := IdleSystem.collect()
	AudioManager.play("cash")
	close_panel()
	collected.emit(amount)


func close_panel() -> void:
	# Fechar sempre coleta a recompensa (nada é perdido).
	if visible and not IdleSystem.pending.is_empty():
		var amount := IdleSystem.collect()
		super.close_panel()
		collected.emit(amount)
		return
	super.close_panel()
