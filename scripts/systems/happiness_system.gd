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
		if not BuildingSystem.is_complete(b):
			continue
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
	var poll_penalty := CityIndexSystem.pollution_penalty()
	if poll_penalty < -0.05:
		total += poll_penalty
		factors.append({"name": "Poluição", "value": poll_penalty, "max": 0.0})
	var traffic_pen := CityIndexSystem.traffic_penalty()
	if traffic_pen < -0.05:
		total += traffic_pen
		factors.append({"name": "Trânsito", "value": traffic_pen, "max": 0.0})
	var tax_h := EconomySystem.tax_happiness()
	if tax_h != 0.0:
		total += tax_h
		factors.append({"name": "Impostos", "value": tax_h, "max": 0.0})
	var unemp := PopulationSystem.unemployment_rate()
	# Desemprego só pesa em cidades maiores (a vila inicial não é punida).
	var size_k := clampf((PopulationSystem.population - 40.0) / 160.0, 0.0, 1.0)
	if unemp > 0.25 and size_k > 0.0:
		var pen := -clampf((unemp - 0.25) * 30.0, 0.0, 10.0) * size_k
		total += pen
		factors.append({"name": "Desemprego", "value": pen, "max": 0.0})
	var ev := EventSystem.fx("happy")
	if ev != 0.0:
		total += ev
		factors.append({"name": "Evento", "value": ev, "max": 0.0})
	var bonus := flat + PrestigeSystem.happiness_bonus() + ResearchSystem.fx("happy")
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
