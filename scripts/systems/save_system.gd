extends Node
## Sistema de salvamento com escrita atômica, checksum SHA-256 e backup.
## Se o arquivo principal estiver corrompido, o backup é usado.

signal saved
signal load_failed(reason: String)

const SAVE_PATH := "user://idlecity_save.json"
const BACKUP_PATH := "user://idlecity_save.bak"
const TEMP_PATH := "user://idlecity_save.tmp"
const SAVE_VERSION := 2
const OLD_FORMAT_BACKUP := "user://idlecity_save_v1_backup.json"
const SALT := "IdleCity::v1::cidade"

var last_save_time := 0.0
var last_error := ""


static func _hash(payload: String) -> String:
	return (payload + SALT).sha256_text()


func has_save() -> bool:
	return _read_valid(SAVE_PATH).size() > 0 or _read_valid(BACKUP_PATH).size() > 0


func write(data: Dictionary) -> bool:
	var payload := JSON.stringify(data, "", false, true)
	var wrapper := {"v": SAVE_VERSION, "time": Time.get_unix_time_from_system(), "hash": _hash(payload), "payload": payload}
	var f := FileAccess.open(TEMP_PATH, FileAccess.WRITE)
	if f == null:
		last_error = "Não foi possível gravar: %s" % error_string(FileAccess.get_open_error())
		push_warning(last_error)
		return false
	f.store_string(JSON.stringify(wrapper))
	f.flush()
	f.close()
	# Confere se o arquivo temporário ficou íntegro antes de substituir.
	if _read_valid(TEMP_PATH).is_empty():
		last_error = "Falha ao verificar o arquivo salvo."
		push_warning(last_error)
		return false
	if not _read_valid(SAVE_PATH).is_empty():
		DirAccess.copy_absolute(ProjectSettings.globalize_path(SAVE_PATH), ProjectSettings.globalize_path(BACKUP_PATH))
	var err := DirAccess.rename_absolute(ProjectSettings.globalize_path(TEMP_PATH), ProjectSettings.globalize_path(SAVE_PATH))
	if err != OK:
		# Alternativa: grava diretamente.
		var f2 := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
		if f2 == null:
			return false
		f2.store_string(JSON.stringify(wrapper))
		f2.close()
	last_save_time = Time.get_unix_time_from_system()
	saved.emit()
	return true


## Retorna os dados salvos ou {} se não houver save válido.
func read() -> Dictionary:
	var d := _read_valid(SAVE_PATH)
	if not d.is_empty():
		return d
	d = _read_valid(BACKUP_PATH)
	if not d.is_empty():
		push_warning("Save principal inválido; usando backup.")
		load_failed.emit("O salvamento principal estava danificado. O backup foi restaurado.")
		return d
	if FileAccess.file_exists(SAVE_PATH):
		load_failed.emit("O salvamento estava danificado e não pôde ser recuperado.")
	return {}


func _read_valid(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var text := f.get_as_text()
	f.close()
	var wrapper = _parse(text)
	if typeof(wrapper) != TYPE_DICTIONARY:
		return {}
	var payload = wrapper.get("payload", null)
	if typeof(payload) != TYPE_STRING:
		return {}
	if str(wrapper.get("hash", "")) != _hash(payload):
		return {}
	var data = _parse(payload)
	if typeof(data) != TYPE_DICTIONARY:
		return {}
	return data


static func _parse(text: String) -> Variant:
	var json := JSON.new()
	if json.parse(text) != OK:
		return null
	return json.data


## Guarda uma cópia do save antigo antes da migração para a 2.0.
func backup_old_format() -> void:
	if FileAccess.file_exists(SAVE_PATH) and not FileAccess.file_exists(OLD_FORMAT_BACKUP):
		DirAccess.copy_absolute(ProjectSettings.globalize_path(SAVE_PATH), ProjectSettings.globalize_path(OLD_FORMAT_BACKUP))


func delete_all() -> void:
	for p in [SAVE_PATH, BACKUP_PATH, TEMP_PATH]:
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(p))
