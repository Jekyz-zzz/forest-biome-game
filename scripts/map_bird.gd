extends Sprite2D
## Burung dekorasi di langit peta. Terbang pelan secara horizontal,
## sedikit naik-turun, lalu muncul lagi dari sisi seberang layar.

## Kecepatan dalam piksel per detik.
@export var speed := 14.0
## 1 = ke kanan, -1 = ke kiri.
@export_range(-1, 1, 2) var direction := 1
## Amplitudo gerak naik-turun (piksel).
@export var bob_amount := 3.0
@export var bob_speed := 1.6

var _base_y := 0.0
var _time := 0.0


func _ready() -> void:
	_base_y = position.y
	_time = randf() * TAU
	# Sprite menghadap kanan; balik kalau terbang ke kiri.
	flip_h = direction < 0


func _process(delta: float) -> void:
	_time += delta
	position.x += speed * float(direction) * delta
	position.y = _base_y + sin(_time * bob_speed) * bob_amount

	var screen_w := get_viewport_rect().size.x
	var half_w := get_rect().size.x * absf(scale.x) / 2.0
	if direction > 0 and position.x - half_w > screen_w:
		position.x = -half_w
	elif direction < 0 and position.x + half_w < 0.0:
		position.x = screen_w + half_w
