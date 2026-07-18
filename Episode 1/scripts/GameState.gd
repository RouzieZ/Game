extends Node

signal state_changed

const DEFAULT_SCENE_ID: String = "scene_1_1"
const INVENTORY_LIMIT: int = 6
const ITEMS_PATH: String = "res://data/items.json"
const DEFAULT_INVENTORY: Array[String] = []
const VALID_HEALTH_STATES: Array[String] = ["normal", "wounded", "critical"]
const STAT_LIMITS: Dictionary = {
	"fatigue": Vector2i(0, 3),
	"hunger": Vector2i(0, 2),
	"humanity": Vector2i(0, 10),
	"survival": Vector2i(0, 10),
	"trust_danya": Vector2i(0, 5),
	"trust_lera": Vector2i(0, 5),
	"trust_mila": Vector2i(0, 5)
}
const DEFAULT_FLAGS: Dictionary = {
	"danya_alive": true,
	"danya_in_group": true,
	"lera_alive": true,
	"lera_with_player": true,
	"mila_found": false,
	"mila_saved": false,
	"mother_clue": false,
	"hospital_truth": false
}

var health: String = "normal"
var fatigue: int = 0
var hunger: int = 0

var humanity: int = 5
var survival: int = 0

var trust_danya: int = 2
var trust_lera: int = 2
var trust_mila: int = 0

var flags: Dictionary = DEFAULT_FLAGS.duplicate(true)
var inventory: Array[String] = []
var current_scene_id: String = DEFAULT_SCENE_ID
var visited_scenes: Array[String] = []

var items: Dictionary = {}

# Settings
var music_volume: float = 0.8
var sound_volume: float = 0.8
var text_speed: float = 1.0  # 0.5 = slow, 1.0 = normal, 2.0 = fast
var text_size: int = 24
var text_reveal_animation: bool = true


func _ready() -> void:
	_load_items()


func add_item(item_id: String) -> bool:
	if not can_add_item(item_id):
		return false

	inventory.append(item_id)
	state_changed.emit()
	return true


func remove_item(item_id: String) -> bool:
	var index := inventory.find(item_id)
	if index == -1:
		return false

	inventory.remove_at(index)
	state_changed.emit()
	return true


func has_item(item_id: String) -> bool:
	return inventory.has(item_id)


func has_item_data(item_id: String) -> bool:
	return items.has(item_id)


func set_flag(flag_name: String, value: Variant) -> void:
	flags[flag_name] = value
	state_changed.emit()


func get_flag(flag_name: String, default_value: Variant = false) -> Variant:
	return flags.get(flag_name, default_value)


func change_stat(stat_name: String, amount: int) -> void:
	var current_value: Variant = get_stat(stat_name)
	if current_value == null:
		push_warning("Unknown stat: %s" % stat_name)
		return

	_set_stat(stat_name, int(current_value) + amount)

	state_changed.emit()


func get_stat(stat_name: String) -> Variant:
	match stat_name:
		"fatigue":
			return fatigue
		"hunger":
			return hunger
		"humanity":
			return humanity
		"survival":
			return survival
		"trust_danya":
			return trust_danya
		"trust_lera":
			return trust_lera
		"trust_mila":
			return trust_mila
		_:
			return null


func set_health(value: String) -> bool:
	if not VALID_HEALTH_STATES.has(value):
		push_warning("Unknown health value: %s" % value)
		return false

	health = value
	state_changed.emit()
	return true


func get_health() -> String:
	return health


func get_health_label() -> String:
	match health:
		"normal":
			return "норма"
		"wounded":
			return "ранен"
		"critical":
			return "тяжело ранен"
		_:
			return health


func get_fatigue_label() -> String:
	match fatigue:
		0:
			return "бодрый"
		1:
			return "уставший"
		2:
			return "измотан"
		3:
			return "на грани"
		_:
			return str(fatigue)


func get_hunger_label() -> String:
	match hunger:
		0:
			return "сыт"
		1:
			return "голоден"
		2:
			return "сильно голоден"
		_:
			return str(hunger)


func is_exhausted() -> bool:
	return fatigue >= 3


func is_critical() -> bool:
	return health == "critical"


func can_add_item(item_id: String) -> bool:
	if not has_item_data(item_id):
		push_warning("Unknown inventory item: %s" % item_id)
		return false

	return get_inventory_weight() + get_item_weight(item_id) <= INVENTORY_LIMIT


func get_inventory_weight() -> int:
	var weight := 0
	for item_id in inventory:
		weight += get_item_weight(item_id)
	return weight


func get_item_weight(item_id: String) -> int:
	var data_value: Variant = items.get(item_id, {})
	if typeof(data_value) != TYPE_DICTIONARY:
		return 1

	var data: Dictionary = data_value as Dictionary
	return int(data.get("weight", 1))


func get_item_title(item_id: String) -> String:
	var data_value: Variant = items.get(item_id, {})
	if typeof(data_value) != TYPE_DICTIONARY:
		return item_id

	var data: Dictionary = data_value as Dictionary
	return str(data.get("title", item_id))


func get_item_description(item_id: String) -> String:
	var data_value: Variant = items.get(item_id, {})
	if typeof(data_value) != TYPE_DICTIONARY:
		return ""

	var data: Dictionary = data_value as Dictionary
	return str(data.get("description", ""))


func reset_game() -> void:
	health = "normal"
	fatigue = 0
	hunger = 0
	humanity = 5
	survival = 0
	trust_danya = 2
	trust_lera = 2
	trust_mila = 0
	flags = DEFAULT_FLAGS.duplicate(true)
	inventory.clear()
	for item_id in DEFAULT_INVENTORY:
		inventory.append(item_id)
	current_scene_id = DEFAULT_SCENE_ID
	visited_scenes.clear()
	# Settings are NOT reset
	state_changed.emit()


func save_game() -> bool:
	return SaveManager.save_local()


func load_game() -> bool:
	return SaveManager.load_local()


func to_dictionary() -> Dictionary:
	return {
		"health": health,
		"fatigue": fatigue,
		"hunger": hunger,
		"humanity": humanity,
		"survival": survival,
		"trust_danya": trust_danya,
		"trust_lera": trust_lera,
		"trust_mila": trust_mila,
		"flags": flags,
		"inventory": inventory,
		"current_scene_id": current_scene_id,
		"visited_scenes": visited_scenes,
		"music_volume": music_volume,
		"sound_volume": sound_volume,
		"text_speed": text_speed,
		"text_size": text_size,
		"text_reveal_animation": text_reveal_animation
	}


func from_dictionary(data: Dictionary) -> void:
	var loaded_health: String = str(data.get("health", "normal"))
	health = loaded_health if VALID_HEALTH_STATES.has(loaded_health) else "normal"
	_set_stat("fatigue", int(data.get("fatigue", 0)))
	_set_stat("hunger", int(data.get("hunger", 0)))
	_set_stat("humanity", int(data.get("humanity", 5)))
	_set_stat("survival", int(data.get("survival", 0)))
	_set_stat("trust_danya", int(data.get("trust_danya", 2)))
	_set_stat("trust_lera", int(data.get("trust_lera", 2)))
	_set_stat("trust_mila", int(data.get("trust_mila", 0)))
	var flags_value: Variant = data.get("flags", DEFAULT_FLAGS)
	flags = DEFAULT_FLAGS.duplicate(true)
	if typeof(flags_value) == TYPE_DICTIONARY:
		var loaded_flags: Dictionary = flags_value as Dictionary
		for flag_name in loaded_flags:
			flags[str(flag_name)] = loaded_flags[flag_name]
	current_scene_id = str(data.get("current_scene_id", DEFAULT_SCENE_ID))

	inventory.clear()
	var inventory_value: Variant = data.get("inventory", DEFAULT_INVENTORY)
	if typeof(inventory_value) == TYPE_ARRAY:
		for item_id in inventory_value:
			inventory.append(str(item_id))

	visited_scenes.clear()
	var visited_scenes_value: Variant = data.get("visited_scenes", [])
	if typeof(visited_scenes_value) == TYPE_ARRAY:
		for scene_id in visited_scenes_value:
			visited_scenes.append(str(scene_id))

	# Load settings
	music_volume = clampf(float(data.get("music_volume", 0.8)), 0.0, 1.0)
	sound_volume = clampf(float(data.get("sound_volume", 0.8)), 0.0, 1.0)
	text_speed = clampf(float(data.get("text_speed", 1.0)), 0.5, 2.0)
	text_size = clampi(int(data.get("text_size", 24)), 16, 32)
	text_reveal_animation = bool(data.get("text_reveal_animation", true))

	state_changed.emit()


func _set_stat(stat_name: String, value: int) -> void:
	var limits_value: Variant = STAT_LIMITS.get(stat_name)
	if typeof(limits_value) != TYPE_VECTOR2I:
		push_warning("Unknown stat limits: %s" % stat_name)
		return

	var limits: Vector2i = limits_value as Vector2i
	var clamped_value: int = clampi(value, limits.x, limits.y)

	match stat_name:
		"fatigue":
			fatigue = clamped_value
		"hunger":
			hunger = clamped_value
		"humanity":
			humanity = clamped_value
		"survival":
			survival = clamped_value
		"trust_danya":
			trust_danya = clamped_value
		"trust_lera":
			trust_lera = clamped_value
		"trust_mila":
			trust_mila = clamped_value


func _load_items() -> void:
	if not FileAccess.file_exists(ITEMS_PATH):
		items = {}
		return

	var file := FileAccess.open(ITEMS_PATH, FileAccess.READ)
	if file == null:
		push_warning("Cannot open items file: %s" % ITEMS_PATH)
		return

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("Items file is not a JSON object.")
		return

	items = parsed as Dictionary
