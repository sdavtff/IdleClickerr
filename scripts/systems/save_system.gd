extends Node
## Sistema de salvamento com escrita atômica, checksum SHA-256 e backup.
## Se o arquivo principal estiver corrompido, o backup é usado. Também mantém
## 3 cópias de segurança rotativas (a cada 5 minutos) que o jogador pode restaurar.

signal saved
signal load_failed(reason: String)

var SAVE_PATH := "user://idlecity_save.json"
var BACKUP_PATH := "user://idlecity_save.bak"
var TEMP_PATH := "user://idlecity_save.tmp"
var OLD_FORMAT_BACKUP := "user://idlecity_save_v1_backup.json"
var SNAPSHOT_PATTERN := "user://idlecity_snapshot_%d.json"
const SAVE_VERSION := 3
const SNAPSHOT_COUNT := 3
const SNAPSHOT_INTERVAL := 300.0
var _last_snapshot := 0.0
const SALT := "IdleCity::v1::cidade"

var last_save_time := 0.0
var last_error := ""


## Usa arquivos separados (autoteste do build exportado não toca no save do jogador).
func use_slot(prefix: String) -> void:
	SAVE_PATH = "user://%s_save.json" % prefix
	BACKUP_PATH = "user://%s_save.bak" % prefix
	TEMP_PATH = "user://%s_save.tmp" % prefix
	OLD_FORMAT_BACKUP = "user://%s_save_old_backup.json" % prefix
	SNAPSHOT_PATTERN = "user://" + prefix + "_snapshot_%d.json"


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
	if last_save_time - _last_snapshot >= SNAPSHOT_INTERVAL:
		_rotate_snapshot()
	saved.emit()
	return true


func _rotate_snapshot() -> void:
	_last_snapshot = last_save_time
	var oldest := 0
	var oldest_t := INF
	for i in SNAPSHOT_COUNT:
		var t := _wrapper_time(SNAPSHOT_PATTERN % i)
		if t < oldest_t:
			oldest_t = t
			oldest = i
	DirAccess.copy_absolute(ProjectSettings.globalize_path(SAVE_PATH), ProjectSettings.globalize_path(SNAPSHOT_PATTERN % oldest))


func _wrapper_time(path: String) -> float:
	if not FileAccess.file_exists(path):
		return -1.0
	var w = _parse(FileAccess.get_file_as_string(path))
	if typeof(w) != TYPE_DICTIONARY:
		return -1.0
	return float(w.get("time", 0.0))


## Cópias de segurança válidas, da mais recente para a mais antiga.
func list_snapshots() -> Array:
	var out := []
	for i in SNAPSHOT_COUNT:
		var path: String = SNAPSHOT_PATTERN % i
		var data := _read_valid(path)
		if data.is_empty():
			continue
		var eco: Dictionary = data.get("economy", {}) if typeof(data.get("economy", {})) == TYPE_DICTIONARY else {}
		var ex: Dictionary = data.get("expansion", {}) if typeof(data.get("expansion", {})) == TYPE_DICTIONARY else {}
		out.append({"slot": i, "time": _wrapper_time(path), "money": float(eco.get("money", 0.0)), "regions": int(ex.get("unlocked", 1))})
	out.sort_custom(func(a, b): return a["time"] > b["time"])
	return out


## Restaura uma cópia de segurança como save principal.
func restore_snapshot(slot: int) -> bool:
	var path: String = SNAPSHOT_PATTERN % slot
	if _read_valid(path).is_empty():
		return false
	if not _read_valid(SAVE_PATH).is_empty():
		DirAccess.copy_absolute(ProjectSettings.globalize_path(SAVE_PATH), ProjectSettings.globalize_path(BACKUP_PATH))
	return DirAccess.copy_absolute(ProjectSettings.globalize_path(path), ProjectSettings.globalize_path(SAVE_PATH)) == OK


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


## Guarda uma cópia do save antigo antes de migrar para um formato novo.
func backup_old_format(fmt := 1) -> void:
	var dest := OLD_FORMAT_BACKUP if fmt <= 1 else OLD_FORMAT_BACKUP.replace("v1", "v%d" % fmt)
	if FileAccess.file_exists(SAVE_PATH) and not FileAccess.file_exists(dest):
		DirAccess.copy_absolute(ProjectSettings.globalize_path(SAVE_PATH), ProjectSettings.globalize_path(dest))


## Apaga o save. As cópias rotativas são mantidas por padrão, para que o
## jogador possa recuperar o progresso mesmo depois de "Novo jogo".
func delete_all(include_snapshots := false) -> void:
	_last_snapshot = 0.0
	var paths := [SAVE_PATH, BACKUP_PATH, TEMP_PATH]
	if include_snapshots:
		for i in SNAPSHOT_COUNT:
			paths.append(SNAPSHOT_PATTERN % i)
	for p in paths:
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(p))
