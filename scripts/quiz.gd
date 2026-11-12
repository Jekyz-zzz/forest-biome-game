extends Control
## Kuis pilihan ganda 5 soal per bioma.
## Alur: intro -> soal (opsi diacak) -> skor + pesan -> kembali ke peta.

var biome_id := "hujan"
var biome: Dictionary
var _questions: Array = []
var _index := 0
var _correct := 0
var _locked := false
var _scored := false

var _content: Control
var _bar_fill: ColorRect
var _options_box: VBoxContainer
var _feedback: Label
var _option_buttons: Array[Button] = []


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	biome_id = GameState.current_biome
	biome = BiomeData.get_biome(biome_id)
	_questions = biome["quiz"]
	_apply_background()

	_content = Control.new()
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


func _centered(btn: Button) -> Button:
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	return btn


# ------------------------------------------------------------------ intro --

func _show_intro() -> void:
	_clear_content()

	var box := UI.panel_box(Vector2(470, 0))
	UI.center_control(box)
	_content.add_child(box)

	var v := UI.vbox(12)
	box.add_child(v)
	v.add_child(UI.label("Kuis", 13, Color("bdf2a0"), HORIZONTAL_ALIGNMENT_CENTER))
	v.add_child(UI.title(String(biome["name"]), 24))
	v.add_child(UI.label(
		"Jawab 5 pertanyaan tentang hutan ini. Setiap jawaban benar membawa "
		+ "kamu selangkah lebih dekat menjadi penjaga hutan.",
		14, UI.CREAM, HORIZONTAL_ALIGNMENT_CENTER, 410
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

	var head := UI.label(
		"Soal %d dari %d" % [_index + 1, _questions.size()],
		15, UI.CREAM, HORIZONTAL_ALIGNMENT_CENTER
	)
	head.position = Vector2(0, 18)
	head.size = Vector2(640, 22)
	_content.add_child(head)

	var bar_bg := ColorRect.new()
	bar_bg.color = Color(1, 1, 1, 0.16)
	bar_bg.position = Vector2(140, 46)
	bar_bg.size = Vector2(360, 8)
	_content.add_child(bar_bg)

	_bar_fill = ColorRect.new()
	_bar_fill.color = Color("7ed957")
	_bar_fill.position = Vector2(140, 46)
	_bar_fill.size = Vector2(360.0 * float(_index) / float(_questions.size()), 8)
	_content.add_child(_bar_fill)

	var box := UI.panel_box(Vector2(500, 0))
	box.position = Vector2(70, 68)
	_content.add_child(box)

	var v := UI.vbox(10)
	box.add_child(v)

	var q: Dictionary = _questions[_index]
	v.add_child(UI.label(String(q["q"]), 17, UI.CREAM, HORIZONTAL_ALIGNMENT_LEFT, 470))

	_options_box = UI.vbox(8)
	v.add_child(_options_box)

	var opts: Array = q["options"]
	var order: Array[int] = []
	for i in range(opts.size()):
		order.append(i)
	order.shuffle()

	for original in order:
		var b := UI.button(String(opts[original]), 14, Vector2(0, 38))
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.pressed.connect(_on_answer.bind(original, b))
		_options_box.add_child(b)
		_option_buttons.append(b)

	_feedback = UI.label("", 14, UI.CREAM, HORIZONTAL_ALIGNMENT_CENTER, 470)
	_feedback.custom_minimum_size = Vector2(0, 22)
	v.add_child(_feedback)


func _on_answer(chosen: int, btn: Button) -> void:
	if _locked:
		return
	_locked = true

	var q: Dictionary = _questions[_index]
	var opts: Array = q["options"]
	var correct := int(q["answer"])

	for b in _option_buttons:
		b.disabled = true

	if chosen == correct:
		_correct += 1
		_feedback.text = "Benar!"
		_feedback.add_theme_color_override("font_color", Color("bdf2a0"))
		_paint(btn, Color("3f7a3a"), Color("7ed957"))
	else:
		_feedback.text = "Belum tepat. Jawaban: %s" % String(opts[correct])
		_feedback.add_theme_color_override("font_color", UI.RED)
		_paint(btn, Color("6b2f2f"), Color("c05050"))
		for b in _option_buttons:
			if b.text == String(opts[correct]):
				_paint(b, Color("3f7a3a"), Color("7ed957"))
				break

	var tw := create_tween()
	tw.tween_property(
		_bar_fill, "size:x",
		360.0 * float(_index + 1) / float(_questions.size()), 0.3
	)

	await get_tree().create_timer(1.5).timeout
	_index += 1
	if _index >= _questions.size():
		_show_score()
	else:
		_show_question()


func _paint(b: Button, bg: Color, border: Color) -> void:
	var sb := UI.flat(bg, 10)
	sb.set_border_width_all(2)
	sb.border_color = border
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
	UI.center_control(box)
	_content.add_child(box)

	var v := UI.vbox(10)
	box.add_child(v)

	v.add_child(UI.title("Kuis Selesai!", 24))
	v.add_child(UI.label(
		"Skor: %d/%d (%d%%)" % [_correct, total, int(round(pct))],
		20, UI.GOLD, HORIZONTAL_ALIGNMENT_CENTER
	))

	var star_count := 1
	if pct >= 90.0:
		star_count = 3
	elif pct >= 70.0:
		star_count = 2

	var holder := Control.new()
	holder.custom_minimum_size = Vector2(0, 44)
	v.add_child(holder)
	for i in range(3):
		var s := UI.star(15, UI.GOLD if i < star_count else Color("39493a"))
		s.position = Vector2(172.0 + 46.0 * float(i), 22)
		holder.add_child(s)
		s.scale = Vector2.ZERO
		var tw := create_tween()
		tw.tween_interval(0.2 + 0.2 * float(i))
		tw.set_trans(Tween.TRANS_BACK)
		tw.tween_property(s, "scale", Vector2.ONE, 0.35)

	v.add_child(UI.label(
		_tier_message(_correct, total),
		14, UI.CREAM, HORIZONTAL_ALIGNMENT_CENTER, 400
	))

	var to_map := _centered(UI.button("Kembali ke Peta", 17, Vector2(190, 42)))
	to_map.pressed.connect(_leave)
	v.add_child(to_map)

	var retry := _centered(UI.button("Ulangi Kuis", 14, Vector2(150, 32)))
	retry.pressed.connect(_start_quiz)
	v.add_child(retry)


func _tier_message(score: int, total: int) -> String:
	if score == total:
		return "Sempurna! Kamu benar-benar penjaga hutan."
	if score >= total - 1:
		return "Hebat! Pengetahuanmu tentang hutan sudah kuat."
	if score >= total - 2:
		return "Bagus! Sedikit lagi kamu jadi ahli hutan."
	return "Jangan menyerah! Pelajari lagi dan coba kembali."


func _leave() -> void:
	GameState.change_scene("res://scenes/map.tscn")
