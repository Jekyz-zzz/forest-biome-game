extends Node2D
## Eksplorasi side-scroller per bioma.
## Berjalan kiri/kanan, 3 activation box berisi dialog edukasi,
## lalu gerbang di ujung kanan -> briefing -> mini-game.
##
## Semua latar, dekorasi, objek, dan gerbang adalah node ColorRect
## di scenes/explore.tscn (di bawah "Placeholders") sehingga bisa
## digeser, diubah ukurannya, dan diganti gambarnya di editor Godot.
## Objek tiap bioma ada di Placeholders/Props/Hujan, Sabana, dan Mangrove;
## saat bermain hanya grup bioma aktif yang ditampilkan.

const LEVEL_LENGTH := 3400.0
const GROUND_TOP := 324.0
const GATE_X := 3120.0

var biome_id := "hujan"
var data: Dictionary

var _player: BinarPlayer
var _hud: CanvasLayer
var _dialog_panel: PanelContainer
var _dialog_title: Label
var _dialog_text: Label
var _dialog_open := false
var _gate_popup: Control
var _briefing: Control
var _slot_label: Label
var _hint_label: Label
var _hint_hidden := false
var _pause_menu: Control
var _paused := false
var _gate_armed := true
var _question_bubbles: Array[Node2D] = []


func _ready() -> void:
	biome_id = GameState.current_biome
	data = BiomeData.get_biome(biome_id)
	_build_world()
	_build_objects()
	_build_gate()
	_build_hud()


# ------------------------------------------------------------------ dunia --

func _ph(path: String) -> Node:
	return get_node_or_null("Placeholders/" + path)


func _build_world() -> void:
	_apply_biome_colors()

	# Pemain + kamera.
	_player = preload("res://scenes/player.tscn").instantiate()
	var start := get_node_or_null("PlayerStart") as Node2D
	_player.position = start.position if start != null else Vector2(100, GROUND_TOP - 40)
	add_child(_player)

	var cam := Camera2D.new()
	cam.limit_left = 0
	cam.limit_right = int(LEVEL_LENGTH)
	cam.limit_top = 0
	cam.limit_bottom = 360
	cam.position_smoothing_enabled = true
	cam.position_smoothing_speed = 6.0
	_player.add_child(cam)
	cam.make_current()

	# Hujan untuk hutan hujan (mengikuti layar).
	if biome_id == "hujan":
		var rain_layer := CanvasLayer.new()
		rain_layer.layer = 5
		var rain := RainEffect.new()
		rain_layer.add_child(rain)
		add_child(rain_layer)


func _apply_biome_colors() -> void:
	var sky := _ph("Sky") as ColorRect
	if sky != null:
		sky.color = data["sky"]

	var horizon := _ph("Horizon") as ColorRect
	if horizon != null:
		horizon.color = Color(data["far"]).darkened(0.18)

	var hills := _ph("Hills") as Node2D
	if hills != null:
		for hill in hills.get_children():
			if hill is ColorRect:
				hill.color = data["far"]

	var soil := _ph("Soil") as ColorRect
	if soil != null:
		soil.color = data["ground"]

	var top := _ph("GroundTop") as ColorRect
	if top != null:
		top.color = data["ground_top"]

	var water := _ph("Water") as CanvasItem
	if water != null:
		water.visible = biome_id == "mangrove"

	var mist := _ph("Mist") as CanvasItem
	if mist != null:
		mist.visible = biome_id == "hujan"

	_apply_decor()
	_show_props()


func _show_props() -> void:
	var props := _ph("Props") as Node2D
	if props == null:
		return
	var active := biome_id.capitalize()
	for group in props.get_children():
		group.visible = group.name == active


func _apply_decor() -> void:
	var decor := _ph("Decor") as Node2D
	if decor == null:
		return

	var i := 0
	for slot in decor.get_children():
		if not (slot is Node2D):
			continue
		var trunk := slot.get_node_or_null("Trunk") as ColorRect
		var canopy := slot.get_node_or_null("Canopy") as ColorRect
		var grass := slot.get_node_or_null("Grass") as ColorRect

		match biome_id:
			"sabana":
				if trunk != null:
					trunk.visible = false
				if canopy != null:
					canopy.visible = false
				if grass != null:
					grass.visible = true
					grass.color = Color("b8a94e") if i % 2 == 0 else Color("9aa84e")
			"mangrove":
				if trunk != null:
					trunk.visible = true
					trunk.color = Color("5d4027")
				if canopy != null:
					canopy.visible = true
					canopy.color = Color("4f7a42")
				if grass != null:
					grass.visible = false
			_:
				if trunk != null:
					trunk.visible = true
					trunk.color = Color("3d2a17")
				if canopy != null:
					canopy.visible = true
					canopy.color = Color("1f4a37") if i % 2 == 0 else Color("25593f")
				if grass != null:
					grass.visible = false
		i += 1


# ---------------------------------------------------------------- objek 3x --

func _build_objects() -> void:
	var props := _ph("Props") as Node2D
	if props == null:
		return
	var group := props.get_node_or_null(biome_id.capitalize()) as Node2D
	if group == null:
		return

	var index := 0
	for obj in group.get_children():
		if not (obj is Node2D):
			continue
		var pos: Vector2 = obj.position

		# Tanda tanya kecil di atas objek.
		var bubble := Node2D.new()
		bubble.position = Vector2(pos.x, pos.y - 175)
		bubble.add_child(UI.circle(11, Color("f4c542")))
		var q := UI.label("?", 15, Color("5a4210"), HORIZONTAL_ALIGNMENT_CENTER)
		q.position = Vector2(-6, -9)
		bubble.add_child(q)
		add_child(bubble)
		_question_bubbles.append(bubble)

		var tw := create_tween().set_loops()
		tw.set_trans(Tween.TRANS_SINE)
		tw.tween_property(bubble, "position:y", bubble.position.y - 8.0, 1.2)
		tw.tween_property(bubble, "position:y", bubble.position.y, 1.2)

		# Activation box.
		var area := Area2D.new()
		area.position = Vector2(pos.x, pos.y - 90)
		var cs := CollisionShape2D.new()
		var rs := RectangleShape2D.new()
		rs.size = Vector2(130, 200)
		cs.shape = rs
		area.add_child(cs)
		area.body_entered.connect(_on_object_entered.bind(index))
		add_child(area)
		index += 1


# ----------------------------------------------------------------- gerbang --

func _build_gate() -> void:
	var gate := _ph("Gate") as Node2D
	var gate_pos := Vector2(GATE_X, GROUND_TOP)
	if gate != null:
		gate_pos = gate.position

	var glow: ColorRect = null
	if gate != null:
		glow = gate.get_node_or_null("Glow") as ColorRect
	if glow != null:
		var tw := create_tween().set_loops()
		tw.set_trans(Tween.TRANS_SINE)
		tw.tween_property(glow, "modulate:a", 0.55, 1.0)
		tw.tween_property(glow, "modulate:a", 1.0, 1.0)

	var area := Area2D.new()
	area.position = Vector2(gate_pos.x - 20, gate_pos.y - 90)
	var cs := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = Vector2(70, 200)
	cs.shape = rs
	area.add_child(cs)
	area.body_entered.connect(_on_gate_entered)
	area.body_exited.connect(_on_gate_exited)
	add_child(area)


# -------------------------------------------------------------------- HUD --

func _build_hud() -> void:
	_hud = CanvasLayer.new()
	_hud.layer = 10
	add_child(_hud)

	var top := UI.hbox(10)
	top.position = Vector2(8, 6)
	_hud.add_child(top)

	var name_l := UI.label(String(data["name"]), 16, Color("eef2e6"))
	name_l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.6))
	name_l.add_theme_constant_override("outline_size", 4)
	top.add_child(name_l)

	var coin_l := UI.label("Koin: %d" % GameState.coins, 15, UI.GOLD)
	coin_l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.75))
	coin_l.add_theme_constant_override("outline_size", 5)
	top.add_child(coin_l)

	var pause_btn := UI.button("Jeda", 14, Vector2(70, 30))
	pause_btn.position = Vector2(560, 6)
	pause_btn.pressed.connect(_set_paused.bind(true))
	_hud.add_child(pause_btn)
	# Teks MagicSound lebih lebar dari 70 px: tepi kanan tetap di x=630.
	pause_btn.reset_size()
	pause_btn.position.x = 630.0 - pause_btn.size.x

	_hint_label = UI.label(String(data["hint"]), 14, Color("eef2e6"), HORIZONTAL_ALIGNMENT_CENTER, 520)
	_hint_label.position = Vector2(60, 42)
	_hint_label.size = Vector2(520, 30)
	_hint_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.7))
	_hint_label.add_theme_constant_override("outline_size", 5)
	_hud.add_child(_hint_label)
	var tw := create_tween()
	tw.tween_interval(5.0)
	tw.tween_property(_hint_label, "modulate:a", 0.0, 1.0)

	_build_dialog()


func _build_dialog() -> void:
	_dialog_panel = UI.panel_box()
	_dialog_panel.position = Vector2(40, 196)
	_dialog_panel.custom_minimum_size = Vector2(560, 0)
	_dialog_panel.visible = false
	_hud.add_child(_dialog_panel)

	var v := UI.vbox(6)
	_dialog_panel.add_child(v)

	_dialog_title = UI.label("", 18, Color("bdf2a0"))
	v.add_child(_dialog_title)
	_dialog_text = UI.label("", 14, UI.CREAM, HORIZONTAL_ALIGNMENT_LEFT, 520)
	v.add_child(_dialog_text)
	var close := UI.button("Tutup", 14, Vector2(100, 32))
	close.pressed.connect(_close_dialog)
	v.add_child(close)


func _open_dialog(index: int) -> void:
	if _dialog_open or _paused:
		return
	var obj: Dictionary = data["objects"][index]
	_dialog_title.text = String(obj["name"])
	_dialog_text.text = String(obj["text"])
	_dialog_panel.visible = true
	_dialog_open = true
	_player.control_mode = BinarPlayer.ControlMode.LOCKED
	if index < _question_bubbles.size():
		_question_bubbles[index].visible = false
	_hide_hint()


func _close_dialog() -> void:
	_dialog_panel.visible = false
	_dialog_open = false
	if not _paused:
		_player.control_mode = BinarPlayer.ControlMode.PLAYER


func _hide_hint() -> void:
	if _hint_hidden:
		return
	_hint_hidden = true
	var tw := create_tween()
	tw.tween_property(_hint_label, "modulate:a", 0.0, 0.6)


func _on_object_entered(body: Node2D, index: int) -> void:
	if body == _player:
		_open_dialog(index)


func _on_gate_entered(body: Node2D) -> void:
	if body != _player or not _gate_armed or _paused:
		return
	_gate_armed = false
	_open_gate_popup()


func _on_gate_exited(body: Node2D) -> void:
	if body == _player:
		_gate_armed = true


# ----------------------------------------------------------- popup gerbang --

func _open_gate_popup() -> void:
	if _gate_popup != null and is_instance_valid(_gate_popup):
		return
	_player.control_mode = BinarPlayer.ControlMode.LOCKED

	var dim := UI.dim()
	_hud.add_child(dim)
	var box := UI.panel_box(Vector2(430, 0))
	UI.center_control(box)
	_hud.add_child(box)
	_gate_popup = box

	var v := UI.vbox(14)
	box.add_child(v)
	v.add_child(UI.label(String(data["gate_text"]), 16, UI.CREAM, HORIZONTAL_ALIGNMENT_CENTER, 390))

	var ready_btn := UI.button("Siap, ayo!", 16)
	ready_btn.pressed.connect(_on_ready_pressed.bind(dim, box))
	v.add_child(ready_btn)

	var again := UI.button("Jelajahi lagi", 16)
	again.pressed.connect(_close_gate_popup.bind(dim, box))
	v.add_child(again)


func _on_ready_pressed(dim: CanvasItem, box: CanvasItem) -> void:
	dim.queue_free()
	box.queue_free()
	_gate_popup = null
	_open_briefing()


func _close_gate_popup(dim: CanvasItem, box: CanvasItem) -> void:
	dim.queue_free()
	box.queue_free()
	_gate_popup = null
	if not _dialog_open and not _paused:
		_player.control_mode = BinarPlayer.ControlMode.PLAYER


# --------------------------------------------------------------- briefing --

func _open_briefing() -> void:
	var dim := UI.dim(Color(0, 0, 0, 0.78))
	_hud.add_child(dim)
	var box := UI.panel_box(Vector2(470, 0))
	UI.center_control(box)
	_hud.add_child(box)
	_briefing = box

	var v := UI.vbox(10)
	box.add_child(v)
	v.add_child(UI.label("Briefing", 13, Color("bdf2a0"), HORIZONTAL_ALIGNMENT_CENTER))
	v.add_child(UI.label(String(data["briefing"]), 20, UI.CREAM, HORIZONTAL_ALIGNMENT_CENTER, 420))

	_slot_label = UI.label(_slot_text(), 14, Color("ffe9a8"), HORIZONTAL_ALIGNMENT_CENTER, 420)
	v.add_child(_slot_label)

	var card_btn := UI.button("Ganti Kartu", 14, Vector2(150, 34))
	card_btn.pressed.connect(_open_card_picker)
	v.add_child(card_btn)

	var start := UI.button("Mulai", 18, Vector2(160, 44))
	start.pressed.connect(_start_minigame)
	v.add_child(start)

	var back := UI.button("Kembali", 14, Vector2(120, 32))
	back.pressed.connect(_close_briefing.bind(dim, box))
	v.add_child(back)


func _slot_text() -> String:
	if GameState.equipped_card == "":
		return "Slot Power Up: 1/1 - kosong"
	var card: Dictionary = GameState.CARDS.get(GameState.equipped_card, {})
	return "Slot Power Up: 1/1 - %s" % String(card.get("name", GameState.equipped_card))


func _refresh_slot() -> void:
	if _slot_label != null and is_instance_valid(_slot_label):
		_slot_label.text = _slot_text()


func _start_minigame() -> void:
	GameState.change_scene(String(data["minigame_scene"]))


func _close_briefing(dim: CanvasItem, box: CanvasItem) -> void:
	dim.queue_free()
	box.queue_free()
	_briefing = null
	if not _paused:
		_player.control_mode = BinarPlayer.ControlMode.PLAYER


# ------------------------------------------------------------ kartu power up --

func _open_card_picker() -> void:
	var dim := UI.dim(Color(0, 0, 0, 0.7))
	_hud.add_child(dim)
	var box := UI.panel_box(Vector2(470, 0))
	UI.center_control(box)
	_hud.add_child(box)

	var v := UI.vbox(8)
	box.add_child(v)
	v.add_child(UI.label("Pilih satu kartu untuk dipakai", 16, UI.CREAM, HORIZONTAL_ALIGNMENT_CENTER, 420))

	if GameState.owned_cards.is_empty():
		v.add_child(UI.label(
			"Kamu belum punya kartu. Kunjungi Toko untuk mendapatkannya!",
			14, UI.CREAM, HORIZONTAL_ALIGNMENT_CENTER, 400
		))
	else:
		for card_id in GameState.owned_cards:
			v.add_child(_make_card_row(String(card_id), dim, box))
		if GameState.equipped_card != "":
			var unequip := UI.button("Lepas kartu", 13, Vector2(140, 30))
			unequip.pressed.connect(_on_unequip.bind(dim, box))
			v.add_child(unequip)

	var close := UI.button("Tutup", 14, Vector2(100, 32))
	close.pressed.connect(_close_popup.bind(dim, box))
	v.add_child(close)


func _make_card_row(card_id: String, picker_dim: CanvasItem, picker_box: CanvasItem) -> Control:
	var card: Dictionary = GameState.CARDS.get(card_id, {})
	var row := UI.hbox(8)

	var chip := ColorRect.new()
	chip.color = card.get("color", Color.WHITE)
	chip.custom_minimum_size = Vector2(18, 18)
	row.add_child(chip)

	var name_l := UI.label(String(card.get("name", card_id)), 13)
	name_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(name_l)
	row.add_child(UI.label("x%d" % int(GameState.owned_cards.get(card_id, 0)), 13, UI.GOLD))

	var equipped := GameState.equipped_card == card_id
	var btn := UI.button("Terpasang" if equipped else "Pasang", 12, Vector2(90, 28))
	btn.disabled = equipped
	btn.pressed.connect(_on_card_equip.bind(card_id, picker_dim, picker_box))
	row.add_child(btn)
	return row


func _on_card_equip(card_id: String, picker_dim: CanvasItem, picker_box: CanvasItem) -> void:
	if GameState.equipped_card != "" and GameState.equipped_card != card_id:
		_confirm_replace_card(card_id, picker_dim, picker_box)
		return
	GameState.equip_card(card_id)
	_refresh_slot()
	_close_popup(picker_dim, picker_box)


func _on_unequip(picker_dim: CanvasItem, picker_box: CanvasItem) -> void:
	GameState.equip_card("")
	_refresh_slot()
	_close_popup(picker_dim, picker_box)


func _confirm_replace_card(card_id: String, picker_dim: CanvasItem, picker_box: CanvasItem) -> void:
	var dim := UI.dim(Color(0, 0, 0, 0.8))
	_hud.add_child(dim)
	var box := UI.panel_box(Vector2(370, 0))
	UI.center_control(box)
	_hud.add_child(box)

	var v := UI.vbox(12)
	box.add_child(v)
	v.add_child(UI.label(
		"Slot sudah terisi. Ganti kartu yang terpasang?",
		15, UI.CREAM, HORIZONTAL_ALIGNMENT_CENTER, 330
	))
	var yes := UI.button("Ganti", 14)
	yes.pressed.connect(_do_replace_card.bind(card_id, dim, box, picker_dim, picker_box))
	v.add_child(yes)
	var no := UI.button("Batal", 14)
	no.pressed.connect(_close_popup.bind(dim, box))
	v.add_child(no)


func _do_replace_card(
	card_id: String,
	dim: CanvasItem,
	box: CanvasItem,
	picker_dim: CanvasItem,
	picker_box: CanvasItem
) -> void:
	GameState.equip_card(card_id)
	_refresh_slot()
	_close_popup(dim, box)
	_close_popup(picker_dim, picker_box)


func _close_popup(a: CanvasItem, b: CanvasItem) -> void:
	a.queue_free()
	b.queue_free()


# ------------------------------------------------------------------- pause --

func _set_paused(paused: bool) -> void:
	if paused and (
		_dialog_open
		or (_gate_popup != null and is_instance_valid(_gate_popup))
		or (_briefing != null and is_instance_valid(_briefing))
	):
		return
	_paused = paused
	if _pause_menu == null:
		_pause_menu = _build_pause_menu()
		_hud.add_child(_pause_menu)
	_pause_menu.visible = paused
	if _player != null:
		_player.control_mode = (
			BinarPlayer.ControlMode.LOCKED if paused else BinarPlayer.ControlMode.PLAYER
		)


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
	restart.pressed.connect(_on_restart)
	v.add_child(restart)

	var exit_btn := UI.button("Keluar ke Peta", 16)
	exit_btn.pressed.connect(_confirm_exit)
	v.add_child(exit_btn)

	root.visible = false
	return root


func _on_restart() -> void:
	get_tree().reload_current_scene()


func _confirm_exit() -> void:
	var dim := UI.dim(Color(0, 0, 0, 0.7))
	_hud.add_child(dim)
	var box := UI.panel_box(Vector2(360, 0))
	UI.center_control(box)
	_hud.add_child(box)

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
	no.pressed.connect(_close_popup.bind(dim, box))
	v.add_child(no)


func _leave_to_map() -> void:
	GameState.change_scene("res://scenes/map.tscn")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		_set_paused(not _paused)
