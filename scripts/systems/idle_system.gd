extends Node
## Sistema idle: calcula a renda acumulada enquanto o jogador esteve fora
## (até 24 horas), com base no horário salvo da última saída.

signal offline_reward_ready(report: Dictionary)

## Horário (Unix) da última vez em que o jogo esteve ativo / foi salvo.
var last_active_time := 0.0
## Recompensa pendente aguardando o jogador tocar em "Coletar".
var pending: Dictionary = {}

const MIN_SECONDS_FOR_POPUP := 60.0


func to_dict() -> Dictionary:
	var d := {"last_active": last_active_time}
	if not pending.is_empty():
		d["pending_money"] = float(pending["money"])
		d["pending_seconds"] = float(pending["seconds"])
	return d


func from_dict(d: Dictionary) -> void:
	last_active_time = EconomySystem._safe(d.get("last_active", 0.0))
	pending = {}
	var pm := EconomySystem._safe(d.get("pending_money", 0.0))
	if pm > 0.0:
		var ps := EconomySystem._safe(d.get("pending_seconds", 0.0))
		pending = {"money": pm, "seconds": ps, "raw_seconds": ps, "capped": false}


func mark_active() -> void:
	last_active_time = Time.get_unix_time_from_system()


## Calcula (sem aplicar) a renda offline para `raw_seconds` de ausência.
func compute(raw_seconds: float) -> Dictionary:
	var secs := clampf(raw_seconds, 0.0, GameData.OFFLINE_MAX_SECONDS)
	var report := {"raw_seconds": maxf(raw_seconds, 0.0), "seconds": secs, "money": 0.0,
		"capped": raw_seconds > GameData.OFFLINE_MAX_SECONDS, "pop_before": PopulationSystem.population, "pop_after": PopulationSystem.population}
	if secs <= 0.0:
		return report
	HappinessSystem.recompute()
	PopulationSystem.recompute()
	EconomySystem.recompute()
	var net_before := EconomySystem.net_ps
	PopulationSystem.simulate_offline(secs)
	HappinessSystem.recompute()
	HappinessSystem.value = HappinessSystem.target
	EconomySystem.recompute()
	var net_after := EconomySystem.net_ps
	report["money"] = maxf(0.0, (net_before + net_after) * 0.5 * secs)
	report["pop_after"] = PopulationSystem.population
	return report


## Chamado ao abrir o jogo ou ao voltar do segundo plano.
func process_absence(now: float) -> Dictionary:
	if last_active_time <= 0.0:
		mark_active()
		return {}
	var raw := now - last_active_time
	mark_active()
	if raw < 1.0:
		return {}
	var report := compute(raw)
	if report["seconds"] >= MIN_SECONDS_FOR_POPUP and report["money"] > 0.0:
		# Acumula com qualquer recompensa ainda não coletada.
		if not pending.is_empty():
			report["money"] += float(pending["money"])
			report["seconds"] = minf(GameData.OFFLINE_MAX_SECONDS, report["seconds"] + float(pending["seconds"]))
		pending = report
		offline_reward_ready.emit(report)
	elif report["money"] > 0.0:
		EconomySystem.add_money(report["money"], true)
	return report


func collect(multiplier: float = 1.0) -> float:
	if pending.is_empty():
		return 0.0
	var amount := float(pending["money"]) * multiplier
	MissionSystem.note_offline(float(pending["seconds"]))
	EconomySystem.add_money(amount, true)
	pending = {}
	return amount
