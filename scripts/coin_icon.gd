class_name CoinIcon
extends Control
## Ikon koin kecil untuk bar atas peta.


func _ready() -> void:
	custom_minimum_size = Vector2(20, 20)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var c := size / 2.0
	draw_circle(c, 9.0, Color("f4c542"))
	draw_circle(c, 6.0, Color("d9a92f"))
	draw_circle(c - Vector2(2, 2), 1.8, Color("ffe9a8"))
