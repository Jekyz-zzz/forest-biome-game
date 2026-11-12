@tool
class_name Placeholder
extends ColorRect
## Blok warna sederhana yang bisa digeser, diubah ukurannya, dan diwarnai
## langsung di editor Godot. Isi properti "Art" di Inspector untuk
## mengganti blok warna dengan gambar (PNG) tanpa mengubah skrip.
##
## Catatan: saat gambar diisi, blok warna tetap tersimpan sebagai cadangan.
## Kosongkan kembali "Art" untuk memakai blok warna lagi.

@export var art: Texture2D:
	set(value):
		art = value
		_apply_art()

@export var art_modulate := Color.WHITE:
	set(value):
		art_modulate = value
		_apply_art()

var _art_rect: TextureRect


func _ready() -> void:
	_apply_art()


func _apply_art() -> void:
	if not is_inside_tree():
		return

	if art == null:
		if _art_rect != null and is_instance_valid(_art_rect):
			_art_rect.queue_free()
		_art_rect = null
		return

	if _art_rect == null or not is_instance_valid(_art_rect):
		_art_rect = TextureRect.new()
		_art_rect.name = "ArtPreview"
		_art_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_art_rect.stretch_mode = TextureRect.STRETCH_SCALE
		_art_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		_art_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_art_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		add_child(_art_rect)

	_art_rect.texture = art
	_art_rect.modulate = art_modulate
