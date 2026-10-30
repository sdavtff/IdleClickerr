extends Node
## Testes automatizados das mecânicas do Idle City.
## Uso: godot --headless --path . res://tests/TestRunner.tscn [-- --balance]

var passed := 0
var failed := 0


func _ready() -> void:
	print("=== Idle City — testes ===")
	test_format()
	test_new_game()
	test_build_and_economy()
	test_upgrades()
	test_population_and_happiness()
	test_offline()
	test_save_load()
	test_save_corruption()
	test_missions_and_regions()
	test_prestige()
	if "--balance" in OS.get_cmdline_user_args():
		balance_sim()
	print("=== %d passaram, %d falharam ===" % [passed, failed])
	SaveSystem.delete_all()
	get_tree().quit(1 if failed > 0 else 0)


func check(cond: bool, name: String) -> void:
	if cond:
		passed += 1
		print("  ok   ", name)
	else:
		failed += 1
		print("  FAIL ", name)


func near(a: float, b: float, tol := 0.01) -> bool:
	return absf(a - b) <= maxf(absf(b) * tol, 0.001)


func fresh() -> void:
	SaveSystem.delete_all()
	GameManager.new_game()


func test_format() -> void:
	print("[Formatação]")
	check(Fmt.money(1000) == "R$ 1.000", "R$ 1.000 -> " + Fmt.money(1000))
	check(Fmt.money(25500) == "R$ 25.500", "R$ 25.500 -> " + Fmt.money(25500))
	check(Fmt.money(1.2e6) == "R$ 1,2 mi", "R$ 1,2 mi -> " + Fmt.money(1.2e6))
	check(Fmt.money(3.5e9) == "R$ 3,5 bi", "R$ 3,5 bi -> " + Fmt.money(3.5e9))
	check(Fmt.money(45800) == "R$ 45.800", "R$ 45.800")
	check(Fmt.duration(8 * 3600 + 32 * 60) == "8 horas e 32 minutos", "duração -> " + Fmt.duration(8 * 3600 + 32 * 60))


func test_new_game() -> void:
	print("[Novo jogo]")
	fresh()
	check(BuildingSystem.buildings.size() == 3, "vila inicial com 3 edifícios")
	check(near(EconomySystem.money, GameData.START_MONEY), "dinheiro inicial")
	check(ExpansionSystem.unlocked == 1, "1 região desbloqueada")
	check(BuildingSystem.free_lot() == 3, "próximo terreno livre = 3")
	check(GameData.BUILDINGS.size() >= 30, "pelo menos 30 tipos de edifícios (%d)" % GameData.BUILDINGS.size())


func test_build_and_economy() -> void:
	print("[Construção e economia]")
	fresh()
	var cost := BuildingSystem.build_cost("casa_pequena")
	check(near(cost, 100.0 * pow(1.12, 2)), "custo cresce com quantidade")
	var before := EconomySystem.money
	var b := BuildingSystem.build("casa_pequena")
	check(not b.is_empty() and int(b["lot"]) == 3, "constrói no próximo terreno")
	check(near(EconomySystem.money, before - cost), "dinheiro debitado")
	EconomySystem.money = 0.0
	check(BuildingSystem.build("padaria").is_empty(), "não constrói sem dinheiro")
	check(not BuildingSystem.can_build("hospital")["ok"], "hospital bloqueado na vila")
	for i in 50:
		GameManager.simulate(0.1)
	EconomySystem.recompute()
	var net := EconomySystem.net_ps
	check(net > 0.0, "renda líquida positiva (%s)" % Fmt.money_ps(net))
	var m0 := EconomySystem.money
	for i in 100:
		GameManager.simulate(0.1)
	check(near(EconomySystem.money - m0, EconomySystem.net_ps * 10.0, 0.08), "dinheiro por segundo acumula (10s)")
	check(EconomySystem.total_earned > 0.0, "total ganho registrado")


func test_upgrades() -> void:
	print("[Melhorias]")
	fresh()
	EconomySystem.money = 1e9
	var b: Dictionary = BuildingSystem.buildings[2]
	var inc1 := BuildingSystem.income_of(b)
	var c1 := BuildingSystem.upgrade_cost(b, 1)
	var c10 := BuildingSystem.upgrade_cost(b, 10)
	var manual := 0.0
	for i in 10:
		manual += float(GameData.get_def(b["id"])["cost"]) * 0.5 * pow(1.14, i)
	check(near(c10, manual), "custo de 10 níveis = soma progressiva")
	check(c1 < c10 / 10.0, "custos progressivos")
	BuildingSystem.upgrade(b["uid"], 9)
	check(int(b["level"]) == 10, "nível 10")
	check(near(BuildingSystem.income_of(b), inc1 * 10 * 2), "marco do nível 10 dobra a renda")
	var n := BuildingSystem.affordable_levels(b, 5000.0)
	check(BuildingSystem.upgrade_cost(b, n) <= 5000.0 and (n >= 90 or BuildingSystem.upgrade_cost(b, n + 1) > 5000.0), "máximo acessível correto (%d)" % n)
	var house: Dictionary = BuildingSystem.buildings[0]
	var cap1 := BuildingSystem.capacity_of(house)
	BuildingSystem.upgrade(house["uid"], 4)
	check(BuildingSystem.capacity_of(house) > cap1, "melhoria aumenta capacidade")
	check(BuildingArt.tier_of(10) == 1 and BuildingArt.height_of("apartamento", 25) > BuildingArt.height_of("apartamento", 1), "visual muda nos marcos")


func test_population_and_happiness() -> void:
	print("[População e felicidade]")
	fresh()
	var h0 := HappinessSystem.target
	for i in 600:
		GameManager.simulate(0.1)
	check(PopulationSystem.population <= PopulationSystem.capacity + 0.01, "população limitada pela capacidade")
	check(PopulationSystem.population > PopulationSystem.START_POPULATION, "população cresce")
	EconomySystem.money = 1e6
	BuildingSystem.build("parque")
	BuildingSystem.build("escola")
	HappinessSystem.recompute()
	check(HappinessSystem.target > h0 + 10.0, "parque e escola aumentam felicidade (%.0f -> %.0f)" % [h0, HappinessSystem.target])
	check(HappinessSystem.target >= 0.0 and HappinessSystem.target <= 100.0, "felicidade entre 0 e 100")
	HappinessSystem.value = 10.0
	PopulationSystem.recompute()
	var low_target := PopulationSystem.target
	var low_speed := PopulationSystem.growth_speed()
	HappinessSystem.value = 90.0
	PopulationSystem.recompute()
	check(PopulationSystem.target > low_target, "felicidade alta atrai mais moradores")
	check(PopulationSystem.growth_speed() > low_speed, "felicidade alta acelera o crescimento")
	for i in 10:
		BuildingSystem.build("casa_pequena")
	HappinessSystem.recompute()
	var pop := PopulationSystem.population
	for i in 300:
		GameManager.simulate(0.1)
	check(PopulationSystem.population > pop, "novas casas trazem moradores")


func test_offline() -> void:
	print("[Renda offline]")
	fresh()
	for i in 1200:
		GameManager.simulate(0.1)
	EconomySystem.recompute()
	var net := EconomySystem.net_ps
	var r8 := IdleSystem.compute(8 * 3600.0)
	check(r8["money"] > net * 8 * 3600 * 0.9 and r8["money"] < net * 8 * 3600 * 1.5, "8h offline ≈ renda × tempo")
	var r48 := IdleSystem.compute(48 * 3600.0)
	EconomySystem.recompute()
	var r24 := IdleSystem.compute(24 * 3600.0)
	check(r48["capped"] and near(r48["seconds"], 86400.0), "limite de 24 horas")
	check(near(r48["money"], r24["money"], 0.05), "48h rende o mesmo que 24h")
	check(IdleSystem.compute(-500)["money"] == 0.0, "relógio voltando no tempo não dá dinheiro")
	IdleSystem.pending = {}
	IdleSystem.last_active_time = Time.get_unix_time_from_system() - 3 * 3600
	var m0 := EconomySystem.money
	IdleSystem.process_absence(Time.get_unix_time_from_system())
	check(not IdleSystem.pending.is_empty(), "recompensa pendente após ausência")
	var got := IdleSystem.collect()
	check(got > 0.0 and near(EconomySystem.money, m0 + got), "coletar adiciona o dinheiro")


func test_save_load() -> void:
	print("[Salvamento]")
	fresh()
	EconomySystem.money = 123456.75
	ExpansionSystem.unlocked = 2
	BuildingSystem.build("casa_moderna", true)
	BuildingSystem.upgrade(BuildingSystem.buildings[0]["uid"], 1)
	EconomySystem.money = 123456.75
	PrestigeSystem.stars = 3
	MissionSystem.claimed = ["m01"]
	check(GameManager.save_game(), "salva sem erros")
	var saved_last := IdleSystem.last_active_time
	var snapshot := JSON.stringify(GameManager.collect_state())
	GameManager.new_game()
	check(EconomySystem.money != 123456.75, "estado alterado após novo jogo")
	# restaura a partir do arquivo gravado anteriormente
	SaveSystem.write(JSON.parse_string(snapshot))
	check(GameManager.continue_game(), "carrega o save")
	check(near(EconomySystem.money, 123456.75, 0.0001), "dinheiro restaurado")
	check(ExpansionSystem.unlocked == 2, "regiões restauradas")
	check(BuildingSystem.buildings.size() == 4 and int(BuildingSystem.buildings[0]["level"]) == 2, "edifícios e níveis restaurados")
	check(PrestigeSystem.stars == 3, "prestígio restaurado")
	check(MissionSystem.claimed.has("m01"), "missões restauradas")
	check(near(IdleSystem.last_active_time, saved_last, 0.001), "horário da última saída salvo")


func test_save_corruption() -> void:
	print("[Proteção contra corrupção]")
	fresh()
	EconomySystem.money = 777.0
	GameManager.save_game()
	EconomySystem.money = 888.0
	GameManager.save_game()
	# corrompe o arquivo principal
	var f := FileAccess.open(SaveSystem.SAVE_PATH, FileAccess.WRITE)
	f.store_string("{lixo corrompido")
	f.close()
	var data := SaveSystem.read()
	check(not data.is_empty() and near(float(data["economy"]["money"]), 777.0), "usa o backup quando o principal corrompe")
	# adulteração do conteúdo (checksum inválido)
	GameManager.save_game()
	var txt := FileAccess.get_file_as_string(SaveSystem.SAVE_PATH).replace("money", "mon3y")
	f = FileAccess.open(SaveSystem.SAVE_PATH, FileAccess.WRITE)
	f.store_string(txt)
	f.close()
	check(not SaveSystem._read_valid(SaveSystem.SAVE_PATH).size(), "checksum detecta adulteração")
	f = FileAccess.open(SaveSystem.BACKUP_PATH, FileAccess.WRITE)
	f.store_string("")
	f.close()
	check(SaveSystem.read().is_empty(), "sem save válido -> retorna vazio (sem travar)")


func test_missions_and_regions() -> void:
	print("[Missões e expansão]")
	fresh()
	var m1: Dictionary = GameData.MISSIONS[0]
	check(not MissionSystem.is_complete(m1), "missão 1 começa incompleta")
	EconomySystem.money = 1000.0
	BuildingSystem.build("casa_pequena")
	check(MissionSystem.is_complete(m1), "missão 1 concluída ao construir")
	var before := EconomySystem.money
	check(MissionSystem.claim("m01"), "coleta recompensa")
	check(near(EconomySystem.money, before + float(m1["reward"])), "recompensa em dinheiro")
	check(not MissionSystem.claim("m01"), "não coleta duas vezes")
	check(not ExpansionSystem.can_unlock(1), "região 2 exige dinheiro e população")
	EconomySystem.money = 1e6
	PopulationSystem.population = 50
	check(ExpansionSystem.unlock(1), "desbloqueia Bairro residencial")
	check(BuildingSystem.unlocked_lots() == 20, "novos terrenos disponíveis")
	check(BuildingSystem.can_build("hospital")["ok"], "novos edifícios liberados")
	check(not ExpansionSystem.unlock(3), "não pula regiões")
	MissionSystem.check()
	check(MissionSystem.achievements.has("a_build_1"), "conquista desbloqueada")


func test_prestige() -> void:
	print("[Prestígio]")
	fresh()
	check(not PrestigeSystem.can_prestige(), "prestígio indisponível no início")
	ExpansionSystem.unlocked = 3
	EconomySystem.total_earned = 4e6
	check(PrestigeSystem.stars_on_reset() == 2, "ganho de estrelas = raiz(ganho / 1 mi)")
	var mult := PrestigeSystem.income_mult()
	var g := GameManager.do_prestige()
	check(g == 2 and PrestigeSystem.stars == 2, "estrelas recebidas")
	check(ExpansionSystem.unlocked == 1 and BuildingSystem.buildings.size() == 3, "cidade reiniciada")
	check(PrestigeSystem.income_mult() > mult, "multiplicador permanente aumentou")
	check(PrestigeSystem.buy("marketing"), "compra melhoria de legado")
	check(MissionSystem.lifetime["prestiges"] == 1, "estatística mantida")


## Simula um jogador jogando de forma simples para verificar o ritmo.
func balance_sim() -> void:
	print("[Simulação de balanceamento]")
	fresh()
	var t := 0.0
	var step := 1.0
	var report := {}
	var last_region := 1
	while t < 3600.0 * 10.0:
		GameManager.simulate(step)
		t += step
		if int(t) % 2 != 0:
			continue
		MissionSystem.check()
		for m in MissionSystem.active_missions():
			MissionSystem.claim(m["id"])
		if ExpansionSystem.unlock(ExpansionSystem.unlocked):
			report[ExpansionSystem.unlocked] = t
		_bot_spend()
		if ExpansionSystem.unlocked != last_region:
			last_region = ExpansionSystem.unlocked
			print("  região %d (%s) em %s | renda %s | pop %s | feliz %d%%" % [last_region, GameData.REGIONS[last_region - 1]["name"], Fmt.short_duration(t), Fmt.money_ps(EconomySystem.net_ps), Fmt.pop(PopulationSystem.population), int(HappinessSystem.value)])
		if ExpansionSystem.unlocked >= GameData.region_count():
			break
	print("  final: %s | renda %s | pop %s | prestígio disponível: %d estrelas" % [Fmt.short_duration(t), Fmt.money_ps(EconomySystem.net_ps), Fmt.pop(PopulationSystem.population), PrestigeSystem.stars_on_reset()])
	check(ExpansionSystem.unlocked >= 4, "progride até a Zona industrial em 10h simuladas")


func _bot_spend() -> void:
	for _i in 6:
		var best_score := 0.0
		var best_action := Callable()
		var pop := PopulationSystem.population
		var need_pop := ExpansionSystem.next_region() >= 0 and pop < float(GameData.REGIONS[ExpansionSystem.next_region()]["pop"])
		var happy_low := HappinessSystem.value < 70.0
		var jobs_short := PopulationSystem.jobs > pop
		if BuildingSystem.free_lot() >= 0:
			for d in GameData.BUILDINGS:
				if not BuildingSystem.can_build(d["id"])["ok"]:
					continue
				var cost := BuildingSystem.build_cost(d["id"])
				var value := float(d.get("income", 0.0)) + float(d.get("cap", 0)) * float(d.get("tax", 0.0))
				if d["cat"] == "res" and (need_pop or jobs_short):
					value *= 3.0
				if d.has("service") and happy_low and HappinessSystem.service_ratio(d["service"]) < 0.9:
					value = maxf(value, cost / 60.0)
				var score := value / cost
				if score > best_score:
					best_score = score
					var id: String = d["id"]
					best_action = func(): BuildingSystem.build(id)
		for b in BuildingSystem.buildings:
			var cost := BuildingSystem.upgrade_cost(b, 1)
			if not EconomySystem.can_afford(cost):
				continue
			var def := GameData.get_def(b["id"])
			var nb: Dictionary = b.duplicate()
			nb["level"] = int(b["level"]) + 1
			var value := BuildingSystem.income_of(nb) - BuildingSystem.income_of(b)
			value += (BuildingSystem.capacity_of(nb) - BuildingSystem.capacity_of(b)) * float(def.get("tax", 0.0)) * (3.0 if need_pop or jobs_short else 1.0)
			if def.has("service") and happy_low and HappinessSystem.service_ratio(def["service"]) < 0.9:
				value = maxf(value, cost / 60.0)
			var score := value / cost * 0.9
			if score > best_score:
				best_score = score
				var uid: int = b["uid"]
				best_action = func(): BuildingSystem.upgrade(uid, 1)
		if not best_action.is_valid():
			return
		best_action.call()
		EconomySystem.recompute()
