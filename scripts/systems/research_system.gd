extends Node
## Árvore de pesquisas: pontos de pesquisa (PP) gerados por escolas,
## bibliotecas e universidades; uma pesquisa por vez, com duração.

signal research_started(r: Dictionary)
signal research_completed(r: Dictionary)

var points := 0.0
var done: Array = []
var active_id := ""
var active_left := 0.0
var points_per_sec := 0.0
var _fx_cache := {}

const OFFLINE_RP_RATE := 0.5
const OFFLINE_RP_MAX_SECONDS := 7200.0


func reset() -> void:
	points = 0.0
	done.clear()
	active_id = ""
	active_left = 0.0
	_rebuild_fx()


func to_dict() -> Dictionary:
	return {"points": points, "done": done.duplicate(), "active": active_id, "left": active_left}


func from_dict(d: Dictionary) -> void:
	points = maxf(0.0, EconomySystem._safe(d.get("points", 0.0)))
	done = []
	for x in d.get("done", []):
		if not GameData.research_def(str(x)).is_empty() and not done.has(str(x)):
			done.append(str(x))
	active_id = str(d.get("active", ""))
	if GameData.research_def(active_id).is_empty() or done.has(active_id):
		active_id = ""
	active_left = maxf(0.0, EconomySystem._safe(d.get("left", 0.0)))
	_rebuild_fx()


func is_done(id: String) -> bool:
	return done.has(id)


func duration_of(r: Dictionary) -> float:
	return 20.0 + float(r["cost"]) * 1.5


func state_of(id: String) -> String:
	if done.has(id):
		return "done"
	if active_id == id:
		return "active"
	var r := GameData.research_def(id)
	for req in r.get("req", []):
		if not done.has(req):
			return "locked"
	return "available"


func can_start(id: String) -> bool:
	var r := GameData.research_def(id)
	return not r.is_empty() and active_id == "" and state_of(id) == "available" and points + 0.0001 >= float(r["cost"])


func start(id: String) -> bool:
	if not can_start(id):
		return false
	var r := GameData.research_def(id)
	points -= float(r["cost"])
	active_id = id
	active_left = duration_of(r)
	research_started.emit(r)
	return true


func compute_rate() -> float:
	var rate := 0.1
	for b in BuildingSystem.buildings:
		if not BuildingSystem.is_complete(b):
			continue
		var def := GameData.get_def(b["id"])
		var w := 0.0
		if def.get("service", "") == "edu":
			w = 0.05
		elif def["id"] in ["empresa_tecnologia", "centro_medico", "complexo_hospitalar"]:
			w = 0.04
		if w > 0.0:
			rate += w * (1.0 + int(def["region"])) * pow(float(b["level"]), 0.6)
	rate *= 1.0 + 0.25 * PrestigeSystem.level("laboratorio")
	rate *= 1.0 + EventSystem.fx("rp")
	return rate


func tick(dt: float) -> void:
	points_per_sec = compute_rate()
	points += points_per_sec * dt
	_advance(dt)


## Tempo offline: gera pontos e avança a pesquisa ativa.
func simulate_offline(seconds: float) -> Array:
	points_per_sec = compute_rate()
	# Offline: metade da velocidade e no máximo 2 horas de pontos.
	points += points_per_sec * minf(seconds, OFFLINE_RP_MAX_SECONDS) * OFFLINE_RP_RATE
	var before := done.size()
	_advance(seconds)
	return done.slice(before)


func _advance(dt: float) -> void:
	if active_id == "":
		return
	active_left -= dt
	if active_left <= 0.0:
		var r := GameData.research_def(active_id)
		done.append(active_id)
		active_id = ""
		active_left = 0.0
		_rebuild_fx()
		MissionSystem.note_research(done.size())
		ChallengeSystem.note("research", 1)
		research_completed.emit(r)


func active_progress() -> float:
	if active_id == "":
		return 0.0
	var dur := duration_of(GameData.research_def(active_id))
	return clampf(1.0 - active_left / dur, 0.0, 1.0)


func _rebuild_fx() -> void:
	_fx_cache = {}
	for id in done:
		var r := GameData.research_def(id)
		for k in r.get("fx", {}).keys():
			_fx_cache[k] = float(_fx_cache.get(k, 0.0)) + float(r["fx"][k])


func fx(key: String) -> float:
	return float(_fx_cache.get(key, 0.0))


## Apenas para testes/depuração.
func force_complete(id: String) -> void:
	if not done.has(id):
		done.append(id)
	_rebuild_fx()
