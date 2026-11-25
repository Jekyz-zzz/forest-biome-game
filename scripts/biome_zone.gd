@tool
class_name BiomeZone
extends Button
## Satu zona bioma di peta.
## Bisa digeser / diubah ukurannya langsung di editor Godot.
## Ganti gambar dengan mengisi properti "art" di Inspector,
## atau timpa tekstur node "Art" dengan gambarmu.
##
## Catatan: status "locked" di editor hanya untuk pratinjau.
## Saat game berjalan, status dihitung dari progres GameState.

@export var biome_id := "hujan"
@export var zone_title := "Hutan Hujan":
	set(value):
		zone_title = value
		_refresh()
@export var accent := Color("66bb6a"):
	set(value):
		accent = value
		_refresh()
## Kosongkan untuk memakai tekstur node Art / warna placeholder.
@export var art: Texture2D:
	set(value):
		art = value
		_refresh()
## Gambar khusus saat terkunci (gembok sudah ada di gambar).
## Kalau diisi, LockOverlay bawaan disembunyikan saat terkunci.
@export var locked_art: Texture2D:
	set(value):
		locked_art = value
		_refresh()
## Path gambar saat zona terbuka. Boleh menunjuk file yang belum ada:
## kalau tidak ditemukan, "art" yang dipakai (tanpa error).
@export_file("*.png", "*.svg", "*.webp") var unlocked_art_path := "":
	set(value):
		unlocked_art_path = value
		_refresh()
## Nama yang tampil kalau gambar terbuka (unlocked_art_path) belum ada,
## karena gambar placeholder tidak memuat tulisan nama zona.
@export var placeholder_title := "":
	set(value):
		placeholder_title = value
		_refresh()
## Pratinjau status terkunci di editor. Runtime tetap dihitung otomatis.
@export var locked := false:
	set(value):
		locked = value
		_refresh()

var saved := false
var completed := false


func _ready() -> void:
	flat = true
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	if not resized.is_connected(_layout_content):
		resized.connect(_layout_content)
	_refresh()


func refresh_state(p_saved: bool, p_completed: bool, p_unlocked: bool) -> void:
	saved = p_saved
	completed = p_completed
	locked = not p_unlocked
	_refresh()


## Pilih gambar sesuai status: locked_art -> unlocked_art_path -> art.
func _current_art() -> Texture2D:
	if locked and locked_art != null:
		return locked_art
	if not locked and unlocked_art_path != "" and ResourceLoader.exists(unlocked_art_path):
		var tex := load(unlocked_art_path) as Texture2D
		if tex != null:
			return tex
	return art


func _refresh() -> void:
	var placeholder := get_node_or_null("Placeholder") as ColorRect
	var art_rect := get_node_or_null("Art") as TextureRect
	var title := get_node_or_null("Content/Title") as Label
	var status := get_node_or_null("Content/StatusRow/Status") as Label
	var lock := get_node_or_null("LockOverlay") as Control

	if placeholder != null:
		placeholder.color = accent.darkened(0.55)

	var use_locked_art := locked and locked_art != null
	if art_rect != null:
		var tex := _current_art()
		if tex != null:
			art_rect.texture = tex
		art_rect.visible = art_rect.texture != null
		art_rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR

	if placeholder != null:
		placeholder.visible = art_rect == null or art_rect.texture == null

	if title != null:
		var shown_title := zone_title
		var using_fallback := unlocked_art_path != "" and _current_art() == art
		if placeholder_title != "" and using_fallback and not locked:
			shown_title = placeholder_title
		title.text = shown_title
		title.visible = shown_title != ""
	if lock != null:
		lock.visible = locked and not use_locked_art
	modulate = Color(0.72, 0.72, 0.72) if locked and not use_locked_art else Color.WHITE
	_layout_content.call_deferred()

	if status == null:
		return
	if locked:
		status.text = "Terkunci"
		status.add_theme_color_override("font_color", Color("cfd8c8"))
	elif completed:
		status.text = "Terselamatkan"
		status.add_theme_color_override("font_color", Color("bdf2a0"))
	elif saved:
		status.text = "Menunggu kuis"
		status.add_theme_color_override("font_color", Color("ffe9a8"))
	else:
		status.text = "Butuh penolong"
		status.add_theme_color_override("font_color", Color("d9e8c9"))


## Letakkan judul + status tepat di bawah gambar yang benar-benar
## tergambar (Art memakai "keep aspect centered", jadi tinggi gambar bisa
## lebih kecil dari kotaknya).
func _layout_content() -> void:
	var content := get_node_or_null("Content") as Control
	var art_rect := get_node_or_null("Art") as TextureRect
	var placeholder := get_node_or_null("Placeholder") as Control
	if content == null:
		return
	var bottom := size.y
	if art_rect != null and art_rect.visible and art_rect.texture != null:
		var area := art_rect.size
		var tex_size := art_rect.texture.get_size()
		if tex_size.x > 0.0 and tex_size.y > 0.0:
			var s := minf(area.x / tex_size.x, area.y / tex_size.y)
			bottom = art_rect.position.y + (area.y + tex_size.y * s) / 2.0
	elif placeholder != null and placeholder.visible:
		bottom = placeholder.position.y + placeholder.size.y
	var h := content.get_combined_minimum_size().y
	content.set_anchors_preset(Control.PRESET_TOP_WIDE)
	content.offset_left = 0.0
	content.offset_right = 0.0
	content.offset_top = bottom
	content.offset_bottom = bottom + h
