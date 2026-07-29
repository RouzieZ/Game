extends Control

const DESKTOP_MARGIN: int = 28
const MOBILE_MARGIN: int = 14
const CHOICE_BUTTON_HEIGHT: int = 56
const CHOICE_GRID_BUTTON_HEIGHT: int = 46
const CHOICE_GRID_MOBILE_HEIGHT: int = 60
const MOBILE_BREAKPOINT: int = 760
const TEXT_REVEAL_BASE_SPEED: float = 34.0
const TEXT_SCROLL_SMOOTHING: float = 8.0
const TEXT_SCROLL_BOTTOM_PADDING: float = 24.0
const GAME_INFO_PATH: String = "res://data/game_info.json"
const SETTINGS_SCREEN_PATH: String = "res://scenes/SettingsScreen.tscn"
const INVENTORY_SCREEN_PATH: String = "res://scenes/InventoryScreen.tscn"
const REST_SCREEN_PATH: String = "res://scenes/RestScreen.tscn"
const END_SCREEN_PATH: String = "res://scenes/EndScreen.tscn"
const ITEM_POPUP_PATH: String = "res://scenes/ItemAcquiredPopup.tscn"
const INVENTORY_ICON_PATH: String = "res://assets/ui/backpack.svg"
const STATUS_ICON_DIR: String = "res://assets/ui/status_"

const BACKGROUND_COLOR: Color = Color("#0d1116")
const PANEL_COLOR: Color = Color("#161b23")
const BUTTON_COLOR: Color = Color("#1f2937")
const BUTTON_HOVER_COLOR: Color = Color("#2a3545")
const BUTTON_PRESSED_COLOR: Color = Color("#18202d")
const BUTTON_DISABLED_COLOR: Color = Color("#11151c")
const TEXT_COLOR: Color = Color("#e2e6ea")
const MUTED_TEXT_COLOR: Color = Color("#7c8899")
const ACCENT_COLOR: Color = Color("#d96f4d")

var margin_container: MarginContainer
var root_container: VBoxContainer
var main_menu_container: VBoxContainer
var game_container: VBoxContainer
var settings_screen: Control
var inventory_screen: InventoryScreen
var rest_screen: RestScreen
var end_screen: EndScreen
var item_popup: ItemAcquiredPopup
var inventory_returns_to_rest: bool = false
var menu_status_label: Label
var continue_button: Button
var game_title_label: Label
var chapter_label: Label
var title_label: Label
var game_header: GridContainer
var heading_box: VBoxContainer
var content_grid: GridContainer
var info_panel: PanelContainer
var info_sidebar: VBoxContainer
var story_scroll: ScrollContainer
var body_label: RichTextLabel
var status_label: Label
var save_status_label: Label
var game_menu_button: Button
var game_menu_layer: Control
var game_menu_panel: PanelContainer
var choices_panel: PanelContainer
var choices_scroll: ScrollContainer
var choices_box: VBoxContainer
var skip_hint_label: Label
var choice_buttons: Array[Button] = []
var status_icon_buttons: Dictionary = {}
var status_icons_grid: GridContainer
var settings_returns_to_game: bool = false
var is_revealing_text: bool = false
var skip_text_reveal: bool = false
var reveal_generation: int = 0
var story_scroll_position: float = 0.0
var story_scroll_target: float = 0.0
var story_auto_scroll_active: bool = false


func _ready() -> void:
	_build_ui()
	StoryManager.scene_changed.connect(_render_scene)
	GameState.state_changed.connect(_render_status)
	GameState.item_added.connect(_on_item_added)
	SaveManager.save_changed.connect(_update_save_status)
	resized.connect(_apply_responsive_layout)
	_render_scene(StoryManager.get_current_scene())
	_update_save_status()
	_apply_responsive_layout()
	YandexSDK.init_sdk()
	YandexSDK.game_ready()


func _process(delta: float) -> void:
	if not story_auto_scroll_active or story_scroll == null:
		return

	var scroll_bar: VScrollBar = story_scroll.get_v_scroll_bar()
	var max_scroll: float = maxf(scroll_bar.max_value - scroll_bar.page, 0.0)
	story_scroll_target = clampf(story_scroll_target, 0.0, max_scroll)
	story_scroll_position = clampf(story_scroll_position, 0.0, max_scroll)

	var blend: float = 1.0 - exp(-TEXT_SCROLL_SMOOTHING * maxf(delta, 0.001))
	story_scroll_position = lerpf(story_scroll_position, story_scroll_target, blend)
	if absf(story_scroll_position - story_scroll_target) < 0.1:
		story_scroll_position = story_scroll_target

	story_scroll.scroll_vertical = int(round(story_scroll_position))


func _build_ui() -> void:
	var background := TextureRect.new()
	background.texture = load("res://ep_one.jpg")
	background.expand = true
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	margin_container = MarginContainer.new()
	margin_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(margin_container)

	root_container = VBoxContainer.new()
	root_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_container.add_theme_constant_override("separation", 12)
	margin_container.add_child(root_container)

	_build_main_menu()
	_build_game_screen()
	_build_game_menu()
	_build_settings_screen()
	_build_overlay_screens()
	_show_main_menu()


func _build_main_menu() -> void:
	main_menu_container = VBoxContainer.new()
	main_menu_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_menu_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_menu_container.alignment = BoxContainer.ALIGNMENT_CENTER
	main_menu_container.add_theme_constant_override("separation", 12)
	root_container.add_child(main_menu_container)

	var title := Label.new()
	title.text = _load_game_title()
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 42)
	title.add_theme_color_override("font_color", TEXT_COLOR)
	main_menu_container.add_child(title)

	var menu_buttons := VBoxContainer.new()
	menu_buttons.custom_minimum_size = Vector2(280, 0)
	menu_buttons.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	menu_buttons.add_theme_constant_override("separation", 8)
	main_menu_container.add_child(menu_buttons)

	_add_menu_button(menu_buttons, "Новая игра", _on_menu_new_game_pressed)
	continue_button = _add_menu_button(menu_buttons, "Продолжить", _on_menu_continue_pressed)
	_add_menu_button(menu_buttons, "Настройки", _on_menu_settings_pressed)
	_add_menu_button(menu_buttons, "Авторы", _on_menu_authors_pressed)
	_add_menu_button(menu_buttons, "Сбросить сохранение", _on_menu_reset_save_pressed)

	menu_status_label = Label.new()
	menu_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	menu_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	menu_status_label.add_theme_color_override("font_color", MUTED_TEXT_COLOR)
	main_menu_container.add_child(menu_status_label)


func _build_game_screen() -> void:
	game_container = VBoxContainer.new()
	game_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	game_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	game_container.add_theme_constant_override("separation", 12)
	root_container.add_child(game_container)

	game_header = GridContainer.new()
	game_header.columns = 2
	game_header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	game_header.add_theme_constant_override("h_separation", 20)
	game_header.add_theme_constant_override("v_separation", 8)
	game_container.add_child(game_header)

	heading_box = VBoxContainer.new()
	heading_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading_box.add_theme_constant_override("separation", 4)
	game_header.add_child(heading_box)

	game_title_label = Label.new()
	game_title_label.text = _load_game_title()
	game_title_label.add_theme_font_size_override("font_size", 16)
	game_title_label.add_theme_color_override("font_color", ACCENT_COLOR)
	heading_box.add_child(game_title_label)

	chapter_label = Label.new()
	chapter_label.add_theme_color_override("font_color", MUTED_TEXT_COLOR)
	heading_box.add_child(chapter_label)

	title_label = Label.new()
	title_label.add_theme_font_size_override("font_size", 28)
	title_label.add_theme_color_override("font_color", TEXT_COLOR)
	heading_box.add_child(title_label)

	var header_actions := HBoxContainer.new()
	header_actions.size_flags_horizontal = Control.SIZE_SHRINK_END
	header_actions.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	header_actions.add_theme_constant_override("separation", 4)
	game_header.add_child(header_actions)

	var inventory_button := Button.new()
	inventory_button.icon = load(INVENTORY_ICON_PATH) as Texture2D
	inventory_button.expand_icon = false
	inventory_button.tooltip_text = "Инвентарь"
	inventory_button.custom_minimum_size = Vector2(42, 46)
	inventory_button.focus_mode = Control.FOCUS_ALL
	inventory_button.pressed.connect(_open_inventory.bind(false))
	UIManager.style_menu_button(inventory_button, 8)
	header_actions.add_child(inventory_button)

	game_menu_button = Button.new()
	game_menu_button.text = "☰"
	game_menu_button.tooltip_text = "Меню"
	game_menu_button.custom_minimum_size = Vector2(46, 46)
	game_menu_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	game_menu_button.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	game_menu_button.focus_mode = Control.FOCUS_ALL
	game_menu_button.add_theme_font_size_override("font_size", 24)
	game_menu_button.pressed.connect(_toggle_game_menu)
	_style_burger_button(game_menu_button)
	header_actions.add_child(game_menu_button)

	content_grid = GridContainer.new()
	content_grid.columns = 2
	content_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_grid.add_theme_constant_override("h_separation", 18)
	content_grid.add_theme_constant_override("v_separation", 10)
	game_container.add_child(content_grid)

	story_scroll = ScrollContainer.new()
	story_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	story_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	story_scroll.resized.connect(_sync_story_width)
	content_grid.add_child(story_scroll)

	body_label = RichTextLabel.new()
	body_label.bbcode_enabled = true
	body_label.fit_content = true
	body_label.scroll_active = false
	body_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body_label.add_theme_font_size_override("normal_font_size", 20)
	body_label.add_theme_color_override("default_color", TEXT_COLOR)
	story_scroll.add_child(body_label)
	call_deferred("_sync_story_width")

	info_panel = PanelContainer.new()
	info_panel.custom_minimum_size.x = 350.0
	info_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	info_panel.add_theme_stylebox_override("panel", _create_info_panel_style())
	content_grid.add_child(info_panel)

	info_sidebar = VBoxContainer.new()
	info_sidebar.add_theme_constant_override("separation", 12)
	info_sidebar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_panel.add_child(info_sidebar)

	save_status_label = Label.new()
	save_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	save_status_label.add_theme_color_override("font_color", MUTED_TEXT_COLOR)
	info_sidebar.add_child(save_status_label)

	skip_hint_label = Label.new()
	skip_hint_label.text = "Пробел или касание: показать текст целиком"
	skip_hint_label.visible = false
	skip_hint_label.add_theme_color_override("font_color", MUTED_TEXT_COLOR)
	skip_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info_sidebar.add_child(skip_hint_label)

	status_label = Label.new()
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.add_theme_color_override("font_color", MUTED_TEXT_COLOR)
	info_sidebar.add_child(status_label)

	var status_icons_center := CenterContainer.new()
	status_icons_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status_icons_center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	info_sidebar.add_child(status_icons_center)

	status_icons_grid = GridContainer.new()
	status_icons_grid.columns = 2
	status_icons_grid.add_theme_constant_override("h_separation", 8)
	status_icons_grid.add_theme_constant_override("v_separation", 8)
	status_icons_center.add_child(status_icons_grid)

	_add_status_icon(status_icons_grid, "health")
	_add_status_icon(status_icons_grid, "fatigue")
	_add_status_icon(status_icons_grid, "hunger")
	_add_status_icon(status_icons_grid, "weight")
	_add_status_icon(status_icons_grid, "humanity")
	_add_status_icon(status_icons_grid, "survival")

	choices_panel = PanelContainer.new()
	choices_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	choices_panel.size_flags_vertical = Control.SIZE_SHRINK_END
	choices_panel.add_theme_stylebox_override("panel", _create_choices_panel_style())
	game_container.add_child(choices_panel)

	choices_scroll = ScrollContainer.new()
	choices_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	choices_scroll.size_flags_vertical = Control.SIZE_SHRINK_END
	choices_panel.add_child(choices_scroll)

	choices_box = VBoxContainer.new()
	choices_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	choices_box.size_flags_vertical = Control.SIZE_SHRINK_END
	choices_box.add_theme_constant_override("separation", 6)
	choices_scroll.add_child(choices_box)


func _add_menu_button(parent: Control, label_text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = label_text
	button.custom_minimum_size = Vector2(0, CHOICE_BUTTON_HEIGHT)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.focus_mode = Control.FOCUS_ALL
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.pressed.connect(callback)
	_style_button(button)
	parent.add_child(button)
	return button


func _show_main_menu(message: String = "") -> void:
	_close_game_menu()
	settings_returns_to_game = false
	if main_menu_container != null:
		main_menu_container.visible = true

	if game_container != null:
		game_container.visible = false

	if settings_screen != null:
		settings_screen.hide()
	_hide_game_overlays()

	choice_buttons.clear()
	_update_menu_state(message)
	YandexSDK.gameplay_stop()


func _show_game_screen() -> void:
	_close_game_menu()
	settings_returns_to_game = false
	if main_menu_container != null:
		main_menu_container.visible = false

	if settings_screen != null:
		settings_screen.visible = false
	_hide_game_overlays()

	if game_container != null:
		game_container.visible = true
		game_container.add_theme_color_override("background_color", PANEL_COLOR)

	_render_scene(StoryManager.get_current_scene())
	_update_save_status()
	call_deferred("_focus_first_available_choice")
	YandexSDK.gameplay_start()


func _update_menu_state(message: String = "") -> void:
	if continue_button != null:
		continue_button.disabled = not SaveManager.has_save()

	if menu_status_label != null:
		var save_text: String = "Сохранение найдено" if SaveManager.has_save() else "Сохранений нет"
		menu_status_label.text = save_text if message.is_empty() else "%s | %s" % [save_text, message]


func _on_menu_new_game_pressed() -> void:
	StoryManager.restart_story()
	_show_game_screen()


func _on_menu_continue_pressed() -> void:
	if SaveManager.load_local():
		StoryManager.last_result_text = ""
		_show_game_screen()
	else:
		_update_menu_state("Нет сохранения для загрузки.")


func _on_menu_settings_pressed() -> void:
	_show_settings_screen(false)


func _on_menu_authors_pressed() -> void:
	_update_menu_state("Авторы: интерактивная история «После звонка».")


func _on_menu_reset_save_pressed() -> void:
	if SaveManager.delete_save():
		_update_menu_state("Сохранение сброшено.")
	else:
		_update_menu_state("Не удалось сбросить сохранение: %s" % SaveManager.last_error)


func _build_game_menu() -> void:
	game_menu_layer = Control.new()
	game_menu_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	game_menu_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	game_menu_layer.z_index = 200
	game_menu_layer.hide()
	game_menu_layer.gui_input.connect(_on_game_menu_layer_input)
	add_child(game_menu_layer)

	game_menu_panel = PanelContainer.new()
	game_menu_panel.anchor_left = 1.0
	game_menu_panel.anchor_right = 1.0
	game_menu_panel.offset_left = -292.0
	game_menu_panel.offset_top = 82.0
	game_menu_panel.offset_right = -28.0
	game_menu_panel.offset_bottom = 318.0
	game_menu_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	game_menu_panel.add_theme_stylebox_override("panel", _create_info_panel_style())
	game_menu_layer.add_child(game_menu_panel)

	var menu_box := VBoxContainer.new()
	menu_box.add_theme_constant_override("separation", 6)
	game_menu_panel.add_child(menu_box)

	_add_game_menu_entry(menu_box, "Сохранить", _on_game_menu_save)
	_add_game_menu_entry(menu_box, "Загрузить", _on_game_menu_load)
	_add_game_menu_entry(menu_box, "Настройки", _on_game_menu_settings)
	_add_game_menu_entry(menu_box, "В главное меню", _on_game_menu_exit)


func _add_game_menu_entry(parent: Control, label_text: String, callback: Callable) -> void:
	var button := Button.new()
	button.text = label_text
	button.custom_minimum_size = Vector2(0, 46)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.focus_mode = Control.FOCUS_ALL
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.pressed.connect(callback)
	_style_choice_button(button)
	parent.add_child(button)


func _toggle_game_menu() -> void:
	if game_menu_layer.visible:
		_close_game_menu()
	else:
		game_menu_layer.show()
		game_menu_layer.move_to_front()


func _close_game_menu() -> void:
	if game_menu_layer != null:
		game_menu_layer.hide()


func _on_game_menu_layer_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
		_close_game_menu()
	elif event is InputEventScreenTouch and (event as InputEventScreenTouch).pressed:
		_close_game_menu()


func _on_game_menu_save() -> void:
	_close_game_menu()
	_on_save_pressed()


func _on_game_menu_load() -> void:
	_close_game_menu()
	_on_load_pressed()


func _on_game_menu_settings() -> void:
	_close_game_menu()
	_show_settings_screen(true)


func _on_game_menu_exit() -> void:
	_close_game_menu()
	_on_back_to_menu_pressed()


func _load_game_title() -> String:
	if not FileAccess.file_exists(GAME_INFO_PATH):
		return "После звонка"

	var file := FileAccess.open(GAME_INFO_PATH, FileAccess.READ)
	if file == null:
		return "После звонка"

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return "После звонка"

	var game_info: Dictionary = parsed as Dictionary
	return str(game_info.get("title", "После звонка"))


func _render_scene(scene: Dictionary) -> void:
	reveal_generation += 1
	var render_generation: int = reveal_generation
	is_revealing_text = false
	skip_text_reveal = false
	body_label.visible_characters = -1
	skip_hint_label.visible = false
	if choices_panel != null:
		choices_panel.show()

	if scene.is_empty():
		chapter_label.text = ""
		title_label.text = "Сцена не найдена"
		body_label.text = "Проверь data/story.json и current_scene_id."
		_render_choices([])
		_render_status()
		return

	var scene_type: String = str(scene.get("type", "story"))
	if scene_type == "camp" or bool(scene.get("camp", false)):
		_show_rest_screen(scene)
		return
	if scene_type == "ending":
		_show_end_screen(scene)
		return

	if rest_screen != null:
		rest_screen.hide()
	if inventory_screen != null:
		inventory_screen.hide()
	if end_screen != null:
		end_screen.hide()
	if main_menu_container != null and not main_menu_container.visible and settings_screen != null and not settings_screen.visible:
		game_container.show()

	chapter_label.text = str(scene.get("chapter", ""))
	title_label.text = str(scene.get("title", ""))
	body_label.add_theme_font_size_override("normal_font_size", int(GameState.text_size))
	var reaction_text: String = StoryManager.last_result_text
	StoryManager.last_result_text = ""
	var scene_text: String = str(scene.get("text", ""))
	var text_content: String = _compose_story_text(reaction_text, scene_text)
	var reaction_character_count: int = reaction_text.length()
	var should_settle_scroll: bool = false
	if GameState.text_reveal_animation:
		choices_box.visible = false
		choices_panel.hide()
		skip_hint_label.visible = true
		should_settle_scroll = await _reveal_body_text(
			text_content,
			render_generation,
			reaction_character_count
		)
		if render_generation != reveal_generation:
			return
		skip_hint_label.visible = false
	else:
		body_label.text = text_content
		body_label.visible_characters = -1
		call_deferred("_sync_story_width")
		_scroll_story_to_top()
	_render_status()
	var choices_value: Variant = scene.get("choices", [])
	var choices: Array = []
	if typeof(choices_value) == TYPE_ARRAY:
		choices = choices_value as Array
	_render_choices(choices)
	choices_box.visible = true
	choices_panel.show()
	if should_settle_scroll:
		await get_tree().process_frame
		if render_generation != reveal_generation:
			return
		await _settle_story_scroll(render_generation)


func _apply_responsive_layout() -> void:
	if margin_container == null:
		return

	var viewport_size: Vector2 = get_viewport_rect().size
	var compact: bool = viewport_size.x <= MOBILE_BREAKPOINT or viewport_size.y <= 560.0
	var margin_size: int = MOBILE_MARGIN if compact else DESKTOP_MARGIN
	var root_gap: int = 8 if compact else 12
	var choice_gap: int = 6

	margin_container.add_theme_constant_override("margin_left", margin_size)
	margin_container.add_theme_constant_override("margin_top", margin_size)
	margin_container.add_theme_constant_override("margin_right", margin_size)
	margin_container.add_theme_constant_override("margin_bottom", margin_size)

	if root_container != null:
		root_container.add_theme_constant_override("separation", root_gap)

	if main_menu_container != null:
		main_menu_container.add_theme_constant_override("separation", root_gap)

	if game_container != null:
		game_container.add_theme_constant_override("separation", root_gap)
	if game_title_label != null:
		game_title_label.visible = not compact
	if game_header != null:
		game_header.columns = 2
	if content_grid != null:
		content_grid.columns = 1 if compact else 2
	if info_panel != null:
		info_panel.custom_minimum_size.x = 0.0 if compact else 350.0
		info_panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN if compact else Control.SIZE_EXPAND_FILL
	if status_icons_grid != null:
		status_icons_grid.columns = 3 if compact else 2
		for status_button_value in status_icon_buttons.values():
			var status_button := status_button_value as Button
			status_button.custom_minimum_size = Vector2(76, 72) if compact else Vector2(118, 92)

	if game_menu_panel != null:
		game_menu_panel.offset_left = -278.0 if compact else -292.0
		game_menu_panel.offset_top = float(margin_size + 54)
		game_menu_panel.offset_right = -float(margin_size)
		game_menu_panel.offset_bottom = game_menu_panel.offset_top + 236.0

	if choices_box != null:
		choices_box.add_theme_constant_override("separation", choice_gap)
	_update_choices_layout(compact)

	_sync_story_width()


func _render_status() -> void:
	if status_label == null:
		return

	status_label.text = (
		"Здоровье: %s | Усталость: %s (%d/3) | Голод: %s (%d/2)\n" +
		"Человечность: %d | Выживание: %d | Вес рюкзака: %d/%d"
	) % [
		GameState.get_health_label(),
		GameState.get_fatigue_label(),
		GameState.fatigue,
		GameState.get_hunger_label(),
		GameState.hunger,
		GameState.humanity,
		GameState.survival,
		GameState.get_inventory_weight(),
		GameState.INVENTORY_LIMIT
	]
	_render_status_icons()


func _add_status_icon(parent: Control, status_id: String) -> void:
	var button := Button.new()
	button.custom_minimum_size = Vector2(118, 92)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_HELP
	button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UIManager.style_menu_button(button, 8)
	parent.add_child(button)
	status_icon_buttons[status_id] = button


func _render_status_icons() -> void:
	_set_status_icon("health", _get_health_icon_state(), _get_health_tooltip())
	_set_status_icon("fatigue", _get_fatigue_icon_state(), _get_fatigue_tooltip())
	_set_status_icon("hunger", _get_hunger_icon_state(), _get_hunger_tooltip())
	_set_status_icon("weight", _get_weight_icon_state(), _get_weight_tooltip())
	_set_status_icon("humanity", _get_humanity_icon_state(), _get_humanity_tooltip())
	_set_status_icon("survival", _get_survival_icon_state(), _get_survival_tooltip())


func _set_status_icon(status_id: String, state: String, tooltip: String) -> void:
	if not status_icon_buttons.has(status_id):
		return
	var button := status_icon_buttons[status_id] as Button
	var icon_path: String = "%s%s_%s.svg" % [STATUS_ICON_DIR, status_id, state]
	button.icon = load(icon_path) as Texture2D
	button.tooltip_text = tooltip


func _get_health_icon_state() -> String:
	match GameState.health:
		"normal":
			return "good"
		"wounded":
			return "warning"
		_:
			return "bad"


func _get_fatigue_icon_state() -> String:
	if GameState.fatigue == 0:
		return "good"
	if GameState.fatigue == 1:
		return "warning"
	return "bad"


func _get_hunger_icon_state() -> String:
	if GameState.hunger == 0:
		return "good"
	if GameState.hunger == 1:
		return "warning"
	return "bad"


func _get_weight_icon_state() -> String:
	var weight: int = GameState.get_inventory_weight()
	if weight <= 3:
		return "good"
	if weight <= 5:
		return "warning"
	return "bad"


func _get_humanity_icon_state() -> String:
	if GameState.humanity >= 7:
		return "good"
	if GameState.humanity >= 4:
		return "warning"
	return "bad"


func _get_survival_icon_state() -> String:
	if GameState.survival >= 7:
		return "good"
	if GameState.survival >= 4:
		return "warning"
	return "bad"


func _get_health_tooltip() -> String:
	match GameState.health:
		"normal":
			return "Здоровье: норма\nРанений нет."
		"wounded":
			return "Здоровье: ранен\nНужен бинт или аптечка."
		_:
			return "Здоровье: критическое\nРискованные действия могут привести к гибели."


func _get_fatigue_tooltip() -> String:
	match GameState.fatigue:
		0:
			return "Усталость: бодрый (0/3)\nГерой готов к нагрузке."
		1:
			return "Усталость: небольшая (1/3)\nСтоит найти время для отдыха."
		2:
			return "Усталость: измотан (2/3)\nОпасные действия становятся сложнее."
		_:
			return "Усталость: на грани (3/3)\nНекоторые действия могут быть недоступны."


func _get_hunger_tooltip() -> String:
	match GameState.hunger:
		0:
			return "Голод: сыт (0/2)\nЕда пока не требуется."
		1:
			return "Голод: голоден (1/2)\nСтоит поесть на ближайшем привале."
		_:
			return "Голод: сильный (2/2)\nНужна еда."


func _get_weight_tooltip() -> String:
	var weight: int = GameState.get_inventory_weight()
	var free_weight: int = maxi(GameState.INVENTORY_LIMIT - weight, 0)
	if weight <= 3:
		return "Рюкзак: %d/%d\nСвободно: %d сл." % [weight, GameState.INVENTORY_LIMIT, free_weight]
	if weight < GameState.INVENTORY_LIMIT:
		return "Рюкзак почти заполнен: %d/%d\nСвободно: %d сл." % [
			weight,
			GameState.INVENTORY_LIMIT,
			free_weight
		]
	return "Рюкзак заполнен: %d/%d\nНовые тяжёлые предметы не поместятся." % [
		weight,
		GameState.INVENTORY_LIMIT
	]


func _get_humanity_tooltip() -> String:
	if GameState.humanity >= 7:
		return "Человечность: %d/10\nГерой сохраняет сострадание." % GameState.humanity
	if GameState.humanity >= 4:
		return "Человечность: %d/10\nРешения героя остаются неоднозначными." % GameState.humanity
	return "Человечность: %d/10\nГерой всё чаще выбирает выживание любой ценой." % GameState.humanity


func _get_survival_tooltip() -> String:
	if GameState.survival >= 7:
		return "Выживание: %d/10\nГерой хорошо подготовлен к опасностям." % GameState.survival
	if GameState.survival >= 4:
		return "Выживание: %d/10\nГерой освоил основные навыки." % GameState.survival
	return "Выживание: %d/10\nОпыта пока недостаточно." % GameState.survival


func _sync_story_width() -> void:
	if story_scroll == null or body_label == null:
		return

	var width: float = maxf(story_scroll.size.x - 24.0, 240.0)
	body_label.custom_minimum_size = Vector2(width, body_label.custom_minimum_size.y)
	body_label.size = Vector2(width, body_label.size.y)


func _scroll_story_to_top() -> void:
	if story_scroll == null:
		return

	story_auto_scroll_active = false
	story_scroll_position = 0.0
	story_scroll_target = 0.0
	story_scroll.scroll_vertical = 0


func _render_choices(choices: Array) -> void:
	choice_buttons.clear()

	for child in choices_box.get_children():
		choices_box.remove_child(child)
		child.queue_free()

	if choices.is_empty():
		var restart_button := Button.new()
		restart_button.text = "Начать заново"
		restart_button.custom_minimum_size = Vector2(0, CHOICE_BUTTON_HEIGHT)
		restart_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		restart_button.focus_mode = Control.FOCUS_ALL
		restart_button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		restart_button.pressed.connect(StoryManager.restart_story)
		_style_choice_button(restart_button)
		choices_box.add_child(restart_button)
		_update_choices_layout()
		restart_button.call_deferred("grab_focus")
		return

	var choice_index: int = 1
	var current_row: HBoxContainer = null
	for choice_data in choices:
		var choice_value: Variant = choice_data
		if typeof(choice_value) != TYPE_DICTIONARY:
			continue

		var choice: Dictionary = choice_value as Dictionary
		var choice_id: String = str(choice.get("id", ""))
		if choice_index % 2 == 1:
			current_row = HBoxContainer.new()
			current_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			current_row.add_theme_constant_override("separation", 6)
			choices_box.add_child(current_row)

		var button := Button.new()
		button.text = "%d. %s" % [choice_index, str(choice.get("text", "Выбор"))]
		button.custom_minimum_size = Vector2(0, CHOICE_BUTTON_HEIGHT)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.focus_mode = Control.FOCUS_ALL
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.set_meta("choice_id", choice_id)

		var availability: Dictionary = StoryManager.get_choice_availability(choice)
		if not bool(availability.get("available", false)):
			button.disabled = true
			button.text += "  [%s]" % str(availability.get("reason", "недоступно"))

		button.pressed.connect(_on_choice_pressed.bind(choice_id))
		_style_button(button)
		_style_choice_button(button)
		current_row.add_child(button)
		choice_buttons.append(button)
		choice_index += 1

	_update_choices_layout()
	call_deferred("_focus_first_available_choice")


func _update_choices_layout(force_compact: Variant = null) -> void:
	if choices_box == null or choices_scroll == null:
		return

	var viewport_size: Vector2 = get_viewport_rect().size
	var compact: bool = (
		bool(force_compact)
		if force_compact != null
		else viewport_size.x <= MOBILE_BREAKPOINT or viewport_size.y <= 560.0
	)
	var button_height: int = CHOICE_GRID_MOBILE_HEIGHT if compact else CHOICE_GRID_BUTTON_HEIGHT
	var available_width: float = maxf(viewport_size.x - float((MOBILE_MARGIN if compact else DESKTOP_MARGIN) * 2), 280.0)
	choices_box.custom_minimum_size.x = available_width
	var gap: int = 6
	for child in choices_box.get_children():
		if child is HBoxContainer:
			(child as HBoxContainer).add_theme_constant_override("separation", gap)
			for row_child in child.get_children():
				if row_child is Button:
					var row_button := row_child as Button
					row_button.custom_minimum_size.y = button_height
					row_button.add_theme_font_size_override("font_size", 14 if compact else 16)
		elif child is Button:
			var full_width_button := child as Button
			full_width_button.custom_minimum_size.y = button_height
			full_width_button.add_theme_font_size_override("font_size", 14 if compact else 16)

	var row_count: int = maxi(choices_box.get_child_count(), 1)
	var rows_height: float = float(row_count * button_height + maxi(row_count - 1, 0) * gap)
	var maximum_height: float = 192.0 if compact else 150.0
	choices_scroll.custom_minimum_size.y = minf(maximum_height, rows_height)


func _on_choice_pressed(choice_id: String) -> void:
	StoryManager.select_choice(choice_id)


func _focus_first_available_choice() -> void:
	for button in choice_buttons:
		if not button.disabled:
			button.grab_focus()
			return


func _input(event: InputEvent) -> void:
	if (
		game_container == null
		or not game_container.visible
		or not is_revealing_text
		or (item_popup != null and item_popup.is_displaying())
	):
		return

	var should_skip: bool = false
	if event is InputEventKey:
		var key_event: InputEventKey = event as InputEventKey
		should_skip = (
			key_event.pressed
			and not key_event.echo
			and key_event.keycode in [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER]
		)
	elif event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event as InputEventMouseButton
		should_skip = mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_LEFT
	elif event is InputEventScreenTouch:
		var touch_event: InputEventScreenTouch = event as InputEventScreenTouch
		should_skip = touch_event.pressed

	if should_skip:
		_skip_text_reveal()
		get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	if game_container == null or not game_container.visible:
		return

	if not (event is InputEventKey):
		return

	var key_event: InputEventKey = event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return

	var choice_index: int = _get_numeric_choice_index(key_event.keycode)
	if choice_index == -1:
		return

	if choice_index >= choice_buttons.size():
		return

	var button: Button = choice_buttons[choice_index]
	if button.disabled:
		return

	var choice_id: String = str(button.get_meta("choice_id", ""))
	if choice_id.is_empty():
		return

	get_viewport().set_input_as_handled()
	_on_choice_pressed(choice_id)


func _get_numeric_choice_index(keycode: int) -> int:
	if keycode >= KEY_1 and keycode <= KEY_9:
		return int(keycode - KEY_1)

	if keycode >= KEY_KP_1 and keycode <= KEY_KP_9:
		return int(keycode - KEY_KP_1)

	return -1


func _style_button(button: Button) -> void:
	UIManager.style_menu_button(button)


func _style_choice_button(button: Button) -> void:
	UIManager.style_menu_button(button, 10)


func _style_burger_button(button: Button) -> void:
	var transparent := StyleBoxEmpty.new()
	var hover := StyleBoxFlat.new()
	hover.bg_color = Color(1, 1, 1, 0.15)
	hover.set_corner_radius_all(6)

	var pressed := StyleBoxFlat.new()
	pressed.bg_color = Color(1, 1, 1, 0.09)
	pressed.set_corner_radius_all(6)

	button.add_theme_stylebox_override("normal", transparent)
	button.add_theme_stylebox_override("focus", transparent)
	button.add_theme_stylebox_override("disabled", transparent)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_color_override("font_color", TEXT_COLOR)
	button.add_theme_color_override("font_hover_color", TEXT_COLOR)
	button.add_theme_color_override("font_pressed_color", TEXT_COLOR)


func _create_info_panel_style() -> StyleBoxFlat:
	var style: StyleBoxFlat = UIManager.create_surface_style(0.62, 16)
	style.content_margin_top = 14.0
	style.content_margin_bottom = 14.0
	return style


func _create_choices_panel_style() -> StyleBoxFlat:
	var style: StyleBoxFlat = UIManager.create_surface_style(0.58, 8)
	style.content_margin_top = 7.0
	style.content_margin_bottom = 7.0
	return style


func _skip_text_reveal() -> void:
	if not is_revealing_text:
		return

	skip_text_reveal = true
	story_auto_scroll_active = false


func _on_new_game_pressed() -> void:
	StoryManager.restart_story()
	_show_game_screen()


func _on_inventory_pressed() -> void:
	_open_inventory(false)


func _on_save_pressed() -> void:
	if SaveManager.save_local():
		_update_save_status("Игра сохранена.")
	else:
		_update_save_status("Ошибка сохранения: %s" % SaveManager.last_error)


func _on_load_pressed() -> void:
	if SaveManager.load_local():
		StoryManager.last_result_text = ""
		_show_game_screen()
		_update_save_status("Сохранение загружено.")
	else:
		_update_save_status("Нет сохранения для загрузки.")


func _on_delete_save_pressed() -> void:
	if SaveManager.delete_save():
		_update_save_status("Сохранение удалено.")
	else:
		_update_save_status("Не удалось удалить сохранение: %s" % SaveManager.last_error)


func _on_back_to_menu_pressed() -> void:
	_show_main_menu()


func _on_settings_back_pressed() -> void:
	if settings_returns_to_game:
		settings_returns_to_game = false
		if settings_screen != null:
			settings_screen.hide()
		if game_container != null:
			game_container.show()
		YandexSDK.gameplay_start()
		return

	_show_main_menu()


func _show_settings_screen(from_game: bool = false) -> void:
	settings_returns_to_game = from_game
	_close_game_menu()
	if main_menu_container != null:
		main_menu_container.visible = false

	if game_container != null:
		game_container.visible = false
	_hide_game_overlays()

	if settings_screen != null:
		settings_screen.show()
		settings_screen.set_z_index(100)
		move_child(settings_screen, get_child_count() - 1)

	YandexSDK.gameplay_stop()


func _build_settings_screen() -> void:
	var settings_scene := preload(SETTINGS_SCREEN_PATH).instantiate() as Control
	settings_scene.hide()
	settings_scene.set_anchors_preset(Control.PRESET_FULL_RECT)
	settings_scene.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	settings_scene.size_flags_vertical = Control.SIZE_EXPAND_FILL
	settings_scene.name = "SettingsScreenInstance"
	settings_scene.connect("back_to_menu", Callable(self, "_on_settings_back_pressed"))
	add_child(settings_scene)
	settings_screen = settings_scene


func _build_overlay_screens() -> void:
	inventory_screen = preload(INVENTORY_SCREEN_PATH).instantiate() as InventoryScreen
	inventory_screen.back_requested.connect(_on_inventory_back_requested)
	add_child(inventory_screen)

	rest_screen = preload(REST_SCREEN_PATH).instantiate() as RestScreen
	rest_screen.choice_requested.connect(_on_rest_choice_requested)
	rest_screen.inventory_requested.connect(_on_rest_inventory_requested)
	rest_screen.menu_requested.connect(_on_back_to_menu_pressed)
	add_child(rest_screen)

	end_screen = preload(END_SCREEN_PATH).instantiate() as EndScreen
	end_screen.restart_requested.connect(_on_end_restart_requested)
	end_screen.menu_requested.connect(_on_back_to_menu_pressed)
	add_child(end_screen)

	item_popup = preload(ITEM_POPUP_PATH).instantiate() as ItemAcquiredPopup
	add_child(item_popup)


func _on_item_added(item_id: String) -> void:
	if item_popup != null:
		item_popup.enqueue_item(item_id)


func _hide_game_overlays() -> void:
	if inventory_screen != null:
		inventory_screen.hide()
	if rest_screen != null:
		rest_screen.hide()
	if end_screen != null:
		end_screen.hide()


func _open_inventory(from_rest: bool) -> void:
	inventory_returns_to_rest = from_rest
	_close_game_menu()
	if rest_screen != null:
		rest_screen.hide()
	if end_screen != null:
		end_screen.hide()
	inventory_screen.open_screen()


func _on_inventory_back_requested() -> void:
	inventory_screen.hide()
	if inventory_returns_to_rest:
		rest_screen.open_scene(StoryManager.get_current_scene())
	else:
		game_container.show()
		_render_status()


func _show_rest_screen(scene: Dictionary) -> void:
	game_container.hide()
	if inventory_screen != null:
		inventory_screen.hide()
	if end_screen != null:
		end_screen.hide()
	rest_screen.open_scene(scene)
	YandexSDK.gameplay_start()


func _on_rest_choice_requested(choice_id: String) -> void:
	StoryManager.select_choice(choice_id)


func _on_rest_inventory_requested() -> void:
	_open_inventory(true)


func _show_end_screen(scene: Dictionary) -> void:
	game_container.hide()
	if inventory_screen != null:
		inventory_screen.hide()
	if rest_screen != null:
		rest_screen.hide()
	end_screen.open_ending(scene)
	YandexSDK.gameplay_stop()


func _on_end_restart_requested() -> void:
	StoryManager.restart_story()
	_show_game_screen()


func _compose_story_text(reaction_text: String, scene_text: String) -> String:
	var safe_scene_text: String = scene_text.replace("[", "[lb]")
	if reaction_text.is_empty():
		return safe_scene_text

	var safe_reaction_text: String = reaction_text.replace("[", "[lb]")
	return "[color=#%s]%s[/color]\n\n%s" % [
		ACCENT_COLOR.to_html(false),
		safe_reaction_text,
		safe_scene_text
	]


func _reveal_body_text(
	text_content: String,
	generation: int,
	pause_after_character: int = 0
) -> bool:
	body_label.text = text_content
	body_label.visible_characters = 0
	_sync_story_width()
	_scroll_story_to_top()
	await get_tree().process_frame
	if generation != reveal_generation:
		return false

	var total: int = body_label.get_total_character_count()
	if total == 0:
		body_label.visible_characters = -1
		return false

	is_revealing_text = true
	skip_text_reveal = false
	story_auto_scroll_active = true
	var reveal_speed: float = TEXT_REVEAL_BASE_SPEED * maxf(0.5, GameState.text_speed)
	var started_at: int = Time.get_ticks_msec()
	var reaction_pause_complete: bool = pause_after_character <= 0

	while body_label.visible_characters < total:
		if generation != reveal_generation:
			return false
		if skip_text_reveal:
			break

		var elapsed_seconds: float = float(Time.get_ticks_msec() - started_at) / 1000.0
		var next_visible_count: int = mini(total, int(elapsed_seconds * reveal_speed))
		if not reaction_pause_complete and next_visible_count >= pause_after_character:
			body_label.visible_characters = mini(pause_after_character, total)
			_update_story_scroll_target_to_visible_text()
			var pause_started_at: int = Time.get_ticks_msec()
			while Time.get_ticks_msec() - pause_started_at < 450:
				await get_tree().process_frame
				if generation != reveal_generation:
					return false
				if skip_text_reveal:
					break
			started_at += Time.get_ticks_msec() - pause_started_at
			reaction_pause_complete = true
			continue

		body_label.visible_characters = next_visible_count
		await get_tree().process_frame
		if generation != reveal_generation:
			return false
		if not skip_text_reveal:
			_update_story_scroll_target_to_visible_text()

	if generation != reveal_generation:
		return false

	var was_skipped: bool = skip_text_reveal
	body_label.visible_characters = -1
	is_revealing_text = false
	skip_text_reveal = false
	if was_skipped:
		story_auto_scroll_active = false
	return not was_skipped


func _update_story_scroll_target_to_visible_text() -> void:
	if story_scroll == null or body_label == null:
		return

	var scroll_bar: VScrollBar = story_scroll.get_v_scroll_bar()
	var max_scroll: float = maxf(scroll_bar.max_value - scroll_bar.page, 0.0)
	if max_scroll <= 0.0:
		return

	var visible_rect: Rect2i = body_label.get_visible_content_rect()
	var visible_bottom: float = float(visible_rect.position.y + visible_rect.size.y)
	var viewport_height: float = maxf(story_scroll.size.y, 1.0)
	story_scroll_target = clampf(
		visible_bottom - viewport_height + TEXT_SCROLL_BOTTOM_PADDING,
		0.0,
		max_scroll
	)


func _settle_story_scroll(generation: int) -> void:
	story_auto_scroll_active = true
	var settle_until: int = Time.get_ticks_msec() + 2000
	while Time.get_ticks_msec() < settle_until:
		await get_tree().process_frame
		if generation != reveal_generation or skip_text_reveal:
			story_auto_scroll_active = false
			return

		var scroll_bar: VScrollBar = story_scroll.get_v_scroll_bar()
		var max_scroll: float = maxf(scroll_bar.max_value - scroll_bar.page, 0.0)
		story_scroll_target = max_scroll
		if absf(story_scroll_position - max_scroll) <= 0.5:
			story_scroll_position = max_scroll
			story_scroll.scroll_vertical = int(round(max_scroll))
			story_auto_scroll_active = false
			return

	var final_scroll_bar: VScrollBar = story_scroll.get_v_scroll_bar()
	var final_scroll: float = maxf(final_scroll_bar.max_value - final_scroll_bar.page, 0.0)
	story_scroll_position = final_scroll
	story_scroll_target = final_scroll
	story_scroll.scroll_vertical = int(round(final_scroll))
	story_auto_scroll_active = false


func _update_save_status(message: String = "") -> void:
	if save_status_label == null:
		_update_menu_state(message)
		return

	var base_text: String = "Сохранение: есть" if SaveManager.has_save() else "Сохранение: нет"
	save_status_label.text = base_text if message.is_empty() else "%s | %s" % [base_text, message]
	_update_menu_state(message)
