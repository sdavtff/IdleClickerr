extends Node
## Ferramenta de desenvolvimento: carrega todos os scripts para detectar erros.
func _ready() -> void:
	var dirs := ["res://scripts/core", "res://scripts/systems", "res://scripts/autoload", "res://scripts/city", "res://scripts/ui", "res://scripts"]
	var failed := 0
	for d in dirs:
		for f in DirAccess.get_files_at(d):
			if f.ends_with(".gd"):
				var s = load(d + "/" + f)
				if s == null or not s.can_instantiate():
					print("FAILED: ", d + "/" + f)
					failed += 1
	print("CHECK DONE, failed=", failed)
	get_tree().quit(1 if failed > 0 else 0)
