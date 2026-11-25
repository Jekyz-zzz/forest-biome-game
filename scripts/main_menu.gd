extends Control
## Menu utama: latar hutan + papan penunjuk arah dengan tombol
## PLAY / SETTING / EXIT di sisi kanan.
##
## Font tombol memakai assets/fonts/MagicSound.ttf.
## Tombol diberi efek hover: membesar, menyala, dan bergoyang halus.
## Ganti gambar latar lewat node "Background" di scenes/main_menu.tscn.

const MENU_FONT_PATH := "res://assets/fonts/MagicSound.ttf"

const INK := Color("4a2a10")
const INK_HOVER := Color("5c3616")
const INK_PRESSED := Color("38200c")
const CREAM_OUTLINE := Color("f5e6b8")
const SHADOW := Color(0.15, 0.08, 0.02, 0.55)

## Ukuran font teks papan, seragam untuk PLAY/SETTING/EXIT. 12 dipilih agar
## "SETTING" (~102 px) muat di badan papan (~120 px) dengan margin.
const PLANK_FONT_SIZE := 12

@onready var _background: TextureRect = $Background
@onready var _play_button: Button = $Planks/PlayButton
@onready var _setting_button: Button = $Planks/SettingButton
@onready var _exit_button: Button = $Planks/ExitButton
@onready var _credits_button: Button = $CreditsButton

var _menu_font: Font


func _ready() -> void:
	GameState.apply_menu_window()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_menu_font = load(MENU_FONT_PATH) as Font
	_background.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR

	_style_plank(_play_button, _on_start)
	_style_plank(_setting_button, _open_settings)
	_style_plank(_exit_button, _on_exit)
	_style_credits(_credits_button)


# ------------------------------------------------------------------ gaya ----

func _style_plank(b: Button, action: Callable) -> void:
	b.flat = true
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.set_meta("base_rotation", b.rotation)

	if _menu_font != null:
		b.add_theme_font_override("font", _menu_font)
	b.add_theme_font_size_override("font_size", PLANK_FONT_SIZE)
	b.add_theme_color_override("font_color", INK)
	b.add_theme_color_override("font_hover_color", INK_HOVER)
	b.add_theme_color_override("font_pressed_color", INK_PRESSED)
	b.add_theme_color_override("font_focus_color", INK)
	b.add_theme_color_override("font_outline_color", CREAM_OUTLINE)
	b.add_theme_constant_override("outline_size", 6)
	b.add_theme_color_override("font_shadow_color", SHADOW)
	b.add_theme_constant_override("shadow_offset_x", 0)
	b.add_theme_constant_override("shadow_offset_y", 3)
	b.add_theme_constant_override("shadow_outline_size", 3)

	# Area tombol menutupi seluruh papan (ekor sampai ujung panah); teks
	# diletakkan di tengah BADAN papan lewat margin kiri/kanan dari metadata
	# node (text_margin_left/right, bisa diatur di Inspector).
	var empty := StyleBoxEmpty.new()
	empty.set_content_margin_all(0)
	empty.content_margin_left = float(b.get_meta("text_margin_left", 0.0))
	empty.content_margin_right = float(b.get_meta("text_margin_right", 0.0))
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		b.add_theme_stylebox_override(state, empty)

	b.pressed.connect(action)
	b.mouse_entered.connect(_on_plank_hover.bind(b, true))
	b.mouse_exited.connect(_on_plank_hover.bind(b, false))
	b.button_down.connect(_on_plank_down.bind(b))
	b.button_up.connect(_on_plank_up.bind(b))


func _style_credits(b: Button) -> void:
	b.flat = true
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	if _menu_font != null:
		b.add_theme_font_override("font", _menu_font)
	b.add_theme_font_size_override("font_size", 16)
	b.add_theme_color_override("font_color", CREAM_OUTLINE)
	b.add_theme_color_override("font_hover_color", Color.WHITE)
	b.add_theme_color_override("font_pressed_color", Color("d9c88f"))
	b.add_theme_color_override("font_outline_color", Color(0.12, 0.07, 0.02, 0.9))
	b.add_theme_constant_override("outline_size", 5)

	var empty := StyleBoxEmpty.new()
	empty.set_content_margin_all(0)
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		b.add_theme_stylebox_override(state, empty)

	b.pressed.connect(_open_credits)
	b.mouse_entered.connect(_on_credits_hover.bind(b, true))
	b.mouse_exited.connect(_on_credits_hover.bind(b, false))


# ----------------------------------------------------------------- hover ----

func _on_plank_hover(b: Button, on: bool) -> void:
	_stop_pulse(b)

	if on:
		var tw := create_tween()
		tw.set_parallel(true)
		tw.set_trans(Tween.TRANS_BACK)
		tw.set_ease(Tween.EASE_OUT)
		tw.tween_property(b, "scale", Vector2(1.08, 1.08), 0.18)
		tw.tween_property(b, "modulate", Color(1.15, 1.1, 0.95), 0.18)

		var base: float = float(b.get_meta("base_rotation", 0.0))
		var pulse := create_tween().set_loops()
		pulse.set_trans(Tween.TRANS_SINE)
		pulse.set_ease(Tween.EASE_IN_OUT)
		pulse.tween_property(b, "rotation", base + 0.018, 0.4)
		pulse.tween_property(b, "rotation", base - 0.018, 0.4)
		b.set_meta("pulse", pulse)
	else:
		var base: float = float(b.get_meta("base_rotation", 0.0))
		var tw := create_tween()
		tw.set_parallel(true)
		tw.set_trans(Tween.TRANS_SINE)
		tw.tween_property(b, "scale", Vector2.ONE, 0.15)
		tw.tween_property(b, "modulate", Color.WHITE, 0.15)
		tw.tween_property(b, "rotation", base, 0.15)


func _on_plank_down(b: Button) -> void:
	_stop_pulse(b)
	var tw := create_tween()
	tw.tween_property(b, "scale", Vector2(0.96, 0.96), 0.06)


func _on_plank_up(b: Button) -> void:
	var target := Vector2(1.08, 1.08) if b.is_hovered() else Vector2.ONE
	var tw := create_tween()
	tw.tween_property(b, "scale", target, 0.08)


func _stop_pulse(b: Button) -> void:
	if not b.has_meta("pulse"):
		return
	var old: Tween = b.get_meta("pulse")
	if old != null and old.is_valid():
		old.kill()
	b.remove_meta("pulse")


func _on_credits_hover(b: Button, on: bool) -> void:
	var tw := create_tween()
	tw.set_parallel(true)
	tw.set_trans(Tween.TRANS_SINE)
	tw.tween_property(b, "modulate", Color(1.2, 1.15, 0.95) if on else Color.WHITE, 0.12)


# ------------------------------------------------------------------ aksi ----

func _on_start() -> void:
	GameState.change_scene("res://scenes/intro.tscn")


func _on_exit() -> void:
	get_tree().quit()


func _open_settings() -> void:
	var dim := UI.dim()
	add_child(dim)
	var box := UI.panel_box(Vector2(280, 0))
	UI.center_control(box)
	add_child(box)

	var v := UI.vbox(12)
	box.add_child(v)
	v.add_child(_popup_title("PENGATURAN"))

	v.add_child(_make_toggle("Musik", "music"))
	v.add_child(_make_toggle("Efek Suara", "sfx"))

	var close := UI.button("Tutup", 16)
	close.pressed.connect(_close_popup.bind(dim, box))
	v.add_child(close)


func _open_credits() -> void:
	var dim := UI.dim()
	add_child(dim)
	var box := UI.panel_box(Vector2(420, 0))
	UI.center_control(box)
	add_child(box)

	var v := UI.vbox(10)
	box.add_child(v)
	v.add_child(_popup_title("KREDIT"))
	v.add_child(UI.label(
		"Rimbana - game edukasi hutan nusantara.",
		14, UI.CREAM, HORIZONTAL_ALIGNMENT_CENTER, 360
	))
	v.add_child(UI.label(
		"Dibuat dengan Godot 4.",
		14, UI.CREAM, HORIZONTAL_ALIGNMENT_CENTER
	))
	v.add_child(UI.label(
		"Font menu: Magic Sound.",
		12, Color(0.85, 0.9, 0.82, 0.8), HORIZONTAL_ALIGNMENT_CENTER
	))

	var close := UI.button("Tutup", 16)
	close.pressed.connect(_close_popup.bind(dim, box))
	v.add_child(close)


func _popup_title(text: String) -> Label:
	var l := UI.label(text, 22, UI.CREAM, HORIZONTAL_ALIGNMENT_CENTER)
	if _menu_font != null:
		l.add_theme_font_override("font", _menu_font)
	l.add_theme_font_size_override("font_size", 24)
	l.add_theme_color_override("font_outline_color", Color(0.05, 0.1, 0.06, 0.9))
	l.add_theme_constant_override("outline_size", 6)
	return l


## Ikon pengaturan suara: [nyala (tanpa coret), mati (dicoret)].
const SOUND_ICONS := {
	"music": ["res://assets/ui/buttons/btn_sound.png", "res://assets/ui/buttons/btn_mute_music.png"],
	"sfx": ["res://assets/ui/buttons/btn_speaker.png", "res://assets/ui/buttons/btn_mute_sound.png"],
}
## Ukuran tampil ikon (sama untuk semua ikon, apa pun ukuran file-nya).
const SOUND_ICON_SIZE := Vector2(36, 36)
## Ikon "mati" sedikit diredupkan; penanda utamanya gambar coret.
const ICON_OFF_TINT := Color(1, 1, 1, 0.75)


## Baris pengaturan: tombol ikon (toggle) + label status.
## Tombol "pressed" = suara nyala, sama seperti CheckBox sebelumnya.
func _make_toggle(text: String, key: String) -> Control:
	var row := UI.hbox(10)

	var icon := TextureButton.new()
	icon.toggle_mode = true
	icon.ignore_texture_size = true
	icon.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	icon.custom_minimum_size = SOUND_ICON_SIZE
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon.set_meta("icons", SOUND_ICONS[key])
	icon.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	icon.button_pressed = bool(GameState.settings.get(key, true))
	row.add_child(icon)

	var status := UI.label("", 16, UI.CREAM)
	if _menu_font != null:
		status.add_theme_font_override("font", _menu_font)
	status.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	status.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_child(status)

	_show_toggle_state(icon, status, text, icon.button_pressed)
	icon.toggled.connect(_on_toggle.bind(key))
	icon.toggled.connect(func(on: bool) -> void: _show_toggle_state(icon, status, text, on))
	UI.add_hover_motion(icon)
	return row


func _show_toggle_state(icon: TextureButton, status: Label, text: String, on: bool) -> void:
	status.text = "%s: %s" % [text, "Nyala" if on else "Mati"]
	var paths: Array = icon.get_meta("icons", [])
	if paths.size() == 2:
		icon.texture_normal = load(paths[0] if on else paths[1]) as Texture2D
	icon.modulate = Color.WHITE if on else ICON_OFF_TINT


func _on_toggle(on: bool, key: String) -> void:
	GameState.settings[key] = on
	GameState.save_game()


func _close_popup(a: CanvasItem, b: CanvasItem) -> void:
	a.queue_free()
	b.queue_free()
