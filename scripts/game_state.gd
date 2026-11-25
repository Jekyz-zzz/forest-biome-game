extends Node
## Autoload "GameState".
## Menyimpan koin, kartu power-up, progres bioma, pengaturan,
## dan menangani perpindahan scene dengan efek fade + tips loading.

const SAVE_PATH := "user://kebangkitan_save.json"
const UI_THEME_PATH := "res://assets/ui_theme.tres"
const WINDOWED_SIZE := Vector2i(1440, 810)

## Menu utama memakai rasio gambar latar (45:32) supaya tidak ter-crop.
const MENU_WINDOW_SIZE := Vector2i(1350, 960)
const MENU_CONTENT_SIZE := Vector2i(640, 455)
const GAME_CONTENT_SIZE := Vector2i(640, 360)

## Font drop-in: taruh file dengan salah satu nama ini di assets/fonts/
## dan font otomatis dipakai untuk seluruh UI.
const CUSTOM_FONT_PATHS: Array[String] = [
	"res://assets/fonts/ui_font.ttf",
	"res://assets/fonts/ui_font.otf",
	"res://assets/fonts/UI_Font.ttf",
	"res://assets/fonts/UI_Font.otf",
]

signal coins_changed(total_coins: int)

const LOADING_TIPS: Array[String] = [
	"Menumbuhkan tunas.",
	"Mengumpulkan embun.",
	"Menyusuri rimba.",
]

## Definisi semua kartu power-up.
const CARDS := {
	"freeze5": {
		"name": "Kartu Freeze 5 Detik",
		"desc": "Waktu berhenti 5 detik di awal permainan.",
		"color": Color("4fc3f7"),
	},
	"freeze10": {
		"name": "Kartu Freeze 10 Detik",
		"desc": "Waktu berhenti 10 detik di awal permainan.",
		"color": Color("0277bd"),
	},
	"protect1": {
		"name": "Kartu Perlindungan 1x Hit",
		"desc": "Kebal dari satu serangan.",
		"color": Color("ffb74d"),
	},
	"invincible": {
		"name": "Kartu Invincible",
		"desc": "Kebal sepanjang permainan.",
		"color": Color("f06292"),
	},
	"coin2x": {
		"name": "Kartu Double Koin",
		"desc": "Koin yang didapat berlipat dua.",
		"color": Color("ffd54f"),
	},
	"coin15": {
		"name": "Kartu Koin 1,5x",
		"desc": "Koin yang didapat naik 1,5 kali.",
		"color": Color("ffca28"),
	},
}

var coins := 0
var equipped_card := ""
var owned_cards: Dictionary = {}
var settings := {"music": true, "sfx": true}
var biome_progress: Dictionary = {}
var current_biome := "hujan"
var last_run: Dictionary = {}

## Jumlah bibit yang sudah ditanam per jenis (dari pembelian di toko).
var planted: Dictionary = {"meranti": 0, "akasia": 0, "bakau": 0}
## Kesuburan peta. Naik setiap beli bibit/pupuk, menentukan tahap hijau peta.
var fertility := 0

## Ambang fertility untuk tahap peta 0, 1, 2, 3. Ubah di sini kalau perlu.
const MAP_STAGE_THRESHOLDS: Array[int] = [0, 3, 6, 10]

## Efek tiap item toko: "plant" = jenis pohon yang ditanam (boleh kosong),
## "fertility" = tambahan kesuburan.
const PURCHASE_EFFECTS := {
	"meranti": {"plant": "meranti", "fertility": 1},
	"akasia": {"plant": "akasia", "fertility": 1},
	"bakau": {"plant": "bakau", "fertility": 1},
	"kompos": {"plant": "", "fertility": 1},
	"kandang": {"plant": "", "fertility": 1},
	"super": {"plant": "", "fertility": 2},
}

## Notifikasi kecil yang ditampilkan peta saat kembali dari bioma.
var pending_map_toast := ""
## Agar popup "semua bioma selesai" tidak muncul berulang-ulang tiap frame.
var ending_shown := false

var _fade_layer: CanvasLayer
var _fade_rect: ColorRect
var _tip_label: Label
var _switching := false
var _windowed_size := WINDOWED_SIZE


func _ready() -> void:
	_ensure_input_actions()
	load_game()
	_apply_ui_theme()
	_build_fade_layer()
	_center_window.call_deferred()


# ------------------------------------------------------------------ input --

func _ensure_input_actions() -> void:
	_add_key_action("move_left", [KEY_A, KEY_LEFT])
	_add_key_action("move_right", [KEY_D, KEY_RIGHT])
	_add_key_action("jump", [KEY_W, KEY_UP, KEY_SPACE])
	_add_key_action("pause", [KEY_ESCAPE, KEY_P])
	_add_key_action("toggle_fullscreen", [KEY_F11])


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_fullscreen"):
		_toggle_fullscreen()
		get_viewport().set_input_as_handled()


func _toggle_fullscreen() -> void:
	var fullscreen := DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	if fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		_apply_window_size(_windowed_size)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)


func _apply_window_size(target: Vector2i) -> void:
	var screen := DisplayServer.window_get_current_screen()
	var usable := DisplayServer.screen_get_usable_rect(screen)
	var size := target
	if size.x > usable.size.x or size.y > usable.size.y:
		var fit := minf(
			float(usable.size.x) / float(size.x),
			float(usable.size.y) / float(size.y)
		)
		size = Vector2i(int(float(size.x) * fit), int(float(size.y) * fit))
	DisplayServer.window_set_size(size)
	_center_window()


## Panggil saat masuk menu utama: rasio jendela mengikuti gambar latar.
func apply_menu_window() -> void:
	_windowed_size = MENU_WINDOW_SIZE
	var w := get_window()
	w.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	w.content_scale_size = MENU_CONTENT_SIZE
	w.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	w.content_scale_stretch = Window.CONTENT_SCALE_STRETCH_FRACTIONAL
	if DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_FULLSCREEN:
		_apply_window_size(MENU_WINDOW_SIZE)


## Panggil saat masuk scene gameplay: kembali ke rasio 16:9.
func apply_game_window() -> void:
	_windowed_size = WINDOWED_SIZE
	var w := get_window()
	w.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	w.content_scale_size = GAME_CONTENT_SIZE
	w.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	w.content_scale_stretch = Window.CONTENT_SCALE_STRETCH_FRACTIONAL
	if DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_FULLSCREEN:
		_apply_window_size(WINDOWED_SIZE)


func _center_window() -> void:
	var screen := DisplayServer.window_get_current_screen()
	var usable := DisplayServer.screen_get_usable_rect(screen)
	var size := DisplayServer.window_get_size()
	size.x = mini(size.x, usable.size.x)
	size.y = mini(size.y, usable.size.y)
	if size != DisplayServer.window_get_size():
		DisplayServer.window_set_size(size)
	var pos := usable.position + (usable.size - size) / 2
	DisplayServer.window_set_position(pos)


# ------------------------------------------------------------------- font --

func _apply_ui_theme() -> void:
	var theme: Theme = load(UI_THEME_PATH) as Theme
	if theme == null:
		return
	for path in CUSTOM_FONT_PATHS:
		if not ResourceLoader.exists(path):
			continue
		var font := load(path) as Font
		if font != null:
			theme.default_font = font
			break
	get_tree().root.theme = theme


func _add_key_action(action_name: String, keys: Array) -> void:
	if InputMap.has_action(action_name):
		return
	InputMap.add_action(action_name)
	for key in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = key
		InputMap.action_add_event(action_name, ev)


# ------------------------------------------------------------------- fade --

func _build_fade_layer() -> void:
	_fade_layer = CanvasLayer.new()
	_fade_layer.layer = 100
	add_child(_fade_layer)

	_fade_rect = ColorRect.new()
	_fade_rect.color = Color(0, 0, 0, 1.0)
	_fade_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade_rect.modulate.a = 0.0
	_fade_layer.add_child(_fade_rect)

	_tip_label = Label.new()
	_tip_label.text = ""
	_tip_label.add_theme_font_size_override("font_size", 14)
	_tip_label.add_theme_color_override("font_color", Color("cfe3ba"))
	_tip_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_tip_label.position.y -= 40.0
	_tip_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tip_label.modulate.a = 0.0
	_fade_layer.add_child(_tip_label)


func change_scene(scene_path: String) -> void:
	## Pindah scene dengan fade hitam + tips loading acak.
	if _switching:
		return
	_switching = true
	_tip_label.text = LOADING_TIPS.pick_random()
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(_fade_rect, "modulate:a", 1.0, 0.3)
	tw.tween_property(_tip_label, "modulate:a", 1.0, 0.3)
	await tw.finished
	if scene_path.contains("main_menu"):
		apply_menu_window()
	else:
		apply_game_window()
	get_tree().change_scene_to_file(scene_path)
	await get_tree().process_frame
	await get_tree().process_frame
	var tw2 := create_tween()
	tw2.set_parallel(true)
	tw2.tween_property(_fade_rect, "modulate:a", 0.0, 0.3)
	tw2.tween_property(_tip_label, "modulate:a", 0.0, 0.3)
	await tw2.finished
	_switching = false


# ------------------------------------------------------------------- save --

func save_game() -> void:
	var data := {
		"coins": coins,
		"equipped_card": equipped_card,
		"owned_cards": owned_cards,
		"settings": settings,
		"biome_progress": biome_progress,
		"planted": planted,
		"fertility": fertility,
	}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify(data, "\t"))
	f.close()


func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	var data: Dictionary = parsed
	coins = int(data.get("coins", 0))
	equipped_card = String(data.get("equipped_card", ""))

	var loaded_cards: Dictionary = data.get("owned_cards", {})
	owned_cards.clear()
	for card_id in loaded_cards:
		owned_cards[card_id] = int(loaded_cards[card_id])

	var loaded_settings: Dictionary = data.get("settings", {})
	settings.merge(loaded_settings, true)

	var loaded_progress: Dictionary = data.get("biome_progress", {})
	biome_progress.clear()
	for biome_id in loaded_progress:
		var p: Dictionary = loaded_progress[biome_id]
		biome_progress[biome_id] = {
			"saved": bool(p.get("saved", false)),
			"quiz_done": bool(p.get("quiz_done", false)),
			"quiz_best": float(p.get("quiz_best", 0.0)),
		}

	## Save lama tanpa data tanam tetap aman: default 0.
	var loaded_planted: Variant = data.get("planted", {})
	for tree_id in planted:
		var count := 0
		if typeof(loaded_planted) == TYPE_DICTIONARY:
			count = int(loaded_planted.get(tree_id, 0))
		planted[tree_id] = maxi(count, 0)
	fertility = maxi(int(data.get("fertility", 0)), 0)


# ---------------------------------------------------------------- progres --

func get_progress(biome_id: String) -> Dictionary:
	if not biome_progress.has(biome_id):
		biome_progress[biome_id] = {
			"saved": false,
			"quiz_done": false,
			"quiz_best": 0.0,
		}
	return biome_progress[biome_id]


func is_biome_saved(biome_id: String) -> bool:
	return bool(get_progress(biome_id)["saved"])


func is_biome_completed(biome_id: String) -> bool:
	var p := get_progress(biome_id)
	return bool(p["saved"]) and bool(p["quiz_done"])


## Bioma pembuka. Mangrove baru terbuka setelah dua hutan ini selesai.
const STARTER_BIOMES: Array[String] = ["hujan", "sabana"]


func is_biome_unlocked(biome_id: String) -> bool:
	if biome_id in STARTER_BIOMES:
		return true
	return is_biome_completed("hujan") and is_biome_completed("sabana")


func all_biomes_completed() -> bool:
	for biome_id in BiomeData.BIOMES:
		if not is_biome_completed(biome_id):
			return false
	return true


func mark_biome_saved(biome_id: String) -> void:
	get_progress(biome_id)["saved"] = true
	save_game()


func mark_quiz_done(biome_id: String, score_percent: float) -> void:
	var p := get_progress(biome_id)
	p["quiz_done"] = true
	p["quiz_best"] = maxf(float(p["quiz_best"]), score_percent)
	save_game()
	if not all_biomes_completed():
		pending_map_toast = "Satu hutan telah pulih. Hutan lain menunggu uluran tanganmu."


# ------------------------------------------------------------------- koin --

func add_coins(amount: int) -> void:
	coins += maxi(amount, 0)
	coins_changed.emit(coins)
	save_game()


func spend_coins(amount: int) -> bool:
	if coins < amount:
		return false
	coins -= amount
	coins_changed.emit(coins)
	save_game()
	return true


# ----------------------------------------------------------------- tanam --

## Catat pembelian item toko (bibit/pupuk) supaya peta makin hijau.
func record_purchase(item_id: String) -> void:
	if not PURCHASE_EFFECTS.has(item_id):
		push_warning("record_purchase: item tidak dikenal '%s'" % item_id)
		return
	var effect: Dictionary = PURCHASE_EFFECTS[item_id]
	var plant_id := String(effect.get("plant", ""))
	if plant_id != "":
		planted[plant_id] = int(planted.get(plant_id, 0)) + 1
	fertility += int(effect.get("fertility", 0))
	save_game()


## Tahap kehijauan peta (0-3) berdasarkan fertility.
func get_map_stage() -> int:
	var stage := 0
	for i in range(MAP_STAGE_THRESHOLDS.size()):
		if fertility >= MAP_STAGE_THRESHOLDS[i]:
			stage = i
	return stage


# ------------------------------------------------------------------ kartu --

func add_card(card_id: String) -> void:
	owned_cards[card_id] = int(owned_cards.get(card_id, 0)) + 1
	save_game()


func equip_card(card_id: String) -> void:
	equipped_card = card_id
	save_game()


func coin_multiplier() -> float:
	if equipped_card == "coin2x":
		return 2.0
	if equipped_card == "coin15":
		return 1.5
	return 1.0


func multiplier_note() -> String:
	if equipped_card == "coin2x":
		return "Bonus x2 dari kartu aktif!"
	if equipped_card == "coin15":
		return "Bonus x1,5 dari kartu aktif!"
	return ""


func random_card_id() -> String:
	## Kartu acak dengan bobot (semakin langka bobotnya kecil).
	var weighted := {
		"freeze5": 22,
		"freeze10": 12,
		"protect1": 18,
		"coin15": 20,
		"coin2x": 16,
		"invincible": 12,
	}
	var total := 0
	for card_id in weighted:
		total += int(weighted[card_id])
	var roll := randi_range(1, total)
	for card_id in weighted:
		roll -= int(weighted[card_id])
		if roll <= 0:
			return card_id
	return "freeze5"
