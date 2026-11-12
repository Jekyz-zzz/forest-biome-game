class_name RainEffect
extends Node2D
## Efek hujan sederhana untuk layar 640x360.
## Letakkan di dalam CanvasLayer supaya mengikuti layar, bukan kamera.

var _drops: Array[Line2D] = []


func _ready() -> void:
	randomize()
	for i in 34:
		var drop := Line2D.new()
		drop.points = PackedVector2Array([Vector2.ZERO, Vector2(-2, 14)])
		drop.width = 1.0
		drop.default_color = Color(0.75, 0.85, 1.0, 0.45)
		drop.position = Vector2(randf() * 640.0, randf() * 360.0)
		add_child(drop)
		_drops.append(drop)


func _process(delta: float) -> void:
	for drop in _drops:
		drop.position.y += 480.0 * delta
		if drop.position.y > 370.0:
			drop.position.y = -20.0
			drop.position.x = randf() * 640.0
