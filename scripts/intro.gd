extends Control
## Intro cerita: 5 bagian teks dengan latar berubah warna. Bisa dilewati.

const SLIDES := [
	{
		"duration": 5.0,
		"text": "Dahulu, nusantara adalah zamrud yang bernapas.",
		"bg": Color("1c4230"),
	},
	{
		"duration": 6.0,
		"text": "Rimba memeluk hujan, sabana menari di bawah senja, dan bakau menjaga pantai dengan akarnya yang setia.",
		"bg": Color("6e5a2a"),
	},
	{
		"duration": 7.0,
		"text": "Namun waktu berjalan, dan tangan-tangan manusia menorehkan luka. Rimba menipis, api merayap, sampah menyesaki akar.",
		"bg": Color("4a4a44"),
	},
	{
		"duration": 5.0,
		"text": "Napas bumi kian lirih.",
		"bg": Color("262b26"),
	},
	{
		"duration": 5.0,
		"text": "Maukah kamu menjadi penjaga terakhirnya? Selamatkan hutan, sebelum ia hanya tinggal kenangan.",
		"bg": Color("10140f"),
	},
]

var _bg: ColorRect
var _text: Label
var _sprout: Node2D
var _finished := false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_bg = $Background
	_text = $StoryText
	_sprout = $Sprout
	_sprout.scale = Vector2.ZERO

	_bg.color = SLIDES[0]["bg"]
	_text.modulate.a = 0.0

	var skip := $SkipButton as Button
	UI.style_button(skip, 14)
	skip.pressed.connect(_skip)

	_play()


func _play() -> void:
	for i in SLIDES.size():
		if _finished:
			return
		var slide: Dictionary = SLIDES[i]
		_text.text = slide["text"]
		var tw_bg := create_tween()
		tw_bg.tween_property(_bg, "color", slide["bg"], 1.2)
		if i == SLIDES.size() - 1:
			_show_sprout()
		var tw := create_tween()
		tw.tween_property(_text, "modulate:a", 1.0, 0.7)
		tw.tween_interval(float(slide["duration"]) - 1.4)
		tw.tween_property(_text, "modulate:a", 0.0, 0.7)
		await tw.finished
	if not _finished:
		_finished = true
		GameState.change_scene("res://scenes/map.tscn")


func _show_sprout() -> void:
	# Tunas kecil tumbuh saat slide terakhir.
	_sprout.scale = Vector2.ZERO
	var tw := create_tween()
	tw.set_trans(Tween.TRANS_BACK)
	tw.tween_property(_sprout, "scale", Vector2.ONE, 1.4)


func _skip() -> void:
	if _finished:
		return
	_finished = true
	GameState.change_scene("res://scenes/map.tscn")
