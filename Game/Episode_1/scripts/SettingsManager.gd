extends Node

signal settings_changed

const SETTINGS_PATH: String = "user://posle_zvonka_settings.json"


func _ready() -> void:
	_ensure_audio_bus("Music")
	_ensure_audio_bus("SFX")
	load_settings()


func set_music_volume(value: float) -> void:
	GameState.music_volume = clampf(value, 0.0, 1.0)
	_apply_audio()
	_save_and_emit()


func set_sound_volume(value: float) -> void:
	GameState.sound_volume = clampf(value, 0.0, 1.0)
	_apply_audio()
	_save_and_emit()


func set_text_speed(value: float) -> void:
	GameState.text_speed = clampf(value, 0.5, 2.0)
	_save_and_emit()


func set_text_size(value: int) -> void:
	GameState.text_size = clampi(value, 16, 32)
	_save_and_emit()


func set_text_animation(enabled: bool) -> void:
	GameState.text_reveal_animation = enabled
	_save_and_emit()


func to_dictionary() -> Dictionary:
	return {
		"music_volume": GameState.music_volume,
		"sound_volume": GameState.sound_volume,
		"text_speed": GameState.text_speed,
		"text_size": GameState.text_size,
		"text_reveal_animation": GameState.text_reveal_animation
	}


func apply_dictionary(data: Dictionary, save_after: bool = false) -> void:
	GameState.music_volume = clampf(float(data.get("music_volume", GameState.music_volume)), 0.0, 1.0)
	GameState.sound_volume = clampf(float(data.get("sound_volume", GameState.sound_volume)), 0.0, 1.0)
	GameState.text_speed = clampf(float(data.get("text_speed", GameState.text_speed)), 0.5, 2.0)
	GameState.text_size = clampi(int(data.get("text_size", GameState.text_size)), 16, 32)
	GameState.text_reveal_animation = bool(data.get("text_reveal_animation", GameState.text_reveal_animation))
	_apply_audio()
	settings_changed.emit()
	if save_after:
		save_settings()


func apply_to_game_state() -> void:
	if not FileAccess.file_exists(SETTINGS_PATH):
		_apply_audio()
		return
	var file: FileAccess = FileAccess.open(SETTINGS_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) == TYPE_DICTIONARY:
		apply_dictionary(parsed as Dictionary)


func save_settings() -> bool:
	var file: FileAccess = FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(to_dictionary(), "\t"))
	return true


func load_settings() -> bool:
	if not FileAccess.file_exists(SETTINGS_PATH):
		_apply_audio()
		return false
	apply_to_game_state()
	return true


func _save_and_emit() -> void:
	save_settings()
	settings_changed.emit()


func _ensure_audio_bus(bus_name: String) -> void:
	if AudioServer.get_bus_index(bus_name) != -1:
		return
	AudioServer.add_bus()
	AudioServer.set_bus_name(AudioServer.bus_count - 1, bus_name)


func _apply_audio() -> void:
	_set_bus_linear_volume("Music", GameState.music_volume)
	_set_bus_linear_volume("SFX", GameState.sound_volume)


func _set_bus_linear_volume(bus_name: String, volume: float) -> void:
	var bus_index: int = AudioServer.get_bus_index(bus_name)
	if bus_index == -1:
		return
	AudioServer.set_bus_mute(bus_index, volume <= 0.001)
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(maxf(volume, 0.001)))
