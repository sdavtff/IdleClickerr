extends Node
## Índices urbanos: trânsito, poluição, produtividade e qualidade de vida.
## São calculados a partir da cidade e afetam felicidade, crescimento e renda.

## Congestionamento de 0 (livre) a 100 (parado).
var traffic := 0.0
## Moradores que se deslocam e capacidade de transporte.
var commuters := 0.0
var transit_capacity := 0.0
## Poluição de 0 a 100.
var pollution := 0.0
## Multiplicador de produtividade aplicado à renda de comércios e empresas.
var productivity := 1.0
## Qualidade de vida de 0 a 100.
var quality_of_life := 50.0


func transit_of(b: Dictionary) -> float:
	var def := GameData.get_def(b["id"])
	if not def.has("transit"):
		return 0.0
	var lv := int(b["level"])
	return float(def["transit"]) * (1.0 + 0.4 * (lv - 1)) * pow(1.5, BuildingSystem.milestones(lv))


func recompute() -> void:
	var cap := GameData.ROAD_CAPACITY_BASE + GameData.ROAD_CAPACITY_PER_REGION * ExpansionSystem.unlocked
	var poll_points := 0.0
	for b in BuildingSystem.buildings:
		if not BuildingSystem.is_complete(b):
			continue
		cap += transit_of(b)
		poll_points += float(GameData.get_def(b["id"]).get("pollution", 0))
	transit_capacity = cap * Modifiers.mult("transit")
	commuters = PopulationSystem.population
	var ratio := commuters / maxf(transit_capacity, 1.0)
	traffic = clampf((ratio - 0.6) / 0.8, 0.0, 1.0) * 100.0
	# Poluição: indústrias (com filtros de pesquisa) + parte do trânsito.
	var industrial := poll_points * (Modifiers.mult("pollution", 0.0) if poll_points > 0.0 else 1.0)
	pollution = clampf(industrial * 5.0 + traffic * 0.25, 0.0, 100.0)
	var edu := HappinessSystem.service_ratio("edu")
	productivity = (0.85 + 0.15 * edu) * (1.0 - 0.15 * traffic / 100.0)
	var needs := PopulationSystem.needs()
	var sum := 0.0
	for n in needs:
		sum += float(n["value"])
	var needs_avg := sum / maxf(1.0, needs.size())
	quality_of_life = clampf(needs_avg * 70.0 + (1.0 - traffic / 100.0) * 15.0 + (1.0 - pollution / 100.0) * 15.0, 0.0, 100.0)


## Penalidade de felicidade causada pelo trânsito (0 a -10).
func traffic_penalty() -> float:
	return -traffic / 10.0


## Penalidade de felicidade causada pela poluição (0 a -18).
func pollution_penalty() -> float:
	return -pollution * 0.18


## Qualidade de vida acelera ou freia o crescimento populacional (0,8x a 1,2x).
func growth_mult() -> float:
	return 0.8 + 0.4 * quality_of_life / 100.0


func grade() -> String:
	if quality_of_life >= 85.0:
		return "A"
	if quality_of_life >= 70.0:
		return "B"
	if quality_of_life >= 55.0:
		return "C"
	if quality_of_life >= 40.0:
		return "D"
	return "E"


func traffic_label() -> String:
	if traffic < 10.0:
		return "Livre"
	if traffic < 40.0:
		return "Moderado"
	if traffic < 75.0:
		return "Intenso"
	return "Congestionado"
