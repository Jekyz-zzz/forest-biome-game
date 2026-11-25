extends Node
## Script debug: screenshot layar kuis + cek otomatis teks terpotong.
##
## Jalankan dari folder proyek (JANGAN pakai --headless, butuh render):
##   <godot.exe> --path . res://tools/screenshot_quiz.tscn
##
## Tidak menyimpan apa pun ke save: _scored diset true sebelum layar skor,
## jadi GameState.mark_quiz_done() / save_game() tidak terpanggil.
## Hasil: screenshots/debug/quiz_*.png, lalu game keluar sendiri.

const QUIZ_SCENE := "res://scenes/quiz.tscn"
const OUT_DIR := "res://screenshots/debug"
const WAIT_FRAMES := 12
const SCREEN := Rect2(0, 0, 640, 360)

## Soal yang difoto: sabana soal 1 (pilihan terpanjang).
const SHOT_BIOME := "sabana"
const SHOT_INDEX := 0

var _problems := 0


func _ready() -> void:
	GameState.apply_game_window()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	await get_tree().process_frame

	var scene := load(QUIZ_SCENE) as PackedScene

	# 1) Cek semua 15 soal dalam kondisi sudah dijawab (layout terpanjang).
	for biome_id in BiomeData.biome_ids():
		var quiz := await _spawn(scene, biome_id)
		for i in range(quiz._questions.size()):
			quiz._index = i
			quiz._show_question()
			await _settle()
			_check(quiz, "%s soal %d (belum dijawab)" % [biome_id, i + 1])
			var answer := int(quiz._questions[i]["answer"])
			var wrong := (answer + 1) % 4
			quiz._on_answer(wrong, quiz._option_buttons[wrong])
			await _settle()
			_check(quiz, "%s soal %d (sudah dijawab)" % [biome_id, i + 1])
		quiz.queue_free()
		await get_tree().process_frame

	# 2) Screenshot: intro, soal, feedback + penjelasan, skor.
	var q := await _spawn(scene, SHOT_BIOME)
	await _shot("quiz_intro")
	q._index = SHOT_INDEX
	q._show_question()
	await _settle()
	await _shot("quiz_question")
	var ans := int(q._questions[SHOT_INDEX]["answer"])
	var wrong_opt := (ans + 1) % 4
	q._on_answer(wrong_opt, q._option_buttons[wrong_opt])
	await get_tree().create_timer(0.4).timeout
	await _settle()
	await _shot("quiz_feedback")
	q._correct = 4
	q._scored = true
	q._show_score()
	await get_tree().create_timer(1.2).timeout
	await _settle()
	_check(q, "layar skor")
	await _shot("quiz_score")

	print("[screenshot_quiz] selesai, masalah layout: %d" % _problems)
	get_tree().quit()


func _spawn(scene: PackedScene, biome_id: String) -> Control:
	GameState.current_biome = biome_id
	var quiz := scene.instantiate() as Control
	add_child(quiz)
	await _settle()
	return quiz


func _settle() -> void:
	for i in WAIT_FRAMES:
		await get_tree().process_frame


func _shot(shot_name: String) -> void:
	await RenderingServer.frame_post_draw
	var path := "%s/%s.png" % [OUT_DIR, shot_name]
	var err := get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path(path))
	print("[screenshot_quiz] %s -> %s" % [path, error_string(err)])


## Laporkan kontrol yang keluar layar atau lebih kecil dari ukuran minimumnya.
func _check(quiz: Control, where: String) -> void:
	var bottom := 0.0
	for c in _all_controls(quiz._content):
		if not c.is_visible_in_tree():
			continue
		var r := c.get_global_rect()
		bottom = maxf(bottom, r.end.y)
		if r.position.x < -0.5 or r.position.y < -0.5 or r.end.x > SCREEN.end.x + 0.5 or r.end.y > SCREEN.end.y + 0.5:
			_report(where, "%s keluar layar %s" % [_desc(c), r])
		var min_size := c.get_combined_minimum_size()
		if c.size.x + 0.5 < min_size.x or c.size.y + 0.5 < min_size.y:
			_report(where, "%s terpotong: size %s < min %s" % [_desc(c), c.size, min_size])
	print("[cek] %-32s tepi bawah = %.0f px" % [where, bottom])


func _all_controls(root: Node) -> Array[Control]:
	var out: Array[Control] = []
	for child in root.get_children():
		if child is Control:
			out.append(child)
		out.append_array(_all_controls(child))
	return out


func _desc(c: Control) -> String:
	var t := ""
	if c is Label:
		t = (c as Label).text
	elif c is Button:
		t = (c as Button).text
	return "%s '%s'" % [c.get_class(), t.left(40)]


func _report(where: String, msg: String) -> void:
	_problems += 1
	push_warning("[screenshot_quiz] %s: %s" % [where, msg])
	print("[MASALAH] %s: %s" % [where, msg])
