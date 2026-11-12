extends MinigameBase
## Mini-game Hutan Hujan Tropis: "Lari dari terkaman Harimau Sumatera!"
## Lompati rintangan; setiap tabrakan membuat harimau makin dekat.
##
## Semua placeholder ada sebagai node ColorRect di scenes/minigame_runner.tscn:
## - Placeholders/Sky, Ground, Moss, BgTrees
## - Placeholders/TigerPrototype, RockPrototype, LogPrototype
## Geser / ubah ukurannya langsung di editor. Isi properti "Art" pada node
## Placeholder untuk mengganti blok warna dengan gambar.
## Marker2D PlayerStart / TigerStart / ObstacleSpawn juga bisa digeser.

@export_group("Aset")
@export var player_scene: PackedScene
@export var player_frames: SpriteFrames

@export_group("Pengaturan")
@export var ground_top := 324.0
@export var obstacle_collision_size := Vector2(26, 26)
@export var base_speed := 240.0
@export var max_speed_bonus := 90.0
@export var tiger_creep_base := 2.0
@export var tiger_creep_bonus := 4.0
@export var jump_velocity := -430.0

var _player: CharacterBody2D
var _tiger: Node2D
var _tiger_x := -160.0
var _obstacles: Array[Node2D] = []
var _bg_root: Node2D
var _bg_trees: Array[Node2D] = []
var _spawn_timer := 1.4
var _elapsed := 0.0
var _hits := 0
var _passed := 0
var _speed := 240.0
var _danger_label: Label
var _tiger_proto: Node2D
var _rock_proto: Node2D
var _log_proto: Node2D
var _player_start := Vector2(160, 284)
var _tiger_start := Vector2(-160, 324)
var _obstacle_spawn := Vector2(700, 324)


func _build_world() -> void:
	_tiger_x = _tiger_start.x
	_speed = base_speed

	var ground_body := get_node_or_null("GroundCollision") as Node2D
	if ground_body != null:
		ground_top = ground_body.position.y - 16.0

	_player_start = _marker_position("PlayerStart", _player_start)
	_tiger_start = _marker_position("TigerStart", Vector2(-160, ground_top))
	_obstacle_spawn = _marker_position("ObstacleSpawn", Vector2(700, ground_top))
	_tiger_x = _tiger_start.x

	# Latar: kalau gambar sudah dipasang, sembunyikan pohon blok.
	var sky := get_node_or_null("Placeholders/Sky") as Placeholder
	_bg_root = get_node_or_null("Placeholders/BgTrees") as Node2D
	if _bg_root != null:
		for child in _bg_root.get_children():
			if child is Node2D:
				_bg_trees.append(child)
		_bg_root.visible = sky == null or sky.art == null

	var ground_art := get_node_or_null("Placeholders/Ground") as Placeholder
	var moss := get_node_or_null("Placeholders/Moss") as CanvasItem
	if moss != null and ground_art != null:
		moss.visible = ground_art.art == null

	# Pemain (dikendalikan skrip, bukan input bebas).
	var scene: PackedScene = player_scene
	if scene == null:
		scene = preload("res://scenes/player.tscn")
	_player = scene.instantiate() as CharacterBody2D
	_player.position = _player_start
	if _player is BinarPlayer:
		_player.control_mode = BinarPlayer.ControlMode.SCRIPT
	if _player.has_node("AnimatedSprite2D"):
		var spr := _player.get_node("AnimatedSprite2D") as AnimatedSprite2D
		spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		if player_frames != null:
			spr.sprite_frames = player_frames
	add_child(_player)

	# Harimau pengejar: duplikat prototipe yang ada di scene.
	_tiger_proto = get_node_or_null("Placeholders/TigerPrototype") as Node2D
	if _tiger_proto != null:
		_tiger = _tiger_proto.duplicate() as Node2D
		_tiger.visible = true
		_tiger.position = Vector2(_tiger_x, ground_top)
		add_child(_tiger)
		_tiger_proto.visible = false

	_rock_proto = get_node_or_null("Placeholders/RockPrototype") as Node2D
	_log_proto = get_node_or_null("Placeholders/LogPrototype") as Node2D
	if _rock_proto != null:
		_rock_proto.visible = false
	if _log_proto != null:
		_log_proto.visible = false

	_danger_label = UI.label("", 17, Color("e8a9a9"), HORIZONTAL_ALIGNMENT_CENTER)
	_danger_label.size = Vector2(360, 26)
	_danger_label.position = Vector2(140, 96)
	_danger_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.7))
	_danger_label.add_theme_constant_override("outline_size", 5)
	_hud_layer.add_child(_danger_label)


func _marker_position(node_name: String, fallback: Vector2) -> Vector2:
	var marker := get_node_or_null(node_name) as Node2D
	return marker.position if marker != null else fallback


func _game_tick(delta: float) -> void:
	_elapsed += delta
	var progress := clampf(_elapsed / duration, 0.0, 1.0)
	_speed = base_speed + max_speed_bonus * progress

	# Latar bergerak.
	if _bg_root != null and _bg_root.visible:
		for d in _bg_trees:
			d.position.x -= _speed * 0.35 * delta
			if d.position.x < -120.0:
				d.position.x += 760.0

	# Lompat.
	var want_jump := Input.is_action_just_pressed("jump") or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	if want_jump and _player.is_on_floor():
		_player.velocity.y = jump_velocity

	# Harimau merayap makin cepat.
	var creep := tiger_creep_base + tiger_creep_bonus * progress
	_tiger_x += creep * delta
	if _tiger != null:
		_tiger.position.x = _tiger_x
	var gap := _player.position.x - _tiger_x
	_danger_label.text = "Harimau dekat!" if gap < 150.0 else ""
	if _tiger_x >= _player.position.x - 70.0:
		_finish(false)
		return

	# Spawn rintangan.
	_spawn_timer -= delta
	if _spawn_timer <= 0.0:
		_spawn_timer = maxf(1.45 - 0.6 * progress, 0.8)
		_spawn_obstacle()

	# Gerakkan rintangan.
	for ob in _obstacles.duplicate():
		ob.position.x -= _speed * delta
		if ob.position.x < -80.0:
			_remove_obstacle(ob)
			_passed += 1
			_collect_coin(2)


func _spawn_obstacle() -> void:
	var ob := Area2D.new()
	var cs := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = obstacle_collision_size
	cs.shape = rs
	cs.position = Vector2(0, -obstacle_collision_size.y / 2.0)
	ob.add_child(cs)

	var proto := _rock_proto if randi() % 2 == 0 else _log_proto
	if proto != null:
		var visual := proto.duplicate() as Node2D
		visual.position = Vector2.ZERO
		visual.visible = true
		ob.add_child(visual)
	else:
		var log := ColorRect.new()
		log.color = Color("6b4a2b")
		log.position = Vector2(-15, -20)
		log.size = Vector2(30, 16)
		ob.add_child(log)
		var moss := ColorRect.new()
		moss.color = Color("4f8c3f")
		moss.position = Vector2(-15, -24)
		moss.size = Vector2(30, 6)
		ob.add_child(moss)

	ob.position = _obstacle_spawn
	ob.body_entered.connect(_on_obstacle_hit.bind(ob))
	add_child(ob)
	_obstacles.append(ob)


func _on_obstacle_hit(body: Node2D, ob: Node2D) -> void:
	if body != _player or ob.has_meta("hit"):
		return
	ob.set_meta("hit", true)

	if _absorb_hit():
		_remove_obstacle(ob)
		return

	_hits += 1
	_tiger_x += 55.0
	if _tiger != null:
		_tiger.position.x = _tiger_x
	_player.position.x -= 14.0
	_show_floating_text("Tersandung! Harimau makin dekat!", Color("e8a9a9"))
	var tw := create_tween()
	tw.tween_property(_player, "modulate", Color(1.0, 0.5, 0.5), 0.1)
	tw.tween_property(_player, "modulate", Color.WHITE, 0.25)
	_remove_obstacle(ob)


func _remove_obstacle(ob: Node2D) -> void:
	_obstacles.erase(ob)
	ob.queue_free()


func _time_up() -> void:
	var stars := 1
	if _hits == 0:
		stars = 3
	elif _hits <= 2:
		stars = 2
	_finish(true, stars, float(_passed))
