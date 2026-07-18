extends Control

const DESKTOP_MARGIN: int = 28
const MOBILE_MARGIN: int = 14
const TOOLBAR_BUTTON_HEIGHT: int = 46
const CHOICE_BUTTON_HEIGHT: int = 56
const MOBILE_BREAKPOINT: int = 760
const GAME_INFO_PATH: String = "res://data/game_info.json"
const SETTINGS_SCREEN_PATH: String = "res://scenes/SettingsScreen.tscn"

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
var menu_status_label: Label
var continue_button: Button
var game_title_label: Label
var chapter_label: Label
var title_label: Label
var result_label: Label
var story_scroll: ScrollContainer
var body_label: RichTextLabel
var status_label: Label
var save_status_label: Label
var toolbar_grid: GridContainer
var choices_box: VBoxContainer
var skip_hint_label: Label
var toolbar_buttons: Array[Button] = []
var choice_buttons: Array[Button] = []
var is_revealing_text: bool = false
var skip_text_reveal: bool = false
var reveal_target_text: String = ""


func _ready() -> void:
	_build_ui()
	StoryManager.scene_changed.connect(_render_scene)
	GameState.state_changed.connect(_render_status)
	SaveManager.save_changed.connect(_update_save_status)
	resized.connect(_apply_responsive_layout)
	_render_scene(StoryManager.get_current_scene())
	_update_save_status()
	_apply_responsive_layout()
	YandexSDK.init_sdk()
	YandexSDK.game_ready()


func _build_ui() -> void:
	var background := TextureRect.new()
	background.texture = load("res://ep_one.jpg")
	background.expand = true
	background.stretch_mode = TextureRect.STRETCH_SCALE
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
	_build_settings_screen()
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

	game_title_label = Label.new()
	game_title_label.text = _load_game_title()
	game_title_label.add_theme_font_size_override("font_size", 16)
	game_title_label.add_theme_color_override("font_color", ACCENT_COLOR)
	game_container.add_child(game_title_label)

	chapter_label = Label.new()
	chapter_label.add_theme_color_override("font_color", MUTED_TEXT_COLOR)
	game_container.add_child(chapter_label)

	title_label = Label.new()
	title_label.add_theme_font_size_override("font_size", 28)
	title_label.add_theme_color_override("font_color", TEXT_COLOR)
	game_container.add_child(title_label)

	toolbar_grid = GridContainer.new()
	toolbar_grid.columns = 4
	toolbar_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	toolbar_grid.add_theme_constant_override("h_separation", 8)
	toolbar_grid.add_theme_constant_override("v_separation", 8)
	game_container.add_child(toolbar_grid)

	_add_toolbar_button(toolbar_grid, "Новая игра", _on_new_game_pressed)
	_add_toolbar_button(toolbar_grid, "Сохранить", _on_save_pressed)
	_add_toolbar_button(toolbar_grid, "Загрузить", _on_load_pressed)
	_add_toolbar_button(toolbar_grid, "Меню", _on_back_to_menu_pressed)

	save_status_label = Label.new()
	save_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	save_status_label.add_theme_color_override("font_color", MUTED_TEXT_COLOR)
	game_container.add_child(save_status_label)

	result_label = Label.new()
	result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result_label.add_theme_color_override("font_color", ACCENT_COLOR)
	game_container.add_child(result_label)

	skip_hint_label = Label.new()
	skip_hint_label.text = "Пробел — пропустить анимацию"
	skip_hint_label.visible = false
	skip_hint_label.add_theme_color_override("font_color", MUTED_TEXT_COLOR)
	skip_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	game_container.add_child(skip_hint_label)

	story_scroll = ScrollContainer.new()
	story_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	story_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	story_scroll.resized.connect(_sync_story_width)
	game_container.add_child(story_scroll)

	body_label = RichTextLabel.new()
	body_label.bbcode_enabled = false
	body_label.fit_content = true
	body_label.scroll_active = false
	body_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body_label.add_theme_font_size_override("normal_font_size", 20)
	body_label.add_theme_color_override("default_color", TEXT_COLOR)
	story_scroll.add_child(body_label)
	call_deferred("_sync_story_width")

	status_label = Label.new()
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.add_theme_color_override("font_color", MUTED_TEXT_COLOR)
	game_container.add_child(status_label)

	choices_box = VBoxContainer.new()
	choices_box.add_theme_constant_override("separation", 8)
	game_container.add_child(choices_box)


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
	if main_menu_container != null:
		main_menu_container.visible = true

	if game_container != null:
		game_container.visible = false

	if settings_screen != null:
		settings_screen.hide()

	choice_buttons.clear()
	_update_menu_state(message)
	YandexSDK.gameplay_stop()


func _show_game_screen() -> void:
	if main_menu_container != null:
		main_menu_container.visible = false

	if settings_screen != null:
		settings_screen.visible = false

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
	_show_settings_screen()


func _on_menu_authors_pressed() -> void:
	_update_menu_state("Авторы: интерактивная история «После звонка».")


func _on_menu_reset_save_pressed() -> void:
	if SaveManager.delete_save():
		_update_menu_state("Сохранение сброшено.")
	else:
		_update_menu_state("Не удалось сбросить сохранение: %s" % SaveManager.last_error)


func _add_toolbar_button(parent: Control, label_text: String, callback: Callable) -> void:
	var button := Button.new()
	button.text = label_text
	button.custom_minimum_size = Vector2(0, TOOLBAR_BUTTON_HEIGHT)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.focus_mode = Control.FOCUS_ALL
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.pressed.connect(callback)
	_style_button(button)
	parent.add_child(button)
	toolbar_buttons.append(button)


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
	if scene.is_empty():
		chapter_label.text = ""
		title_label.text = "Сцена не найдена"
		body_label.text = "Проверь data/story.json и current_scene_id."
		result_label.text = ""
		_render_choices([])
		_render_status()
		return

	chapter_label.text = str(scene.get("chapter", ""))
	title_label.text = str(scene.get("title", ""))
	body_label.add_theme_font_size_override("normal_font_size", int(GameState.text_size))
	var text_content: String = str(scene.get("text", ""))
	if GameState.text_reveal_animation:
		choices_box.visible = false
		skip_hint_label.visible = true
		await _reveal_body_text(text_content)
		skip_hint_label.visible = false
	else:
		body_label.text = text_content
		call_deferred("_sync_story_width")
		_scroll_story_to_bottom()
	result_label.text = StoryManager.last_result_text
	_render_status()
	var choices_value: Variant = scene.get("choices", [])
	var choices: Array = []
	if typeof(choices_value) == TYPE_ARRAY:
		choices = choices_value as Array
	_render_choices(choices)
	choices_box.visible = true


func _apply_responsive_layout() -> void:
	if margin_container == null:
		return

	var viewport_size: Vector2 = get_viewport_rect().size
	var compact: bool = viewport_size.x <= MOBILE_BREAKPOINT or viewport_size.y <= 560.0
	var margin_size: int = MOBILE_MARGIN if compact else DESKTOP_MARGIN
	var root_gap: int = 8 if compact else 12
	var choice_gap: int = 7 if compact else 8

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

	if toolbar_grid != null:
		toolbar_grid.columns = 2 if compact else 4

	for toolbar_button in toolbar_buttons:
		toolbar_button.custom_minimum_size = Vector2(0, TOOLBAR_BUTTON_HEIGHT)

	if choices_box != null:
		choices_box.add_theme_constant_override("separation", choice_gap)

	_sync_story_width()


func _render_status() -> void:
	if status_label == null:
		return

	var item_titles: Array[String] = []
	for item_id in GameState.inventory:
		item_titles.append(GameState.get_item_title(item_id))

	var inventory_text: String = "пусто"
	if not item_titles.is_empty():
		inventory_text = ", ".join(item_titles)

	status_label.text = (
		"Здоровье: %s | Усталость: %s (%d/3) | Голод: %s (%d/2)\n" +
		"Человечность: %d | Выживание: %d | Вес рюкзака: %d/%d | Предметы (%d): %s"
	) % [
		GameState.get_health_label(),
		GameState.get_fatigue_label(),
		GameState.fatigue,
		GameState.get_hunger_label(),
		GameState.hunger,
		GameState.humanity,
		GameState.survival,
		GameState.get_inventory_weight(),
		GameState.INVENTORY_LIMIT,
		GameState.inventory.size(),
		inventory_text
	]


func _sync_story_width() -> void:
	if story_scroll == null or body_label == null:
		return

	var width: float = maxf(story_scroll.size.x - 24.0, 240.0)
	body_label.custom_minimum_size = Vector2(width, body_label.custom_minimum_size.y)
	body_label.size = Vector2(width, body_label.size.y)


func _scroll_story_to_bottom() -> void:
	if story_scroll == null:
		return

	story_scroll.scroll_vertical = 999999


func _render_choices(choices: Array) -> void:
	choice_buttons.clear()

	for child in choices_box.get_children():
		child.queue_free()

	if choices.is_empty():
		var restart_button := Button.new()
		restart_button.text = "Начать заново"
		restart_button.custom_minimum_size = Vector2(0, CHOICE_BUTTON_HEIGHT)
		restart_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		restart_button.focus_mode = Control.FOCUS_ALL
		restart_button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		restart_button.pressed.connect(StoryManager.restart_story)
		choices_box.add_child(restart_button)
		restart_button.call_deferred("grab_focus")
		return

	var choice_index: int = 1
	for choice_data in choices:
		var choice_value: Variant = choice_data
		if typeof(choice_value) != TYPE_DICTIONARY:
			continue

		var choice: Dictionary = choice_value as Dictionary
		var choice_id: String = str(choice.get("id", ""))
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
		choices_box.add_child(button)
		choice_buttons.append(button)
		choice_index += 1

	call_deferred("_focus_first_available_choice")


func _on_choice_pressed(choice_id: String) -> void:
	StoryManager.select_choice(choice_id)


func _focus_first_available_choice() -> void:
	for button in choice_buttons:
		if not button.disabled:
			button.grab_focus()
			return


func _unhandled_input(event: InputEvent) -> void:
	if game_container == null or not game_container.visible:
		return

	if not (event is InputEventKey):
		return

	var key_event: InputEventKey = event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return

	if is_revealing_text and key_event.keycode == KEY_SPACE:
		_skip_text_reveal()
		get_viewport().set_input_as_handled()
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
	var normal_box := StyleBoxFlat.new()
	normal_box.bg_color = Color(0, 0, 0, 0)
	normal_box.border_color = Color(0, 0, 0, 0)
	normal_box.corner_radius_top_left = 10
	normal_box.corner_radius_top_right = 10
	normal_box.corner_radius_bottom_left = 10
	normal_box.corner_radius_bottom_right = 10

	var hover_box := StyleBoxFlat.new()
	hover_box.bg_color = Color(1, 1, 1, 0.15)
	hover_box.border_color = Color(0, 0, 0, 0)
	hover_box.corner_radius_top_left = 10
	hover_box.corner_radius_top_right = 10
	hover_box.corner_radius_bottom_left = 10
	hover_box.corner_radius_bottom_right = 10

	var pressed_box := StyleBoxFlat.new()
	pressed_box.bg_color = Color(0, 0, 0, 0)
	pressed_box.border_color = Color(0, 0, 0, 0)
	pressed_box.corner_radius_top_left = 10
	pressed_box.corner_radius_top_right = 10
	pressed_box.corner_radius_bottom_left = 10
	pressed_box.corner_radius_bottom_right = 10

	var disabled_box := StyleBoxFlat.new()
	disabled_box.bg_color = Color(0, 0, 0, 0)
	disabled_box.border_color = Color(0, 0, 0, 0)
	disabled_box.corner_radius_top_left = 10
	disabled_box.corner_radius_top_right = 10
	disabled_box.corner_radius_bottom_left = 10
	disabled_box.corner_radius_bottom_right = 10

	button.add_theme_stylebox_override("normal", normal_box)
	button.add_theme_stylebox_override("hover", hover_box)
	button.add_theme_stylebox_override("pressed", pressed_box)
	button.add_theme_stylebox_override("disabled", disabled_box)
	button.add_theme_color_override("font_color", TEXT_COLOR)
	button.add_theme_color_override("font_color_hover", TEXT_COLOR)
	button.add_theme_color_override("font_color_pressed", TEXT_COLOR)
	button.add_theme_color_override("font_color_disabled", MUTED_TEXT_COLOR)


func _skip_text_reveal() -> void:
	if not is_revealing_text:
		return

	skip_text_reveal = true


func _on_new_game_pressed() -> void:
	StoryManager.restart_story()
	_show_game_screen()


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
	# Вернуться в главное меню после закрытия экрана настроек
	_show_main_menu()


func _show_settings_screen() -> void:
	if main_menu_container != null:
		main_menu_container.visible = false

	if game_container != null:
		game_container.visible = false

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


func _reveal_body_text(text_content: String) -> void:
	body_label.text = ""
	var total := text_content.length()
	is_revealing_text = true
	skip_text_reveal = false
	for i in total:
		if skip_text_reveal:
			break
		body_label.text = text_content.substr(0, i + 1)
		call_deferred("_sync_story_width")
		_scroll_story_to_bottom()
		await get_tree().create_timer(0.03 / maxf(0.5, GameState.text_speed)).timeout

	if skip_text_reveal:
		body_label.text = text_content
		call_deferred("_sync_story_width")
		_scroll_story_to_bottom()

	is_revealing_text = false
	skip_text_reveal = false
	_scroll_story_to_bottom()


func _update_save_status(message: String = "") -> void:
	if save_status_label == null:
		_update_menu_state(message)
		return

	var base_text: String = "Сохранение: есть" if SaveManager.has_save() else "Сохранение: нет"
	save_status_label.text = base_text if message.is_empty() else "%s | %s" % [base_text, message]
	_update_menu_state(message)
