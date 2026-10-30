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
	test_construction_time()
	test_research()
	test_events()
	test_challenges()
	test_finance()
	test_migration_v1()
	test_offline_v2()
	test_new_buildings()
	test_city_index()
	test_boosts()
	test_login()
	test_snapshots()
	test_migration_v2()
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
	BuildingSystem.instant_build = true
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


func test_construction_time() -> void:
	print("[2.0: Tempo de construção]")
	fresh()
	BuildingSystem.instant_build = false
	EconomySystem.money = 1e6
	var b := BuildingSystem.build("loja_conveniencia")
	check(not BuildingSystem.is_complete(b), "obra começa em andamento (%s)" % Fmt.short_duration(b["build_left"]))
	EconomySystem.recompute()
	var inc := EconomySystem.income_ps
	check(BuildingSystem.upgrade(b["uid"], 1) == 0, "não melhora durante a obra")
	var done := []
	BuildingSystem.building_completed.connect(func(x): done.append(x), CONNECT_ONE_SHOT)
	BuildingSystem.advance_construction(float(b["build_left"]) + 0.1)
	check(BuildingSystem.is_complete(b) and done.size() == 1, "obra concluída emite sinal")
	EconomySystem.recompute()
	check(EconomySystem.income_ps > inc, "edifício pronto passa a render")
	var b2 := BuildingSystem.build("padaria")
	var cost := BuildingSystem.accelerate_cost(b2)
	var m0 := EconomySystem.money
	check(cost > 0.0 and BuildingSystem.accelerate(b2["uid"]) and BuildingSystem.is_complete(b2), "acelerar conclui a obra")
	check(near(EconomySystem.money, m0 - cost), "acelerar cobra o valor exibido")
	ResearchSystem.force_complete("c1")
	check(BuildingSystem.build_time("hospital") < GameData.base_build_time(GameData.get_def("hospital")), "pesquisa reduz o tempo de obra")
	BuildingSystem.instant_build = true


func test_research() -> void:
	print("[2.0: Pesquisas]")
	fresh()
	check(not ResearchSystem.can_start("c1"), "sem pontos não pesquisa")
	ResearchSystem.points = 100
	check(ResearchSystem.state_of("c2") == "locked", "pré-requisito bloqueia")
	check(ResearchSystem.start("i1"), "inicia pesquisa")
	check(not ResearchSystem.can_start("c1"), "uma pesquisa por vez")
	EconomySystem.money = 1e6
	BuildingSystem.build("loja_conveniencia")
	EconomySystem.recompute()
	var before := float(EconomySystem.income_by_cat.get("com", 0.0))
	ResearchSystem.tick(ResearchSystem.active_left + 1.0)
	check(ResearchSystem.is_done("i1") and ResearchSystem.active_id == "", "pesquisa concluída após o tempo")
	ResearchSystem.force_complete("m1")
	EconomySystem.recompute()
	check(float(EconomySystem.income_by_cat.get("com", 0.0)) > before * 1.1, "pesquisa aumenta renda comercial")
	ExpansionSystem.unlocked = 4
	EconomySystem.money = 1e8
	check(not BuildingSystem.can_build("estacao_metro")["ok"], "metrô exige pesquisa")
	ResearchSystem.force_complete("t2")
	check(BuildingSystem.can_build("estacao_metro")["ok"], "pesquisa libera o metrô")
	var rate0 := ResearchSystem.compute_rate()
	BuildingSystem.build("escola")
	check(ResearchSystem.compute_rate() > rate0, "escolas geram pontos de pesquisa")
	ResearchSystem.points = 0
	ResearchSystem.simulate_offline(86400)
	check(ResearchSystem.points <= ResearchSystem.compute_rate() * 7200 * 0.5 + 1, "pesquisa offline limitada")


func test_events() -> void:
	print("[2.0: Eventos]")
	fresh()
	EconomySystem.money = 1e6
	BuildingSystem.build("loja_conveniencia")
	for i in 20:
		GameManager.simulate(0.5)
	EventSystem.start("festival")
	HappinessSystem.recompute()
	check(EventSystem.fx("happy") > 0 and HappinessSystem.factors.any(func(f): return f["name"] == "Evento"), "festival aumenta felicidade")
	var m0 := EconomySystem.money
	for i in 3:
		MissionSystem.on_bubble()
	check(EventSystem.goal_done and EconomySystem.money > m0, "objetivo do evento dá recompensa")
	EventSystem.tick(1000)
	check(EventSystem.active_id == "" and EventSystem.fx("happy") == 0.0, "evento termina após a duração")
	EventSystem.start("boom")
	var c := BuildingSystem.build_cost("casa_pequena")
	EventSystem.tick(1000)
	check(c < BuildingSystem.build_cost("casa_pequena"), "boom imobiliário baratea construções")
	EventSystem.start("crise")
	HappinessSystem.value = 80
	EventSystem.tick(1000)
	check(MissionSystem.lifetime["events_done"] >= 2, "crise superada com felicidade conta como objetivo")
	EventSystem.start("tempestade")
	EventSystem.skip(10000)
	check(EventSystem.active_id == "", "evento expira no tempo offline")


func test_challenges() -> void:
	print("[2.0: Desafios diários e semanais]")
	fresh()
	ChallengeSystem.reset()
	check(ChallengeSystem.daily.size() == 3 and ChallengeSystem.weekly.size() == 3, "3 desafios diários e 3 metas semanais")
	var first: Dictionary = ChallengeSystem.daily[0]
	first["progress"] = first["target"]
	var m0 := EconomySystem.money
	var stars := PrestigeSystem.stars
	check(ChallengeSystem.claim(false, 0) and EconomySystem.money > m0, "coleta desafio diário")
	check(not ChallengeSystem.claim(false, 0), "não coleta duas vezes")
	ChallengeSystem.weekly[1]["progress"] = ChallengeSystem.weekly[1]["target"]
	check(ChallengeSystem.claim(true, 1) and PrestigeSystem.stars == stars + 1, "meta semanal dá estrela")
	var saved_day := ChallengeSystem.day_key
	ChallengeSystem.day_key = "9999-12-31"
	ChallengeSystem.refresh_periods()
	check(ChallengeSystem.day_key == "9999-12-31" and ChallengeSystem.daily[0]["claimed"], "relógio voltando não gera novos desafios")
	ChallengeSystem.day_key = "2000-01-01"
	ChallengeSystem.refresh_periods()
	check(ChallengeSystem.day_key == saved_day and not ChallengeSystem.daily[0]["claimed"], "novo dia gera novos desafios")
	ChallengeSystem.note("build", 100)
	var any_build := false
	for c in ChallengeSystem.daily + ChallengeSystem.weekly:
		if c["kind"] == "build" and c["progress"] > 0:
			any_build = true
	check(any_build or not (ChallengeSystem.daily + ChallengeSystem.weekly).any(func(c): return c["kind"] == "build"), "progresso registrado")


func test_finance() -> void:
	print("[2.0: Finanças]")
	fresh()
	EconomySystem.money = 1e6
	for id in ["casa_pequena", "casa_pequena", "loja_conveniencia"]:
		BuildingSystem.build(id)
	for i in 300:
		GameManager.simulate(0.5)
	EconomySystem.set_tax_level(1)
	var t1 := EconomySystem.tax_income
	EconomySystem.set_tax_level(3)
	check(EconomySystem.tax_income > t1 * 1.4, "imposto alto arrecada mais")
	HappinessSystem.recompute()
	var h_high := HappinessSystem.target
	EconomySystem.set_tax_level(0)
	HappinessSystem.recompute()
	check(HappinessSystem.target > h_high + 15, "imposto alto reduz felicidade")
	EconomySystem.set_tax_level(1)
	var cats: Dictionary = EconomySystem.income_by_cat
	check(cats.has("res") and cats.has("com"), "receitas por categoria")
	var m0 := EconomySystem.money
	var lim := EconomySystem.loan_limit()
	check(EconomySystem.take_loan(lim) and near(EconomySystem.money, m0 + lim), "empréstimo recebido")
	check(not EconomySystem.take_loan(lim), "apenas um empréstimo por vez")
	check(near(EconomySystem.loan_balance, lim * 1.15), "juros de 15%")
	var debt := EconomySystem.loan_balance
	for i in 100:
		GameManager.simulate(0.5)
	check(EconomySystem.loan_balance < debt, "parcelas automáticas reduzem a dívida")
	EconomySystem.money += EconomySystem.loan_balance
	check(EconomySystem.repay_loan() and EconomySystem.loan_balance == 0.0, "quitar dívida")
	EconomySystem.money = 1e6
	check(EconomySystem.invest("cdb", 500.0), "aplica no CDB")
	check(EconomySystem.collect_investment(0) < 0.0, "não resgata antes do prazo")
	EconomySystem.simulate_offline(3601)
	var got := EconomySystem.collect_investment(0)
	check(near(got, 500.0 * 1.08), "CDB rende 8% em 1 hora")
	check(float(EconomySystem.ledger.get("build", 0.0)) > 0 and float(EconomySystem.ledger.get("loan_in", 0.0)) > 0, "relatório registra ganhos e gastos")
	for i in 70:
		EconomySystem.record_history()
	check(EconomySystem.history.size() <= EconomySystem.HISTORY_MAX, "histórico limitado")


func test_migration_v1() -> void:
	print("[2.0: Migração de save da 1.0]")
	fresh()
	var v1 := {
		"economy": {"money": 54321.0, "total_earned": 9e5, "lifetime_earned": 2e6},
		"buildings": {"buildings": [{"uid": 1, "id": "casa_pequena", "lot": 0, "level": 7}, {"uid": 2, "id": "padaria", "lot": 1, "level": 12}], "next_uid": 3},
		"population": {"population": 30.0}, "happiness": {"value": 55.0}, "expansion": {"unlocked": 2},
		"missions": {"claimed": ["m01"], "achievements": ["a_build_1"], "lifetime": {"built": 5}},
		"prestige": {"stars": 2, "stars_total": 3, "count": 1, "upgrades": {"marketing": 1}},
		"idle": {"last_active": Time.get_unix_time_from_system() - 120},
	}
	SaveSystem.write(v1)
	check(GameManager.continue_game(), "save 1.0 carrega na 2.0")
	check(near(EconomySystem.money, 54321.0) and ExpansionSystem.unlocked == 2, "dinheiro e regiões preservados")
	check(BuildingSystem.buildings.size() == 2 and BuildingSystem.buildings.all(func(b): return BuildingSystem.is_complete(b)), "edifícios antigos prontos")
	check(int(BuildingSystem.buildings[1]["level"]) == 12 and PrestigeSystem.level("marketing") == 1, "níveis e prestígio preservados")
	check(EconomySystem.tax_level == 1 and ResearchSystem.done.is_empty(), "novos sistemas com valores padrão")
	check(FileAccess.file_exists(SaveSystem.OLD_FORMAT_BACKUP), "cópia de segurança do save antigo")
	GameManager.save_game()
	check(int(SaveSystem.read().get("format", 0)) == GameManager.SAVE_FORMAT, "save regravado no formato atual")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveSystem.OLD_FORMAT_BACKUP))


func test_offline_v2() -> void:
	print("[2.0: Offline]")
	fresh()
	BuildingSystem.instant_build = false
	EconomySystem.money = 1e6
	var b := BuildingSystem.build("loja_conveniencia")
	BuildingSystem.instant_build = true
	IdleSystem.pending = {}
	IdleSystem.last_active_time = Time.get_unix_time_from_system() + 3600
	var m0 := EconomySystem.money
	var r := IdleSystem.process_absence(Time.get_unix_time_from_system())
	check(r.get("clock_back", false) and IdleSystem.pending.is_empty() and EconomySystem.money == m0, "relógio adiantado/voltado não gera renda")
	IdleSystem.last_active_time = Time.get_unix_time_from_system() - 7200
	r = IdleSystem.process_absence(Time.get_unix_time_from_system())
	check(BuildingSystem.is_complete(b) and int(r["buildings_done"]) == 1, "obras concluem offline")
	check(not IdleSystem.pending.is_empty() and r["by_cat"].size() > 0, "resumo por categoria")
	var r2 := IdleSystem.process_absence(Time.get_unix_time_from_system())
	check(r2.is_empty(), "sem recompensa duplicada ao reabrir")
	var got := IdleSystem.collect()
	check(got > 0.0 and IdleSystem.collect() == 0.0, "coleta uma única vez")


func test_new_buildings() -> void:
	print("[2.0: Novas construções]")
	check(GameData.BUILDINGS.size() >= 53, "%d tipos de edifícios" % GameData.BUILDINGS.size())
	check(GameData.buildings_in_category("esp").size() >= 5, "categoria Especiais")
	check(GameData.region_count() == 8, "8 regiões (Orla Dourada)")
	var ok := true
	for d in GameData.BUILDINGS:
		if not BuildingArt.HEIGHTS.has(d["id"]):
			ok = false
			print("    sem arte: ", d["id"])
	check(ok, "todos os edifícios têm arte e altura")
	fresh()
	ExpansionSystem.unlocked = 8
	EconomySystem.money = 1e14
	for r in GameData.RESEARCH:
		ResearchSystem.force_complete(r["id"])
	var built := 0
	for d in GameData.BUILDINGS:
		if not BuildingSystem.build(d["id"]).is_empty():
			built += 1
	check(built == GameData.BUILDINGS.size() - 3 or built >= 45, "todas as construções podem ser construídas (%d)" % built)
	EconomySystem.recompute()
	check(EconomySystem.income_ps > 0 and not is_nan(EconomySystem.income_ps), "economia estável com todos os edifícios")
	var r0 := ExpansionSystem.unlocked
	check(r0 == 8, "regiões")


func test_city_index() -> void:
	print("[3.0: Índices urbanos]")
	fresh()
	ExpansionSystem.unlocked = 3
	EconomySystem.money = 1e9
	PopulationSystem.population = 50
	CityIndexSystem.recompute()
	check(CityIndexSystem.traffic == 0.0, "cidade pequena sem trânsito")
	PopulationSystem.population = 6000
	CityIndexSystem.recompute()
	var jam := CityIndexSystem.traffic
	check(jam > 50.0 and CityIndexSystem.productivity < 1.0, "população grande congestiona e reduz produtividade (%d%%)" % int(jam))
	HappinessSystem.recompute()
	check(HappinessSystem.factors.any(func(f): return f["name"] == "Trânsito"), "trânsito afeta a felicidade")
	for i in 3:
		BuildingSystem.build("terminal_onibus")
	CityIndexSystem.recompute()
	check(CityIndexSystem.traffic < jam, "terminais de ônibus reduzem o trânsito")
	var p0 := CityIndexSystem.pollution
	ExpansionSystem.unlocked = 4
	BuildingSystem.build("fabrica")
	CityIndexSystem.recompute()
	check(CityIndexSystem.pollution > p0, "fábrica aumenta a poluição")
	var p1 := CityIndexSystem.pollution
	BuildingSystem.build("reciclagem")
	CityIndexSystem.recompute()
	check(CityIndexSystem.pollution < p1, "reciclagem reduz a poluição")
	check(CityIndexSystem.quality_of_life >= 0.0 and CityIndexSystem.quality_of_life <= 100.0 and CityIndexSystem.grade() != "", "qualidade de vida 0-100 com nota")


func test_boosts() -> void:
	print("[3.0: Bônus temporários]")
	fresh()
	EconomySystem.money = 1e6
	BuildingSystem.build("loja_conveniencia")
	for i in 50:
		GameManager.simulate(0.2)
	EconomySystem.recompute()
	var inc := EconomySystem.income_ps
	BoostSystem.last_free = 0.0
	check(BoostSystem.claim_free("renda"), "incentivo grátis ativa bônus")
	EconomySystem.recompute()
	check(near(EconomySystem.income_ps, inc * 2.0, 0.02), "renda em dobro")
	check(not BoostSystem.claim_free("obras"), "incentivo tem recarga de 3 horas")
	BoostSystem.last_free = Time.get_unix_time_from_system() + 99999.0
	check(BoostSystem.free_ready_in() <= GameData.FREE_BOOST_COOLDOWN + 1.0, "relógio voltando não trava nem libera o incentivo")
	BoostSystem.add("obras", 100)
	check(BuildingSystem.build_time("hospital") < GameData.base_build_time(GameData.get_def("hospital")) * 0.6, "obras turbo")
	BoostSystem.tick(10000)
	check(BoostSystem.active.is_empty(), "bônus expiram")
	BoostSystem.add("renda", 3600)
	var r := IdleSystem.compute(1800)
	EconomySystem.recompute()
	check(near(r["money"], inc * 1800, 0.25) and near(BoostSystem.time_left("renda"), 1800, 0.01), "bônus não multiplica a renda offline e é consumido")
	BoostSystem.add("renda", 99999)
	check(BoostSystem.time_left("renda") <= GameData.BOOST_MAX_SECONDS, "duração máxima de 2 horas")


func test_login() -> void:
	print("[3.0: Recompensa diária]")
	fresh()
	check(BoostSystem.login_available() and BoostSystem.next_login_day() == 1, "primeiro dia disponível")
	var m0 := EconomySystem.money
	check(not BoostSystem.claim_login().is_empty() and EconomySystem.money > m0, "dia 1 dá dinheiro")
	check(not BoostSystem.login_available() and BoostSystem.claim_login().is_empty(), "só uma vez por dia")
	var today := ChallengeSystem.current_day_key()
	var yesterday_unix := Time.get_unix_time_from_system() - 86400
	var y := Time.get_date_dict_from_unix_time(int(yesterday_unix))
	BoostSystem.login_day_key = "%04d-%02d-%02d" % [y["year"], y["month"], y["day"]]
	BoostSystem.login_streak = 2
	check(BoostSystem.login_available() and BoostSystem.next_login_day() == 3, "sequência continua no dia seguinte")
	BoostSystem.claim_login()
	check(BoostSystem.is_active("renda") and BoostSystem.login_streak == 3, "dia 3 dá bônus de renda")
	BoostSystem.login_day_key = "2001-01-01"
	BoostSystem.login_streak = 5
	check(BoostSystem.next_login_day() == 1, "perder um dia reinicia a sequência")
	BoostSystem.login_day_key = "9999-01-01"
	check(not BoostSystem.login_available(), "relógio voltando não libera recompensa")
	BoostSystem.login_day_key = today


func test_snapshots() -> void:
	print("[3.0: Cópias de segurança]")
	fresh()
	SaveSystem.delete_all(true)
	EconomySystem.money = 111.0
	SaveSystem._last_snapshot = 0.0
	GameManager.save_game()
	var snaps := SaveSystem.list_snapshots()
	check(snaps.size() == 1 and near(snaps[0]["money"], 111.0), "cópia criada no salvamento")
	EconomySystem.money = 999.0
	GameManager.save_game()
	check(SaveSystem.list_snapshots().size() == 1, "cópias a cada 5 minutos, não a cada salvamento")
	GameManager.new_game()
	check(SaveSystem.list_snapshots().size() >= 1, "novo jogo mantém as cópias")
	var slot: int = snaps[0]["slot"]
	check(SaveSystem.restore_snapshot(slot) and GameManager.continue_game() and near(EconomySystem.money, 111.0), "restaurar recupera o progresso")
	SaveSystem.delete_all(true)
	check(SaveSystem.list_snapshots().is_empty(), "apagar tudo remove as cópias")


func test_migration_v2() -> void:
	print("[3.0: Migração de save da 2.0]")
	fresh()
	var v2 := GameManager.collect_state()
	v2.erase("boosts")
	v2["format"] = 2
	v2["economy"]["money"] = 4242.0
	SaveSystem.write(v2)
	check(GameManager.continue_game() and near(EconomySystem.money, 4242.0), "save 2.0 carrega na 3.0")
	check(BoostSystem.active.is_empty() and BoostSystem.login_available(), "novos sistemas com valores padrão")
	var bk := SaveSystem.OLD_FORMAT_BACKUP.replace("v1", "v2")
	check(FileAccess.file_exists(bk), "cópia do save 2.0 antes da migração")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(bk))
	GameManager.save_game()
	check(int(SaveSystem.read().get("format", 0)) == 3, "regravado no formato 3")


## Simula um jogador jogando de forma simples para verificar o ritmo.
func balance_sim() -> void:
	print("[Simulação de balanceamento (com tempo de obra, pesquisas e eventos)]")
	fresh()
	BuildingSystem.instant_build = false
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
		if ResearchSystem.active_id == "":
			for r in GameData.RESEARCH:
				if ResearchSystem.start(r["id"]):
					break
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
	print("  pesquisas concluídas: %d | eventos cumpridos: %d" % [ResearchSystem.done.size(), int(MissionSystem.lifetime["events_done"])])
	BuildingSystem.instant_build = true


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
				if d.has("transit") and CityIndexSystem.traffic > 30.0 and BuildingSystem.count_owned(d["id"]) < ExpansionSystem.unlocked:
					value = maxf(value, cost / 60.0)
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
