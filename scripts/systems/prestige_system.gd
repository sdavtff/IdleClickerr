extends Node
## Sistema de prestígio: reinicia a cidade em troca de Estrelas de Prestígio,
## que dão bônus permanentes e compram melhorias de legado.

signal prestige_done(stars_gained: int)
signal upgrades_changed

## Estrelas disponíveis para gastar.
var stars := 0
## Estrelas já conquistadas no total (cada uma dá +5% de renda permanente).
var stars_total := 0
var prestige_count := 0
var upgrades := {}


func to_dict() -> Dictionary:
	return {"stars": stars, "stars_total": stars_total, "count": prestige_count, "upgrades": upgrades.duplicate()}


func from_dict(d: Dictionary) -> void:
	stars = maxi(0, int(d.get("stars", 0)))
	stars_total = maxi(stars, int(d.get("stars_total", 0)))
	prestige_count = maxi(0, int(d.get("count", 0)))
	upgrades = {}
	var u = d.get("upgrades", {})
	if typeof(u) == TYPE_DICTIONARY:
		for k in u.keys():
			var def := GameData.prestige_upgrade(str(k))
			if not def.is_empty():
				upgrades[str(k)] = clampi(int(u[k]), 0, int(def["max"]))


func wipe() -> void:
	stars = 0
	stars_total = 0
	prestige_count = 0
	upgrades = {}


func level(id: String) -> int:
	return int(upgrades.get(id, 0))


# --- Bônus -----------------------------------------------------------------------

func income_mult() -> float:
	return (1.0 + GameData.STAR_INCOME_BONUS * stars_total) * (1.0 + 0.1 * level("marketing"))


func cost_mult() -> float:
	return 1.0 - 0.05 * level("eficiencia")


func growth_mult() -> float:
	return 1.0 + 0.25 * level("imigracao")


func capacity_mult() -> float:
	return 1.0 + 0.05 * level("imigracao")


func happiness_bonus() -> float:
	return 4.0 * level("carisma")


func start_money() -> float:
	return maxf(GameData.START_MONEY, GameData.CAPITAL_LEVELS[clampi(level("capital"), 0, GameData.CAPITAL_LEVELS.size() - 1)])


func start_regions() -> int:
	return 1 + level("heranca")


# --- Prestígio -------------------------------------------------------------------

func stars_on_reset() -> int:
	return int(floor(sqrt(EconomySystem.total_earned / GameData.PRESTIGE_DIVISOR)))


func can_prestige() -> bool:
	return ExpansionSystem.unlocked >= GameData.PRESTIGE_MIN_REGIONS and stars_on_reset() >= 1


func do_prestige() -> int:
	if not can_prestige():
		return 0
	var gained := stars_on_reset()
	stars += gained
	stars_total += gained
	prestige_count += 1
	MissionSystem.note_prestige()
	prestige_done.emit(gained)
	return gained


func upgrade_cost(id: String) -> int:
	var def := GameData.prestige_upgrade(id)
	return int(ceil(float(def["base"]) * pow(float(def["growth"]), level(id))))


func can_buy(id: String) -> bool:
	var def := GameData.prestige_upgrade(id)
	return not def.is_empty() and level(id) < int(def["max"]) and stars >= upgrade_cost(id)


func buy(id: String) -> bool:
	if not can_buy(id):
		return false
	stars -= upgrade_cost(id)
	upgrades[id] = level(id) + 1
	upgrades_changed.emit()
	return true
