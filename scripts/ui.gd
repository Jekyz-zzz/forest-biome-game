class_name UI
extends RefCounted
## Kumpulan pembuat elemen UI sederhana agar tampilan konsisten.

const CREAM := Color("f2ead8")
const GOLD := Color("f4c542")
const GREEN := Color("7ed957")
const DARK_GREEN := Color("2e5d33")
const RED := Color("e8a9a9")

const PANEL_BG := Color(0.07, 0.14, 0.09, 0.94)
const PANEL_BORDER := Color("4e7a3a")


static func label(
	text: String,
	font_size: int,
	color: Color = CREAM,
	align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT,
	wrap_width: int = 0
) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.horizontal_alignment = align
	if wrap_width > 0:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size = Vector2(wrap_width, 0)
	return l


static func title(text: String, font_size: int, color: Color = CREAM) -> Label:
	var l := label(text, font_size, color, HORIZONTAL_ALIGNMENT_CENTER)
	l.theme_type_variation = &"TitleLabel"  # font MagicSound, lihat ui_theme.tres
	l.add_theme_color_override("font_outline_color", Color(0.05, 0.1, 0.06, 0.9))
	l.add_theme_constant_override("outline_size", 8)
	return l


## Tampilan tombol (warna, papan kayu, font MagicSound) diatur di
## assets/ui_theme.tres. Di sini hanya ukuran font + efek hover membesar.
static func style_button(b: Button, font_size := 16) -> Button:
	b.add_theme_font_size_override("font_size", font_size)
	add_hover_motion(b)
	return b


# ------------------------------------------------------------ efek hover --

## Batas pembesaran saat hover: maksimal 6% dan maksimal ~6 px per sisi,
## supaya tombol lebar (mis. pilihan kuis) tidak menutupi tetangganya.
const HOVER_MAX_SCALE := 1.06
const HOVER_MAX_GROW_PX := 6.0
const HOVER_TIME := 0.12


## Tombol membesar halus dari tengah saat hover. Hanya mengubah `scale`
## (visual), bukan ukuran/posisi, jadi layout container tidak bergeser.
static func add_hover_motion(b: Button) -> void:
	if b.has_meta(&"ui_hover_motion"):
		return
	b.set_meta(&"ui_hover_motion", true)
	b.mouse_entered.connect(func() -> void: _hover_to(b, true))
	b.mouse_exited.connect(func() -> void: _hover_to(b, false))
	# Pivot selalu di tengah. Container me-reset scale saat menata ulang,
	# jadi scale hover dipasang lagi sesudahnya.
	b.resized.connect(func() -> void: (func() -> void: _sync_hover(b)).call_deferred())
	# Tombol yang di-disable saat masih di-hover (mis. pilihan kuis) mengecil lagi.
	b.draw.connect(func() -> void:
		if b.disabled and b.scale != Vector2.ONE:
			_hover_to(b, false))
	_sync_hover(b)


static func _hover_scale(b: Button) -> Vector2:
	var longest := maxf(maxf(b.size.x, b.size.y), 1.0)
	var s := minf(HOVER_MAX_SCALE, 1.0 + 2.0 * HOVER_MAX_GROW_PX / longest)
	return Vector2(s, s)


static func _hover_to(b: Button, on: bool) -> void:
	if not is_instance_valid(b) or not b.is_inside_tree():
		return
	b.pivot_offset = b.size / 2.0
	var target := _hover_scale(b) if on and not b.disabled else Vector2.ONE
	if b.has_meta(&"ui_hover_tween"):
		var old := b.get_meta(&"ui_hover_tween") as Tween
		if old != null and old.is_valid():
			old.kill()
	var tw := b.create_tween()
	tw.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(b, "scale", target, HOVER_TIME)
	b.set_meta(&"ui_hover_tween", tw)


static func _sync_hover(b: Button) -> void:
	if not is_instance_valid(b):
		return
	b.pivot_offset = b.size / 2.0
	if b.is_hovered() and not b.disabled:
		b.scale = _hover_scale(b)


static func button(text: String, font_size := 16, min_size := Vector2(140, 40)) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = min_size
	return style_button(b, font_size)


static func flat(bg: Color, radius := 10) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_corner_radius_all(radius)
	sb.set_content_margin_all(12)
	return sb


static func panel_box(min_size := Vector2.ZERO) -> PanelContainer:
	var p := PanelContainer.new()
	if min_size != Vector2.ZERO:
		p.custom_minimum_size = min_size
	var sb := flat(PANEL_BG, 14)
	sb.set_border_width_all(3)
	sb.border_color = PANEL_BORDER
	p.add_theme_stylebox_override("panel", sb)
	return p


static func vbox(spacing := 10) -> VBoxContainer:
	var c := VBoxContainer.new()
	c.add_theme_constant_override("separation", spacing)
	return c


static func hbox(spacing := 10) -> HBoxContainer:
	var c := HBoxContainer.new()
	c.add_theme_constant_override("separation", spacing)
	return c


## Pasang anchor tengah + arah tumbuh dua sisi, supaya kontrol
## selalu terpusat otomatis setelah ukurannya berubah.
static func center_control(ctrl: Control) -> Control:
	ctrl.anchor_left = 0.5
	ctrl.anchor_right = 0.5
	ctrl.anchor_top = 0.5
	ctrl.anchor_bottom = 0.5
	ctrl.grow_horizontal = Control.GROW_DIRECTION_BOTH
	ctrl.grow_vertical = Control.GROW_DIRECTION_BOTH
	return ctrl


static func full_rect(ctrl: Control) -> Control:
	ctrl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return ctrl


## Latar gelap semi-transparan untuk popup (memblokir klik di belakangnya).
static func dim(color := Color(0, 0, 0, 0.6)) -> ColorRect:
	var c := ColorRect.new()
	c.color = color
	full_rect(c)
	return c


static func circle_points(radius: float, point_count := 20) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in point_count:
		var ang := TAU * float(i) / float(point_count)
		pts.append(Vector2(cos(ang), sin(ang)) * radius)
	return pts


static func circle(radius := 10.0, color := GOLD) -> Polygon2D:
	var p := Polygon2D.new()
	p.polygon = circle_points(radius)
	p.color = color
	return p


static func star_points(radius: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 10:
		var ang := TAU * float(i) / 10.0 - PI / 2.0
		var r := radius if i % 2 == 0 else radius * 0.45
		pts.append(Vector2(cos(ang), sin(ang)) * r)
	return pts


static func star(radius := 12.0, color := GOLD) -> Polygon2D:
	var p := Polygon2D.new()
	p.polygon = star_points(radius)
	p.color = color
	return p


static func checkmark(scale := 1.0, color := GREEN) -> Line2D:
	var l := Line2D.new()
	l.points = PackedVector2Array([
		Vector2(-8, 2) * scale,
		Vector2(-2, 8) * scale,
		Vector2(10, -8) * scale,
	])
	l.width = 5.0 * scale
	l.default_color = color
	l.joint_mode = Line2D.LINE_JOINT_ROUND
	l.begin_cap_mode = Line2D.LINE_CAP_ROUND
	l.end_cap_mode = Line2D.LINE_CAP_ROUND
	return l
