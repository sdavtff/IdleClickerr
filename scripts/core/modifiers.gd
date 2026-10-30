class_name Modifiers
extends RefCounted
## Soma os efeitos ativos de pesquisas e eventos para uma chave
## (ex.: "biz" = +15% renda empresarial, "build_time" = -20% tempo de obra).


static func get_fx(key: String) -> float:
	return ResearchSystem.fx(key) + EventSystem.fx(key) + BoostSystem.fx(key)


## Multiplicador (1 + soma), nunca abaixo de `floor_value`.
static func mult(key: String, floor_value := 0.1) -> float:
	return maxf(floor_value, 1.0 + get_fx(key))


## Multiplicador de renda para uma categoria de edifício.
static func category_mult(cat: String) -> float:
	var m := mult("all_income")
	match cat:
		"com":
			m *= mult("com")
		"biz":
			m *= mult("biz")
		"fun":
			m *= mult("fun")
		"esp":
			m *= mult("biz") * mult("com")
	return m
