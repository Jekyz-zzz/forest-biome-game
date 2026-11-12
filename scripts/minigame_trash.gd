extends MinigameBase
## Mini-game Hutan Mangrove: "Tarik sampah sampai bersih!"
## Seret sampah keluar dari akar bakau. Bersihkan semua sebelum waktu habis.

const TOTAL_TRASH := 8

var _trash_nodes: Array[Node2D] = []
var _cleaned := 0
var _dragging: Node2D = null
var _drag_offset := Vector2.ZERO
var _count_label: Label
var _bottle_proto: Node2D
var _bag_proto: Node2D


func _build_world() -> void:
	duration = 35.0
	time_left = duration

	_bottle_proto = get_node_or_null("Placeholders/BottlePrototype") as Node2D
	_bag_proto = get_node_or_null("Placeholders/BagPrototype") as Node2D
	if _bottle_proto != null:
		_bottle_proto.visible = false
	if _bag_proto != null:
		_bag_proto.visible = false

	# Sampah muncul di titik-titik yang bisa digeser di editor.
	var spots_root := get_node_or_null("Placeholders/TrashSpots") as Node2D
	if spots_root != null:
		var i := 0
		for spot in spots_root.get_children():
			if spot is Node2D:
				_spawn_trash(spot.position, i % 2 == 0)
				i += 1
				if i >= TOTAL_TRASH:
					break

	# Info jumlah sampah.
	_count_label = UI.label("Sampah: 0/%d" % TOTAL_TRASH, 14, Color("eef2e6"))
	_count_label.position = Vector2(8, 34)
	_hud_layer.add_child(_count_label)
	_update_hud()


func _spawn_trash(pos: Vector2, is_bottle: bool) -> void:
	var trash := Area2D.new()
	trash.position = pos

	var cs := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = Vector2(34, 34)
	cs.shape = rs
	trash.add_child(cs)

	var proto := _bottle_proto if is_bottle else _bag_proto
	if proto != null:
		var visual := proto.duplicate() as Node2D
		visual.position = Vector2.ZERO
		visual.visible = true
		trash.add_child(visual)
	else:
		var fallback := ColorRect.new()
		fallback.color = Color("5fa8d3") if is_bottle else Color("ececec")
		fallback.position = Vector2(-10, -14) if is_bottle else Vector2(-13, -10)
		fallback.size = Vector2(12, 26) if is_bottle else Vector2(26, 20)
		trash.add_child(fallback)

	trash.set_meta("origin", pos)
	trash.rotation = randf_range(-0.4, 0.4)
	trash.input_pickable = true
	trash.input_event.connect(_on_trash_input.bind(trash))
	add_child(trash)
	_trash_nodes.append(trash)


func _on_trash_input(_viewport: Node, event: InputEvent, _shape_idx: int, trash: Area2D) -> void:
	if trash.has_meta("out"):
		return
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_start_drag(trash, event.position)
	elif event is InputEventScreenTouch:
		if event.pressed:
			_start_drag(trash, event.position)


func _start_drag(trash: Node2D, pos: Vector2) -> void:
	_dragging = trash
	_drag_offset = trash.position - pos
	trash.z_index = 20
	var tw := create_tween()
	tw.tween_property(trash, "scale", Vector2(1.18, 1.18), 0.1)


func _move_drag(pos: Vector2) -> void:
	if _dragging == null or not is_instance_valid(_dragging):
		return
	_dragging.position = (pos + _drag_offset).clamp(Vector2(10, 40), Vector2(630, 340))


func _end_drag() -> void:
	if _dragging == null or not is_instance_valid(_dragging):
		_dragging = null
		return
	var trash := _dragging
	_dragging = null
	trash.z_index = 0

	var origin: Vector2 = trash.get_meta("origin")
	if trash.position.distance_to(origin) > 85.0:
		_free_trash(trash)
	else:
		var tw := create_tween()
		tw.set_trans(Tween.TRANS_BACK)
		tw.tween_property(trash, "position", origin, 0.2)
		tw.parallel().tween_property(trash, "scale", Vector2.ONE, 0.2)


func _free_trash(trash: Node2D) -> void:
	if trash.has_meta("out"):
		return
	trash.set_meta("out", true)
	_trash_nodes.erase(trash)
	_cleaned += 1
	_collect_coin(2)
	_update_count()

	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(trash, "position:y", trash.position.y - 140.0, 0.5)
	tw.tween_property(trash, "rotation", trash.rotation + 3.0, 0.5)
	tw.tween_property(trash, "modulate:a", 0.0, 0.5)
	tw.chain().tween_callback(trash.queue_free)

	if _cleaned >= TOTAL_TRASH:
		_finish_cleaned()


func _update_count() -> void:
	_count_label.text = "Sampah: %d/%d" % [_cleaned, TOTAL_TRASH]


func _finish_cleaned() -> void:
	var ratio := time_left / duration
	var stars := 1
	if ratio >= 0.35:
		stars = 3
	elif ratio >= 0.15:
		stars = 2
	_finish(true, stars, 1.0)


func _time_up() -> void:
	if _cleaned >= TOTAL_TRASH:
		_finish_cleaned()
	else:
		_finish(false)


func _input(event: InputEvent) -> void:
	if _dragging == null:
		return
	if event is InputEventMouseMotion and (event.button_mask & MOUSE_BUTTON_MASK_LEFT):
		_move_drag(event.position)
	elif event is InputEventScreenDrag:
		_move_drag(event.position)
	elif event is InputEventMouseButton and not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_end_drag()
	elif event is InputEventScreenTouch and not event.pressed:
		_end_drag()
