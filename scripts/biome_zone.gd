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
	_refresh()


func refresh_state(p_saved: bool, p_completed: bool, p_unlocked: bool) -> void:
	saved = p_saved
	completed = p_completed
	locked = not p_unlocked
	_refresh()


func _refresh() -> void:
	var placeholder := get_node_or_null("Placeholder") as ColorRect
	var art_rect := get_node_or_null("Art") as TextureRect
	var title := get_node_or_null("Content/Title") as Label
	var status := get_node_or_null("Content/StatusRow/Status") as Label
	var lock := get_node_or_null("LockOverlay") as Control

	if placeholder != null:
		placeholder.color = accent.darkened(0.55)

	if art_rect != null:
		if art != null:
			art_rect.texture = art
		art_rect.visible = art_rect.texture != null
		art_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	if placeholder != null:
		placeholder.visible = art_rect == null or art_rect.texture == null

	if title != null:
		title.text = zone_title
	if lock != null:
		lock.visible = locked
	modulate = Color(0.72, 0.72, 0.72) if locked else Color.WHITE

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
