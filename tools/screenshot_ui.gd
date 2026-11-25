extends Node
## Script debug: screenshot semua layar yang punya tombol, plus lembar
## contoh state tombol (normal / hover / pressed / disabled).
##
## Jalankan dari folder proyek (JANGAN pakai --headless, butuh render):
##   <godot.exe> --path . res://tools/screenshot_ui.tscn -- --tag=after
##
## Tidak menyimpan apa pun ke save: tidak ada tombol beli/selesai yang
## ditekan, dan layar skor kuis tidak dibuka.
## Hasil: screenshots/debug/ui_<tag>_<nama>.png, lalu game keluar sendiri.

const OUT_DIR := "res://screenshots/debug"
const WAIT_FRAMES := 12

var _tag := "shot"
## --only=explore,quiz : hanya jalankan bagian yang namanya disebut.
var _only: PackedStringArray = []


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--tag="):
			_tag = arg.trim_prefix("--tag=")
		elif arg.begins_with("--only="):
			_only = arg.trim_prefix("--only=").split(",")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	GameState.apply_game_window()
	await _settle()

	if _want("states"): await _shot_states()
	if _want("menu"):
		await _shot_main_menu()
		GameState.apply_game_window()
	if _want("intro"):
		await _shot_simple("res://scenes/intro.tscn", "intro", 1.5)
		await _shot_intro_slides()
	if _want("map"): await _shot_map()
	if _want("quiz"): await _shot_quiz()
	if _want("shop"): await _shot_shop()
	if _want("results"): await _shot_results()
	if _want("explore"):
		await _shot_explore()
		await _shot_explore_objects("hujan")
		await _shot_explore_objects("sabana")
		await _shot_explore_objects("mangrove")
	if _want("runner"): await _shot_runner()
	if _want("fire"): await _shot_simple("res://scenes/minigame_fire.tscn", "fire", 2.0)

	print("[screenshot_ui] selesai")
	get_tree().quit()


# ----------------------------------------------------------- lembar state --

func _want(part: String) -> bool:
	return _only.is_empty() or _only.has(part)


func _shot_states() -> void:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	var bg := ColorRect.new()
	bg.color = Color("17301c")
	UI.full_rect(bg)
	root.add_child(bg)

	var box := UI.panel_box(Vector2(600, 0))
	box.position = Vector2(20, 14)
	root.add_child(box)
	var v := UI.vbox(10)
	box.add_child(v)
	v.add_child(UI.title("Contoh Tombol", 22))

	var row := UI.hbox(12)
	v.add_child(row)
	var normal := UI.button("Normal", 16, Vector2(130, 40))
	var hover := UI.button("Hover", 16, Vector2(130, 40))
	var pressed := UI.button("Pressed", 16, Vector2(130, 40))
	var disabled := UI.button("Disabled", 16, Vector2(130, 40))
	pressed.toggle_mode = true
	pressed.button_pressed = true
	disabled.disabled = true
	for b in [normal, hover, pressed, disabled]:
		row.add_child(b)

	var row2 := UI.hbox(12)
	v.add_child(row2)
	for t in ["Mulai", "Lanjut", "Kembali", "Beli", "Pasang", "Jeda"]:
		row2.add_child(UI.button(t, 14, Vector2(80, 32)))

	var long := UI.button("A. Kalimat pilihan jawaban yang panjang dan harus mudah dibaca", 13, Vector2(280, 34))
	long.theme_type_variation = &"ButtonLong"
	long.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	long.alignment = HORIZONTAL_ALIGNMENT_LEFT
	v.add_child(long)

	var cb := CheckBox.new()
	cb.text = "Musik (CheckBox)"
	cb.button_pressed = true
	cb.add_theme_color_override("font_color", UI.CREAM)
	v.add_child(cb)

	v.add_child(UI.label("Label biasa: teks panjang tetap memakai font bawaan.", 13))

	await _settle()
	_hover(hover)
	await get_tree().create_timer(0.4).timeout
	await _shot("states")
	root.queue_free()
	await get_tree().process_frame


# ---------------------------------------------------------------- layar --

func _shot_main_menu() -> void:
	var menu := (load("res://scenes/main_menu.tscn") as PackedScene).instantiate()
	add_child(menu)
	await _settle()
	await _shot("main_menu")
	# Hover pada papan SETTING (membesar dari tengah teks).
	_hover(menu.get_node("Planks/SettingButton"))
	await get_tree().create_timer(0.5).timeout
	await _shot("main_menu_hover_setting")
	_hover(menu.get_node("CreditsButton"))
	await get_tree().create_timer(0.4).timeout
	# Tandai area klik tiap papan (hanya untuk pengecekan visual).
	var marks: Array[Node] = []
	for n in ["PlayButton", "SettingButton", "ExitButton"]:
		var b := menu.get_node("Planks/" + n) as Button
		var r := ColorRect.new()
		r.color = Color(1, 0, 0, 0.25)
		r.mouse_filter = Control.MOUSE_FILTER_IGNORE
		r.size = b.size
		b.add_child(r)
		marks.append(r)
	await _settle()
	await _shot("main_menu_hitareas")
	for r in marks:
		r.queue_free()
	await get_tree().process_frame

	menu._open_settings()
	await _settle()
	# 4 kombinasi musik x efek (tampilan saja; _on_toggle/save tidak dipanggil).
	var icons := menu.find_children("*", "TextureButton", true, false)
	for combo in [[true, true], [true, false], [false, true], [false, false]]:
		for i in icons.size():
			var icon := icons[i] as TextureButton
			var on: bool = combo[i]
			icon.set_pressed_no_signal(on)
			var status := icon.get_parent().get_child(1) as Label
			menu._show_toggle_state(icon, status, ["Musik", "Efek Suara"][i], on)
		await _settle()
		await _shot("settings_musik_%s_efek_%s" % ["nyala" if combo[0] else "mati", "nyala" if combo[1] else "mati"])
	menu._open_credits()
	await _settle()
	await _shot("main_menu_credits")
	menu.queue_free()
	await get_tree().process_frame

func _shot_simple(path: String, shot_name: String, wait := 0.0) -> void:
	var scene := (load(path) as PackedScene).instantiate()
	add_child(scene)
	await _settle()
	if wait > 0.0:
		await get_tree().create_timer(wait).timeout
	await _shot(shot_name)
	scene.queue_free()
	await get_tree().process_frame


func _shot_map() -> void:
	var map := (load("res://scenes/map.tscn") as PackedScene).instantiate()
	add_child(map)
	await _settle()
	await _shot("map")
	map._on_zone_pressed("hujan")
	await _settle()
	await _shot("map_popup")
	map.queue_free()
	await get_tree().process_frame


func _shot_quiz() -> void:
	GameState.current_biome = "sabana"
	var q := (load("res://scenes/quiz.tscn") as PackedScene).instantiate()
	add_child(q)
	await _settle()
	await _shot("quiz_intro")
	q._index = 0
	q._show_question()
	await _settle()
	_hover(q._option_buttons[0])
	await get_tree().create_timer(0.4).timeout
	await _shot("quiz_question")
	var ans := int(q._questions[0]["answer"])
	var wrong := (ans + 1) % 4
	q._on_answer(wrong, q._option_buttons[wrong])
	await get_tree().create_timer(0.5).timeout
	await _settle()
	await _shot("quiz_answered")
	q._correct = 4
	q._scored = true  # cegah mark_quiz_done()/save
	q._show_score()
	await get_tree().create_timer(1.2).timeout
	await _shot("quiz_score")
	q.queue_free()
	await get_tree().process_frame


func _shot_shop() -> void:
	var shop := (load("res://scenes/shop.tscn") as PackedScene).instantiate()
	add_child(shop)
	await _settle()
	await _shot("shop")
	shop._on_tab_pressed("pupuk")
	await _settle()
	await _shot("shop_pupuk")
	shop.queue_free()
	await get_tree().process_frame


func _shot_results() -> void:
	for stars in [1, 2, 3]:
		GameState.last_run = {"stars": stars, "coins": 12, "biome": "hujan", "won": true}
		await _shot_simple("res://scenes/results.tscn", "results_%d" % stars, 1.5)


func _shot_intro_slides() -> void:
	var intro := (load("res://scenes/intro.tscn") as PackedScene).instantiate()
	add_child(intro)
	await _settle()
	intro._finished = true  # hentikan alur otomatis
	await get_tree().create_timer(0.8).timeout
	for i in intro.SLIDES.size():
		var slide: Dictionary = intro.SLIDES[i]
		intro._text.text = slide["text"]
		intro._text.modulate.a = 1.0
		intro._bg.art_modulate = intro.bg_tint(slide)
		if i == intro.SLIDES.size() - 1:
			intro._sprout.scale = Vector2.ONE
		await _settle()
		await _shot("intro_slide%d" % (i + 1))
	intro.queue_free()
	await get_tree().process_frame


func _shot_explore_objects(biome_id: String) -> void:
	GameState.current_biome = biome_id
	var ex := (load("res://scenes/explore.tscn") as PackedScene).instantiate()
	add_child(ex)
	await _settle()
	var i := 1
	for x in [620.0, 1450.0, 2280.0]:
		ex._player.global_position = Vector2(x - 170.0, 280.0)
		await get_tree().create_timer(1.0).timeout
		await _shot("explore_%s_obj%d" % [biome_id, i])
		ex._open_dialog(i - 1)
		await _settle()
		await _shot("explore_%s_obj%d_dialog" % [biome_id, i])
		ex._close_dialog()
		i += 1
	ex.queue_free()
	await get_tree().process_frame


func _shot_explore() -> void:
	GameState.current_biome = "hujan"
	var ex := (load("res://scenes/explore.tscn") as PackedScene).instantiate()
	add_child(ex)
	await _settle()
	await _shot("explore")
	ex._set_paused(true)
	await _settle()
	await _shot("explore_pause")
	ex._set_paused(false)
	ex._open_dialog(0)
	await _settle()
	await _shot("explore_dialog")
	ex._close_dialog()
	ex._open_briefing()
	await _settle()
	await _shot("explore_briefing")
	ex._open_card_picker()
	await _settle()
	await _shot("explore_card_picker")
	if ex._card_scroll != null:
		ex._card_scroll.scroll_vertical = 100000
		await _settle()
		await _shot("explore_card_picker_bottom")
	ex.queue_free()
	await get_tree().process_frame


func _shot_runner() -> void:
	GameState.current_biome = "hujan"
	var mg := (load("res://scenes/minigame_runner.tscn") as PackedScene).instantiate()
	add_child(mg)
	await _settle()
	await get_tree().create_timer(3.5).timeout
	await _shot("runner_play")
	mg._set_paused(true)
	await _settle()
	await _shot("runner_pause")
	mg._set_paused(false)
	mg._show_game_over()
	await _settle()
	await _shot("runner_game_over")
	mg.queue_free()
	await get_tree().process_frame


# --------------------------------------------------------------- bantuan --

## Kirim gerakan mouse palsu ke tengah tombol supaya state hover aktif.
func _hover(b: Control) -> void:
	var ev := InputEventMouseMotion.new()
	ev.position = b.get_global_rect().get_center()
	ev.global_position = ev.position
	get_viewport().push_input(ev, true)


func _settle() -> void:
	for i in WAIT_FRAMES:
		await get_tree().process_frame


func _shot(shot_name: String) -> void:
	await RenderingServer.frame_post_draw
	var path := "%s/ui_%s_%s.png" % [OUT_DIR, _tag, shot_name]
	var err := get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path(path))
	print("[screenshot_ui] %s -> %s" % [path, error_string(err)])
