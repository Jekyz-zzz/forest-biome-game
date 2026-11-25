extends Control
## Kuis pilihan ganda 5 soal per bioma, 4 pilihan (A-D) per soal.
## Alur: intro -> soal -> feedback + penjelasan -> "Lanjut" -> ... -> skor -> peta.

const LETTERS := ["A", "B", "C", "D"]
const COLOR_RIGHT_BG := Color("3f7a3a")
const COLOR_RIGHT_BORDER := Color("7ed957")
const COLOR_WRONG_BG := Color("6b2f2f")
const COLOR_WRONG_BORDER := Color("c05050")

## Ukuran layout layar soal (viewport 640x360). Posisi diatur container:
## header + progress bar + panel dikelompokkan dan di-center otomatis.
const PANEL_W := 600.0
## Lebar isi panel = PANEL_W - 2 * (margin 12 + border 3).
const INNER_W := 570
## Progress bar selebar panel soal.
const BAR_W := PANEL_W
const BAR_H := 8.0
## Jarak ekstra antara teks soal dan tombol pilihan (di atas separation vbox).
const QUESTION_GAP := 6.0

var biome_id := "hujan"
var biome: Dictionary
var _questions: Array = []
var _index := 0
var _correct := 0
var _locked := false
var _scored := false

## Wadah tiap layar (intro/soal/skor); CenterContainer full-rect supaya
## isinya selalu di tengah layar, termasuk saat panel bertambah tinggi.
var _content: CenterContainer
var _bar_fill: ColorRect
var _after_box: VBoxContainer
var _option_buttons: Array[Button] = []


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	biome_id = GameState.current_biome
	biome = BiomeData.get_biome(biome_id)
	_questions = biome["quiz"]
	_apply_background()

	_content = CenterContainer.new()
	UI.full_rect(_content)
	add_child(_content)

	_show_intro()


# ------------------------------------------------------------------ latar --

func _apply_background() -> void:
	var base := get_node_or_null("Background/Base") as ColorRect
	if base != null:
		base.color = Color(biome["accent"]).darkened(0.74)

	var leaves := get_node_or_null("Background/Leaves") as Node2D
	if leaves != null:
		for leaf in leaves.get_children():
			if leaf is ColorRect:
				leaf.color = Color(biome["far"]).darkened(0.1)


func _clear_content() -> void:
	for child in _content.get_children():
		_content.remove_child(child)
		child.queue_free()
	_option_buttons.clear()
	_after_box = null


func _centered(btn: Button) -> Button:
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	return btn


# ------------------------------------------------------------------ intro --

func _show_intro() -> void:
	_clear_content()

	var box := UI.panel_box(Vector2(470, 0))
	_content.add_child(box)

	var v := UI.vbox(12)
	box.add_child(v)
	v.add_child(UI.label(
		"Kuis  -  %s" % String(biome["name"]),
		13, Color("bdf2a0"), HORIZONTAL_ALIGNMENT_CENTER
	))
	var head := UI.title("Seberapa kenal kamu dengan hutan ini?", 22)
	head.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	head.custom_minimum_size = Vector2(430, 0)
	v.add_child(head)
	v.add_child(UI.label(
		"%d soal singkat" % _questions.size(),
		15, UI.CREAM, HORIZONTAL_ALIGNMENT_CENTER
	))

	var start := _centered(UI.button("Mulai Kuis", 18, Vector2(180, 44)))
	start.pressed.connect(_start_quiz)
	v.add_child(start)

	var back := _centered(UI.button("Kembali ke Peta", 14, Vector2(170, 34)))
	back.pressed.connect(_leave)
	v.add_child(back)


func _start_quiz() -> void:
	_index = 0
	_correct = 0
	_locked = false
	_scored = false
	_show_question()


# ------------------------------------------------------------------- soal --

func _show_question() -> void:
	_clear_content()
	_locked = false

	# Satu kelompok: header, progress bar, panel soal. Di-center oleh _content.
	var group := UI.vbox(8)
	group.alignment = BoxContainer.ALIGNMENT_CENTER
	_content.add_child(group)

	group.add_child(UI.label(
		"Soal %d/%d" % [_index + 1, _questions.size()],
		15, UI.CREAM, HORIZONTAL_ALIGNMENT_CENTER
	))

	# Latar bar = kontrol berukuran tetap; isi bar ditumpuk di atasnya.
	var bar_bg := ColorRect.new()
	bar_bg.color = Color(1, 1, 1, 0.16)
	bar_bg.custom_minimum_size = Vector2(BAR_W, BAR_H)
	bar_bg.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	group.add_child(bar_bg)

	_bar_fill = ColorRect.new()
	_bar_fill.color = Color("7ed957")
	_bar_fill.size = Vector2(BAR_W * float(_index) / float(_questions.size()), BAR_H)
	bar_bg.add_child(_bar_fill)

	var box := UI.panel_box(Vector2(PANEL_W, 0))
	box.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	group.add_child(box)

	var v := UI.vbox(8)
	box.add_child(v)

	var q: Dictionary = _questions[_index]
	v.add_child(UI.label(String(q["q"]), 15, UI.CREAM, HORIZONTAL_ALIGNMENT_LEFT, INNER_W))

	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, QUESTION_GAP)
	gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(gap)

	# 4 pilihan dalam grid 2x2, urutan A-D sesuai data.
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 6)
	v.add_child(grid)

	var opts: Array = q["options"]
	var btn_w := (float(INNER_W) - 8.0) / 2.0
	for i in range(opts.size()):
		var b := UI.button("%s. %s" % [LETTERS[i], String(opts[i])], 13, Vector2(btn_w, 34))
		# Teks pilihan panjang: font biasa + margin rapat (variasi theme "ButtonLong").
		b.theme_type_variation = &"ButtonLong"
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.pressed.connect(_on_answer.bind(i, b))
		grid.add_child(b)
		_option_buttons.append(b)

	# Area feedback + penjelasan + "Lanjut", diisi setelah menjawab.
	_after_box = UI.vbox(4)
	v.add_child(_after_box)


func _on_answer(chosen: int, btn: Button) -> void:
	if _locked:
		return
	_locked = true

	var q: Dictionary = _questions[_index]
	var correct := int(q["answer"])

	for b in _option_buttons:
		b.disabled = true

	var feedback: Label
	if chosen == correct:
		_correct += 1
		feedback = UI.label("Tepat sekali!", 15, Color("bdf2a0"))
		_paint(btn, COLOR_RIGHT_BG, COLOR_RIGHT_BORDER)
	else:
		feedback = UI.label("Belum tepat, yuk ingat lagi.", 15, UI.RED)
		_paint(btn, COLOR_WRONG_BG, COLOR_WRONG_BORDER)
		_paint(_option_buttons[correct], COLOR_RIGHT_BG, COLOR_RIGHT_BORDER)

	var tw := create_tween()
	tw.tween_property(
		_bar_fill, "size:x",
		BAR_W * float(_index + 1) / float(_questions.size()), 0.3
	)

	# Feedback + penjelasan di kiri, tombol "Lanjut" di kanan.
	var row := UI.hbox(10)
	_after_box.add_child(row)

	var text_col := UI.vbox(2)
	text_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(text_col)
	text_col.add_child(feedback)
	text_col.add_child(UI.label(
		String(q.get("explanation", "")), 13, UI.CREAM, HORIZONTAL_ALIGNMENT_LEFT, INNER_W - 120
	))

	var next := UI.button("Lanjut", 15, Vector2(110, 36))
	next.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	next.pressed.connect(_next_question)
	row.add_child(next)
	next.grab_focus.call_deferred()


func _next_question() -> void:
	_index += 1
	if _index >= _questions.size():
		_show_score()
	else:
		_show_question()


func _tight_margins(sb: StyleBoxFlat) -> void:
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6


func _paint(b: Button, bg: Color, border: Color) -> void:
	var sb := UI.flat(bg, 10)
	sb.set_border_width_all(2)
	sb.border_color = border
	_tight_margins(sb)
	b.add_theme_color_override("font_disabled_color", UI.CREAM)
	b.add_theme_stylebox_override("disabled", sb)
	b.add_theme_stylebox_override("normal", sb)
	b.add_theme_stylebox_override("hover", sb)


# ------------------------------------------------------------------- skor --

func _show_score() -> void:
	_clear_content()

	var total := _questions.size()
	var pct := float(_correct) / float(total) * 100.0
	if not _scored:
		_scored = true
		GameState.mark_quiz_done(biome_id, pct)

	var box := UI.panel_box(Vector2(460, 0))
	_content.add_child(box)

	var v := UI.vbox(10)
	box.add_child(v)

	v.add_child(UI.title("Kuis Selesai!", 24))
	v.add_child(UI.label(
		"Skor kamu: %d%%" % int(round(pct)),
		20, UI.GOLD, HORIZONTAL_ALIGNMENT_CENTER
	))

	var star_count := 1
	if pct >= 90.0:
		star_count = 3
	elif pct >= 70.0:
		star_count = 2

	var rating := UI.star_rating(star_count, 56)
	v.add_child(rating)
	var star_img := rating.get_node("Stars") as Control
	star_img.scale = Vector2.ZERO
	var tw := create_tween()
	tw.tween_interval(0.2)
	tw.set_trans(Tween.TRANS_BACK)
	tw.tween_property(star_img, "scale", Vector2.ONE, 0.4)

	v.add_child(UI.label(
		_tier_message(pct),
		14, UI.CREAM, HORIZONTAL_ALIGNMENT_CENTER, 400
	))

	var to_map := _centered(UI.button("Kembali ke Peta", 17, Vector2(190, 42)))
	to_map.pressed.connect(_leave)
	v.add_child(to_map)

	var retry := _centered(UI.button("Ulangi Kuis", 14, Vector2(150, 32)))
	retry.pressed.connect(_start_quiz)
	v.add_child(retry)


func _tier_message(pct: float) -> String:
	if pct >= 80.0:
		return "Luar biasa! Kamu penjaga hutan sejati."
	if pct >= 50.0:
		return "Bagus! Sedikit lagi jadi ahlinya."
	return "Jangan menyerah, rimba menunggu kamu belajar lagi."


func _leave() -> void:
	GameState.change_scene("res://scenes/map.tscn")
