extends Control
## Layar hasil mini-game: konfeti daun, rating bintang, dan koin naik animasi.


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var run := GameState.last_run
	var stars := int(run.get("stars", 1))
	var coins := int(run.get("coins", 0))
	var biome := BiomeData.get_biome(String(run.get("biome", "hujan")))

	_spawn_confetti()

	var box := UI.vbox(10)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(box)
	UI.center_control(box)

	if bool(run.get("won", true)):
		box.add_child(UI.title("%s terselamatkan!" % biome["short_name"], 26, Color("bdf2a0")))
	else:
		box.add_child(UI.title("Hampir! Hutan masih butuh kamu.", 22, Color("e8a9a9")))

	box.add_child(UI.label("Performa:", 15, UI.CREAM, HORIZONTAL_ALIGNMENT_CENTER))

	var star_holder := Control.new()
	star_holder.custom_minimum_size = Vector2(160, 44)
	box.add_child(star_holder)
	for i in range(3):
		var s := UI.star(15, UI.GOLD if i < stars else Color("39493a"))
		s.position = Vector2(30.0 + 44.0 * float(i), 22)
		star_holder.add_child(s)
		s.scale = Vector2.ZERO
		var tw := create_tween()
		tw.tween_interval(0.3 + 0.25 * float(i))
		tw.set_trans(Tween.TRANS_BACK)
		tw.tween_property(s, "scale", Vector2.ONE, 0.4)

	var coins_label := UI.label("Koin didapat: +0", 20, UI.GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	box.add_child(coins_label)
	var tw2 := create_tween()
	tw2.tween_interval(0.2)
	tw2.tween_method(_set_coins_text.bind(coins_label), 0, coins, 1.0)

	var note := String(run.get("bonus_note", ""))
	if note != "":
		box.add_child(UI.label(note, 15, Color("ffe9a8"), HORIZONTAL_ALIGNMENT_CENTER))

	var next := UI.button("Lanjut ke Kuis", 18, Vector2(200, 46))
	next.pressed.connect(_on_next)
	box.add_child(next)


func _set_coins_text(value: int, label: Label) -> void:
	label.text = "Koin didapat: +%d" % value


func _on_next() -> void:
	GameState.change_scene("res://scenes/quiz.tscn")


func _spawn_confetti() -> void:
	# Prototipe daun konfeti ada di scenes/results.tscn (node "ConfettiLeaf").
	var proto := get_node_or_null("ConfettiLeaf") as ColorRect
	if proto == null:
		return
	proto.visible = false

	var colors := [Color("7ed957"), Color("ffd54f")]
	for i in range(18):
		var leaf := proto.duplicate() as ColorRect
		leaf.visible = true
		leaf.color = colors[i % colors.size()]
		leaf.position = Vector2(randf() * 640.0, -20.0)
		leaf.rotation = randf_range(-0.4, 0.4)
		add_child(leaf)
		var tw := create_tween()
		tw.set_loops(2)
		tw.tween_property(leaf, "position:y", 380.0, randf_range(2.5, 4.0))
		tw.parallel().tween_property(leaf, "rotation", TAU, randf_range(2.5, 4.0))
		tw.tween_property(leaf, "modulate:a", 0.0, 0.4)
		tw.tween_callback(leaf.queue_free)
