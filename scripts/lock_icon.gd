class_name LockIcon
extends Control
## Ikon gembok sederhana, bisa diganti dengan tekstur sendiri di scene zona.


func _ready() -> void:
	custom_minimum_size = Vector2(34, 34)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()


func _draw() -> void:
	var c := size / 2.0
	draw_arc(c + Vector2(0, -5), 9.0, PI, TAU, 18, Color("e8e2d0"), 3.0)
	draw_rect(Rect2(c + Vector2(-12, -1), Vector2(24, 18)), Color("e8e2d0"))
	draw_circle(c + Vector2(0, 7), 2.6, Color("3a3a30"))
	draw_rect(Rect2(c + Vector2(-1, 7), Vector2(2, 6)), Color("3a3a30"))
