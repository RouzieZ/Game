class_name InventoryScreen
extends Control

signal back_requested

const ITEM_TEXTURE_DIR: String = "res://assets/items/"
const VISIBLE_SLOT_COUNT: int = 6
const TEXT_COLOR: Color = Color("#e2e6ea")
const MUTED_COLOR: Color = Color("#8d98a8")
const ACCENT_COLOR: Color = Color("#d96f4d")

var modal_panel: PanelContainer
var item_grid: GridContainer
var weight_label: Label
var description_label: Label
var message_label: Label
var use_button: Button
var discard_button: Button
var selected_item_id: String = ""
var item_panels: Dictionary = {}


func _ready() -> void:
	_build_ui()
	GameState.state_changed.connect(refresh)
	resized.connect(_apply_responsive_layout)
	hide()


func open_screen() -> void:
	show()
	move_to_front()
	refresh()
	_apply_responsive_layout()


func refresh() -> void:
	if item_grid == null:
		return

	weight_label.text = "Вес рюкзака: %d / %d" % [
		GameState.get_inventory_weight(),
		GameState.INVENTORY_LIMIT
	]

	for child in item_grid.get_children():
		item_grid.remove_child(child)
		child.queue_free()
	item_panels.clear()

	if not selected_item_id.is_empty() and not GameState.has_item(selected_item_id):
		selected_item_id = ""

	var slot_count: int = maxi(VISIBLE_SLOT_COUNT, GameState.inventory.size())
	for slot_index in slot_count:
		if slot_index < GameState.inventory.size():
			_add_item_slot(GameState.inventory[slot_index])
		else:
			_add_empty_slot()

	_update_selection()


func _build_ui() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

	var dimmer := ColorRect.new()
	dimmer.color = Color(0.01, 0.015, 0.02, 0.72)
	dimmer.set_anchors_preset(Control.PRESET_FULL_RECT)
	dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dimmer)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(center)

	modal_panel = PanelContainer.new()
	modal_panel.add_theme_stylebox_override("panel", _create_panel_style())
	center.add_child(modal_panel)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 14)
	modal_panel.add_child(root)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 16)
	root.add_child(header)

	var title := Label.new()
	title.text = "Inventory / Инвентарь"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", TEXT_COLOR)
	header.add_child(title)

	weight_label = Label.new()
	weight_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	weight_label.add_theme_color_override("font_color", MUTED_COLOR)
	header.add_child(weight_label)

	var close_button := Button.new()
	close_button.text = "×"
	close_button.tooltip_text = "Закрыть"
	close_button.custom_minimum_size = Vector2(42, 42)
	close_button.add_theme_font_size_override("font_size", 24)
	close_button.pressed.connect(func() -> void: back_requested.emit())
	_style_icon_button(close_button)
	header.add_child(close_button)

	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(scroll)

	item_grid = GridContainer.new()
	item_grid.columns = 3
	item_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	item_grid.add_theme_constant_override("h_separation", 18)
	item_grid.add_theme_constant_override("v_separation", 18)
	scroll.add_child(item_grid)

	var details := PanelContainer.new()
	details.add_theme_stylebox_override("panel", _create_details_style())
	root.add_child(details)

	var details_row := HBoxContainer.new()
	details_row.add_theme_constant_override("separation", 14)
	details.add_child(details_row)

	var description_box := VBoxContainer.new()
	description_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	description_box.add_theme_constant_override("separation", 4)
	details_row.add_child(description_box)

	description_label = Label.new()
	description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description_label.add_theme_color_override("font_color", TEXT_COLOR)
	description_box.add_child(description_label)

	message_label = Label.new()
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message_label.add_theme_color_override("font_color", ACCENT_COLOR)
	description_box.add_child(message_label)

	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 8)
	details_row.add_child(actions)

	use_button = Button.new()
	use_button.text = "Использовать"
	use_button.custom_minimum_size = Vector2(130, 44)
	use_button.pressed.connect(_use_selected_item)
	_style_action_button(use_button)
	actions.add_child(use_button)

	discard_button = Button.new()
	discard_button.text = "Оставить"
	discard_button.custom_minimum_size = Vector2(110, 44)
	discard_button.pressed.connect(_discard_selected_item)
	_style_action_button(discard_button)
	actions.add_child(discard_button)


func _add_item_slot(item_id: String) -> void:
	var slot := PanelContainer.new()
	slot.custom_minimum_size = Vector2(190, 180)
	slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slot.add_theme_stylebox_override("panel", _create_slot_style(item_id == selected_item_id))
	item_grid.add_child(slot)
	item_panels[item_id] = slot

	var slot_content := VBoxContainer.new()
	slot_content.alignment = BoxContainer.ALIGNMENT_CENTER
	slot_content.add_theme_constant_override("separation", 6)
	slot.add_child(slot_content)

	var image_button := TextureButton.new()
	image_button.custom_minimum_size = Vector2(150, 138)
	image_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	image_button.size_flags_vertical = Control.SIZE_EXPAND_FILL
	image_button.ignore_texture_size = true
	image_button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	image_button.texture_normal = _load_item_texture(item_id)
	image_button.tooltip_text = GameState.get_item_description(item_id)
	image_button.pressed.connect(_select_item.bind(item_id))
	image_button.mouse_entered.connect(_set_slot_hover.bind(item_id, true))
	image_button.mouse_exited.connect(_set_slot_hover.bind(item_id, false))
	slot_content.add_child(image_button)

	var item_name := Label.new()
	item_name.text = "%s  ·  %d сл." % [
		GameState.get_item_title(item_id),
		GameState.get_item_weight(item_id)
	]
	item_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	item_name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	item_name.add_theme_color_override("font_color", TEXT_COLOR)
	slot_content.add_child(item_name)


func _add_empty_slot() -> void:
	var slot := PanelContainer.new()
	slot.custom_minimum_size = Vector2(190, 180)
	slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slot.add_theme_stylebox_override("panel", _create_empty_slot_style())
	item_grid.add_child(slot)

	var empty_label := Label.new()
	empty_label.text = "Пусто"
	empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	empty_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	empty_label.add_theme_color_override("font_color", Color(0.45, 0.49, 0.55, 0.55))
	slot.add_child(empty_label)


func _load_item_texture(item_id: String) -> Texture2D:
	var texture_path: String = "%s%s.png" % [ITEM_TEXTURE_DIR, item_id]
	if not ResourceLoader.exists(texture_path):
		return null
	return load(texture_path) as Texture2D


func _select_item(item_id: String) -> void:
	selected_item_id = item_id
	message_label.text = ""
	_update_selection()


func _set_slot_hover(item_id: String, hovered: bool) -> void:
	if not item_panels.has(item_id):
		return
	var panel := item_panels[item_id] as PanelContainer
	panel.add_theme_stylebox_override(
		"panel",
		_create_slot_style(item_id == selected_item_id, hovered)
	)


func _update_selection() -> void:
	for item_id in item_panels:
		var panel := item_panels[item_id] as PanelContainer
		panel.add_theme_stylebox_override(
			"panel",
			_create_slot_style(str(item_id) == selected_item_id)
		)

	if selected_item_id.is_empty():
		description_label.text = "Выберите предмет"
		use_button.disabled = true
		discard_button.disabled = true
		return

	description_label.text = "%s · %d сл.\n%s" % [
		GameState.get_item_title(selected_item_id),
		GameState.get_item_weight(selected_item_id),
		GameState.get_item_description(selected_item_id)
	]
	var availability: Dictionary = InventoryManager.get_use_availability(selected_item_id)
	use_button.disabled = not bool(availability.get("success", false))
	use_button.tooltip_text = "" if not use_button.disabled else str(availability.get("message", ""))
	discard_button.disabled = false


func _use_selected_item() -> void:
	var result: Dictionary = InventoryManager.use_item(selected_item_id)
	message_label.text = str(result.get("message", ""))
	refresh()


func _discard_selected_item() -> void:
	var result: Dictionary = InventoryManager.discard_item(selected_item_id)
	message_label.text = str(result.get("message", ""))
	selected_item_id = ""
	refresh()


func _apply_responsive_layout() -> void:
	if modal_panel == null or item_grid == null:
		return

	var viewport_size: Vector2 = get_viewport_rect().size
	var compact: bool = viewport_size.x <= 760.0
	var panel_width: float = minf(viewport_size.x - (20.0 if compact else 56.0), 1120.0)
	var panel_height: float = minf(viewport_size.y - (20.0 if compact else 48.0), 780.0)
	modal_panel.custom_minimum_size = Vector2(maxf(panel_width, 300.0), maxf(panel_height, 420.0))
	item_grid.columns = 2 if compact else 3


func _create_panel_style() -> StyleBoxFlat:
	var style: StyleBoxFlat = UIManager.create_surface_style(0.9, 26)
	style.content_margin_left = 26.0
	style.content_margin_top = 20.0
	style.content_margin_right = 26.0
	style.content_margin_bottom = 22.0
	return style


func _create_slot_style(selected: bool, hovered: bool = false) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = (
		Color(1, 1, 1, 0.15)
		if selected or hovered
		else Color(1, 1, 1, 0.07)
	)
	style.set_corner_radius_all(6)
	style.content_margin_left = 10.0
	style.content_margin_top = 8.0
	style.content_margin_right = 10.0
	style.content_margin_bottom = 8.0
	return style


func _create_empty_slot_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1, 1, 1, 0.035)
	style.set_corner_radius_all(6)
	return style


func _create_details_style() -> StyleBoxFlat:
	var style: StyleBoxFlat = UIManager.create_surface_style(0.5, 14)
	style.content_margin_left = 14.0
	style.content_margin_top = 10.0
	style.content_margin_right = 14.0
	style.content_margin_bottom = 10.0
	return style


func _style_icon_button(button: Button) -> void:
	UIManager.style_menu_button(button, 8)


func _style_action_button(button: Button) -> void:
	UIManager.style_menu_button(button, 10)
