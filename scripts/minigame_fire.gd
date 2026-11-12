extends MinigameBase
## Mini-game Hutan Sabana: "Padamkan api dan jangan biarkan menyebar!"
## Tap api sebelum tumbuh besar; api yang dibiarkan menyebar mengurangi
## kesehatan hutan.

var _fires: Array[Node2D] = []
var _spawn_timer := 1.2
var _elapsed := 0.0
var _extinguished := 0
var _health := 3
var _health_icons: Array[Control] = []
var _decals: Node2D
var _fire_proto: Node2D


## Ikon daun kecil untuk kesehatan hutan.
class LeafIcon extends Control:
	func _init() -> void:
		custom_minimum_size = Vector2(18, 18)

	func _draw() -> void:
		var pts := PackedVector2Array([
			Vector2(9, 1), Vector2(16, 9), Vector2(9, 17), Vector2(2, 9),
		])
		draw_colored_polygon(pts, Color("7ed957"))
		draw_polyline(PackedVector2Array([pts[0], pts[1], pts[2], pts[3], pts[0]]),
			Color(0.16, 0.36, 0.14, 0.8), 1.5)
		draw_line(Vector2(9, 3), Vector2(9, 15), Color(0.16, 0.36, 0.14, 0.55), 1.0)


func _build_world() -> void:
	_decals = get_node_or_null("Placeholders/Decals") as Node2D
	_fire_proto = get_node_or_null("Placeholders/FirePrototype") as Node2D
	if _fire_proto != null:
		_fire_proto.visible = false

	# UI kesehatan hutan
	var health_row := UI.hbox(4)
	health_row.position = Vector2(415, 7)
	_hud_layer.add_child(health_row)
	var hl := UI.label("Hutan:", 13, Color("5a4210"))
	hl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	health_row.add_child(hl)
	for i in range(3):
		var leaf := LeafIcon.new()
		health_row.add_child(leaf)
		_health_icons.append(leaf)


func _game_tick(delta: float) -> void:
	_elapsed += delta
	var progress := clampf(_elapsed / duration, 0.0, 1.0)

	_spawn_timer -= delta
	if _spawn_timer <= 0.0 and _fires.size() < 6:
		_spawn_timer = maxf(2.2 - 1.2 * progress, 0.9)
		_spawn_fire(randf_range(70.0, 570.0))

	for fire in _fires.duplicate():
		var age: float = float(fire.get_meta("age")) + delta
		fire.set_meta("age", age)
		var grow_time: float = float(fire.get_meta("grow_time"))
		var s := lerpf(0.45, 1.7, clampf(age / grow_time, 0.0, 1.0))
		fire.scale = Vector2(s, s)
		if age >= grow_time:
			_spread_fire(fire)


func _spawn_fire(x: float) -> void:
	var fire := Area2D.new()
	fire.position = Vector2(x, GROUND_TOP)

	var cs := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = Vector2(44, 60)
	cs.shape = rs
	cs.position = Vector2(0, -30)
	fire.add_child(cs)

	var flame: CanvasItem = null
	if _fire_proto != null:
		var visual := _fire_proto.duplicate() as Node2D
		visual.position = Vector2.ZERO
		visual.visible = true
		fire.add_child(visual)
		flame = visual.get_node_or_null("Flame") as CanvasItem

	if flame == null:
		var fallback := ColorRect.new()
		fallback.color = Color("e25822")
		fallback.position = Vector2(-14, -44)
		fallback.size = Vector2(28, 44)
		fire.add_child(fallback)
		flame = fallback

	fire.set_meta("age", 0.0)
	fire.set_meta("grow_time", maxf(5.0 - 2.0 * clampf(_elapsed / duration, 0.0, 1.0), 3.0))
	fire.input_pickable = true
	fire.input_event.connect(_on_fire_input.bind(fire))
	add_child(fire)
	_fires.append(fire)

	var tw := create_tween().set_loops()
	tw.set_trans(Tween.TRANS_SINE)
	tw.tween_property(flame, "position:y", flame.position.y - 4.0, 0.25)
	tw.tween_property(flame, "position:y", flame.position.y, 0.25)


func _on_fire_input(_viewport: Node, event: InputEvent, _shape_idx: int, fire: Area2D) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_extinguish(fire)
	elif event is InputEventScreenTouch:
		if event.pressed:
			_extinguish(fire)


func _extinguish(fire: Area2D) -> void:
	if not is_instance_valid(fire) or fire.has_meta("out"):
		return
	fire.set_meta("out", true)
	_puff(fire.position)
	_fires.erase(fire)
	fire.queue_free()
	_extinguished += 1
	_collect_coin(2)


func _puff(pos: Vector2) -> void:
	var puff := Node2D.new()
	puff.position = pos + Vector2(0, -20)
	add_child(puff)
	for i in range(3):
		var smoke := UI.circle(7.0 + 3.0 * float(i), Color(0.85, 0.85, 0.85, 0.8))
		smoke.position = Vector2(randf_range(-6, 6), randf_range(-8, 4))
		puff.add_child(smoke)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(puff, "scale", Vector2(2.2, 2.2), 0.4)
	tw.tween_property(puff, "modulate:a", 0.0, 0.4)
	tw.chain().tween_callback(puff.queue_free)


func _spread_fire(fire: Area2D) -> void:
	if not is_instance_valid(fire):
		return
	var pos := fire.position
	_fires.erase(fire)
	fire.queue_free()

	# bekas terbakar
	var decal := UI.circle(16, Color(0.12, 0.1, 0.08, 0.75))
	decal.position = pos + Vector2(0, -6)
	decal.scale = Vector2(1.6, 0.5)
	if _decals != null:
		_decals.add_child(decal)

	_health -= 1
	_update_health()
	_flash_damage()
	_show_floating_text("Api menyebar!", Color("e8a9a9"))

	if _health <= 0:
		_finish(false)
		return

	# api baru menjalar di kiri-kanan
	for i in range(2):
		if _fires.size() >= 8:
			break
		var nx := clampf(pos.x + randf_range(-90.0, 90.0), 60.0, 580.0)
		_spawn_fire(nx)


func _update_health() -> void:
	for i in range(_health_icons.size()):
		var alive := i < _health
		_health_icons[i].modulate = Color.WHITE if alive else Color(0.35, 0.35, 0.35, 0.5)


func _flash_damage() -> void:
	var flash := ColorRect.new()
	flash.color = Color(1.0, 0.25, 0.15, 0.28)
	UI.full_rect(flash)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud_layer.add_child(flash)
	var tw := create_tween()
	tw.tween_property(flash, "modulate:a", 0.0, 0.45)
	tw.tween_callback(flash.queue_free)


func _time_up() -> void:
	var stars := 1
	if _health >= 3:
		stars = 3
	elif _health == 2:
		stars = 2
	_finish(true, stars, float(_extinguished))
