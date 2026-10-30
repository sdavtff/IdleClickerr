class_name ScrollList
extends Control
## Lista com rolagem por toque (arraste com inércia) otimizada para celular.
## Os itens ficam em `content` (VBoxContainer).

var content: VBoxContainer
var modal: Control
var scroll := 0.0
var _vel := 0.0
var _pressing := false
var _dragging := false
var _press_y := 0.0
var _last_y := 0.0
var _last_t := 0
var _content_h := 0.0

const DRAG_THRESHOLD := 12.0


func _init() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_PASS
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 10)
	content.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(content)


func max_scroll() -> float:
	return maxf(0.0, _content_h - size.y)


func scroll_to_top() -> void:
	scroll = 0.0
	_vel = 0.0


func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	var min_h := content.get_combined_minimum_size().y
	if not is_equal_approx(min_h, _content_h) or not is_equal_approx(content.size.x, size.x):
		_content_h = min_h
		content.size = Vector2(size.x, min_h)
	if not _pressing and absf(_vel) > 1.0:
		scroll += _vel * delta
		_vel *= pow(0.05, delta)
	scroll = clampf(scroll, 0.0, max_scroll())
	content.position = Vector2(0, -round(scroll))


func _is_active() -> bool:
	if not is_visible_in_tree():
		return false
	return modal == null or UI.top_modal() == modal


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and (mb.button_index == MOUSE_BUTTON_WHEEL_DOWN or mb.button_index == MOUSE_BUTTON_WHEEL_UP):
			if _is_active() and get_global_rect().has_point(mb.position):
				_vel = 0.0
				scroll = clampf(scroll + (60.0 if mb.button_index == MOUSE_BUTTON_WHEEL_DOWN else -60.0), 0.0, max_scroll())
			return
		if mb.button_index != MOUSE_BUTTON_LEFT:
			return
		if mb.pressed:
			if _is_active() and get_global_rect().has_point(mb.position):
				_pressing = true
				_dragging = false
				_press_y = mb.position.y
				_last_y = mb.position.y
				_last_t = Time.get_ticks_msec()
				_vel = 0.0
				UI.drag_happened = false
		elif _pressing:
			_pressing = false
			if _dragging:
				UI.drag_happened = true
				# Libera o bloqueio de clique logo após o evento atual.
				_reset_drag_flag.call_deferred()
	elif event is InputEventMouseMotion and _pressing:
		var mm := event as InputEventMouseMotion
		if not _dragging and absf(mm.position.y - _press_y) > DRAG_THRESHOLD:
			_dragging = true
			UI.drag_happened = true
		if _dragging:
			var dy := mm.position.y - _last_y
			var now := Time.get_ticks_msec()
			var dt := maxf(1.0, float(now - _last_t)) / 1000.0
			scroll = clampf(scroll - dy, 0.0, max_scroll())
			_vel = lerpf(_vel, -dy / dt, 0.5)
			_last_t = now
		_last_y = mm.position.y


func _reset_drag_flag() -> void:
	await get_tree().process_frame
	UI.drag_happened = false
