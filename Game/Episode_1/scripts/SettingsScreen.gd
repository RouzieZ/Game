extends Control

signal back_to_menu

@onready var music_volume_slider = $MarginContainer/VBoxContainer/ScrollContainer/SettingsVBox/MusicVolumeContainer/MusicVolumeSlider
@onready var music_label = $MarginContainer/VBoxContainer/ScrollContainer/SettingsVBox/MusicVolumeContainer/MusicLabel
@onready var sound_volume_slider = $MarginContainer/VBoxContainer/ScrollContainer/SettingsVBox/SoundVolumeContainer/SoundVolumeSlider
@onready var sound_label = $MarginContainer/VBoxContainer/ScrollContainer/SettingsVBox/SoundVolumeContainer/SoundLabel
@onready var text_speed_slider = $MarginContainer/VBoxContainer/ScrollContainer/SettingsVBox/TextSpeedContainer/TextSpeedSlider
@onready var text_speed_label = $MarginContainer/VBoxContainer/ScrollContainer/SettingsVBox/TextSpeedContainer/TextSpeedLabel
@onready var text_size_slider = $MarginContainer/VBoxContainer/ScrollContainer/SettingsVBox/TextSizeContainer/TextSizeSlider
@onready var text_size_label = $MarginContainer/VBoxContainer/ScrollContainer/SettingsVBox/TextSizeContainer/TextSizeLabel
@onready var text_animation_checkbox = $MarginContainer/VBoxContainer/ScrollContainer/SettingsVBox/TextAnimationContainer/TextAnimationCheckBox
@onready var reset_save_button = $MarginContainer/VBoxContainer/ScrollContainer/SettingsVBox/ResetSaveContainer/ResetSaveButton
@onready var back_button = $MarginContainer/VBoxContainer/ButtonContainer/BackButton
@onready var confirm_dialog = $ConfirmDialog


func _ready() -> void:
	UIManager.style_menu_button(reset_save_button, 10)
	UIManager.style_menu_button(back_button, 12)
	_refresh_controls()
	SaveManager.save_changed.connect(_on_save_changed)
	SettingsManager.settings_changed.connect(_refresh_controls)
	visibility_changed.connect(_on_visibility_changed)


func _on_music_volume_changed(value: float) -> void:
	SettingsManager.set_music_volume(value)


func _on_sound_volume_changed(value: float) -> void:
	SettingsManager.set_sound_volume(value)


func _on_text_speed_changed(value: float) -> void:
	SettingsManager.set_text_speed(value)


func _on_text_size_changed(value: float) -> void:
	SettingsManager.set_text_size(int(value))


func _on_text_animation_toggled(pressed: bool) -> void:
	SettingsManager.set_text_animation(pressed)


func _on_reset_save_pressed() -> void:
	confirm_dialog.popup_centered_ratio(0.5)


func _on_confirm_delete_save() -> void:
	SaveManager.delete_save()
	_update_reset_save_button()


func _on_save_changed() -> void:
	_update_reset_save_button()


func _on_back_pressed() -> void:
	visible = false
	emit_signal("back_to_menu")


func _on_visibility_changed() -> void:
	if visible:
		_refresh_controls()


func _refresh_controls() -> void:
	if music_volume_slider == null:
		return
	music_volume_slider.set_value_no_signal(GameState.music_volume)
	sound_volume_slider.set_value_no_signal(GameState.sound_volume)
	text_speed_slider.set_value_no_signal(GameState.text_speed)
	text_size_slider.set_value_no_signal(float(GameState.text_size))
	text_animation_checkbox.set_pressed_no_signal(GameState.text_reveal_animation)
	_update_music_label()
	_update_sound_label()
	_update_text_speed_label()
	_update_text_size_label()
	_update_reset_save_button()


func _update_music_label() -> void:
	var percentage = int(GameState.music_volume * 100)
	music_label.text = "Громкость музыки: %d%%" % percentage


func _update_sound_label() -> void:
	var percentage = int(GameState.sound_volume * 100)
	sound_label.text = "Громкость звуков: %d%%" % percentage


func _update_text_speed_label() -> void:
	text_speed_label.text = "Скорость текста: %.1fx" % GameState.text_speed


func _update_text_size_label() -> void:
	text_size_label.text = "Размер текста: %dpx" % GameState.text_size


func _update_reset_save_button() -> void:
	reset_save_button.disabled = not SaveManager.has_save()
	if reset_save_button.disabled:
		reset_save_button.text = "Нет сохранения"
	else:
		reset_save_button.text = "Удалить"
