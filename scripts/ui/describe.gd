class_name Describe
extends RefCounted
## Textos descritivos de edifícios para a interface.


static func stats_lines(def: Dictionary, level: int) -> Array[String]:
	var b := {"id": def["id"], "level": level, "lot": 0, "uid": 0}
	var out: Array[String] = []
	if def.has("income"):
		out.append("Renda: " + Fmt.money_ps(BuildingSystem.income_of(b)))
	if def.has("cap"):
		var cap := BuildingSystem.capacity_of(b)
		out.append("Moradores: " + Fmt.pop(cap))
		out.append("Impostos: até " + Fmt.money_ps(cap * float(def["tax"])))
	if def.has("jobs"):
		out.append("Empregos: " + Fmt.pop(BuildingSystem.jobs_of(b)))
	if def.has("service"):
		out.append("%s: atende %s" % [GameData.SERVICE_NAMES[def["service"]], Fmt.pop(BuildingSystem.coverage_of(b))])
	if def.has("transit"):
		out.append("Transporte: %s pessoas" % Fmt.pop(CityIndexSystem.transit_of(b)))
	if def.has("rp"):
		out.append("Pesquisa: +%s/s" % Fmt.num(float(def["rp"]) * pow(float(level), 0.6)))
	if def.has("happy"):
		out.append("Felicidade +%d%%" % int(def["happy"]))
	if def.has("income_bonus"):
		out.append("Renda da cidade +%d%%" % int(float(def["income_bonus"]) * 100))
	var pol := int(def.get("pollution", 0))
	if pol > 0:
		out.append("Poluição +%d" % pol)
	elif pol < 0:
		out.append("Reduz poluição (%d)" % pol)
	if def.has("upkeep"):
		out.append("Manutenção: " + Fmt.money_ps(BuildingSystem.upkeep_of(b)))
	return out


static func short_stats(def: Dictionary, level := 1) -> String:
	return "  |  ".join(stats_lines(def, level))


## Linha "antes » depois" para a próxima melhoria.
static func upgrade_delta(b: Dictionary, levels: int) -> String:
	var def := GameData.get_def(b["id"])
	var nb := b.duplicate()
	nb["level"] = mini(int(b["level"]) + maxi(levels, 1), GameData.MAX_LEVEL)
	if def.has("income"):
		return "Renda: %s » %s" % [Fmt.money_ps(BuildingSystem.income_of(b)), Fmt.money_ps(BuildingSystem.income_of(nb))]
	if def.has("cap"):
		return "Moradores: %s » %s" % [Fmt.pop(BuildingSystem.capacity_of(b)), Fmt.pop(BuildingSystem.capacity_of(nb))]
	if def.has("service"):
		return "Atende: %s » %s" % [Fmt.pop(BuildingSystem.coverage_of(b)), Fmt.pop(BuildingSystem.coverage_of(nb))]
	return "Nível %d » %d" % [int(b["level"]), int(nb["level"])]


static func next_milestone(level: int) -> int:
	for m in GameData.LEVEL_MILESTONES:
		if level < m:
			return m
	return -1
