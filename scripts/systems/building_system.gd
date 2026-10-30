extends Node
## Sistema de construções: edifícios construídos, lotes, custos, melhorias e
## os valores derivados de cada edifício (renda, capacidade, cobertura...).

signal building_built(b: Dictionary)
signal building_upgraded(b: Dictionary, levels: int)
signal building_removed(uid: int)
signal buildings_reset
signal building_completed(b: Dictionary)

## Cada edifício: {"uid": int, "id": String, "lot": int, "level": int, "build_left": float}
## build_left > 0 indica obra em andamento (segundos restantes, avança jogando e offline).
var buildings: Array = []
var next_uid := 1
## Constrói sem tempo de obra (somente testes automatizados).
var instant_build := false
var _by_uid: Dictionary = {}
var _by_lot: Dictionary = {}


func reset() -> void:
	buildings.clear()
	_by_uid.clear()
	_by_lot.clear()
	next_uid = 1
	buildings_reset.emit()


func to_dict() -> Dictionary:
	return {"buildings": buildings.duplicate(true), "next_uid": next_uid}


func from_dict(d: Dictionary) -> void:
	buildings.clear()
	_by_uid.clear()
	_by_lot.clear()
	next_uid = int(d.get("next_uid", 1))
	for raw in d.get("buildings", []):
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var id := str(raw.get("id", ""))
		if not GameData.has_def(id):
			continue
		var b := {
			"uid": int(raw.get("uid", next_uid)),
			"id": id,
			"lot": int(raw.get("lot", -1)),
			"level": clampi(int(raw.get("level", 1)), 1, GameData.MAX_LEVEL),
			"build_left": maxf(0.0, EconomySystem._safe(raw.get("build_left", 0.0))),
			"build_total": maxf(1.0, EconomySystem._safe(raw.get("build_total", 1.0))),
		}
		if b["lot"] < 0 or b["lot"] >= GameData.total_lots() or _by_lot.has(b["lot"]) or _by_uid.has(b["uid"]):
			continue
		_add(b)
		next_uid = maxi(next_uid, b["uid"] + 1)
	buildings_reset.emit()


func _add(b: Dictionary) -> void:
	buildings.append(b)
	_by_uid[b["uid"]] = b
	_by_lot[b["lot"]] = b


# --- Consultas ---------------------------------------------------------------

func get_building(uid: int) -> Dictionary:
	return _by_uid.get(uid, {})


func building_at_lot(lot: int) -> Dictionary:
	return _by_lot.get(lot, {})


func count_owned(id: String) -> int:
	var n := 0
	for b in buildings:
		if b["id"] == id:
			n += 1
	return n


func count_category(cat: String) -> int:
	var n := 0
	for b in buildings:
		if GameData.get_def(b["id"])["cat"] == cat:
			n += 1
	return n


func total_levels() -> int:
	var n := 0
	for b in buildings:
		n += int(b["level"])
	return n


func max_level() -> int:
	var n := 0
	for b in buildings:
		n = maxi(n, int(b["level"]))
	return n


func unlocked_lots() -> int:
	return ExpansionSystem.unlocked * GameData.LOTS_PER_REGION


func free_lot() -> int:
	for lot in unlocked_lots():
		if not _by_lot.has(lot):
			return lot
	return -1


func free_lot_count() -> int:
	return unlocked_lots() - buildings.size()


func is_def_unlocked(def: Dictionary) -> bool:
	return int(def["region"]) < ExpansionSystem.unlocked


# --- Fórmulas ----------------------------------------------------------------

static func is_complete(b: Dictionary) -> bool:
	return float(b.get("build_left", 0.0)) <= 0.0


func under_construction() -> Array:
	return buildings.filter(func(b): return not is_complete(b))


func build_time(id: String) -> float:
	var def := GameData.get_def(id)
	var t := GameData.base_build_time(def) * Modifiers.mult("build_time", 0.15)
	t *= maxf(0.25, 1.0 - 0.15 * PrestigeSystem.level("obras"))
	return maxf(1.0, t)


func build_progress(b: Dictionary) -> float:
	if is_complete(b):
		return 1.0
	return clampf(1.0 - float(b["build_left"]) / maxf(1.0, float(b.get("build_total", 1.0))), 0.0, 1.0)


## Preço para concluir a obra agora (proporcional ao tempo restante e à renda).
func accelerate_cost(b: Dictionary) -> float:
	if is_complete(b):
		return 0.0
	var per_sec := maxf(EconomySystem.income_ps * 0.6, float(GameData.get_def(b["id"])["cost"]) * 0.004)
	return ceilf(float(b["build_left"]) * per_sec)


func accelerate(uid: int) -> bool:
	var b := get_building(uid)
	if b.is_empty() or is_complete(b):
		return false
	if not EconomySystem.spend(accelerate_cost(b), "accelerate"):
		return false
	_complete(b)
	return true


func _complete(b: Dictionary) -> void:
	b["build_left"] = 0.0
	building_completed.emit(b)


## Avança as obras (jogando ou offline). Retorna os edifícios concluídos.
func advance_construction(dt: float) -> Array:
	var finished := []
	for b in buildings:
		if not is_complete(b):
			b["build_left"] = float(b["build_left"]) - dt
			if float(b["build_left"]) <= 0.0:
				_complete(b)
				finished.append(b)
	return finished


## Conclui todas as obras imediatamente (usado em testes e no início da cidade).
func finish_all() -> void:
	for b in buildings:
		if not is_complete(b):
			_complete(b)


static func milestones(level: int) -> int:
	var m := 0
	for t in GameData.LEVEL_MILESTONES:
		if level >= t:
			m += 1
	return m


static func level_income_mult(level: int) -> float:
	return float(level) * pow(2.0, milestones(level))


static func income_of(b: Dictionary) -> float:
	var def := GameData.get_def(b["id"])
	return float(def.get("income", 0.0)) * level_income_mult(int(b["level"]))


static func capacity_of(b: Dictionary) -> float:
	var def := GameData.get_def(b["id"])
	var lv := int(b["level"])
	return float(def.get("cap", 0)) * (1.0 + 0.25 * (lv - 1)) * pow(1.4, milestones(lv)) * Modifiers.mult("res_cap")


static func tax_of(b: Dictionary) -> float:
	return float(GameData.get_def(b["id"]).get("tax", 0.0))


static func coverage_of(b: Dictionary) -> float:
	var def := GameData.get_def(b["id"])
	var lv := int(b["level"])
	return float(def.get("cov", 0)) * (1.0 + 0.5 * (lv - 1)) * pow(1.5, milestones(lv)) * Modifiers.mult("coverage")


static func upkeep_of(b: Dictionary) -> float:
	var def := GameData.get_def(b["id"])
	return float(def.get("upkeep", 0.0)) * (1.0 + 0.3 * (int(b["level"]) - 1))


static func jobs_of(b: Dictionary) -> float:
	var def := GameData.get_def(b["id"])
	return float(def.get("jobs", 0)) * (1.0 + 0.15 * (int(b["level"]) - 1))


func build_cost(id: String) -> float:
	var def := GameData.get_def(id)
	return float(def["cost"]) * pow(GameData.BUILD_COST_GROWTH, count_owned(id)) * PrestigeSystem.cost_mult() * Modifiers.mult("build_cost", 0.3)


func upgrade_cost(b: Dictionary, levels: int = 1) -> float:
	var def := GameData.get_def(b["id"])
	var lv := int(b["level"])
	levels = mini(levels, GameData.MAX_LEVEL - lv)
	if levels <= 0:
		return INF
	var g := GameData.UPGRADE_COST_GROWTH
	var base := float(def["cost"]) * GameData.UPGRADE_COST_FACTOR * PrestigeSystem.cost_mult() * Modifiers.mult("upgrade_cost", 0.3)
	return base * pow(g, lv - 1) * (pow(g, levels) - 1.0) / (g - 1.0)


## Quantos níveis podem ser comprados com o dinheiro informado.
func affordable_levels(b: Dictionary, money: float) -> int:
	var def := GameData.get_def(b["id"])
	var lv := int(b["level"])
	var remaining := GameData.MAX_LEVEL - lv
	if remaining <= 0:
		return 0
	var g := GameData.UPGRADE_COST_GROWTH
	var first := float(def["cost"]) * GameData.UPGRADE_COST_FACTOR * PrestigeSystem.cost_mult() * Modifiers.mult("upgrade_cost", 0.3) * pow(g, lv - 1)
	if money < first:
		return 0
	var n := int(floor(log(money * (g - 1.0) / first + 1.0) / log(g)))
	n = clampi(n, 0, remaining)
	# Corrige imprecisões de ponto flutuante.
	while n > 0 and upgrade_cost(b, n) > money:
		n -= 1
	return n


func can_build(id: String) -> Dictionary:
	var def := GameData.get_def(id)
	if def.is_empty():
		return {"ok": false, "reason": "Edifício inválido"}
	if not is_def_unlocked(def):
		return {"ok": false, "reason": "Requer " + GameData.REGIONS[def["region"]]["name"]}
	if def.has("research") and not ResearchSystem.is_done(def["research"]):
		return {"ok": false, "reason": "Requer pesquisa: " + GameData.research_def(def["research"])["name"]}
	if def.get("unique", false) and count_owned(id) > 0:
		return {"ok": false, "reason": "Já construído"}
	if free_lot() < 0:
		return {"ok": false, "reason": "Sem terrenos livres"}
	if not EconomySystem.can_afford(build_cost(id)):
		return {"ok": false, "reason": "Dinheiro insuficiente"}
	return {"ok": true, "reason": ""}


# --- Ações -------------------------------------------------------------------

## Constrói o edifício no próximo terreno livre. Retorna o edifício ou {}.
func build(id: String, free: bool = false) -> Dictionary:
	var lot := free_lot()
	if lot < 0:
		return {}
	if not free:
		if not can_build(id)["ok"]:
			return {}
		if not EconomySystem.spend(build_cost(id), "build"):
			return {}
	var t := 0.0 if (free or instant_build) else build_time(id)
	var b := {"uid": next_uid, "id": id, "lot": lot, "level": 1, "build_left": t, "build_total": maxf(1.0, t)}
	next_uid += 1
	_add(b)
	if not free:
		MissionSystem.on_built()
		if GameData.get_def(id)["cat"] == "esp":
			MissionSystem.note_special()
		EventSystem.note("build", 1)
		ChallengeSystem.note("build", 1)
	building_built.emit(b)
	return b


func upgrade(uid: int, levels: int = 1) -> int:
	var b := get_building(uid)
	if b.is_empty():
		return 0
	if not is_complete(b):
		return 0
	levels = mini(levels, GameData.MAX_LEVEL - int(b["level"]))
	if levels <= 0:
		return 0
	var cost := upgrade_cost(b, levels)
	if not EconomySystem.spend(cost, "upgrade"):
		return 0
	b["level"] = int(b["level"]) + levels
	MissionSystem.on_upgraded(levels)
	EventSystem.note("upgrade", levels)
	ChallengeSystem.note("upgrade", levels)
	building_upgraded.emit(b, levels)
	return levels


func demolish_refund(b: Dictionary) -> float:
	return float(GameData.get_def(b["id"])["cost"]) * GameData.DEMOLISH_REFUND


func demolish(uid: int) -> bool:
	var b := get_building(uid)
	if b.is_empty():
		return false
	EconomySystem.add_money(demolish_refund(b), false)
	buildings.erase(b)
	_by_uid.erase(uid)
	_by_lot.erase(b["lot"])
	building_removed.emit(uid)
	return true
