extends Node
## Sistema de população: capacidade habitacional, empregos e crescimento
## influenciado pela felicidade.

const START_POPULATION := 8.0

var population := START_POPULATION
var capacity := 0.0
var jobs := 0.0
var target := 0.0
var growth_per_sec := 0.0


func reset() -> void:
	population = START_POPULATION
	growth_per_sec = 0.0
	recompute()


func to_dict() -> Dictionary:
	return {"population": population}


func from_dict(d: Dictionary) -> void:
	population = maxf(0.0, EconomySystem._safe(d.get("population", START_POPULATION)))
	recompute()


func recompute() -> void:
	var cap := 0.0
	var j := 0.0
	for b in BuildingSystem.buildings:
		if not BuildingSystem.is_complete(b):
			continue
		cap += BuildingSystem.capacity_of(b)
		j += BuildingSystem.jobs_of(b)
	capacity = cap * PrestigeSystem.capacity_mult()
	jobs = j
	target = capacity * clampf(0.5 + HappinessSystem.value / 100.0, 0.5, 1.0)


## Felicidade alta atrai moradores mais rápido; baixa reduz o limite.
func growth_speed() -> float:
	return (0.35 + HappinessSystem.value / 100.0 * 1.15) * PrestigeSystem.growth_mult() * Modifiers.mult("growth")


func tick(dt: float) -> void:
	recompute()
	var before := population
	if population < target:
		var step := maxf(0.25, (target - population) * 0.04) * growth_speed() * dt
		population = minf(target, population + step)
	elif population > target:
		var drop := maxf(0.1, (population - target) * 0.03) * dt
		population = maxf(target, population - drop)
	growth_per_sec = (population - before) / maxf(dt, 0.0001)
	MissionSystem.note_population(population)


## Avança o crescimento durante o tempo offline (aproximação fechada).
func simulate_offline(seconds: float) -> void:
	recompute()
	if population < target:
		var k := 0.04 * growth_speed()
		var gap := target - population
		var remaining := gap * exp(-k * seconds) - 0.25 * growth_speed() * seconds
		population = target - maxf(0.0, remaining)
	MissionSystem.note_population(population)


## Moradores sem emprego (0 se houver vagas para todos).
func unemployed() -> float:
	return maxf(0.0, population - jobs)


func unemployment_rate() -> float:
	return 0.0 if population < 1.0 else unemployed() / population


## Necessidades da população (0 a 1) para o painel.
func needs() -> Array:
	var housing := 1.0 if capacity <= 0.0 else clampf((capacity - population) / maxf(1.0, capacity * 0.1) + 0.5, 0.0, 1.0)
	var job_ok := 1.0 - clampf(unemployment_rate() / 0.5, 0.0, 1.0)
	return [
		{"name": "Moradia", "value": housing, "hint": "Construa ou melhore residências"},
		{"name": "Empregos", "value": job_ok, "hint": "Comércios, empresas e indústrias geram vagas"},
		{"name": "Saúde", "value": HappinessSystem.service_ratio("saude"), "hint": "Hospitais e centros médicos"},
		{"name": "Educação", "value": HappinessSystem.service_ratio("edu"), "hint": "Escolas, bibliotecas e universidades"},
		{"name": "Lazer", "value": HappinessSystem.service_ratio("lazer"), "hint": "Parques, praças, cinemas e estádios"},
		{"name": "Segurança", "value": HappinessSystem.service_ratio("seg"), "hint": "Delegacias e bombeiros"},
	]


func available_jobs_ratio() -> float:
	if jobs <= 0.0:
		return 1.0
	return population / jobs
