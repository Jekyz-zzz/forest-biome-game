extends Node
## Script debug: mengambil screenshot peta dalam beberapa kondisi.
##
## Jalankan dari folder proyek (JANGAN pakai --headless, butuh render):
##   <godot.exe> --path . res://tools/screenshot_map.tscn
##
## Semua kondisi hanya diatur di memori. Script ini tidak memanggil
## save_game() atau fungsi GameState yang menyimpan, jadi save asli aman.
## Hasil: screenshots/debug/map_<kondisi>.png, lalu game keluar sendiri.

const MAP_SCENE := "res://scenes/map.tscn"
const OUT_DIR := "res://screenshots/debug"
## Frame yang ditunggu sebelum mengambil gambar (biar layout & texture siap).
const WAIT_FRAMES := 12

## fertility menentukan tahap peta (lihat GameState.MAP_STAGE_THRESHOLDS).
## completed = bioma yang dianggap sudah diselamatkan + kuis selesai.
const CASES := [
	{"name": "stage0", "fertility": 0,
		"planted": {"meranti": 0, "akasia": 0, "bakau": 0}, "completed": []},
	{"name": "stage1", "fertility": 3,
		"planted": {"meranti": 2, "akasia": 1, "bakau": 0}, "completed": []},
	{"name": "stage2", "fertility": 6,
		"planted": {"meranti": 3, "akasia": 2, "bakau": 1}, "completed": []},
	{"name": "stage3", "fertility": 18,
		"planted": {"meranti": 8, "akasia": 6, "bakau": 4}, "completed": []},
	{"name": "mangrove_locked", "fertility": 6,
		"planted": {"meranti": 3, "akasia": 3, "bakau": 2}, "completed": ["hujan"]},
	{"name": "mangrove_unlocked", "fertility": 6,
		"planted": {"meranti": 3, "akasia": 3, "bakau": 2}, "completed": ["hujan", "sabana"]},
]


func _ready() -> void:
	GameState.apply_game_window()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	await get_tree().process_frame

	var map_scene := load(MAP_SCENE) as PackedScene
	for c in CASES:
		_apply_case(c)
		var map := map_scene.instantiate()
		add_child(map)
		for i in WAIT_FRAMES:
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var path := "%s/map_%s.png" % [OUT_DIR, c["name"]]
		var err := get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path(path))
		print("[screenshot_map] %s  stage=%d  -> %s (%s)" % [
			c["name"], GameState.get_map_stage(), path, error_string(err)])
		map.queue_free()
		await get_tree().process_frame

	get_tree().quit()


## Atur GameState di memori saja.
func _apply_case(c: Dictionary) -> void:
	GameState.fertility = int(c["fertility"])
	GameState.planted = (c["planted"] as Dictionary).duplicate()
	GameState.biome_progress = {}
	for biome_id in ["hujan", "sabana", "mangrove"]:
		var done: bool = biome_id in c["completed"]
		var p := GameState.get_progress(biome_id)
		p["saved"] = done
		p["quiz_done"] = done
	GameState.pending_map_toast = ""
