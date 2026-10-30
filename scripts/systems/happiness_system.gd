extends Node
## Sistema de felicidade (0% a 100%). Depende de serviços (saúde, educação,
## segurança e lazer) em relação à população, qualidade das moradias,
## poluição e bônus fixos.

## Valor exibido (suavizado).
var value := 30.0
## Valor alvo calculado.
var target := 30.0
## Detalhamento para a interface: [{name, value, max}]
var factors: Array = []
var coverage: Dictionary = {"saude": 0.0, "edu": 0.0, "seg": 0.0, "lazer": 0.0}

const BASE := 25.0
const WEIGHTS := {"saude": 15.0, "edu": 14.0, "seg": 12.0, "lazer": 18.0}
const HOUSING_MAX := 10.0


func reset() -> void:
	recompute()
	value = target


func to_dict() -> Dictionary:
	return {"value": value}


func from_dict(d: Dictionary) -> void:
	value = clampf(EconomySystem._safe(d.get("value", 30.0)), 0.0, 100.0)
	recompute()


func service_ratio(kind: String) -> float:
	var pop := maxf(PopulationSystem.population, 20.0)
	return clampf(float(coverage.get(kind, 0.0)) / pop, 0.0, 1.0)


func recompute() -> void:
	for k in coverage.keys():
		coverage[k] = 0.0
	var flat := 0.0
	var pollution := 0.0
	var comfort_sum := 0.0
	var cap_sum := 0.0
	for b in BuildingSystem.buildings:
		var def := GameData.get_def(b["id"])
		if def.has("service"):
			coverage[def["service"]] += BuildingSystem.coverage_of(b)
		flat += float(def.get("happy", 0))
		pollution += float(def.get("pollution", 0))
		if def["cat"] == "res":
			var c := BuildingSystem.capacity_of(b)
			cap_sum += c
			comfort_sum += c * float(def.get("comfort", 0.3)) * minf(1.0, 0.8 + 0.02 * int(b["level"]))
	factors = []
	var total := BASE
	factors.append({"name": "Base", "value": BASE, "max": BASE})
	for k in ["saude", "edu", "seg", "lazer"]:
		var v: float = WEIGHTS[k] * service_ratio(k)
		total += v
		factors.append({"name": GameData.SERVICE_NAMES[k], "value": v, "max": WEIGHTS[k]})
	var housing := 0.0 if cap_sum <= 0.0 else HOUSING_MAX * comfort_sum / cap_sum
	total += housing
	factors.append({"name": "Moradias", "value": housing, "max": HOUSING_MAX})
	var poll_penalty := clampf(pollution * 1.5, 0.0, 20.0)
	if poll_penalty > 0.0:
		total -= poll_penalty
		factors.append({"name": "Poluição", "value": -poll_penalty, "max": 0.0})
	var bonus := flat + PrestigeSystem.happiness_bonus()
	if bonus != 0.0:
		total += bonus
		factors.append({"name": "Bônus", "value": bonus, "max": 0.0})
	target = clampf(total, 0.0, 100.0)


func tick(dt: float) -> void:
	recompute()
	value = move_toward(value, target, maxf(1.5, absf(target - value) * 0.5) * dt)
	MissionSystem.note_happiness(value)


func label() -> String:
	if value >= 85.0:
		return "Radiante"
	if value >= 65.0:
		return "Feliz"
	if value >= 45.0:
		return "Satisfeita"
	if value >= 25.0:
		return "Insatisfeita"
	return "Revoltada"


func color() -> Color:
	if value >= 65.0:
		return Color("2ecc71")
	if value >= 45.0:
		return Color("f1c40f")
	if value >= 25.0:
		return Color("e67e22")
	return Color("e74c3c")
