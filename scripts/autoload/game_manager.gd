extends Node
## Orquestra os sistemas: loop de simulação, novo jogo, carregamento,
## salvamento automático, prestígio e eventos do ciclo de vida do Android.

signal stats_tick
signal toast(text: String, kind: String)
signal city_reset

const TICK := 0.1
## Versão do formato do save. 1 = Idle City 1.0; 2 = Idle City 2.0.
const SAVE_FORMAT := 2
const AUTOSAVE_INTERVAL := 15.0
const MISSION_CHECK_INTERVAL := 0.5

var running := false
var paused_sim := false
var _acc := 0.0
var _autosave_acc := 0.0
var _mission_acc := 0.0
var _period_acc := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().set_auto_accept_quit(false)
	# O botão "voltar" do Android fecha janelas em vez de sair do jogo.
	get_tree().set_quit_on_go_back(false)
	MissionSystem.mission_ready.connect(func(m): toast.emit("Missão concluída: " + m["text"], "mission"))
	MissionSystem.achievement_unlocked.connect(func(a): toast.emit("Conquista: %s! +2%% renda e %s" % [a["name"], Fmt.money(MissionSystem.achievement_reward())], "achievement"))
	ResearchSystem.research_completed.connect(func(r): toast.emit("Pesquisa concluída: " + r["name"], "research"))
	EventSystem.event_started.connect(func(e): toast.emit("Evento: %s! %s" % [e["name"], e["desc"]], "event"))
	EventSystem.event_goal_done.connect(func(e, amount): toast.emit("Objetivo do evento cumprido! +%s" % Fmt.money(amount), "mission"))
	ChallengeSystem.challenge_completed.connect(func(c, w): toast.emit("%s concluído: %s" % ["Meta semanal" if w else "Desafio diário", c["text"]], "mission"))
	EconomySystem.investment_matured.connect(func(inv): toast.emit("Investimento pronto para resgate: " + GameData.investment_def(inv["id"])["name"], "info"))
	BuildingSystem.building_completed.connect(func(b):
		if running:
			toast.emit("Obra concluída: " + GameData.get_def(b["id"])["name"], "info"))
	SaveSystem.load_failed.connect(func(reason): toast.emit(reason, "warning"))


# --- Ciclo de jogo ---------------------------------------------------------------

func has_save() -> bool:
	return SaveSystem.has_save()


## Apaga tudo (inclusive prestígio e conquistas) e cria uma cidade nova.
func new_game() -> void:
	SaveSystem.delete_all()
	PrestigeSystem.wipe()
	MissionSystem.wipe()
	ChallengeSystem.reset()
	EconomySystem.lifetime_earned = 0.0
	_setup_fresh_city()
	save_game()


## Carrega o save. Retorna false se não houver dados válidos.
func continue_game() -> bool:
	var data := SaveSystem.read()
	if data.is_empty():
		return false
	if int(data.get("format", 1)) < SAVE_FORMAT:
		SaveSystem.backup_old_format()
	apply_state(data)
	return true


func _setup_fresh_city() -> void:
	BuildingSystem.reset()
	ExpansionSystem.reset(PrestigeSystem.start_regions())
	EconomySystem.reset(PrestigeSystem.start_money())
	MissionSystem.reset_run()
	MissionSystem.note_regions(ExpansionSystem.unlocked)
	ResearchSystem.reset()
	EventSystem.reset()
	PopulationSystem.reset()
	# A pequena vila inicial.
	BuildingSystem.build("casa_pequena", true)
	BuildingSystem.build("casa_pequena", true)
	BuildingSystem.build("padaria", true)
	PopulationSystem.recompute()
	HappinessSystem.reset()
	EconomySystem.recompute()
	IdleSystem.pending = {}
	IdleSystem.mark_active()


func collect_state() -> Dictionary:
	return {
		"economy": EconomySystem.to_dict(),
		"buildings": BuildingSystem.to_dict(),
		"population": PopulationSystem.to_dict(),
		"happiness": HappinessSystem.to_dict(),
		"expansion": ExpansionSystem.to_dict(),
		"missions": MissionSystem.to_dict(),
		"prestige": PrestigeSystem.to_dict(),
		"idle": IdleSystem.to_dict(),
		"research": ResearchSystem.to_dict(),
		"events": EventSystem.to_dict(),
		"challenges": ChallengeSystem.to_dict(),
		"format": SAVE_FORMAT,
	}


## Converte saves antigos para o formato atual (nunca perde dados).
static func migrate(data: Dictionary) -> Dictionary:
	var fmt := int(data.get("format", 1))
	if fmt < 2:
		# 1.0 -> 2.0: edifícios antigos já estão prontos, imposto normal,
		# sem pesquisas/eventos/desafios ainda.
		var bsec = data.get("buildings", {})
		if typeof(bsec) == TYPE_DICTIONARY:
			for b in bsec.get("buildings", []):
				if typeof(b) == TYPE_DICTIONARY:
					b["build_left"] = 0.0
		var eco = data.get("economy", {})
		if typeof(eco) == TYPE_DICTIONARY and not eco.has("tax_level"):
			eco["tax_level"] = 1
		for k in ["research", "events", "challenges"]:
			if not data.has(k):
				data[k] = {}
		data["format"] = 2
		data["migrated_from"] = fmt
	return data


func apply_state(data: Dictionary) -> void:
	data = migrate(data)
	PrestigeSystem.from_dict(_section(data, "prestige"))
	ExpansionSystem.from_dict(_section(data, "expansion"))
	MissionSystem.from_dict(_section(data, "missions"))
	EconomySystem.from_dict(_section(data, "economy"))
	BuildingSystem.from_dict(_section(data, "buildings"))
	PopulationSystem.from_dict(_section(data, "population"))
	HappinessSystem.from_dict(_section(data, "happiness"))
	IdleSystem.from_dict(_section(data, "idle"))
	ResearchSystem.from_dict(_section(data, "research"))
	EventSystem.from_dict(_section(data, "events"))
	ChallengeSystem.from_dict(_section(data, "challenges"))
	PopulationSystem.recompute()
	EconomySystem.recompute()


static func _section(data: Dictionary, key: String) -> Dictionary:
	var v = data.get(key, {})
	return v if typeof(v) == TYPE_DICTIONARY else {}


func save_game() -> bool:
	IdleSystem.mark_active()
	_autosave_acc = 0.0
	return SaveSystem.write(collect_state())


## Inicia a simulação na cena do jogo e calcula a renda offline.
func start_running() -> void:
	running = true
	_acc = 0.0
	IdleSystem.process_absence(Time.get_unix_time_from_system())
	EconomySystem.recompute()
	MissionSystem.check()


func stop_running() -> void:
	if running:
		save_game()
	running = false


func do_prestige() -> int:
	var gained := PrestigeSystem.do_prestige()
	if gained <= 0:
		return 0
	_setup_fresh_city()
	save_game()
	city_reset.emit()
	return gained


func _process(delta: float) -> void:
	if not running or paused_sim:
		return
	_acc += minf(delta, 1.0)
	while _acc >= TICK:
		_acc -= TICK
		simulate(TICK)
	_mission_acc += delta
	if _mission_acc >= MISSION_CHECK_INTERVAL:
		_mission_acc = 0.0
		MissionSystem.check()
		_period_acc += MISSION_CHECK_INTERVAL
		if _period_acc >= 60.0:
			_period_acc = 0.0
			ChallengeSystem.refresh_periods()
	_autosave_acc += delta
	if _autosave_acc >= AUTOSAVE_INTERVAL:
		save_game()


func simulate(dt: float) -> void:
	BuildingSystem.advance_construction(dt)
	ResearchSystem.tick(dt)
	EventSystem.tick(dt)
	HappinessSystem.tick(dt)
	PopulationSystem.tick(dt)
	EconomySystem.recompute()
	EconomySystem.tick(dt)
	IdleSystem.mark_active()
	stats_tick.emit()


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_WM_CLOSE_REQUEST:
			if running:
				save_game()
			get_tree().quit()
		NOTIFICATION_APPLICATION_PAUSED:
			if running:
				save_game()
		NOTIFICATION_APPLICATION_RESUMED:
			if running:
				IdleSystem.process_absence(Time.get_unix_time_from_system())
		NOTIFICATION_APPLICATION_FOCUS_OUT:
			if running:
				save_game()
