extends Node

signal scene_changed(scene: Dictionary)

const STORY_PATH: String = "res://data/story.json"
const BAD_HEALTH_ENDING_SCENE_ID: String = "ending_silence"

var scenes: Dictionary = {}
var start_scene_id: String = "scene_1_1"
var last_result_text: String = ""


func _ready() -> void:
	load_story()


func load_story(path: String = STORY_PATH) -> void:
	scenes.clear()

	if not FileAccess.file_exists(path):
		push_error("Story file not found: %s" % path)
		return

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Cannot open story file: %s" % path)
		return

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Story file root must be a JSON object.")
		return

	var story_data: Dictionary = parsed as Dictionary

	start_scene_id = str(story_data.get("start_scene_id", start_scene_id))

	var scenes_value: Variant = story_data.get("scenes", [])
	if typeof(scenes_value) != TYPE_ARRAY:
		push_error("Story scenes must be an array.")
		return

	var story_scenes: Array = scenes_value as Array
	for scene_data in story_scenes:
		var scene: Variant = scene_data
		if typeof(scene) != TYPE_DICTIONARY:
			continue

		var scene_dictionary: Dictionary = scene as Dictionary
		var scene_id: String = str(scene_dictionary.get("id", ""))
		if scene_id.is_empty():
			continue

		scenes[scene_id] = scene_dictionary

	if not scenes.has(GameState.current_scene_id) or not bool(get_scene_availability(GameState.current_scene_id).get("available", false)):
		GameState.current_scene_id = start_scene_id


func get_current_scene() -> Dictionary:
	var scene_value: Variant = scenes.get(GameState.current_scene_id, {})
	if typeof(scene_value) != TYPE_DICTIONARY:
		return {}

	return scene_value as Dictionary


func get_scene_availability(scene_id: String) -> Dictionary:
	var scene_value: Variant = scenes.get(scene_id, {})
	if typeof(scene_value) != TYPE_DICTIONARY:
		return {
			"available": false,
			"reason": "сцена не найдена"
		}

	var scene: Dictionary = scene_value as Dictionary
	return _get_conditions_availability(scene.get("conditions", []))


func get_choice_availability(choice: Dictionary) -> Dictionary:
	if bool(choice.get("dangerous", false)) and GameState.is_exhausted():
		return {
			"available": false,
			"reason": "Артём на грани усталости"
		}

	return _get_conditions_availability(choice.get("conditions", []))


func _get_conditions_availability(conditions_source: Variant) -> Dictionary:
	var conditions_value: Variant = conditions_source
	if typeof(conditions_value) != TYPE_ARRAY:
		return {
			"available": false,
			"reason": "условия должны быть массивом"
		}

	var conditions: Array = conditions_value as Array
	for condition_data in conditions:
		var condition_value: Variant = condition_data
		if typeof(condition_value) != TYPE_DICTIONARY:
			continue

		var condition: Dictionary = condition_value as Dictionary
		var result: Dictionary = _is_condition_met(condition)
		if not bool(result.get("met", false)):
			return {
				"available": false,
				"reason": str(result.get("reason", "условие не выполнено"))
			}

	return {
		"available": true,
		"reason": ""
	}


func select_choice(choice_id: String) -> bool:
	var scene: Dictionary = get_current_scene()
	var choices_value: Variant = scene.get("choices", [])
	if typeof(choices_value) != TYPE_ARRAY:
		return false

	var choices: Array = choices_value as Array
	for choice_data in choices:
		var choice_value: Variant = choice_data
		if typeof(choice_value) != TYPE_DICTIONARY:
			continue

		var choice: Dictionary = choice_value as Dictionary
		if str(choice.get("id", "")) != choice_id:
			continue

		var availability: Dictionary = get_choice_availability(choice)
		if not bool(availability.get("available", false)):
			return false

		if bool(choice.get("risky", false)) and GameState.is_critical():
			last_result_text = str(choice.get(
				"critical_result_text",
				"Тело не выдержало ещё одного риска."
			))
			if scenes.has(BAD_HEALTH_ENDING_SCENE_ID):
				_go_to_scene(BAD_HEALTH_ENDING_SCENE_ID)
			return true

		var effects_value: Variant = choice.get("effects", [])
		var effects: Array = []
		if typeof(effects_value) == TYPE_ARRAY:
			effects = effects_value as Array
		var forced_next_scene_id: String = _apply_effects(effects)
		last_result_text = str(choice.get("result_text", ""))

		if not forced_next_scene_id.is_empty():
			_go_to_scene(forced_next_scene_id)
			return true

		var next_scene_id: String = str(choice.get("next", ""))
		if next_scene_id.is_empty():
			return true

		_go_to_scene(next_scene_id)
		return true

	return false


func restart_story() -> void:
	last_result_text = ""
	GameState.reset_game()
	GameState.current_scene_id = start_scene_id
	scene_changed.emit(get_current_scene())


func _go_to_scene(scene_id: String) -> void:
	if not scenes.has(scene_id):
		push_warning("Next scene is missing in story.json: %s" % scene_id)
		return

	var availability: Dictionary = get_scene_availability(scene_id)
	if not bool(availability.get("available", false)):
		push_warning("Next scene is unavailable: %s (%s)" % [scene_id, str(availability.get("reason", ""))])
		return

	if not GameState.visited_scenes.has(GameState.current_scene_id):
		GameState.visited_scenes.append(GameState.current_scene_id)

	GameState.current_scene_id = scene_id
	scene_changed.emit(get_current_scene())


func _apply_effects(effects: Array) -> String:
	var forced_next_scene_id: String = ""

	for effect_data in effects:
		var effect_value: Variant = effect_data
		if typeof(effect_value) != TYPE_DICTIONARY:
			continue

		var effect: Dictionary = effect_value as Dictionary
		var effect_type: String = str(effect.get("type", ""))
		var target: String = str(effect.get("target", ""))

		match effect_type:
			"stat":
				GameState.change_stat(target, int(effect.get("value", 0)))
			"flag":
				GameState.set_flag(target, effect.get("value", true))
			"add_item":
				var added := GameState.add_item(target)
				if not added:
					push_warning("Inventory is full, cannot add item: %s" % target)
			"remove_item":
				GameState.remove_item(target)
			"health":
				GameState.set_health(str(effect.get("value", "normal")))
			"ending":
				forced_next_scene_id = str(effect.get("target", ""))
			_:
				push_warning("Unknown effect type: %s" % effect_type)

	return forced_next_scene_id


func _is_condition_met(condition: Dictionary) -> Dictionary:
	var condition_type: String = str(condition.get("type", ""))
	var target: String = str(condition.get("target", ""))

	match condition_type:
		"has_item":
			return _condition_result(
				GameState.has_item(target),
				"нужен предмет: %s" % GameState.get_item_title(target)
			)
		"not_has_item":
			return _condition_result(
				not GameState.has_item(target),
				"предмет уже есть: %s" % GameState.get_item_title(target)
			)
		"flag":
			var expected: Variant = condition.get("value", true)
			return _condition_result(
				GameState.get_flag(target) == expected,
				"требуется сюжетный флаг: %s" % target
			)
		"stat_min":
			var stat_min: int = int(condition.get("value", 0))
			return _condition_result(
				int(GameState.get_stat(target)) >= stat_min,
				"нужно значение %s не ниже %d" % [target, stat_min]
			)
		"stat_max":
			var stat_max: int = int(condition.get("value", 0))
			return _condition_result(
				int(GameState.get_stat(target)) <= stat_max,
				"нужно значение %s не выше %d" % [target, stat_max]
			)
		_:
			return _condition_result(true, "")


func _condition_result(is_met: bool, reason: String) -> Dictionary:
	return {
		"met": is_met,
		"reason": "" if is_met else reason
	}
