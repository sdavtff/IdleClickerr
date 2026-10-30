extends Node
## Sistema econômico: dinheiro, renda por categoria, impostos, manutenção,
## banco (investimentos e empréstimos), histórico e relatório financeiro.

signal money_changed(money: float)
signal investment_matured(inv: Dictionary)

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
var upkeep_ps := 0.0
var loan_payment_ps := 0.0
var work_efficiency := 1.0
var happiness_mult := 1.0
var global_mult := 1.0
var in_deficit := false
## Renda por categoria (R$/s): res (impostos), com, biz, fun, esp.
var income_by_cat := {}
## Manutenção por categoria (R$/s).
var upkeep_by_cat := {}

# Finanças da cidade.
var tax_level := 1
var loan_balance := 0.0
var investments: Array = []
## Relógio interno do jogo (avança jogando e offline) usado pelos investimentos.
var econ_time := 0.0
## Histórico: [{t, money, income, expense}]
var history: Array = []
var _history_acc := 0.0
## Totais desta cidade por tipo de lançamento.
var ledger := {}

const HISTORY_INTERVAL := 30.0
const HISTORY_MAX := 120
const LEDGER_KEYS := ["ops", "rewards", "invest", "loan_in", "build", "upgrade", "expansion", "accelerate", "loan_out", "invest_out", "upkeep"]


func reset(start_money: float) -> void:
	money = start_money
	total_earned = 0.0
	income_ps = 0.0
	expense_ps = 0.0
	net_ps = 0.0
	tax_level = 1
	loan_balance = 0.0
	investments = []
	history = []
	_history_acc = 0.0
	ledger = {}
	money_changed.emit(money)


func to_dict() -> Dictionary:
	return {"money": money, "total_earned": total_earned, "lifetime_earned": lifetime_earned,
		"tax_level": tax_level, "loan": loan_balance, "investments": investments.duplicate(true),
		"econ_time": econ_time, "history": history.duplicate(true), "ledger": ledger.duplicate()}


func from_dict(d: Dictionary) -> void:
	money = maxf(0.0, _safe(d.get("money", GameData.START_MONEY)))
	total_earned = maxf(0.0, _safe(d.get("total_earned", 0.0)))
	lifetime_earned = maxf(total_earned, _safe(d.get("lifetime_earned", 0.0)))
	tax_level = clampi(int(d.get("tax_level", 1)), 0, GameData.TAX_LEVELS.size() - 1)
	loan_balance = maxf(0.0, _safe(d.get("loan", 0.0)))
	econ_time = maxf(0.0, _safe(d.get("econ_time", 0.0)))
	investments = []
	for inv in d.get("investments", []):
		if typeof(inv) == TYPE_DICTIONARY and not GameData.investment_def(str(inv.get("id", ""))).is_empty():
			investments.append({"id": str(inv["id"]), "amount": maxf(0.0, _safe(inv.get("amount", 0.0))),
				"end": _safe(inv.get("end", 0.0)), "rate": _safe(inv.get("rate", 0.0))})
	history = []
	for h in d.get("history", []):
		if typeof(h) == TYPE_DICTIONARY:
			history.append(h)
	ledger = {}
	var lg = d.get("ledger", {})
	if typeof(lg) == TYPE_DICTIONARY:
		for k in lg.keys():
			ledger[str(k)] = _safe(lg[k])
	money_changed.emit(money)


static func _safe(v) -> float:
	var f := float(v) if (typeof(v) == TYPE_FLOAT or typeof(v) == TYPE_INT) else 0.0
	if is_nan(f) or is_inf(f):
		return 0.0
	return f


func _log(key: String, amount: float) -> void:
	ledger[key] = float(ledger.get(key, 0.0)) + amount


func can_afford(amount: float) -> bool:
	return money + 0.0001 >= amount


func spend(amount: float, category: String = "build") -> bool:
	if amount < 0.0 or not can_afford(amount):
		return false
	money = maxf(0.0, money - amount)
	_log(category, amount)
	money_changed.emit(money)
	return true


## Adiciona dinheiro. Se `earned`, conta como renda ganha (missões/prestígio).
func add_money(amount: float, earned: bool = true, category: String = "") -> void:
	if amount <= 0.0 or is_nan(amount) or is_inf(amount):
		return
	money += amount
	_log(category if category != "" else ("ops" if earned else "rewards"), amount)
	if earned:
		total_earned += amount
		lifetime_earned += amount
		ChallengeSystem.note_earned(amount)
	money_changed.emit(money)


## Recompensa proporcional à renda (minutos), limitada a uma fração do custo da
## próxima região para evitar o efeito "bola de neve" na progressão.
func scaled_reward(minutes: float, cap_fraction: float, minimum := 500.0) -> float:
	var amount := maxf(minimum, income_ps * 60.0 * minutes)
	var next := ExpansionSystem.next_region()
	if next >= 0:
		amount = minf(amount, maxf(minimum, ExpansionSystem.unlock_cost(next) * cap_fraction))
	return amount


# --- Impostos -------------------------------------------------------------------------

func tax_mult() -> float:
	return float(GameData.TAX_LEVELS[tax_level]["mult"]) * Modifiers.mult("tax")


func tax_happiness() -> float:
	return float(GameData.TAX_LEVELS[tax_level]["happy"])


func set_tax_level(i: int) -> void:
	tax_level = clampi(i, 0, GameData.TAX_LEVELS.size() - 1)
	recompute()


# --- Renda ------------------------------------------------------------------------------

## Multiplicador global aplicado a toda renda.
func compute_global_mult() -> float:
	var m := PrestigeSystem.income_mult()
	m *= MissionSystem.income_mult()
	for b in BuildingSystem.buildings:
		if not BuildingSystem.is_complete(b):
			continue
		var bonus := float(GameData.get_def(b["id"]).get("income_bonus", 0.0))
		if bonus > 0.0:
			m *= 1.0 + bonus
	return m


## Recalcula renda e despesas a partir do estado atual da cidade.
func recompute() -> void:
	var jobs := 0.0
	var tax_potential := 0.0
	var gross_by_cat := {}
	upkeep_by_cat = {}
	var upkeep_mult := Modifiers.mult("upkeep")
	var upkeep := 0.0
	for b in BuildingSystem.buildings:
		if not BuildingSystem.is_complete(b):
			continue
		var cat: String = GameData.get_def(b["id"])["cat"]
		var inc := BuildingSystem.income_of(b)
		if inc > 0.0:
			gross_by_cat[cat] = float(gross_by_cat.get(cat, 0.0)) + inc * Modifiers.category_mult(cat)
		jobs += BuildingSystem.jobs_of(b)
		tax_potential += BuildingSystem.capacity_of(b) * BuildingSystem.tax_of(b)
		var u := BuildingSystem.upkeep_of(b) * upkeep_mult
		if u > 0.0:
			upkeep += u
			upkeep_by_cat[cat] = float(upkeep_by_cat.get(cat, 0.0)) + u
	var pop := PopulationSystem.population
	var cap := PopulationSystem.capacity
	work_efficiency = 1.0 if jobs <= 0.0 else clampf(pop / jobs, GameData.MIN_WORK_EFFICIENCY, 1.0)
	var occupancy := 0.0 if cap <= 0.0 else clampf(pop / cap, 0.0, 1.0)
	happiness_mult = 0.7 + 0.6 * HappinessSystem.value / 100.0
	global_mult = compute_global_mult()
	var k := work_efficiency * happiness_mult * global_mult * CityIndexSystem.productivity
	income_by_cat = {}
	business_income = 0.0
	for cat in gross_by_cat.keys():
		var v: float = gross_by_cat[cat] * k
		income_by_cat[cat] = v
		business_income += v
	tax_income = tax_potential * occupancy * happiness_mult * global_mult * tax_mult() * Modifiers.mult("all_income")
	income_by_cat["res"] = tax_income
	income_ps = business_income + tax_income
	upkeep_ps = upkeep
	loan_payment_ps = 0.0
	if loan_balance > 0.0:
		loan_payment_ps = minf(maxf(income_ps - upkeep, 0.0) * GameData.LOAN_REPAY_SHARE, loan_balance * 10.0)
	expense_ps = upkeep + loan_payment_ps
	net_ps = income_ps - expense_ps


func tick(dt: float) -> void:
	econ_time += dt
	if loan_balance > 0.0 and loan_payment_ps > 0.0:
		var pay := minf(loan_balance, loan_payment_ps * dt)
		loan_balance -= pay
		_log("loan_out", pay)
		if loan_balance < 0.01:
			loan_balance = 0.0
	_log("upkeep", upkeep_ps * dt)
	var gain := (income_ps - upkeep_ps) * dt
	if gain >= 0.0:
		in_deficit = false
		var net_gain := gain - loan_payment_ps * dt
		if net_gain > 0.0:
			add_money(net_gain, true)
	else:
		money = maxf(0.0, money + gain)
		in_deficit = money <= 0.0
		money_changed.emit(money)
	_check_investments()
	_history_acc += dt
	if _history_acc >= HISTORY_INTERVAL:
		_history_acc = 0.0
		record_history()


func record_history() -> void:
	history.append({"t": econ_time, "money": money, "income": income_ps, "expense": expense_ps,
		"pop": PopulationSystem.population, "happy": HappinessSystem.value, "traffic": CityIndexSystem.traffic, "qol": CityIndexSystem.quality_of_life})
	while history.size() > HISTORY_MAX:
		history.pop_front()


## Avança o relógio financeiro no tempo offline (investimentos e empréstimo).
func simulate_offline(seconds: float) -> Array:
	econ_time += seconds
	if loan_balance > 0.0:
		var pay := minf(loan_balance, loan_payment_ps * seconds)
		loan_balance -= pay
		_log("loan_out", pay)
	return matured_investments()


# --- Banco: empréstimos -----------------------------------------------------------

func loan_limit() -> float:
	return maxf(5000.0, income_ps * 1800.0)


func take_loan(amount: float) -> bool:
	if amount <= 0.0 or loan_balance > 0.0 or amount > loan_limit() + 0.01:
		return false
	money += amount
	loan_balance = amount * (1.0 + GameData.LOAN_INTEREST)
	_log("loan_in", amount)
	money_changed.emit(money)
	recompute()
	return true


func repay_loan() -> bool:
	if loan_balance <= 0.0 or not can_afford(loan_balance):
		return false
	money -= loan_balance
	_log("loan_out", loan_balance)
	loan_balance = 0.0
	money_changed.emit(money)
	recompute()
	return true


# --- Banco: investimentos ------------------------------------------------------------

func invest_limit() -> float:
	return maxf(1000.0, income_ps * 3600.0)


func invest(id: String, amount: float) -> bool:
	var def := GameData.investment_def(id)
	if def.is_empty() or investments.size() >= GameData.MAX_INVESTMENTS:
		return false
	amount = minf(amount, invest_limit())
	if amount <= 0.0 or not spend(amount, "invest_out"):
		return false
	var rate := randf_range(float(def["min"]), float(def["max"]))
	rate *= 1.0 + 0.1 * PrestigeSystem.level("juros") if rate > 0.0 else 1.0
	investments.append({"id": id, "amount": amount, "end": econ_time + float(def["dur"]), "rate": rate})
	return true


func investment_left(inv: Dictionary) -> float:
	return maxf(0.0, float(inv["end"]) - econ_time)


func is_matured(inv: Dictionary) -> bool:
	return investment_left(inv) <= 0.0


func matured_investments() -> Array:
	return investments.filter(func(inv): return is_matured(inv))


func collect_investment(index: int) -> float:
	if index < 0 or index >= investments.size():
		return -1.0
	var inv: Dictionary = investments[index]
	if not is_matured(inv):
		return -1.0
	investments.remove_at(index)
	var payout := float(inv["amount"]) * (1.0 + float(inv["rate"]))
	money += payout
	_log("invest", payout)
	var profit := payout - float(inv["amount"])
	if profit > 0.0:
		total_earned += profit
		lifetime_earned += profit
	MissionSystem.note_investment()
	ChallengeSystem.note("invest", 1)
	money_changed.emit(money)
	return payout


var _notified := {}


func _check_investments() -> void:
	for inv in investments:
		var key := "%s_%d" % [inv["id"], int(inv["end"])]
		if is_matured(inv) and not _notified.has(key):
			_notified[key] = true
			investment_matured.emit(inv)
