class_name DayNight
extends RefCounted
## Ciclo de dia e noite. t: 0 = meia-noite, 0.25 = 6h, 0.5 = meio-dia, 0.75 = 18h.

const CYCLE_SECONDS := 360.0

var t := 0.33
var enabled := true


func advance(dt: float) -> void:
	if enabled:
		t = fposmod(t + dt / CYCLE_SECONDS, 1.0)


func elevation() -> float:
	return sin((t - 0.25) * TAU)


func daylight() -> float:
	return smoothstep(-0.14, 0.2, elevation())


func night_factor() -> float:
	return 1.0 - smoothstep(-0.06, 0.16, elevation())


func dusk() -> float:
	return clampf(1.0 - absf(elevation()) / 0.3, 0.0, 1.0)


func world_tint() -> Color:
	var night := Color(0.34, 0.38, 0.62)
	var c := night.lerp(Color.WHITE, daylight())
	return c.lerp(Color(1.0, 0.8, 0.66), dusk() * 0.4 * daylight())


func sky_colors() -> Array:
	var day_top := Color(0.33, 0.63, 0.95)
	var day_bot := Color(0.72, 0.89, 1.0)
	var dusk_top := Color(0.33, 0.33, 0.62)
	var dusk_bot := Color(1.0, 0.62, 0.42)
	var night_top := Color(0.03, 0.05, 0.15)
	var night_bot := Color(0.12, 0.15, 0.33)
	var d := daylight()
	var top := night_top.lerp(day_top, d)
	var bot := night_bot.lerp(day_bot, d)
	var k := dusk()
	top = top.lerp(dusk_top, k * 0.6)
	bot = bot.lerp(dusk_bot, k * 0.75)
	return [top, bot]


func clock_text() -> String:
	var minutes := int(t * 24.0 * 60.0)
	return "%02d:%02d" % [minutes / 60, (minutes % 60) / 10 * 10]
