@tool
class_name TreeSlot
extends Marker2D
## Satu slot pohon di peta. Titik Marker = pangkal pohon.
## Texture biasanya diisi otomatis oleh map.gd dari array per jenis
## (lihat properti di node Map). Kalau texture kosong, slot menggambar
## placeholder sederhana: cokelat = mati, hijau = hidup.

## Jenis pohon untuk slot ini: "meranti", "akasia", atau "bakau".
@export var tree_type := "meranti"
@export var dead_texture: Texture2D:
	set(value):
		dead_texture = value
		queue_redraw()
@export var alive_texture: Texture2D:
	set(value):
		alive_texture = value
		queue_redraw()
## Tinggi pohon hidup di layar (piksel). Lebar mengikuti rasio gambar.
@export var tree_height := 26.0:
	set(value):
		tree_height = value
		queue_redraw()
## Tinggi pohon mati di layar (piksel).
@export var dead_tree_height := 22.0:
	set(value):
		dead_tree_height = value
		queue_redraw()
## Pratinjau di editor. Saat game berjalan, diatur oleh map.gd.
@export var alive := false:
	set(value):
		alive = value
		queue_redraw()

const TRUNK := Color("6d4c33")
const DEAD := Color("8a6a4a")
const LEAF := Color("4f9a3f")
const LEAF_LIGHT := Color("7cc35a")

## Cache area tidak-transparan tiap texture, supaya ruang kosong di
## sekitar gambar tidak membuat pohon melayang atau mengecil.
static var _used_rects: Dictionary = {}


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	queue_redraw()


func _draw() -> void:
	var tex := alive_texture if alive else dead_texture
	if tex != null:
		var src := _used_rect(tex)
		var h := tree_height if alive else dead_tree_height
		var w := h * src.size.x / maxf(src.size.y, 1.0)
		# Pangkal bawah-tengah gambar berada di titik Marker.
		draw_texture_rect_region(tex, Rect2(-w / 2.0, -h, w, h), src)
		return
	if alive:
		_draw_alive_placeholder()
	else:
		_draw_dead_placeholder()


static func _used_rect(tex: Texture2D) -> Rect2:
	var key := tex.get_rid()
	if _used_rects.has(key):
		return _used_rects[key]
	var full := Rect2(Vector2.ZERO, tex.get_size())
	var rect := full
	var img := tex.get_image()
	if img != null:
		if img.is_compressed():
			img.decompress()
		var used := img.get_used_rect()
		if used.size.x > 0 and used.size.y > 0:
			rect = Rect2(used)
	_used_rects[key] = rect
	return rect


func _draw_dead_placeholder() -> void:
	# Batang + dua cabang gundul.
	draw_rect(Rect2(-1.5, -14, 3, 14), DEAD)
	draw_line(Vector2(0, -9), Vector2(-5, -14), DEAD, 1.5)
	draw_line(Vector2(0, -11), Vector2(4, -16), DEAD, 1.5)
	draw_line(Vector2(-5, -14), Vector2(-6, -17), DEAD, 1.0)


func _draw_alive_placeholder() -> void:
	# Batang + tajuk bulat.
	draw_rect(Rect2(-1.5, -8, 3, 8), TRUNK)
	draw_circle(Vector2(0, -13), 7.0, LEAF)
	draw_circle(Vector2(-2, -15), 3.0, LEAF_LIGHT)
