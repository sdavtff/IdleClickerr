extends Node
## Orquestra os sistemas: loop de simulação, novo jogo, carregamento,
## salvamento automático, prestígio e eventos do ciclo de vida do Android.

signal stats_tick
signal toast(text: String, kind: String)
signal city_reset

const TICK := 0.1
const AUTOSAVE_INTERVAL := 15.0
const MISSION_CHECK_INTERVAL := 0.5

var running := false
var paused_sim := false
var _acc := 0.0
var _autosave_acc := 0.0
var _mission_acc := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().set_auto_accept_quit(false)
	# O botão "voltar" do Android fecha janelas em vez de sair do jogo.
	get_tree().set_quit_on_go_back(false)
	MissionSystem.mission_ready.connect(func(m): toast.emit("Missão concluída: " + m["text"], "mission"))
	MissionSystem.achievement_unlocked.connect(func(a): toast.emit("Conquista: " + a["name"] + " (+2% renda)", "achievement"))
	SaveSystem.load_failed.connect(func(reason): toast.emit(reason, "warning"))


# --- Ciclo de jogo ---------------------------------------------------------------

func has_save() -> bool:
	return SaveSystem.has_save()


## Apaga tudo (inclusive prestígio e conquistas) e cria uma cidade nova.
func new_game() -> void:
	SaveSystem.delete_all()
	PrestigeSystem.wipe()
	MissionSystem.wipe()
	EconomySystem.lifetime_earned = 0.0
	_setup_fresh_city()
	save_game()


## Carrega o save. Retorna false se não houver dados válidos.
func continue_game() -> bool:
	var data := SaveSystem.read()
	if data.is_empty():
		return false
	apply_state(data)
	return true


func _setup_fresh_city() -> void:
	BuildingSystem.reset()
	ExpansionSystem.reset(PrestigeSystem.start_regions())
	EconomySystem.reset(PrestigeSystem.start_money())
	MissionSystem.reset_run()
	MissionSystem.note_regions(ExpansionSystem.unlocked)
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
	}


func apply_state(data: Dictionary) -> void:
	PrestigeSystem.from_dict(_section(data, "prestige"))
	ExpansionSystem.from_dict(_section(data, "expansion"))
	MissionSystem.from_dict(_section(data, "missions"))
	EconomySystem.from_dict(_section(data, "economy"))
	BuildingSystem.from_dict(_section(data, "buildings"))
	PopulationSystem.from_dict(_section(data, "population"))
	HappinessSystem.from_dict(_section(data, "happiness"))
	IdleSystem.from_dict(_section(data, "idle"))
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
	_autosave_acc += delta
	if _autosave_acc >= AUTOSAVE_INTERVAL:
		save_game()


func simulate(dt: float) -> void:
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
