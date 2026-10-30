extends Node
## Sistema de expansão: regiões desbloqueadas da cidade (crescimento horizontal).

signal region_unlocked(index: int)

## Quantidade de regiões desbloqueadas (a Vila inicial sempre conta).
var unlocked := 1


func reset(start_regions: int = 1) -> void:
	unlocked = clampi(start_regions, 1, GameData.region_count())


func to_dict() -> Dictionary:
	return {"unlocked": unlocked}


func from_dict(d: Dictionary) -> void:
	unlocked = clampi(int(d.get("unlocked", 1)), 1, GameData.region_count())


func next_region() -> int:
	return unlocked if unlocked < GameData.region_count() else -1


func unlock_cost(index: int) -> float:
	return float(GameData.REGIONS[index]["cost"])


func requirements(index: int) -> Dictionary:
	var r: Dictionary = GameData.REGIONS[index]
	return {
		"money": float(r["cost"]),
		"pop": int(r["pop"]),
		"money_ok": EconomySystem.can_afford(float(r["cost"])),
		"pop_ok": PopulationSystem.population + 0.001 >= float(r["pop"]),
		"order_ok": index == unlocked,
	}


func can_unlock(index: int) -> bool:
	if index < 0 or index >= GameData.region_count() or index != unlocked:
		return false
	var req := requirements(index)
	return req["money_ok"] and req["pop_ok"]


func unlock(index: int) -> bool:
	if not can_unlock(index):
		return false
	if not EconomySystem.spend(unlock_cost(index)):
		return false
	unlocked = index + 1
	MissionSystem.note_regions(unlocked)
	region_unlocked.emit(index)
	return true


## Desbloqueio sem custo (usado por bônus de prestígio).
func force_unlock_to(count: int) -> void:
	unlocked = clampi(maxi(unlocked, count), 1, GameData.region_count())
	MissionSystem.note_regions(unlocked)
