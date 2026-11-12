extends Control
## Toko hutan: beli tanaman/pupuk, dapat kartu power-up acak,
## lalu pasang satu kartu ke slot. Koin kurang -> goyang + pesan.

const ITEMS := [
	{
		"tab": "tanaman",
		"name": "Bibit Meranti",
		"price": 40,
		"desc": "Pohon raksasa rimba.",
		"color": Color("66bb6a"),
	},
	{
		"tab": "tanaman",
		"name": "Bibit Akasia",
		"price": 40,
		"desc": "Peneduh padang sabana.",
		"color": Color("c9b458"),
	},
	{
		"tab": "tanaman",
		"name": "Bibit Bakau",
		"price": 45,
		"desc": "Penjaga pantai dari abrasi.",
		"color": Color("4db6ac"),
	},
	{
		"tab": "pupuk",
		"name": "Pupuk Kompos",
		"price": 60,
		"desc": "Menyuburkan tanah hutan.",
		"color": Color("8d6e63"),
	},
	{
		"tab": "pupuk",
		"name": "Pupuk Kandang",
		"price": 60,
		"desc": "Nutrisi alami untuk tunas.",
		"color": Color("a1887f"),
	},
	{
		"tab": "pupuk",
		"name": "Super Pupuk",
		"price": 110,
		"desc": "Pupuk istimewa, hasil melimpah.",
		"color": Color("7ed957"),
	},
]

var _tab := "tanaman"
var _coin_label: Label
var _items_box: VBoxContainer
var _cards_box: VBoxContainer
var _equipped_label: Label
var _tab_buttons: Dictionary = {}
var _toast_label: Label
var _toast_tween: Tween


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_topbar()
	_build_tabs()
	_build_panels()
	_build_toast()

	GameState.coins_changed.connect(_on_coins_changed)
	_refresh_tabs()
	_refresh_items()
	_refresh_cards()


# ------------------------------------------------------------------ latar --
# Latar toko (base, rak, daun, glow) ada sebagai node di scenes/shop.tscn.


# ----------------------------------------------------------------- topbar --

func _build_topbar() -> void:
	var back := UI.button("Kembali", 14, Vector2(90, 30))
	back.position = Vector2(10, 10)
	back.pressed.connect(_on_back)
	add_child(back)

	var title := UI.title("Toko Hutan", 22)
	title.position = Vector2(0, 8)
	title.size = Vector2(640, 30)
	add_child(title)

	_coin_label = UI.label(
		"Koin: %d" % GameState.coins, 15, UI.GOLD, HORIZONTAL_ALIGNMENT_RIGHT
	)
	_coin_label.position = Vector2(490, 14)
	_coin_label.size = Vector2(140, 22)
	add_child(_coin_label)


func _on_coins_changed(total: int) -> void:
	_coin_label.text = "Koin: %d" % total


func _on_back() -> void:
	GameState.change_scene("res://scenes/map.tscn")


# ------------------------------------------------------------------- tab --

func _build_tabs() -> void:
	var row := UI.hbox(8)
	row.position = Vector2(10, 50)
	add_child(row)

	for tab_id in ["tanaman", "pupuk"]:
		var b := UI.button(tab_id.capitalize(), 14, Vector2(110, 30))
		b.pressed.connect(_on_tab_pressed.bind(tab_id))
		row.add_child(b)
		_tab_buttons[tab_id] = b


func _on_tab_pressed(tab_id: String) -> void:
	_tab = tab_id
	_refresh_tabs()
	_refresh_items()


func _refresh_tabs() -> void:
	for tab_id in _tab_buttons:
		var b: Button = _tab_buttons[tab_id]
		var active: bool = String(tab_id) == _tab
		var sb := UI.flat(Color("4e8742") if active else Color("2e5228"), 8)
		if active:
			sb.set_border_width_all(2)
			sb.border_color = UI.GOLD
		b.add_theme_stylebox_override("normal", sb)


# ---------------------------------------------------------------- panel --

func _build_panels() -> void:
	var left := UI.panel_box(Vector2(376, 258))
	left.position = Vector2(10, 88)
	add_child(left)

	var lv := UI.vbox(8)
	left.add_child(lv)

	var head := UI.hbox(8)
	lv.add_child(head)
	var head_label := UI.label("Belanja", 16, Color("bdf2a0"))
	head.add_child(head_label)
	var note := UI.label("Beli untuk dapat kartu acak", 10, Color(0.85, 0.9, 0.82, 0.8))
	note.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	note.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	head.add_child(note)

	_items_box = UI.vbox(8)
	_items_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	lv.add_child(_items_box)

	var right := UI.panel_box(Vector2(234, 258))
	right.position = Vector2(396, 88)
	add_child(right)

	var rv := UI.vbox(6)
	right.add_child(rv)
	rv.add_child(UI.label("Koleksi Kartu", 15, Color("bdf2a0")))

	_equipped_label = UI.label("", 11, UI.GOLD, HORIZONTAL_ALIGNMENT_LEFT, 200)
	rv.add_child(_equipped_label)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	rv.add_child(scroll)

	_cards_box = UI.vbox(6)
	_cards_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_cards_box)


func _wrap_row(content: Control) -> PanelContainer:
	var p := PanelContainer.new()
	var sb := UI.flat(Color(1, 1, 1, 0.06), 8)
	sb.set_content_margin_all(6)
	p.add_theme_stylebox_override("panel", sb)
	p.add_child(content)
	return p


# ---------------------------------------------------------------- item --

func _refresh_items() -> void:
	for child in _items_box.get_children():
		_items_box.remove_child(child)
		child.queue_free()

	for item in ITEMS:
		if String(item["tab"]) != _tab:
			continue
		_items_box.add_child(_make_item_row(item))


func _make_item_row(item: Dictionary) -> Control:
	var row := UI.hbox(8)

	var chip := ColorRect.new()
	chip.color = item["color"]
	chip.custom_minimum_size = Vector2(14, 14)
	row.add_child(chip)

	var info := UI.vbox(2)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_child(UI.label(String(item["name"]), 13))
	info.add_child(UI.label(
		String(item["desc"]), 10, Color(0.85, 0.9, 0.82, 0.8),
		HORIZONTAL_ALIGNMENT_LEFT, 190
	))
	row.add_child(info)

	var right := UI.vbox(2)
	right.alignment = BoxContainer.ALIGNMENT_CENTER
	var price := UI.label(
		"%d koin" % int(item["price"]), 11, UI.GOLD, HORIZONTAL_ALIGNMENT_RIGHT
	)
	price.custom_minimum_size = Vector2(66, 0)
	right.add_child(price)
	var buy := UI.button("Beli", 12, Vector2(66, 24))
	buy.pressed.connect(_on_buy.bind(item))
	right.add_child(buy)
	row.add_child(right)

	return _wrap_row(row)


func _on_buy(item: Dictionary) -> void:
	var price := int(item["price"])
	if not GameState.spend_coins(price):
		_show_toast("Koin belum cukup. Selamatkan hutan dulu, ya!")
		_shake_coins()
		return

	var card_id := GameState.random_card_id()
	GameState.add_card(card_id)
	_refresh_cards()
	_show_reveal(card_id)


# --------------------------------------------------------------- koleksi --

func _refresh_cards() -> void:
	for child in _cards_box.get_children():
		_cards_box.remove_child(child)
		child.queue_free()

	if GameState.equipped_card == "":
		_equipped_label.text = "Slot kosong - pilih satu kartu."
	else:
		var equipped: Dictionary = GameState.CARDS.get(GameState.equipped_card, {})
		_equipped_label.text = "Terpasang: %s" % String(
			equipped.get("name", GameState.equipped_card)
		)

	var owned_any := false
	for card_id in GameState.CARDS:
		var count := int(GameState.owned_cards.get(card_id, 0))
		if count <= 0:
			continue
		owned_any = true
		_cards_box.add_child(_make_card_row(String(card_id), count))

	if not owned_any:
		_cards_box.add_child(UI.label(
			"Belum ada kartu. Beli tanaman atau pupuk untuk mendapatkannya.",
			11, UI.CREAM, HORIZONTAL_ALIGNMENT_CENTER, 190
		))


func _make_card_row(card_id: String, count: int) -> Control:
	var card: Dictionary = GameState.CARDS.get(card_id, {})

	var col := UI.vbox(4)
	var top := UI.hbox(6)

	var chip := ColorRect.new()
	chip.color = card.get("color", Color.WHITE)
	chip.custom_minimum_size = Vector2(12, 12)
	top.add_child(chip)

	var name_l := UI.label(String(card.get("name", card_id)), 11)
	name_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	top.add_child(name_l)

	top.add_child(UI.label("x%d" % count, 11, UI.GOLD))
	col.add_child(top)

	var equipped := GameState.equipped_card == card_id
	var btn := UI.button("Lepas" if equipped else "Pasang", 11, Vector2(0, 24))
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.pressed.connect(_on_equip.bind(card_id))
	col.add_child(btn)

	return _wrap_row(col)


func _on_equip(card_id: String) -> void:
	if GameState.equipped_card == card_id:
		GameState.equip_card("")
		_show_toast("Kartu dilepas dari slot.")
	else:
		GameState.equip_card(card_id)
		var card: Dictionary = GameState.CARDS.get(card_id, {})
		_show_toast("%s terpasang." % String(card.get("name", card_id)))
	_refresh_cards()


# ---------------------------------------------------------------- reveal --

func _show_reveal(card_id: String) -> void:
	var card: Dictionary = GameState.CARDS.get(card_id, {})

	var dim := UI.dim(Color(0, 0, 0, 0.75))
	add_child(dim)

	var box := UI.panel_box(Vector2(380, 0))
	UI.center_control(box)
	add_child(box)

	var v := UI.vbox(10)
	box.add_child(v)
	v.add_child(UI.label("Kamu mendapat kartu!", 15, Color("bdf2a0"), HORIZONTAL_ALIGNMENT_CENTER))

	var chip_holder := Control.new()
	chip_holder.custom_minimum_size = Vector2(0, 46)
	v.add_child(chip_holder)
	var chip := Panel.new()
	var sb := UI.flat(card.get("color", Color.WHITE), 10)
	sb.set_content_margin_all(0)
	chip.add_theme_stylebox_override("panel", sb)
	chip.position = Vector2(172, 4)
	chip.size = Vector2(38, 38)
	chip_holder.add_child(chip)

	v.add_child(UI.label(
		String(card.get("name", card_id)), 19, UI.CREAM, HORIZONTAL_ALIGNMENT_CENTER, 330
	))
	v.add_child(UI.label(
		String(card.get("desc", "")), 13, UI.CREAM, HORIZONTAL_ALIGNMENT_CENTER, 320
	))
	v.add_child(UI.label(
		"Kartu tersimpan di koleksi.", 11, Color(0.85, 0.9, 0.82, 0.8),
		HORIZONTAL_ALIGNMENT_CENTER, 320
	))

	var close := UI.button("Simpan", 16, Vector2(150, 38))
	close.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close.pressed.connect(_close_popup.bind(dim, box))
	v.add_child(close)


func _close_popup(a: CanvasItem, b: CanvasItem) -> void:
	a.queue_free()
	b.queue_free()


# ----------------------------------------------------------------- toast --

func _build_toast() -> void:
	_toast_label = UI.label("", 14, UI.GOLD, HORIZONTAL_ALIGNMENT_CENTER, 600)
	_toast_label.position = Vector2(20, 326)
	_toast_label.size = Vector2(600, 24)
	_toast_label.modulate.a = 0.0
	add_child(_toast_label)


func _show_toast(msg: String) -> void:
	_toast_label.text = msg
	_toast_label.modulate.a = 0.0
	if _toast_tween != null and _toast_tween.is_valid():
		_toast_tween.kill()
	_toast_tween = create_tween()
	_toast_tween.tween_property(_toast_label, "modulate:a", 1.0, 0.2)
	_toast_tween.tween_interval(2.0)
	_toast_tween.tween_property(_toast_label, "modulate:a", 0.0, 0.4)


func _shake_coins() -> void:
	var base := _coin_label.position
	_coin_label.add_theme_color_override("font_color", Color("e8a9a9"))
	var tw := create_tween()
	for i in range(3):
		tw.tween_property(_coin_label, "position", base + Vector2(6, 0), 0.05)
		tw.tween_property(_coin_label, "position", base - Vector2(6, 0), 0.05)
	tw.tween_property(_coin_label, "position", base, 0.05)
	tw.tween_callback(
		func() -> void: _coin_label.add_theme_color_override("font_color", UI.GOLD)
	)
