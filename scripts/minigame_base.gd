class_name MinigameBase
extends Node2D
## Dasar semua mini-game: HUD (waktu/koin/kartu), pause, kartu freeze,
## kartu perlindungan, dan alur selesai (hasil / gagal).

const GROUND_TOP := 324.0

var duration := 30.0
var time_left := 30.0
var run_coins := 0
var biome: Dictionary

var _paused := false
var _game_over_open := false
var _freeze_left := 0.0
var _protect_hits := 0
var _hud_layer: CanvasLayer
var _time_label: Label
var _coin_label: Label
var _card_label: Label
var _freeze_label: Label
var _tutorial_label: Label
var _pause_menu: Control


func _ready() -> void:
	biome = BiomeData.get_biome(GameState.current_biome)
	time_left = duration
	match GameState.equipped_card:
		"freeze5":
			_freeze_left = 5.0
		"freeze10":
			_freeze_left = 10.0
		"protect1":
			_protect_hits = 1
	_build_hud()
	_build_world()
	_show_tutorial(String(biome.get("tutorial", "")))


# ------------------------------------------------------------ untuk subclass --

func _build_world() -> void:
	pass


func _game_tick(_delta: float) -> void:
	pass


func _time_up() -> void:
	_finish(true, 1, 0.0)


func _on_pause_opened() -> void:
	pass


func _on_pause_closed() -> void:
	pass


# -------------------------------------------------------------------- HUD --

func _build_hud() -> void:
	_hud_layer = CanvasLayer.new()
	_hud_layer.layer = 10
	add_child(_hud_layer)

	var bar := UI.hbox(12)
	bar.position = Vector2(8, 6)
	_hud_layer.add_child(bar)

	_time_label = UI.label("Waktu: %d" % int(time_left), 16)
	_time_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_add_hud_outline(_time_label)
	bar.add_child(_time_label)

	_coin_label = UI.label("Koin: 0", 16)
	_coin_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_add_hud_outline(_coin_label)
	bar.add_child(_coin_label)

	_card_label = UI.label(_card_text(), 14, Color("ffe9a8"))
	_card_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_add_hud_outline(_card_label)
	bar.add_child(_card_label)

	var pause_btn := UI.button("Jeda", 14, Vector2(70, 30))
	pause_btn.position = Vector2(560, 6)
	pause_btn.pressed.connect(_set_paused.bind(true))
	_hud_layer.add_child(pause_btn)

	_freeze_label = UI.label("", 18, Color("bfe8ff"), HORIZONTAL_ALIGNMENT_CENTER)
	_freeze_label.size = Vector2(600, 30)
	_freeze_label.position = Vector2(20, 66)
	_freeze_label.visible = false
	_hud_layer.add_child(_freeze_label)

	_tutorial_label = UI.label("", 15, Color("eef2e6"), HORIZONTAL_ALIGNMENT_CENTER, 520)
	_tutorial_label.position = Vector2(60, 44)
	_tutorial_label.size = Vector2(520, 40)
	_add_hud_outline(_tutorial_label)
	_hud_layer.add_child(_tutorial_label)


func _add_hud_outline(l: Label) -> void:
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.72))
	l.add_theme_constant_override("outline_size", 5)


func _card_text() -> String:
	if GameState.equipped_card == "":
		return "Kartu: -"
	var card: Dictionary = GameState.CARDS.get(GameState.equipped_card, {})
	return "Kartu: %s" % String(card.get("name", GameState.equipped_card))


func _show_tutorial(text: String) -> void:
	_tutorial_label.text = text
	_tutorial_label.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(_tutorial_label, "modulate:a", 1.0, 0.3)
	tw.tween_interval(2.4)
	tw.tween_property(_tutorial_label, "modulate:a", 0.0, 0.5)


func _update_hud() -> void:
	_time_label.text = "Waktu: %d" % ceili(time_left)
	_coin_label.text = "Koin: %d" % run_coins


func _collect_coin(amount := 1) -> void:
	run_coins += amount
	_update_hud()


func _show_floating_text(text: String, color := Color("ffe9a8")) -> void:
	var l := UI.label(text, 15, color, HORIZONTAL_ALIGNMENT_CENTER)
	l.size = Vector2(360, 26)
	l.position = Vector2(140, 100)
	_add_hud_outline(l)
	l.modulate.a = 0.0
	_hud_layer.add_child(l)
	var tw := create_tween()
	tw.tween_property(l, "modulate:a", 1.0, 0.2)
	tw.parallel().tween_property(l, "position:y", l.position.y - 30.0, 1.2)
	tw.tween_property(l, "modulate:a", 0.0, 0.4)
	tw.tween_callback(l.queue_free)


# ----------------------------------------------------------------- proses --

func _process(delta: float) -> void:
	if _paused or _game_over_open:
		return
	if _freeze_left > 0.0:
		_freeze_left = move_toward(_freeze_left, 0.0, delta)
		_freeze_label.visible = true
		_freeze_label.text = "Kartu Freeze aktif! Waktu berhenti %d detik..." % ceili(_freeze_left)
		if _freeze_left <= 0.0:
			_freeze_label.visible = false
		return
	_game_tick(delta)
	time_left -= delta
	_update_hud()
	if time_left <= 0.0:
		time_left = 0.0
		_update_hud()
		_time_up()


func _absorb_hit() -> bool:
	## true bila serangan ditahan oleh kartu (jangan dianggap kena).
	if GameState.equipped_card == "invincible":
		_show_floating_text("Kartu Invincible menahan serangan!")
		return true
	if _protect_hits > 0:
		_protect_hits -= 1
		_show_floating_text("Kartu Perlindungan menahan serangan!")
		return true
	return false


# ----------------------------------------------------------------- selesai --

func _finish(won: bool, stars := 1, score := 0.0) -> void:
	if _paused:
		return
	_paused = true
	if not won:
		_show_game_over()
		return
	var mult := GameState.coin_multiplier()
	var final_coins := int(round(float(run_coins) * mult))
	GameState.last_run = {
		"biome": GameState.current_biome,
		"won": true,
		"stars": stars,
		"score": score,
		"raw_coins": run_coins,
		"coins": final_coins,
		"bonus_note": GameState.multiplier_note(),
	}
	GameState.mark_biome_saved(GameState.current_biome)
	GameState.add_coins(final_coins)
	GameState.change_scene("res://scenes/results.tscn")


func _show_game_over() -> void:
	_game_over_open = true
	_pause_menu = null

	var dim := UI.dim(Color(0, 0, 0, 0.75))
	_hud_layer.add_child(dim)
	var box := UI.panel_box(Vector2(370, 0))
	UI.center_control(box)
	_hud_layer.add_child(box)

	var v := UI.vbox(12)
	box.add_child(v)
	v.add_child(UI.label(
		"Hutan belum terselamatkan.",
		19, Color("e8a9a9"), HORIZONTAL_ALIGNMENT_CENTER, 330
	))
	v.add_child(UI.label(
		"Tenang, kamu bisa coba lagi!",
		15, UI.CREAM, HORIZONTAL_ALIGNMENT_CENTER, 330
	))

	var retry := UI.button("Coba Lagi", 16)
	retry.pressed.connect(_on_retry)
	v.add_child(retry)

	var to_map := UI.button("Ke Peta", 16)
	to_map.pressed.connect(_leave_to_map)
	v.add_child(to_map)


func _on_retry() -> void:
	get_tree().reload_current_scene()


func _leave_to_map() -> void:
	GameState.change_scene("res://scenes/map.tscn")


# ------------------------------------------------------------------- pause --

func _set_paused(paused: bool) -> void:
	if _game_over_open:
		return
	_paused = paused
	if _pause_menu == null:
		_pause_menu = _build_pause_menu()
		_hud_layer.add_child(_pause_menu)
	_pause_menu.visible = paused
	if paused:
		_on_pause_opened()
	else:
		_on_pause_closed()


func _build_pause_menu() -> Control:
	var root := Control.new()
	UI.full_rect(root)
	root.add_child(UI.dim(Color(0, 0, 0, 0.6)))

	var box := UI.panel_box(Vector2(320, 0))
	UI.center_control(box)
	root.add_child(box)

	var v := UI.vbox(10)
	box.add_child(v)
	v.add_child(UI.label("Istirahat sejenak", 20, UI.CREAM, HORIZONTAL_ALIGNMENT_CENTER))

	var resume := UI.button("Lanjutkan", 16)
	resume.pressed.connect(_set_paused.bind(false))
	v.add_child(resume)

	var restart := UI.button("Ulangi", 16)
	restart.pressed.connect(_on_retry)
	v.add_child(restart)

	var exit_btn := UI.button("Keluar ke Peta", 16)
	exit_btn.pressed.connect(_confirm_exit)
	v.add_child(exit_btn)

	root.visible = false
	return root


func _confirm_exit() -> void:
	var dim := UI.dim(Color(0, 0, 0, 0.7))
	_hud_layer.add_child(dim)
	var box := UI.panel_box(Vector2(360, 0))
	UI.center_control(box)
	_hud_layer.add_child(box)

	var v := UI.vbox(12)
	box.add_child(v)
	v.add_child(UI.label(
		"Kalau keluar sekarang, progres game ini tidak tersimpan. Yakin?",
		15, UI.CREAM, HORIZONTAL_ALIGNMENT_CENTER, 320
	))

	var yes := UI.button("Ya, keluar", 15)
	yes.pressed.connect(_leave_to_map)
	v.add_child(yes)

	var no := UI.button("Tidak", 15)
	no.pressed.connect(_close_exit_popup.bind(dim, box))
	v.add_child(no)


func _close_exit_popup(dim: CanvasItem, box: CanvasItem) -> void:
	dim.queue_free()
	box.queue_free()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		_set_paused(not _paused)
