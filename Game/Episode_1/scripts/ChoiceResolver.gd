extends Node


func get_conditions_availability(conditions_source: Variant) -> Dictionary:
	if typeof(conditions_source) != TYPE_ARRAY:
		return _availability(false, "условия должны быть массивом")

	var conditions: Array = conditions_source as Array
	for condition_data in conditions:
		if typeof(condition_data) != TYPE_DICTIONARY:
			return _availability(false, "условие должно быть объектом")

		var result: Dictionary = check_condition(condition_data as Dictionary)
		if not bool(result.get("available", false)):
			return result

	return _availability(true, "")


func check_condition(condition: Dictionary) -> Dictionary:
	var condition_type: String = str(condition.get("type", ""))
	var target: String = str(condition.get("target", ""))

	match condition_type:
		"has_item":
			return _availability(
				GameState.has_item(target),
				"нужен предмет: %s" % GameState.get_item_title(target)
			)
		"not_has_item":
			return _availability(
				not GameState.has_item(target),
				"предмет уже есть: %s" % GameState.get_item_title(target)
			)
		"flag":
			var expected: Variant = condition.get("value", true)
			return _availability(
				GameState.get_flag(target) == expected,
				str(condition.get("reason", "требуется сюжетное условие: %s" % target))
			)
		"health":
			var expected_health: String = str(condition.get("value", "normal"))
			return _availability(
				GameState.health == expected_health,
				str(condition.get("reason", "требуется состояние здоровья: %s" % expected_health))
			)
		"stat_min":
			var stat_min: int = int(condition.get("value", 0))
			var stat_value: Variant = GameState.get_stat(target)
			return _availability(
				stat_value != null and int(stat_value) >= stat_min,
				str(condition.get("reason", "нужно значение %s не ниже %d" % [target, stat_min]))
			)
		"stat_max":
			var stat_max: int = int(condition.get("value", 0))
			var stat_value: Variant = GameState.get_stat(target)
			return _availability(
				stat_value != null and int(stat_value) <= stat_max,
				str(condition.get("reason", "нужно значение %s не выше %d" % [target, stat_max]))
			)
		"any":
			return _check_any(condition.get("conditions", []), str(condition.get("reason", "нужно выполнить одно из условий")))
		"all":
			return get_conditions_availability(condition.get("conditions", []))
		_:
			push_warning("Unknown condition type: %s" % condition_type)
			return _availability(false, "неизвестный тип условия: %s" % condition_type)


func apply_effects(effects_source: Variant) -> Dictionary:
	var result: Dictionary = {
		"forced_next": "",
		"messages": []
	}
	if typeof(effects_source) != TYPE_ARRAY:
		return result

	var messages: Array[String] = []
	for effect_data in effects_source as Array:
		if typeof(effect_data) != TYPE_DICTIONARY:
			continue

		var effect: Dictionary = effect_data as Dictionary
		var effect_type: String = str(effect.get("type", ""))
		var target: String = str(effect.get("target", ""))
		match effect_type:
			"stat":
				GameState.change_stat(target, int(effect.get("value", 0)))
			"flag":
				GameState.set_flag(target, effect.get("value", true))
			"add_item":
				if not GameState.add_item(target):
					messages.append("В рюкзаке не хватило места для предмета «%s»." % GameState.get_item_title(target))
			"remove_item":
				GameState.remove_item(target)
			"health":
				GameState.set_health(str(effect.get("value", "normal")))
			"use_item":
				var use_result: Dictionary = InventoryManager.use_item(target)
				if not bool(use_result.get("success", false)):
					messages.append(str(use_result.get("message", "Предмет нельзя использовать.")))
			"consume_food":
				var food_result: Dictionary = InventoryManager.use_best_food()
				if not bool(food_result.get("success", false)):
					messages.append(str(food_result.get("message", "Еды нет.")))
			"heal_best":
				var heal_result: Dictionary = InventoryManager.use_best_medicine()
				if not bool(heal_result.get("success", false)):
					messages.append(str(heal_result.get("message", "Лечить раны нечем.")))
			"ending":
				result["forced_next"] = target
			_:
				push_warning("Unknown effect type: %s" % effect_type)
				messages.append("Неизвестный эффект: %s" % effect_type)

	result["messages"] = messages
	return result


func _check_any(conditions_source: Variant, failure_reason: String) -> Dictionary:
	if typeof(conditions_source) != TYPE_ARRAY:
		return _availability(false, failure_reason)

	for condition_data in conditions_source as Array:
		if typeof(condition_data) != TYPE_DICTIONARY:
			continue
		var result: Dictionary = check_condition(condition_data as Dictionary)
		if bool(result.get("available", false)):
			return _availability(true, "")

	return _availability(false, failure_reason)


func _availability(available: bool, reason: String) -> Dictionary:
	return {
		"available": available,
		"reason": "" if available else reason
	}
