extends Node

const ENDINGS_PATH: String = "res://data/endings.json"
const FALLBACK_ENDING_ID: String = "ending_road"

var endings: Array[Dictionary] = []


func _ready() -> void:
	load_endings()


func load_endings(path: String = ENDINGS_PATH) -> void:
	endings.clear()
	if not FileAccess.file_exists(path):
		push_error("Endings file not found: %s" % path)
		return

	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Cannot open endings file: %s" % path)
		return

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Endings file root must be an object.")
		return

	var data: Dictionary = parsed as Dictionary
	var source: Variant = data.get("endings", [])
	if typeof(source) != TYPE_ARRAY:
		return

	for ending_data in source as Array:
		if typeof(ending_data) == TYPE_DICTIONARY:
			endings.append(ending_data as Dictionary)

	endings.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("priority", 0)) > int(b.get("priority", 0))
	)


func choose_ending(route: String = "") -> String:
	if not route.is_empty():
		GameState.set_flag("ending_route", route)

	for ending in endings:
		var availability: Dictionary = ChoiceResolver.get_conditions_availability(ending.get("conditions", []))
		if bool(availability.get("available", false)):
			return str(ending.get("id", FALLBACK_ENDING_ID))

	return FALLBACK_ENDING_ID


func get_ending_data(ending_id: String) -> Dictionary:
	for ending in endings:
		if str(ending.get("id", "")) == ending_id:
			return ending
	return {}
