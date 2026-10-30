extends Node
## Sistema de missões (por cidade) e conquistas (permanentes).

signal mission_ready(m: Dictionary)
signal mission_claimed(m: Dictionary)
signal achievement_unlocked(a: Dictionary)
signal missions_changed

const ACTIVE_COUNT := 3

# --- Estado da cidade atual (zera no prestígio) ---
var claimed: Array = []
var announced: Array = []
var run_built := 0
var run_upgrades := 0
var run_bubbles := 0
var run_bonus := 0.0

# --- Estado permanente ---
var lifetime := {
	"built": 0, "upgrades": 0, "max_pop": 0.0, "max_happy": 0.0, "max_regions": 1,
	"max_level": 1, "bubbles": 0, "max_offline": 0.0, "prestiges": 0, "earned": 0.0,
}
var achievements: Array = []


func reset_run() -> void:
	claimed.clear()
	announced.clear()
	run_built = 0
	run_upgrades = 0
	run_bubbles = 0
	run_bonus = 0.0
	missions_changed.emit()


## Apaga também o progresso permanente (usado em "Novo jogo").
func wipe() -> void:
	reset_run()
	for k in lifetime.keys():
		lifetime[k] = 0
	lifetime["max_regions"] = 1
	lifetime["max_level"] = 1
	achievements.clear()


func to_dict() -> Dictionary:
	return {
		"claimed": claimed.duplicate(), "announced": announced.duplicate(),
		"run_built": run_built, "run_upgrades": run_upgrades, "run_bubbles": run_bubbles,
		"run_bonus": run_bonus, "lifetime": lifetime.duplicate(), "achievements": achievements.duplicate(),
	}


func from_dict(d: Dictionary) -> void:
	claimed = _string_array(d.get("claimed", []))
	announced = _string_array(d.get("announced", []))
	run_built = int(d.get("run_built", 0))
	run_upgrades = int(d.get("run_upgrades", 0))
	run_bubbles = int(d.get("run_bubbles", 0))
	run_bonus = maxf(0.0, EconomySystem._safe(d.get("run_bonus", 0.0)))
	var lt = d.get("lifetime", {})
	if typeof(lt) == TYPE_DICTIONARY:
		for k in lifetime.keys():
			if lt.has(k):
				lifetime[k] = lt[k]
	achievements = _string_array(d.get("achievements", []))
	missions_changed.emit()


static func _string_array(v) -> Array:
	var out := []
	if typeof(v) == TYPE_ARRAY:
		for x in v:
			out.append(str(x))
	return out


# --- Registro de eventos -------------------------------------------------------

func on_built() -> void:
	run_built += 1
	lifetime["built"] = int(lifetime["built"]) + 1


func on_upgraded(levels: int) -> void:
	run_upgrades += levels
	lifetime["upgrades"] = int(lifetime["upgrades"]) + levels
	lifetime["max_level"] = maxi(int(lifetime["max_level"]), BuildingSystem.max_level())


func on_bubble() -> void:
	run_bubbles += 1
	lifetime["bubbles"] = int(lifetime["bubbles"]) + 1


func note_population(p: float) -> void:
	if p > float(lifetime["max_pop"]):
		lifetime["max_pop"] = p


func note_happiness(h: float) -> void:
	if h > float(lifetime["max_happy"]):
		lifetime["max_happy"] = h


func note_regions(n: int) -> void:
	lifetime["max_regions"] = maxi(int(lifetime["max_regions"]), n)


func note_offline(seconds: float) -> void:
	lifetime["max_offline"] = maxf(float(lifetime["max_offline"]), seconds)


func note_prestige() -> void:
	lifetime["prestiges"] = int(lifetime["prestiges"]) + 1


# --- Missões -------------------------------------------------------------------

func income_mult() -> float:
	return (1.0 + run_bonus) * (1.0 + GameData.ACHIEVEMENT_BONUS * achievements.size())


func active_missions() -> Array:
	var out := []
	for m in GameData.MISSIONS:
		if not claimed.has(m["id"]):
			out.append(m)
			if out.size() >= ACTIVE_COUNT:
				break
	return out


func progress(m: Dictionary) -> float:
	match str(m["type"]):
		"build_total":
			return float(run_built)
		"own":
			return float(BuildingSystem.count_owned(m["key"]))
		"earn":
			return EconomySystem.total_earned
		"pop":
			return floor(PopulationSystem.population)
		"happy":
			return HappinessSystem.value
		"region":
			return float(ExpansionSystem.unlocked)
		"level":
			return float(BuildingSystem.max_level())
		"total_levels":
			return float(BuildingSystem.total_levels())
		"income":
			return EconomySystem.net_ps
		"bubbles":
			return float(run_bubbles)
	return 0.0


func is_complete(m: Dictionary) -> bool:
	return progress(m) + 0.0001 >= float(m["target"])


func ready_count() -> int:
	var n := 0
	for m in active_missions():
		if is_complete(m):
			n += 1
	return n


func claim(id: String) -> bool:
	var idx := GameData.mission_index(id)
	if idx < 0 or claimed.has(id):
		return false
	var m: Dictionary = GameData.MISSIONS[idx]
	if not active_missions().has(m) or not is_complete(m):
		return false
	claimed.append(id)
	EconomySystem.add_money(float(m["reward"]), false)
	run_bonus += float(m.get("bonus", 0.0))
	mission_claimed.emit(m)
	missions_changed.emit()
	return true


func all_done() -> bool:
	return claimed.size() >= GameData.MISSIONS.size()


# --- Conquistas ----------------------------------------------------------------

func achievement_progress(a: Dictionary) -> float:
	var key: String = a["stat"]
	if key == "earned":
		return EconomySystem.lifetime_earned
	return float(lifetime.get(key, 0))


func check() -> void:
	lifetime["earned"] = EconomySystem.lifetime_earned
	lifetime["max_level"] = maxi(int(lifetime["max_level"]), BuildingSystem.max_level())
	for m in active_missions():
		if is_complete(m) and not announced.has(m["id"]):
			announced.append(m["id"])
			mission_ready.emit(m)
	for a in GameData.ACHIEVEMENTS:
		if achievements.has(a["id"]):
			continue
		if achievement_progress(a) + 0.0001 >= float(a["target"]):
			achievements.append(a["id"])
			achievement_unlocked.emit(a)
