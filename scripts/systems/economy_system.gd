extends Node
## Sistema econômico: dinheiro, renda, despesas e multiplicadores.

signal money_changed(money: float)

var money := GameData.START_MONEY
## Total ganho nesta cidade (zera no prestígio). Usado para prestígio e missões.
var total_earned := 0.0
## Total ganho em todas as cidades (permanente).
var lifetime_earned := 0.0

# Valores calculados a cada tick.
var income_ps := 0.0
var expense_ps := 0.0
var net_ps := 0.0
var business_income := 0.0
var tax_income := 0.0
var work_efficiency := 1.0
var happiness_mult := 1.0
var global_mult := 1.0
var in_deficit := false


func reset(start_money: float) -> void:
	money = start_money
	total_earned = 0.0
	income_ps = 0.0
	expense_ps = 0.0
	net_ps = 0.0
	money_changed.emit(money)


func to_dict() -> Dictionary:
	return {"money": money, "total_earned": total_earned, "lifetime_earned": lifetime_earned}


func from_dict(d: Dictionary) -> void:
	money = maxf(0.0, _safe(d.get("money", GameData.START_MONEY)))
	total_earned = maxf(0.0, _safe(d.get("total_earned", 0.0)))
	lifetime_earned = maxf(total_earned, _safe(d.get("lifetime_earned", 0.0)))
	money_changed.emit(money)


static func _safe(v) -> float:
	var f := float(v) if (typeof(v) == TYPE_FLOAT or typeof(v) == TYPE_INT) else 0.0
	if is_nan(f) or is_inf(f):
		return 0.0
	return f


func can_afford(amount: float) -> bool:
	return money + 0.0001 >= amount


func spend(amount: float) -> bool:
	if amount < 0.0 or not can_afford(amount):
		return false
	money = maxf(0.0, money - amount)
	money_changed.emit(money)
	return true


## Adiciona dinheiro. Se `earned`, conta como renda ganha (missões/prestígio).
func add_money(amount: float, earned: bool = true) -> void:
	if amount <= 0.0 or is_nan(amount) or is_inf(amount):
		return
	money += amount
	if earned:
		total_earned += amount
		lifetime_earned += amount
	money_changed.emit(money)


## Multiplicador global aplicado a toda renda.
func compute_global_mult() -> float:
	var m := PrestigeSystem.income_mult()
	m *= MissionSystem.income_mult()
	for b in BuildingSystem.buildings:
		var bonus := float(GameData.get_def(b["id"]).get("income_bonus", 0.0))
		if bonus > 0.0:
			m *= 1.0 + bonus
	return m


## Recalcula renda e despesas a partir do estado atual da cidade.
func recompute() -> void:
	var jobs := 0.0
	var gross := 0.0
	var tax_potential := 0.0
	var upkeep := 0.0
	for b in BuildingSystem.buildings:
		gross += BuildingSystem.income_of(b)
		jobs += BuildingSystem.jobs_of(b)
		tax_potential += BuildingSystem.capacity_of(b) * BuildingSystem.tax_of(b)
		upkeep += BuildingSystem.upkeep_of(b)
	var pop := PopulationSystem.population
	var cap := PopulationSystem.capacity
	work_efficiency = 1.0 if jobs <= 0.0 else clampf(pop / jobs, GameData.MIN_WORK_EFFICIENCY, 1.0)
	var occupancy := 0.0 if cap <= 0.0 else clampf(pop / cap, 0.0, 1.0)
	happiness_mult = 0.7 + 0.6 * HappinessSystem.value / 100.0
	global_mult = compute_global_mult()
	business_income = gross * work_efficiency * happiness_mult * global_mult
	tax_income = tax_potential * occupancy * happiness_mult * global_mult
	income_ps = business_income + tax_income
	expense_ps = upkeep
	net_ps = income_ps - expense_ps


func tick(dt: float) -> void:
	if net_ps >= 0.0:
		in_deficit = false
		add_money(net_ps * dt, true)
	else:
		money = maxf(0.0, money + net_ps * dt)
		in_deficit = money <= 0.0
		money_changed.emit(money)
