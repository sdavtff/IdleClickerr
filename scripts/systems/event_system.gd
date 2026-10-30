extends Node
## Eventos aleatórios com duração, efeitos, objetivo e recompensa
## (Festival, Boom imobiliário, Crise, Turismo, Tempestade...).

signal event_started(e: Dictionary)
signal event_ended(e: Dictionary, success: bool, reward: float)
signal event_goal_done(e: Dictionary, reward: float)

var active_id := ""
var left := 0.0
var duration := 0.0
var progress := 0
var goal_done := false
var next_in := 180.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()


func reset() -> void:
	active_id = ""
	left = 0.0
	progress = 0
	goal_done = false
	next_in = 180.0


func to_dict() -> Dictionary:
	return {"active": active_id, "left": left, "dur": duration, "progress": progress, "goal_done": goal_done, "next_in": next_in}


func from_dict(d: Dictionary) -> void:
	active_id = str(d.get("active", ""))
	if GameData.event_def(active_id).is_empty():
		active_id = ""
	left = maxf(0.0, EconomySystem._safe(d.get("left", 0.0)))
	duration = maxf(left, EconomySystem._safe(d.get("dur", left)))
	progress = int(d.get("progress", 0))
	goal_done = bool(d.get("goal_done", false))
	next_in = clampf(EconomySystem._safe(d.get("next_in", 180.0)), 10.0, 900.0)


func active() -> Dictionary:
	return GameData.event_def(active_id)


func fx(key: String) -> float:
	if active_id == "":
		return 0.0
	return float(active().get("fx", {}).get(key, 0.0))


func reward_amount(e: Dictionary) -> float:
	return EconomySystem.scaled_reward(float(e.get("reward_min", 3.0)), 0.06, 300.0)


func tick(dt: float) -> void:
	if active_id == "":
		next_in -= dt
		if next_in <= 0.0:
			start_random()
		return
	left -= dt
	if left <= 0.0:
		_finish()


func start_random() -> void:
	var e: Dictionary = GameData.EVENTS[_rng.randi() % GameData.EVENTS.size()]
	start(e["id"])


func start(id: String) -> void:
	var e := GameData.event_def(id)
	if e.is_empty():
		return
	active_id = id
	duration = float(e["dur"])
	if e.get("good", false):
		duration *= 1.0 + ResearchSystem.fx("event_duration")
	left = duration
	progress = 0
	goal_done = false
	event_started.emit(e)


func note(kind: String, amount: int = 1) -> void:
	if active_id == "" or goal_done:
		return
	var e := active()
	if e["goal"] != kind:
		return
	progress += amount
	if progress >= int(e["target"]):
		_complete_goal()


func _complete_goal() -> void:
	goal_done = true
	var e := active()
	var amount := reward_amount(e)
	EconomySystem.add_money(amount, false, "rewards")
	ResearchSystem.points += float(e.get("reward_rp", 0))
	MissionSystem.note_event_done()
	event_goal_done.emit(e, amount)


func _finish() -> void:
	var e := active()
	var success := goal_done
	var reward := 0.0
	if not goal_done and e.get("goal", "") == "happy_end":
		if HappinessSystem.value >= float(e["target"]):
			reward = reward_amount(e)
			_complete_goal()
			success = true
	active_id = ""
	left = 0.0
	next_in = _rng.randf_range(GameData.EVENT_INTERVAL[0], GameData.EVENT_INTERVAL[1])
	event_ended.emit(e, success, reward)


## Tempo offline: eventos ativos terminam sem cumprir o objetivo.
func skip(seconds: float) -> void:
	if active_id != "":
		left -= seconds
		if left <= 0.0:
			active_id = ""
			left = 0.0
			next_in = _rng.randf_range(30.0, 120.0)
	else:
		next_in = maxf(20.0, next_in - seconds)
