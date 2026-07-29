extends Node

signal save_changed

const SAVE_FILE_NAME: String = "posle_zvonka_save.json"
const SAVE_PATH: String = "user://posle_zvonka_save.json"
const SAVE_VERSION: int = 2

var last_error: String = ""


func save_local() -> bool:
	return save_to_path(SAVE_PATH)


func save_to_path(path: String, emit_change: bool = true) -> bool:
	last_error = ""

	var save_root: Dictionary = {
		"version": SAVE_VERSION,
		"game_state": GameState.to_dictionary(),
		"settings": SettingsManager.to_dictionary()
	}

	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		last_error = "Не удалось открыть файл сохранения."
		return false

	file.store_string(JSON.stringify(save_root, "\t"))
	if emit_change:
		save_changed.emit()
	return true


func load_local() -> bool:
	return load_from_path(SAVE_PATH)


func load_from_path(path: String, emit_change: bool = true) -> bool:
	last_error = ""

	if not FileAccess.file_exists(path):
		last_error = "Файл сохранения не найден."
		return false

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		last_error = "Не удалось прочитать файл сохранения."
		return false

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		last_error = "Сохранение повреждено."
		return false

	var save_root: Dictionary = parsed as Dictionary
	var save_version: int = int(save_root.get("version", 1))
	if save_version > SAVE_VERSION:
		last_error = "Сохранение создано более новой версией игры."
		return false

	var state_value: Variant = save_root.get("game_state", {})
	if typeof(state_value) != TYPE_DICTIONARY:
		last_error = "В сохранении нет данных GameState."
		return false

	var state_data: Dictionary = state_value as Dictionary
	GameState.from_dictionary(state_data)
	SettingsManager.apply_to_game_state()
	if emit_change:
		save_changed.emit()
	return true


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func delete_save() -> bool:
	last_error = ""

	if not has_save():
		save_changed.emit()
		return true

	var dir := DirAccess.open("user://")
	if dir == null:
		last_error = "Не удалось открыть папку user://."
		return false

	var error_code: int = dir.remove(SAVE_FILE_NAME)
	if error_code != OK:
		last_error = "Ошибка удаления файла: %d" % error_code
		return false

	save_changed.emit()
	return true


func save_cloud() -> bool:
	if YandexSDK.is_available():
		var cloud_saved: bool = YandexSDK.save_data(GameState.to_dictionary())
		if cloud_saved:
			return true

	return save_local()


func load_cloud() -> bool:
	if YandexSDK.is_available():
		var cloud_data: Dictionary = YandexSDK.load_data()
		if not cloud_data.is_empty():
			GameState.from_dictionary(cloud_data)
			save_changed.emit()
			return true

	return load_local()
