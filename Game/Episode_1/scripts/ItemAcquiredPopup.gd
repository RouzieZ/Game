class_name ItemAcquiredPopup
extends Control

const ITEM_TEXTURE_DIR: String = "res://assets/items/"
const AUTO_CLOSE_SECONDS: float = 20.0
const TEXT_COLOR: Color = Color("#e2e6ea")
const MUTED_COLOR: Color = Color("#8d98a8")
const ACCENT_COLOR: Color = Color("#d96f4d")

var dimmer: ColorRect
var popup_panel: PanelContainer
var item_image: TextureRect
var item_name_label: Label
var item_info_label: Label
var auto_close_timer: Timer
var pending_items: Array[String] = []
var current_item_id: String = ""
var closing: bool = false
var active_tween: Tween


func _ready() -> void:
	_build_ui()
	resized.connect(_apply_responsive_layout)
	hide()


func enqueue_item(item_id: String) -> void:
	if item_id.is_empty():
		return
	pending_items.append(item_id)
	if current_item_id.is_empty() and not closing:
		call_deferred("_show_next_item")


func is_displaying() -> bool:
	return visible or not pending_items.is_empty() or not current_item_id.is_empty()


func dismiss() -> void:
	if not visible or closing:
		return

	closing = true
	auto_close_timer.stop()
	if active_tween != null and active_tween.is_valid():
		active_tween.kill()

	active_tween = create_tween()
	active_tween.set_parallel(true)
	active_tween.tween_property(popup_panel, "scale", Vector2(0.96, 0.96), 0.18)
	active_tween.tween_property(popup_panel, "modulate:a", 0.0, 0.18)
	active_tween.tween_property(dimmer, "color:a", 0.0, 0.18)
	await active_tween.finished

	hide()
	current_item_id = ""
	closing = false
	if not pending_items.is_empty():
		call_deferred("_show_next_item")


func _show_next_item() -> void:
	if closing or not current_item_id.is_empty() or pending_items.is_empty():
		return

	current_item_id = pending_items.pop_front()
	item_name_label.text = GameState.get_item_title(current_item_id)
	item_info_label.text = "Вес: %d сл." % GameState.get_item_weight(current_item_id)
	item_image.texture = _load_item_texture(current_item_id)

	show()
	move_to_front()
	_apply_responsive_layout()
	await get_tree().process_frame

	popup_panel.pivot_offset = popup_panel.size * 0.5
	popup_panel.scale = Vector2(0.92, 0.92)
	popup_panel.modulate.a = 0.0
	dimmer.color.a = 0.0

	if active_tween != null and active_tween.is_valid():
		active_tween.kill()
	active_tween = create_tween()
	active_tween.set_parallel(true)
	active_tween.set_trans(Tween.TRANS_QUAD)
	active_tween.set_ease(Tween.EASE_OUT)
	active_tween.tween_property(popup_panel, "scale", Vector2.ONE, 0.28)
	active_tween.tween_property(popup_panel, "modulate:a", 1.0, 0.22)
	active_tween.tween_property(dimmer, "color:a", 0.66, 0.22)
	auto_close_timer.start(AUTO_CLOSE_SECONDS)


func _build_ui() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 300

	dimmer = ColorRect.new()
	dimmer.color = Color(0.005, 0.008, 0.012, 0.66)
	dimmer.set_anchors_preset(Control.PRESET_FULL_RECT)
	dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dimmer)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(center)

	popup_panel = PanelContainer.new()
	popup_panel.add_theme_stylebox_override("panel", UIManager.create_surface_style(0.94, 24))
	center.add_child(popup_panel)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 14)
	popup_panel.add_child(root)

	var header := HBoxContainer.new()
	root.add_child(header)

	var title := Label.new()
	title.text = "НОВЫЙ ПРЕДМЕТ"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", TEXT_COLOR)
	header.add_child(title)

	var close_button := Button.new()
	close_button.text = "×"
	close_button.tooltip_text = "Закрыть"
	close_button.custom_minimum_size = Vector2(42, 42)
	close_button.add_theme_font_size_override("font_size", 24)
	close_button.pressed.connect(dismiss)
	UIManager.style_menu_button(close_button, 8)
	header.add_child(close_button)

	var image_surface := PanelContainer.new()
	image_surface.size_flags_vertical = Control.SIZE_EXPAND_FILL
	image_surface.add_theme_stylebox_override("panel", _create_image_surface_style())
	root.add_child(image_surface)

	item_image = TextureRect.new()
	item_image.custom_minimum_size = Vector2(340, 340)
	item_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	item_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	item_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	image_surface.add_child(item_image)

	item_name_label = Label.new()
	item_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	item_name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	item_name_label.add_theme_font_size_override("font_size", 24)
	item_name_label.add_theme_color_override("font_color", ACCENT_COLOR)
	root.add_child(item_name_label)

	item_info_label = Label.new()
	item_info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	item_info_label.add_theme_color_override("font_color", MUTED_COLOR)
	root.add_child(item_info_label)

	auto_close_timer = Timer.new()
	auto_close_timer.one_shot = true
	auto_close_timer.timeout.connect(dismiss)
	add_child(auto_close_timer)


func _apply_responsive_layout() -> void:
	if popup_panel == null or item_image == null:
		return

	var viewport_size: Vector2 = get_viewport_rect().size
	var compact: bool = viewport_size.x <= 700.0 or viewport_size.y <= 620.0
	var popup_width: float = minf(viewport_size.x - (24.0 if compact else 64.0), 590.0)
	var popup_height: float = minf(viewport_size.y - (24.0 if compact else 56.0), 650.0)
	popup_panel.custom_minimum_size = Vector2(maxf(popup_width, 300.0), maxf(popup_height, 400.0))
	var image_size: float = minf(popup_width - 70.0, popup_height - 210.0)
	item_image.custom_minimum_size = Vector2.ONE * maxf(image_size, 190.0)


func _load_item_texture(item_id: String) -> Texture2D:
	var texture_path: String = "%s%s.png" % [ITEM_TEXTURE_DIR, item_id]
	if not ResourceLoader.exists(texture_path):
		return null
	return load(texture_path) as Texture2D


func _create_image_surface_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1, 1, 1, 0.12)
	style.set_corner_radius_all(6)
	style.content_margin_left = 12.0
	style.content_margin_top = 12.0
	style.content_margin_right = 12.0
	style.content_margin_bottom = 12.0
	return style
