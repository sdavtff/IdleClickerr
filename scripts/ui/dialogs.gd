class_name ConfirmDialog
extends ModalPanel
## Diálogo de confirmação genérico.

var _msg: Label
var _ok: Button
var _cancel: Button
var _on_ok: Callable


func _init() -> void:
	super()
	title = "Confirmar"
	icon_name = "check"
	desired_size = Vector2(760, 440)


func ask(p_title: String, message: String, ok_text: String, on_ok: Callable, ok_color := UI.C_RED) -> void:
	_build_frame()
	title_label.text = p_title
	_on_ok = on_ok
	open_panel()
	_msg.text = message
	_ok.text = ok_text
	UI.color_button(_ok, ok_color)


func rebuild() -> void:
	if _msg != null:
		return
	_msg = UI.label("", 21, UI.C_TEXT)
	_msg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_msg.custom_minimum_size = Vector2(600, 0)
	list.content.add_child(_msg)
	var row := UI.hbox(14)
	list.content.add_child(row)
	_cancel = UI.button("Cancelar", UI.C_GREY, close_panel, 22)
	_cancel.custom_minimum_size = Vector2(0, 66)
	_cancel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(_cancel)
	_ok = UI.button("OK", UI.C_RED, _confirm, 22)
	_ok.custom_minimum_size = Vector2(0, 66)
	_ok.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(_ok)


func _confirm() -> void:
	close_panel()
	if _on_ok.is_valid():
		_on_ok.call()
