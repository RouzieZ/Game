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

	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
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

	for scene_data in scenes_value as Array:
		if typeof(scene_data) != TYPE_DICTIONARY:
			continue
		var scene: Dictionary = scene_data as Dictionary
		var scene_id: String = str(scene.get("id", ""))
		if scene_id.is_empty():
			continue
		if scenes.has(scene_id):
			push_warning("Duplicate scene id: %s" % scene_id)
		scenes[scene_id] = scene

	validate_current_scene()


func validate_current_scene() -> void:
	if not scenes.has(GameState.current_scene_id):
		GameState.current_scene_id = start_scene_id
		return
	var availability: Dictionary = get_scene_availability(GameState.current_scene_id)
	if not bool(availability.get("available", false)):
		GameState.current_scene_id = start_scene_id


func get_current_scene() -> Dictionary:
	return get_scene(GameState.current_scene_id)


func get_scene(scene_id: String) -> Dictionary:
	var scene_value: Variant = scenes.get(scene_id, {})
	if typeof(scene_value) != TYPE_DICTIONARY:
		return {}
	return scene_value as Dictionary


func get_scene_availability(scene_id: String) -> Dictionary:
	var scene: Dictionary = get_scene(scene_id)
	if scene.is_empty():
		return {"available": false, "reason": "сцена не найдена"}
	return ChoiceResolver.get_conditions_availability(scene.get("conditions", []))


func get_choice_availability(choice: Dictionary) -> Dictionary:
	if bool(choice.get("dangerous", false)) and GameState.is_exhausted():
		return {"available": false, "reason": "Артём на грани усталости"}
	return ChoiceResolver.get_conditions_availability(choice.get("conditions", []))


func get_current_choices() -> Array:
	var source: Variant = get_current_scene().get("choices", [])
	return source as Array if typeof(source) == TYPE_ARRAY else []


func select_choice(choice_id: String) -> bool:
	for choice_data in get_current_choices():
		if typeof(choice_data) != TYPE_DICTIONARY:
			continue
		var choice: Dictionary = choice_data as Dictionary
		if str(choice.get("id", "")) != choice_id:
			continue

		var availability: Dictionary = get_choice_availability(choice)
		if not bool(availability.get("available", false)):
			last_result_text = str(availability.get("reason", "Выбор недоступен."))
			return false

		if bool(choice.get("risky", false)) and GameState.is_critical():
			last_result_text = str(choice.get("critical_result_text", "Тело не выдержало ещё одного риска."))
			go_to_scene(BAD_HEALTH_ENDING_SCENE_ID)
			return true

		var effect_result: Dictionary = ChoiceResolver.apply_effects(choice.get("effects", []))
		var result_parts: Array[String] = []
		var choice_result: String = str(choice.get("result_text", ""))
		if not choice_result.is_empty():
			result_parts.append(choice_result)
		var messages_value: Variant = effect_result.get("messages", [])
		if typeof(messages_value) == TYPE_ARRAY:
			for message in messages_value as Array:
				result_parts.append(str(message))
		last_result_text = " ".join(result_parts)

		var forced_next: String = str(effect_result.get("forced_next", ""))
		var next_scene_id: String = forced_next if not forced_next.is_empty() else str(choice.get("next", ""))
		if not next_scene_id.is_empty():
			go_to_scene(next_scene_id)
		return true

	return false


func restart_story() -> void:
	last_result_text = ""
	GameState.reset_game()
	GameState.current_scene_id = start_scene_id
	scene_changed.emit(get_current_scene())


func refresh_current_scene() -> void:
	scene_changed.emit(get_current_scene())


func go_to_scene(scene_id: String) -> bool:
	var resolved_scene_id: String = _resolve_ending_check(scene_id)
	if not scenes.has(resolved_scene_id):
		push_warning("Next scene is missing in story.json: %s" % resolved_scene_id)
		return false

	var availability: Dictionary = get_scene_availability(resolved_scene_id)
	if not bool(availability.get("available", false)):
		push_warning("Next scene is unavailable: %s (%s)" % [resolved_scene_id, str(availability.get("reason", ""))])
		return false

	if not GameState.visited_scenes.has(GameState.current_scene_id):
		GameState.visited_scenes.append(GameState.current_scene_id)
	GameState.current_scene_id = resolved_scene_id
	scene_changed.emit(get_current_scene())
	return true


func _resolve_ending_check(scene_id: String) -> String:
	var scene: Dictionary = get_scene(scene_id)
	if str(scene.get("type", "")) != "ending_check":
		return scene_id
	var route: String = str(scene.get("route", ""))
	return EndingManager.choose_ending(route)
