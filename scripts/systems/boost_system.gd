extends Node
## Bônus temporários (renda x2, obras turbo, ciência acelerada, migração),
## incentivo gratuito com recarga e recompensa diária em sequência de 7 dias.

signal boosts_changed
signal login_claimed(day: int, rewards: Array)

## id -> segundos restantes
var active := {}
## Horário (Unix) do último incentivo gratuito.
var last_free := 0.0
## Recompensa diária.
var login_day_key := ""
var login_streak := 0
## Desliga os bônus temporariamente (cálculo de renda offline).
var suspended := false


func reset_all() -> void:
	active = {}
	last_free = 0.0
	login_day_key = ""
	login_streak = 0
	boosts_changed.emit()


func to_dict() -> Dictionary:
	return {"active": active.duplicate(), "last_free": last_free, "login_day": login_day_key, "streak": login_streak}


func from_dict(d: Dictionary) -> void:
	active = {}
	var a = d.get("active", {})
	if typeof(a) == TYPE_DICTIONARY:
		for k in a.keys():
			if GameData.BOOSTS.has(str(k)):
				active[str(k)] = clampf(EconomySystem._safe(a[k]), 0.0, GameData.BOOST_MAX_SECONDS)
	last_free = maxf(0.0, EconomySystem._safe(d.get("last_free", 0.0)))
	login_day_key = str(d.get("login_day", ""))
	login_streak = clampi(int(d.get("streak", 0)), 0, 10000)
	boosts_changed.emit()


func fx(key: String) -> float:
	if suspended:
		return 0.0
	var total := 0.0
	for id in active.keys():
		total += float(GameData.boost_def(id)["fx"].get(key, 0.0))
	return total


func is_active(id: String) -> bool:
	return float(active.get(id, 0.0)) > 0.0


func time_left(id: String) -> float:
	return float(active.get(id, 0.0))


func add(id: String, seconds: float) -> void:
	if not GameData.BOOSTS.has(id) or seconds <= 0.0:
		return
	active[id] = minf(GameData.BOOST_MAX_SECONDS, float(active.get(id, 0.0)) + seconds)
	boosts_changed.emit()


func tick(dt: float) -> void:
	if active.is_empty():
		return
	var ended := false
	for id in active.keys():
		active[id] = float(active[id]) - dt
		if active[id] <= 0.0:
			active.erase(id)
			ended = true
	if ended:
		boosts_changed.emit()


## Tempo offline consome os bônus (eles não multiplicam a renda offline).
func skip(seconds: float) -> void:
	tick(seconds)


# --- Incentivo gratuito ---------------------------------------------------------------

func free_ready_in() -> float:
	var now := Time.get_unix_time_from_system()
	if now < last_free:
		# Relógio voltou: reinicia a referência para não liberar bônus antecipado.
		last_free = now
	return maxf(0.0, last_free + GameData.FREE_BOOST_COOLDOWN - now)


func claim_free(id: String) -> bool:
	if not GameData.BOOSTS.has(id) or free_ready_in() > 0.0:
		return false
	last_free = Time.get_unix_time_from_system()
	add(id, GameData.FREE_BOOST_SECONDS)
	return true


# --- Recompensa diária ------------------------------------------------------------------

static func _day_number(key: String) -> int:
	var parts := key.split("-")
	if parts.size() != 3:
		return -1
	var unix := Time.get_unix_time_from_datetime_dict({"year": int(parts[0]), "month": int(parts[1]), "day": int(parts[2]), "hour": 12, "minute": 0, "second": 0})
	return int(unix / 86400)


func login_available() -> bool:
	var today := ChallengeSystem.current_day_key()
	return login_day_key == "" or today > login_day_key


## Dia da sequência (1 a 7) que será recebido hoje.
func next_login_day() -> int:
	var today := ChallengeSystem.current_day_key()
	var streak := login_streak
	if login_day_key == "" or _day_number(today) - _day_number(login_day_key) > 1:
		streak = 0
	return (streak % GameData.LOGIN_REWARDS.size()) + 1


func claim_login() -> Array:
	if not login_available():
		return []
	var today := ChallengeSystem.current_day_key()
	if login_day_key == "" or _day_number(today) - _day_number(login_day_key) > 1:
		login_streak = 0
	var day := (login_streak % GameData.LOGIN_REWARDS.size()) + 1
	login_streak += 1
	login_day_key = today
	var rewards: Array = GameData.LOGIN_REWARDS[day - 1]
	for r in rewards:
		match str(r["kind"]):
			"money":
				EconomySystem.add_money(EconomySystem.scaled_reward(float(r["v"]), 0.1), false, "rewards")
			"rp":
				ResearchSystem.points += float(r["v"])
			"boost":
				add(str(r["id"]), float(r["v"]))
			"star":
				PrestigeSystem.stars += int(r["v"])
	login_claimed.emit(day, rewards)
	return rewards


static func describe_reward(r: Dictionary) -> String:
	match str(r["kind"]):
		"money":
			return "%d min de renda" % int(r["v"])
		"rp":
			return "%d pontos de pesquisa" % int(r["v"])
		"boost":
			return "%s (%s)" % [GameData.boost_def(r["id"])["name"], Fmt.short_duration(float(r["v"]))]
		"star":
			return "%d estrela de prestígio" % int(r["v"])
	return ""
