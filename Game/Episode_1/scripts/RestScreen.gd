class_name RestScreen
extends Control

signal choice_requested(choice_id: String)
signal inventory_requested
signal menu_requested

const TEXT_COLOR: Color = Color("#e2e6ea")
const MUTED_COLOR: Color = Color("#8d98a8")
const ACCENT_COLOR: Color = Color("#d96f4d")

var title_label: Label
var body_label: Label
var status_label: Label
var actions_box: VBoxContainer
var current_scene: Dictionary = {}


func _ready() -> void:
	_build_ui()
	GameState.state_changed.connect(refresh)
	hide()


func open_scene(scene: Dictionary) -> void:
	current_scene = scene
	show()
	refresh()


func refresh() -> void:
	if current_scene.is_empty() or actions_box == null:
		return
	title_label.text = str(current_scene.get("title", "Привал"))
	body_label.text = str(current_scene.get("text", ""))
	status_label.text = "Здоровье: %s | Усталость: %s | Голод: %s | Вес: %d/%d" % [
		GameState.get_health_label(),
		GameState.get_fatigue_label(),
		GameState.get_hunger_label(),
		GameState.get_inventory_weight(),
		GameState.INVENTORY_LIMIT
	]
	for child in actions_box.get_children():
		child.queue_free()

	var choices_value: Variant = current_scene.get("choices", [])
	if typeof(choices_value) != TYPE_ARRAY:
		return
	for choice_data in choices_value as Array:
		if typeof(choice_data) != TYPE_DICTIONARY:
			continue
		var choice: Dictionary = choice_data as Dictionary
		var availability: Dictionary = StoryManager.get_choice_availability(choice)
		if not bool(availability.get("available", false)) and bool(choice.get("hide_when_unavailable", false)):
			continue
		if str(choice.get("id", "")) == "camp_continue":
			_add_inventory_button()
		_add_choice_button(choice, availability)


func _build_ui() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var background := ColorRect.new()
	background.color = Color(0.01, 0.015, 0.02, 0.72)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["margin_left", "margin_top", "margin_right", "margin_bottom"]:
		margin.add_theme_constant_override(side, 20)
	add_child(margin)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 12)
	margin.add_child(root)

	var header := HBoxContainer.new()
	root.add_child(header)
	title_label = Label.new()
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.add_theme_font_size_override("font_size", 28)
	title_label.add_theme_color_override("font_color", TEXT_COLOR)
	header.add_child(title_label)
	var menu_button := Button.new()
	menu_button.text = "Меню"
	menu_button.custom_minimum_size = Vector2(100, 44)
	menu_button.pressed.connect(func() -> void: menu_requested.emit())
	UIManager.style_menu_button(menu_button, 10)
	header.add_child(menu_button)

	body_label = Label.new()
	body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body_label.add_theme_color_override("font_color", TEXT_COLOR)
	root.add_child(body_label)
	status_label = Label.new()
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.add_theme_color_override("font_color", ACCENT_COLOR)
	root.add_child(status_label)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(scroll)
	actions_box = VBoxContainer.new()
	actions_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions_box.add_theme_constant_override("separation", 8)
	scroll.add_child(actions_box)


func _add_choice_button(choice: Dictionary, availability: Dictionary) -> void:
	var button := Button.new()
	button.text = str(choice.get("text", "Действие"))
	button.custom_minimum_size = Vector2(0, 52)
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.disabled = not bool(availability.get("available", false))
	if button.disabled:
		button.text += "  [%s]" % str(availability.get("reason", "недоступно"))
	button.pressed.connect(func() -> void: choice_requested.emit(str(choice.get("id", ""))))
	UIManager.style_menu_button(button, 12)
	actions_box.add_child(button)


func _add_inventory_button() -> void:
	var button := Button.new()
	button.text = "Разобрать рюкзак"
	button.custom_minimum_size = Vector2(0, 52)
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.pressed.connect(func() -> void: inventory_requested.emit())
	UIManager.style_menu_button(button, 12)
	actions_box.add_child(button)
