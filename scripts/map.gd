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

@export_group("Pohon")
## Gambar slot kosong (pohon mati).
@export var dead_tree_texture: Texture2D:
	set(value):
		dead_tree_texture = value
		_apply_tree_textures()
## Variasi pohon hidup per jenis. Slot ke-1, 3, 5, ... memakai variasi 1,
## slot ke-2, 4, 6, ... memakai variasi 2, dan seterusnya (tidak acak).
## Kalau array akasia/bakau kosong, dipakai variasi meranti.
@export var meranti_textures: Array[Texture2D] = []:
	set(value):
		meranti_textures = value
		_apply_tree_textures()
@export var akasia_textures: Array[Texture2D] = []:
	set(value):
		akasia_textures = value
		_apply_tree_textures()
@export var bakau_textures: Array[Texture2D] = []:
	set(value):
		bakau_textures = value
		_apply_tree_textures()
@export_group("")

@onready var _coin_label: Label = $TopBar/CoinLabel
@onready var _shop_button: Button = $TopBar/ShopButton
@onready var _zones_root: Control = $Zones
@onready var _overlay: Control = $Overlay

var _zone_nodes: Dictionary = {}

## Alpha island_hijau untuk tahap peta 0, 1, 2, 3.
const GREEN_ALPHA_BY_STAGE: Array[float] = [0.0, 0.33, 0.66, 1.0]
## Slot kosong (pohon mati) hanya tampil sampai tahap ini. Sesudahnya
## slot kosong disembunyikan; slot yang terisi selalu tampil.
const SHOW_DEAD_TREES_UNTIL_STAGE := 1
## Grup slot pohon -> jenis pohon di GameState.planted.
const SLOT_GROUPS := {
	"MapDecor/SlotsHujan": "meranti",
	"MapDecor/SlotsSabana": "akasia",
	"MapDecor/SlotsMangrove": "bakau",
}


func _ready() -> void:
	_apply_background()
	_apply_tree_textures()
	if Engine.is_editor_hint():
		return

	_style_icon_button(_shop_button)
	_shop_button.pressed.connect(_on_shop_pressed)

	_collect_zones()
	_refresh_zone_status()
	# Dipanggil setiap kali scene peta dimuat (termasuk kembali dari toko).
	_refresh_map_growth()

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


# ----------------------------------------------------------- kehijauan --

func _textures_for(tree_id: String) -> Array[Texture2D]:
	var list: Array[Texture2D] = meranti_textures
	if tree_id == "akasia" and not akasia_textures.is_empty():
		list = akasia_textures
	elif tree_id == "bakau" and not bakau_textures.is_empty():
		list = bakau_textures
	return list


## Pasang texture ke setiap slot. Jalan juga di editor untuk pratinjau.
func _apply_tree_textures() -> void:
	if not is_inside_tree():
		return
	for group_path in SLOT_GROUPS:
		var group := get_node_or_null(group_path)
		if group == null:
			continue
		var list := _textures_for(String(SLOT_GROUPS[group_path]))
		var index := 0
		for slot in group.get_children():
			if not slot is TreeSlot:
				continue
			var tree_slot := slot as TreeSlot
			tree_slot.dead_texture = dead_tree_texture
			tree_slot.alive_texture = list[index % list.size()] if not list.is_empty() else null
			index += 1


func _refresh_map_growth() -> void:
	var stage := clampi(GameState.get_map_stage(), 0, GREEN_ALPHA_BY_STAGE.size() - 1)
	var green := get_node_or_null("BackgroundGreen") as CanvasItem
	if green != null:
		green.modulate.a = GREEN_ALPHA_BY_STAGE[stage]
	var show_dead := stage <= SHOW_DEAD_TREES_UNTIL_STAGE

	for group_path in SLOT_GROUPS:
		var group := get_node_or_null(group_path)
		if group == null:
			continue
		var tree_id := String(SLOT_GROUPS[group_path])
		var grown := int(GameState.planted.get(tree_id, 0))
		var index := 0
		for slot in group.get_children():
			if slot is TreeSlot:
				var tree_slot := slot as TreeSlot
				tree_slot.alive = index < grown
				tree_slot.visible = tree_slot.alive or show_dead
				index += 1


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
	_coin_label.text = "%d" % total


func _on_shop_pressed() -> void:
	GameState.change_scene("res://scenes/shop.tscn")


# ------------------------------------------------------------ tombol ikon --

## Tombol bergambar (mis. Toko). Efek sama dengan papan di menu utama:
## membesar + menyala saat hover, mengecil sedikit saat ditekan.
func _style_icon_button(b: Button) -> void:
	b.flat = true
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.pivot_offset = b.size / 2.0
	var empty := StyleBoxEmpty.new()
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		b.add_theme_stylebox_override(state, empty)
	b.mouse_entered.connect(_on_icon_button_hover.bind(b, true))
	b.mouse_exited.connect(_on_icon_button_hover.bind(b, false))
	b.button_down.connect(_on_icon_button_scale.bind(b, Vector2(0.96, 0.96), 0.06))
	b.button_up.connect(func() -> void:
		_on_icon_button_scale(b, Vector2(1.08, 1.08) if b.is_hovered() else Vector2.ONE, 0.08))


func _on_icon_button_hover(b: Button, on: bool) -> void:
	var tw := create_tween()
	tw.set_parallel(true)
	tw.set_trans(Tween.TRANS_BACK if on else Tween.TRANS_SINE)
	tw.set_ease(Tween.EASE_OUT)
	tw.tween_property(b, "scale", Vector2(1.08, 1.08) if on else Vector2.ONE, 0.18 if on else 0.15)
	tw.tween_property(b, "modulate", Color(1.15, 1.1, 0.95) if on else Color.WHITE, 0.18 if on else 0.15)


func _on_icon_button_scale(b: Button, target: Vector2, duration: float) -> void:
	create_tween().tween_property(b, "scale", target, duration)


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
