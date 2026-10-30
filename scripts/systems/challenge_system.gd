extends Node
## Desafios diários (3 por dia) e metas semanais (3 por semana), gerados de
## forma determinística pela data. O relógio voltando no tempo não gera novos.

signal challenges_changed
signal challenge_completed(c: Dictionary, weekly: bool)

var day_key := ""
var week_key := ""
var daily: Array = []
var weekly: Array = []


func to_dict() -> Dictionary:
	return {"day": day_key, "week": week_key, "daily": daily.duplicate(true), "weekly": weekly.duplicate(true)}


func from_dict(d: Dictionary) -> void:
	day_key = str(d.get("day", ""))
	week_key = str(d.get("week", ""))
	daily = _clean(d.get("daily", []))
	weekly = _clean(d.get("weekly", []))
	refresh_periods()


func reset() -> void:
	day_key = ""
	week_key = ""
	daily = []
	weekly = []
	refresh_periods()


static func _clean(v) -> Array:
	var out := []
	if typeof(v) != TYPE_ARRAY:
		return out
	for c in v:
		if typeof(c) == TYPE_DICTIONARY and c.has("kind") and c.has("target"):
			out.append({"kind": str(c["kind"]), "target": float(c["target"]), "progress": float(c.get("progress", 0)),
				"claimed": bool(c.get("claimed", false)), "text": str(c.get("text", ""))})
	return out


static func current_day_key() -> String:
	var d := Time.get_date_dict_from_system()
	return "%04d-%02d-%02d" % [d["year"], d["month"], d["day"]]


static func current_week_key() -> String:
	var unix := int(Time.get_unix_time_from_system())
	var days := unix / 86400
	# 1/1/1970 foi quinta-feira; semanas começam na segunda.
	return "S%d" % ((days + 3) / 7)


## Gera novos desafios quando o dia/semana muda (apenas para frente).
func refresh_periods() -> void:
	var dk := current_day_key()
	if day_key == "" or dk > day_key or daily.is_empty():
		day_key = dk
		daily = _generate(GameData.DAILY_TEMPLATES, dk.hash(), 3)
	var wk := current_week_key()
	if week_key == "" or _week_num(wk) > _week_num(week_key) or weekly.is_empty():
		week_key = wk
		weekly = _generate(GameData.WEEKLY_TEMPLATES, wk.hash() + 7, 3)
	challenges_changed.emit()


static func _week_num(k: String) -> int:
	return int(k.substr(1))


func _generate(templates: Array, seed_value: int, count: int) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var pool := templates.duplicate()
	var out := []
	for i in count:
		if pool.is_empty():
			break
		var t: Dictionary = pool.pop_at(rng.randi() % pool.size())
		var n := rng.randi_range(int(t["min"]), int(t["max"]))
		var c := {"kind": t["kind"], "target": float(n), "progress": 0.0, "claimed": false, "text": ""}
		if t["kind"] == "earn_minutes":
			var target := maxf(2000.0, EconomySystem.income_ps * 60.0 * n)
			c["target"] = target
			c["text"] = t["text"] % Fmt.money(target)
		else:
			c["text"] = t["text"] % n
		out.append(c)
	return out


func note(kind: String, amount: float) -> void:
	for list in [daily, weekly]:
		for c in list:
			if c["kind"] == kind and not c["claimed"]:
				c["progress"] = minf(float(c["target"]), float(c["progress"]) + amount)


func note_earned(amount: float) -> void:
	if amount > 0.0:
		note("earn_minutes", amount)


func is_ready(c: Dictionary) -> bool:
	return not c["claimed"] and float(c["progress"]) + 0.0001 >= float(c["target"])


func ready_count() -> int:
	var n := 0
	for list in [daily, weekly]:
		for c in list:
			if is_ready(c):
				n += 1
	return n


func reward_money(weekly_c: bool) -> float:
	var minutes := GameData.WEEKLY_REWARD_MIN if weekly_c else GameData.DAILY_REWARD_MIN
	return EconomySystem.scaled_reward(minutes, 0.25 if weekly_c else 0.08)


func claim(is_weekly: bool, index: int) -> bool:
	var list := weekly if is_weekly else daily
	if index < 0 or index >= list.size():
		return false
	var c: Dictionary = list[index]
	if not is_ready(c):
		return false
	c["claimed"] = true
	EconomySystem.add_money(reward_money(is_weekly), false, "rewards")
	ResearchSystem.points += GameData.WEEKLY_REWARD_RP if is_weekly else GameData.DAILY_REWARD_RP
	if is_weekly:
		PrestigeSystem.stars += 1
	else:
		MissionSystem.note_daily()
	challenge_completed.emit(c, is_weekly)
	challenges_changed.emit()
	return true
