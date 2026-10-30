class_name UI
extends RefCounted
## Kit de interface: tema, cores, botões estilizados, ícones e utilidades.

const C_BG := Color("1d2740")
const C_CARD := Color("fdfbf6")
const C_CARD_ALT := Color("f1ede4")
const C_TEXT := Color("2c3450")
const C_MUTED := Color("7a819a")
const C_GREEN := Color("2fb36b")
const C_BLUE := Color("3d8bdb")
const C_ORANGE := Color("f39c12")
const C_RED := Color("e05a4f")
const C_PURPLE := Color("8e6fd8")
const C_GOLD := Color("f5c242")
const C_GREY := Color("a3aabb")
const OUTLINE := Color("232a40")

static var font_bold: Font
static var font_semi: Font
static var _icons := {}
## Verdadeiro se o último toque virou arraste numa lista (evita cliques acidentais).
static var drag_happened := false
static var modal_stack: Array = []


static func init_fonts() -> void:
	if font_bold == null:
		font_bold = load("res://assets/fonts/Fredoka-Bold.woff")
		font_semi = load("res://assets/fonts/Fredoka-SemiBold.woff")


static func icon(name: String) -> Texture2D:
	if not _icons.has(name):
		_icons[name] = load("res://assets/icons/%s.png" % name)
	return _icons[name]


static func style(bg: Color, radius := 16, border := 0, border_col := OUTLINE, bottom := 0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.set_corner_radius_all(radius)
	s.border_color = border_col
	s.set_border_width_all(border)
	if bottom > 0:
		s.border_width_bottom = bottom
	s.content_margin_left = 12
	s.content_margin_right = 12
	s.content_margin_top = 6
	s.content_margin_bottom = 6
	s.anti_aliasing = true
	return s


static func make_theme() -> Theme:
	init_fonts()
	var t := Theme.new()
	t.default_font = font_semi
	t.default_font_size = 22
	t.set_color("font_color", "Label", C_TEXT)
	t.set_color("font_color", "Button", Color.WHITE)
	t.set_color("font_hover_color", "Button", Color.WHITE)
	t.set_color("font_pressed_color", "Button", Color.WHITE)
	t.set_color("font_focus_color", "Button", Color.WHITE)
	t.set_color("font_disabled_color", "Button", Color(1, 1, 1, 0.85))
	t.set_font("font", "Button", font_bold)
	t.set_font_size("font_size", "Button", 22)
	t.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	_button_styles(t, "Button", C_BLUE)
	var pb_bg := style(Color("dfe3ec"), 9)
	pb_bg.content_margin_top = 0
	pb_bg.content_margin_bottom = 0
	t.set_stylebox("background", "ProgressBar", pb_bg)
	t.set_stylebox("fill", "ProgressBar", style(C_GREEN, 9))
	t.set_color("font_color", "ProgressBar", C_TEXT)
	t.set_font_size("font_size", "ProgressBar", 15)
	t.set_stylebox("panel", "PanelContainer", style(C_CARD, 18))
	return t


static func _button_styles(t: Theme, type: String, col: Color) -> void:
	t.set_stylebox("normal", type, style(col, 14, 3, col.darkened(0.35), 6))
	t.set_stylebox("hover", type, style(col.lightened(0.08), 14, 3, col.darkened(0.35), 6))
	var pressed := style(col.darkened(0.08), 14, 3, col.darkened(0.35), 3)
	pressed.content_margin_top = 9
	t.set_stylebox("pressed", type, pressed)
	t.set_stylebox("disabled", type, style(C_GREY, 14, 3, C_GREY.darkened(0.3), 6))


static func color_button(b: Button, col: Color) -> void:
	b.add_theme_stylebox_override("normal", style(col, 14, 3, col.darkened(0.35), 6))
	b.add_theme_stylebox_override("hover", style(col.lightened(0.08), 14, 3, col.darkened(0.35), 6))
	var pressed := style(col.darkened(0.08), 14, 3, col.darkened(0.35), 3)
	pressed.content_margin_top = 9
	b.add_theme_stylebox_override("pressed", pressed)


## Botão estilizado. `guarded` ignora toques que viraram arraste de lista.
static func button(text: String, col: Color, callback: Callable, size := 22, guarded := true, icon_name := "") -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", size)
	color_button(b, col)
	if icon_name != "":
		b.icon = icon(icon_name)
		b.expand_icon = true
		b.add_theme_constant_override("icon_max_width", int(size * 1.4))
	b.pressed.connect(func():
		if guarded and drag_happened:
			return
		AudioManager.play("click")
		callback.call())
	return b


static func label(text: String, size := 22, col := C_TEXT, bold := false, align := HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	init_fonts()
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	if bold:
		l.add_theme_font_override("font", font_bold)
	l.horizontal_alignment = align
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


static func outlined(l: Label, outline := 6, col := OUTLINE) -> Label:
	l.add_theme_constant_override("outline_size", outline)
	l.add_theme_color_override("font_outline_color", col)
	return l


static func icon_rect(name: String, size := 36) -> TextureRect:
	var r := TextureRect.new()
	r.texture = icon(name)
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	r.custom_minimum_size = Vector2(size, size)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r


static func card(bg := C_CARD, radius := 16, pad := 12) -> PanelContainer:
	var p := PanelContainer.new()
	var s := style(bg, radius, 3, Color(0, 0, 0, 0.08), 5)
	s.border_color = Color("d9d3c4")
	s.content_margin_left = pad
	s.content_margin_right = pad
	s.content_margin_top = pad
	s.content_margin_bottom = pad
	p.add_theme_stylebox_override("panel", s)
	p.mouse_filter = Control.MOUSE_FILTER_PASS
	return p


static func hbox(sep := 10) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", sep)
	h.mouse_filter = Control.MOUSE_FILTER_PASS
	return h


static func vbox(sep := 6) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", sep)
	v.mouse_filter = Control.MOUSE_FILTER_PASS
	return v


static func spacer(expand := true) -> Control:
	var c := Control.new()
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if expand:
		c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return c


static func progress(value: float, max_value: float, col := C_GREEN) -> ProgressBar:
	var p := ProgressBar.new()
	p.max_value = maxf(max_value, 0.0001)
	p.value = clampf(value, 0.0, p.max_value)
	p.show_percentage = false
	p.custom_minimum_size = Vector2(0, 18)
	p.add_theme_stylebox_override("fill", style(col, 9))
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return p


static func clear(node: Node) -> void:
	for c in node.get_children():
		node.remove_child(c)
		c.queue_free()


static func top_modal() -> Control:
	return null if modal_stack.is_empty() else modal_stack[-1]
