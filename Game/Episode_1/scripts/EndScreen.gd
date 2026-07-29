class_name EndScreen
extends Control

signal restart_requested
signal menu_requested

var title_label: Label
var text_label: Label
var summary_label: Label


func _ready() -> void:
	_build_ui()
	hide()


func open_ending(scene: Dictionary) -> void:
	show()
	title_label.text = str(scene.get("title", "Концовка"))
	text_label.text = str(scene.get("text", ""))
	summary_label.text = "Человечность: %d | Выживание: %d | Мила: %s" % [
		GameState.humanity,
		GameState.survival,
		"найдена" if bool(GameState.get_flag("mila_found")) else "не найдена"
	]


func _build_ui() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var background := ColorRect.new()
	background.color = Color(0.01, 0.015, 0.02, 0.72)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["margin_left", "margin_top", "margin_right", "margin_bottom"]:
		margin.add_theme_constant_override(side, 24)
	add_child(margin)
	var root := VBoxContainer.new()
	root.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_theme_constant_override("separation", 16)
	margin.add_child(root)
	title_label = Label.new()
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 36)
	title_label.add_theme_color_override("font_color", Color("#d96f4d"))
	root.add_child(title_label)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 220)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(scroll)
	text_label = Label.new()
	text_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_label.add_theme_font_size_override("font_size", 21)
	text_label.add_theme_color_override("font_color", Color("#e2e6ea"))
	scroll.add_child(text_label)
	summary_label = Label.new()
	summary_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	summary_label.add_theme_color_override("font_color", Color("#8d98a8"))
	root.add_child(summary_label)
	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 10)
	root.add_child(actions)
	var restart_button := Button.new()
	restart_button.text = "Начать заново"
	restart_button.custom_minimum_size = Vector2(180, 52)
	restart_button.pressed.connect(func() -> void: restart_requested.emit())
	UIManager.style_menu_button(restart_button, 14)
	actions.add_child(restart_button)
	var menu_button := Button.new()
	menu_button.text = "В меню"
	menu_button.custom_minimum_size = Vector2(140, 52)
	menu_button.pressed.connect(func() -> void: menu_requested.emit())
	UIManager.style_menu_button(menu_button, 14)
	actions.add_child(menu_button)
