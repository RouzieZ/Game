extends Node

signal item_used(item_id: String, result: Dictionary)


func get_use_availability(item_id: String) -> Dictionary:
	if not GameState.has_item(item_id):
		return _result(false, "Предмета нет в рюкзаке.")

	match item_id:
		"water":
			return _result(GameState.fatigue > 0 or GameState.hunger > 0, "Сейчас вода не нужна.")
		"bar", "canned_food":
			return _result(GameState.hunger > 0, "Артём не голоден.")
		"bandage":
			return _result(GameState.health == "wounded", "Бинт помогает только при лёгкой ране.")
		"medkit":
			return _result(GameState.health != "normal", "Аптечка сейчас не нужна.")
		_:
			return _result(false, "Этот предмет нельзя использовать напрямую.")


func use_item(item_id: String) -> Dictionary:
	var availability: Dictionary = get_use_availability(item_id)
	if not bool(availability.get("success", false)):
		return availability

	var message: String = ""
	match item_id:
		"water":
			if GameState.fatigue > 0:
				GameState.change_stat("fatigue", -1)
				message = "Вода немного вернула силы."
			else:
				GameState.change_stat("hunger", -1)
				message = "Вода притупила голод."
		"bar":
			GameState.change_stat("hunger", -1)
			message = "Батончик помог справиться с голодом."
		"canned_food":
			GameState.change_stat("hunger", -2)
			message = "Консервы надолго утолили голод."
		"bandage":
			GameState.set_health("normal")
			message = "Рана обработана бинтом."
		"medkit":
			GameState.set_health("wounded" if GameState.health == "critical" else "normal")
			message = "Аптечка помогла обработать раны."

	GameState.remove_item(item_id)
	var result: Dictionary = _result(true, message)
	item_used.emit(item_id, result)
	return result


func discard_item(item_id: String) -> Dictionary:
	if not GameState.remove_item(item_id):
		return _result(false, "Предмета нет в рюкзаке.")
	return _result(true, "Предмет оставлен.")


func use_best_food() -> Dictionary:
	if GameState.has_item("canned_food"):
		return use_item("canned_food")
	if GameState.has_item("bar"):
		return use_item("bar")
	return _result(false, "В рюкзаке нет еды.")


func use_best_medicine() -> Dictionary:
	if GameState.health == "critical" and GameState.has_item("medkit"):
		return use_item("medkit")
	if GameState.health == "wounded" and GameState.has_item("bandage"):
		return use_item("bandage")
	if GameState.health == "wounded" and GameState.has_item("medkit"):
		return use_item("medkit")
	return _result(false, "Подходящих медикаментов нет.")


func _result(success: bool, message: String) -> Dictionary:
	return {
		"success": success,
		"message": message
	}
