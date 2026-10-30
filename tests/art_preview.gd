extends Node2D
## Ferramenta de desenvolvimento: renderiza todos os edifícios e salva capturas.
## Uso: godot --path . res://tests/ArtPreview.tscn -- --out=/caminho

var page := 0
var night := false
var level := 1
var out_dir := "user://"


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out_dir = a.substr(6)
	GameManager.running = false
	_run()


func _run() -> void:
	var shots := [[3, false, 1], [3, true, 1], [2, false, 1]]
	for s in shots:
		page = s[0]
		night = s[1]
		level = s[2]
		queue_redraw()
		await get_tree().process_frame
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var img := get_viewport().get_texture().get_image()
		img.save_png(out_dir.path_join("art_p%d_%s_l%d.png" % [page, "night" if night else "day", level]))
	get_tree().quit()


func _draw() -> void:
	var bg := Color("87c9f5") if not night else Color("1c2340")
	draw_rect(Rect2(0, 0, 2000, 2000), bg)
	var per := 7
	var sc := 0.66
	var ids := []
	for d in GameData.BUILDINGS:
		ids.append(d["id"])
	var start := page * per * 2
	for i in range(start, mini(start + per * 2, ids.size())):
		var k := i - start
		var col := k % per
		var row := k / per
		var base := Vector2(95 + col * 180, 330 + row * 345)
		draw_set_transform(base, 0.0, Vector2(sc, sc))
		draw_rect(Rect2(-120, 0, 240, 30), Color("9e9e9e"))
		BuildingArt.draw(self, ids[i], level, 0)
		if night:
			draw_rect(Rect2(-130, -520, 260, 560), Color(0.1, 0.12, 0.3, 0.55))
			BuildingArt.draw(self, ids[i], level, 1)
		draw_string(BuildingArt.font(), Vector2(-120, 60), ids[i], HORIZONTAL_ALIGNMENT_CENTER, 240, 24, Color.WHITE)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
