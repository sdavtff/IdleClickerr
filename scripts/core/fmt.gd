class_name Fmt
extends RefCounted
## Formatação de valores em português brasileiro (R$ 1.000 / R$ 1,2 mi).

const SUFFIXES := [
	[1e33, "dec"], [1e30, "non"], [1e27, "oct"], [1e24, "sep"], [1e21, "sex"],
	[1e18, "qui"], [1e15, "quatri"], [1e12, "tri"], [1e9, "bi"], [1e6, "mi"],
]


static func money(v: float) -> String:
	return ("-R$ " if v < 0 else "R$ ") + num(absf(v))


static func money_ps(v: float) -> String:
	return money(v) + "/s"


static func num(v: float) -> String:
	var neg := v < 0.0
	v = absf(v)
	var s := ""
	if v >= 1e36:
		s = ("%.2e" % v).replace(".", ",")
	elif v >= 1e6:
		for pair in SUFFIXES:
			if v >= pair[0]:
				s = _decimal(v / pair[0]) + " " + pair[1]
				break
	elif v >= 1000.0:
		s = thousands(int(floor(v)))
	elif v >= 100.0 or is_equal_approx(v, roundf(v)):
		s = str(int(floor(v + 0.0001)))
	elif v >= 10.0:
		s = ("%.1f" % v).replace(".", ",")
	else:
		s = ("%.2f" % v).replace(".", ",")
	return ("-" if neg else "") + s


static func _decimal(v: float) -> String:
	var txt := ""
	if v >= 100.0:
		txt = str(int(floor(v)))
	elif v >= 10.0:
		txt = "%.1f" % (floor(v * 10.0) / 10.0)
	else:
		txt = "%.2f" % (floor(v * 100.0) / 100.0)
	if txt.contains("."):
		txt = txt.rstrip("0").rstrip(".")
	return txt.replace(".", ",")


static func thousands(n: int) -> String:
	var neg := n < 0
	var s := str(absi(n))
	var out := ""
	var count := 0
	for i in range(s.length() - 1, -1, -1):
		out = s[i] + out
		count += 1
		if count % 3 == 0 and i > 0:
			out = "." + out
	return ("-" if neg else "") + out


static func pop(v: float) -> String:
	if v >= 1e6:
		return num(v)
	return thousands(int(floor(v)))


static func percent(v: float) -> String:
	return str(int(round(v))) + "%"


static func duration(seconds: float) -> String:
	var total := int(seconds)
	var h := total / 3600
	var m := (total % 3600) / 60
	var s := total % 60
	var parts: Array[String] = []
	if h > 0:
		parts.append("%d %s" % [h, "hora" if h == 1 else "horas"])
	if m > 0:
		parts.append("%d %s" % [m, "minuto" if m == 1 else "minutos"])
	if h == 0 and m == 0:
		parts.append("%d %s" % [s, "segundo" if s == 1 else "segundos"])
	return " e ".join(parts)


static func short_duration(seconds: float) -> String:
	var total := int(seconds)
	if total >= 3600:
		return "%dh %02dm" % [total / 3600, (total % 3600) / 60]
	if total >= 60:
		return "%dm %02ds" % [total / 60, total % 60]
	return "%ds" % total
