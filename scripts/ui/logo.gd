class_name GameLogo
extends Control
## Logotipo "IDLE CITY" desenhado com contorno, sombra e mini skyline.

var font_size := 96


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(720, 230)


func _draw() -> void:
	UI.init_fonts()
	var f := UI.font_bold
	var cx := size.x * 0.5
	# mini skyline atrás do texto
	var base := size.y - 70.0
	var blocks := [[-250, 60, 70, Color("4fa3e0")], [-175, 100, 64, Color("8e6fd8")], [-105, 140, 60, Color("f39c12")],
		[-40, 112, 70, Color("3fbf6f")], [36, 160, 58, Color("e05a5a")], [100, 96, 66, Color("f5c242")], [172, 128, 70, Color("4fa3e0")]]
	for b in blocks:
		var r := Rect2(cx + b[0], base - b[1], b[2], b[1])
		draw_rect(r.grow(4), UI.OUTLINE)
		draw_rect(r, b[3])
		for wy in range(int(r.position.y) + 12, int(base) - 12, 22):
			for wx in range(int(r.position.x) + 10, int(r.end.x) - 14, 20):
				draw_rect(Rect2(wx, wy, 10, 12), Color("fff3b0"))
	var text := "IDLE CITY"
	var w := f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var pos := Vector2(cx - w * 0.5, size.y - 18)
	draw_string_outline(f, pos + Vector2(0, 8), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 26, Color(0, 0, 0, 0.25))
	draw_string_outline(f, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 22, UI.OUTLINE)
	draw_string(f, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color("ffd23f"))
	draw_string(f, pos + Vector2(0, -4), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color("ffe36e"))
