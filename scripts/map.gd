@tool
extends Control
## Peta utama.
## Latar & zona sudah tersusun sebagai node di map.tscn supaya bisa
## digeser / diganti asetnya langsung di editor Godot.
## Isi properti "background" di Inspector untuk memakai gambar peta sendiri.

@export var background: Texture2D:
	set(value):
		background = value
		_apply_background()

@onready var _coin_label: Label = $TopBar/CoinLabel
@onready var _shop_button: Button = $TopBar/ShopButton
@onready var _zones_root: Control = $Zones
@onready var _overlay: Control = $Overlay

var _zone_nodes: Dictionary = {}


func _ready() -> void:
	_apply_background()
	if Engine.is_editor_hint():
		return

	UI.style_button(_shop_button, 16)
	_shop_button.pressed.connect(_on_shop_pressed)

	_collect_zones()
	_refresh_zone_status()

	GameState.coins_changed.connect(_on_coins_changed)
	_on_coins_changed(GameState.coins)

	_check_notifications()


# ------------------------------------------------------------------ latar --

func _apply_background() -> void:
	var bg := get_node_or_null("BackgroundArt") as TextureRect
	var scenery := get_node_or_null("Scenery") as CanvasItem
	if bg == null:
		return
	if background != null:
		bg.texture = background
		bg.visible = true
		bg.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		if scenery != null:
			scenery.visible = false
	else:
		bg.visible = false
		if scenery != null:
			scenery.visible = true


# ------------------------------------------------------------------ zona --

func _collect_zones() -> void:
	_zone_nodes.clear()
	for child in _zones_root.get_children():
		if child is BiomeZone:
			var zone: BiomeZone = child
			_zone_nodes[zone.biome_id] = zone
			zone.pressed.connect(_on_zone_pressed.bind(zone.biome_id))


func _refresh_zone_status() -> void:
	for biome_id in _zone_nodes:
		var zone: BiomeZone = _zone_nodes[biome_id]
		zone.refresh_state(
			GameState.is_biome_saved(biome_id),
			GameState.is_biome_completed(biome_id),
			GameState.is_biome_unlocked(biome_id)
		)


# ------------------------------------------------------------------ topbar --

func _on_coins_changed(total: int) -> void:
	_coin_label.text = "Koin: %d" % total


func _on_shop_pressed() -> void:
	GameState.change_scene("res://scenes/shop.tscn")


# -------------------------------------------------------------------- popup --

func _on_zone_pressed(biome_id: String) -> void:
	if not GameState.is_biome_unlocked(biome_id):
		_show_locked_popup(biome_id)
		return

	var biome := BiomeData.get_biome(biome_id)
	var dim := UI.dim()
	_overlay.add_child(dim)
	var box := UI.panel_box(Vector2(400, 0))
	UI.center_control(box)
	_overlay.add_child(box)

	var v := UI.vbox(14)
	box.add_child(v)
	v.add_child(UI.label(
		"Masuk ke Hutan %s?" % biome["name"],
		18, UI.CREAM, HORIZONTAL_ALIGNMENT_CENTER, 360
	))

	var explore_btn := UI.button("Jelajahi", 16)
	explore_btn.pressed.connect(_enter_biome.bind(biome_id, dim, box))
	v.add_child(explore_btn)

	var back := UI.button("Kembali", 16)
	back.pressed.connect(_close_popup.bind(dim, box))
	v.add_child(back)


func _show_locked_popup(biome_id: String) -> void:
	var biome := BiomeData.get_biome(biome_id)
	var dim := UI.dim()
	_overlay.add_child(dim)
	var box := UI.panel_box(Vector2(400, 0))
	UI.center_control(box)
	_overlay.add_child(box)

	var v := UI.vbox(14)
	box.add_child(v)
	v.add_child(UI.label(
		"Hutan %s masih terkunci." % biome["name"],
		18, UI.CREAM, HORIZONTAL_ALIGNMENT_CENTER, 360
	))
	v.add_child(UI.label(
		"Selesaikan Hutan Hujan dan Hutan Sabana dulu, ya.",
		14, Color("ffe9a8"), HORIZONTAL_ALIGNMENT_CENTER, 350
	))

	var ok := UI.button("Mengerti", 16)
	ok.pressed.connect(_close_popup.bind(dim, box))
	v.add_child(ok)


func _enter_biome(biome_id: String, dim: CanvasItem, box: CanvasItem) -> void:
	dim.queue_free()
	box.queue_free()
	GameState.current_biome = biome_id
	GameState.change_scene("res://scenes/explore.tscn")


func _close_popup(a: CanvasItem, b: CanvasItem) -> void:
	a.queue_free()
	b.queue_free()


# -------------------------------------------------------------- notifikasi --

func _check_notifications() -> void:
	if GameState.pending_map_toast != "":
		var msg := GameState.pending_map_toast
		GameState.pending_map_toast = ""
		_show_toast(msg)

	if GameState.all_biomes_completed() and not GameState.ending_shown:
		GameState.ending_shown = true
		_show_ending()


func _show_toast(msg: String) -> void:
	var toast := UI.panel_box()
	toast.add_child(UI.label(msg, 14, UI.CREAM, HORIZONTAL_ALIGNMENT_CENTER, 400))
	toast.position = Vector2(120, -50)
	add_child(toast)
	var tw := create_tween()
	tw.set_trans(Tween.TRANS_BACK)
	tw.tween_property(toast, "position:y", 70.0, 0.5)
	tw.tween_interval(2.8)
	tw.tween_property(toast, "modulate:a", 0.0, 0.5)
	tw.tween_callback(toast.queue_free)


func _show_ending() -> void:
	var dim := UI.dim(Color(0, 0, 0, 0.7))
	_overlay.add_child(dim)
	var box := UI.panel_box(Vector2(460, 0))
	UI.center_control(box)
	_overlay.add_child(box)

	var v := UI.vbox(14)
	box.add_child(v)
	v.add_child(UI.label(
		"Berkat kamu, nusantara kembali bernapas.",
		20, Color("bdf2a0"), HORIZONTAL_ALIGNMENT_CENTER, 420
	))
	v.add_child(UI.label(
		"Ketiga hutan telah pulih. Terima kasih, penjaga hutan!",
		14, UI.CREAM, HORIZONTAL_ALIGNMENT_CENTER, 420
	))

	var again := UI.button("Main Lagi", 16)
	again.pressed.connect(_on_play_again.bind(dim, box))
	v.add_child(again)

	var shop := UI.button("Ke Toko", 16)
	shop.pressed.connect(_on_shop_pressed)
	v.add_child(shop)


func _on_play_again(dim: CanvasItem, box: CanvasItem) -> void:
	dim.queue_free()
	box.queue_free()
	GameState.ending_shown = true
	GameState.change_scene("res://scenes/main_menu.tscn")
