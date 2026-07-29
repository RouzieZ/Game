extends Node

var failures: Array[String] = []
const TEST_SAVE_PATH: String = "user://posle_zvonka_smoke_test.json"


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_required_content()
	_test_inventory_limit()
	_test_inventory_use()
	_test_inventory_screen()
	await _test_item_popup()
	_test_save_roundtrip()
	_test_endings()
	_test_human_route()

	if failures.is_empty():
		print("SMOKE_TEST_OK")
		UIManager.shutdown()
		await get_tree().process_frame
		get_tree().quit(0)
		return

	for failure in failures:
		push_error(failure)
	UIManager.shutdown()
	await get_tree().process_frame
	get_tree().quit(1)


func _test_required_content() -> void:
	var required_scenes: Array[String] = [
		"scene_1_1", "scene_1_2", "scene_1_3", "scene_2_1b", "scene_2_1c",
		"scene_2_2", "scene_4_1", "scene_4_2", "scene_5_1", "scene_6_1", "scene_7_1",
		"ending_human", "ending_survivor", "ending_military", "ending_message", "ending_silence"
	]
	for scene_id in required_scenes:
		_expect(StoryManager.scenes.has(scene_id), "Missing required scene: %s" % scene_id)
	_expect(StoryManager.scenes.size() >= 30, "The MVP story is too small.")

	var status_ids: Array[String] = [
		"health", "fatigue", "hunger", "weight", "humanity", "survival"
	]
	var status_states: Array[String] = ["good", "warning", "bad"]
	for status_id in status_ids:
		for status_state in status_states:
			var icon_path: String = "res://assets/ui/status_%s_%s.svg" % [
				status_id,
				status_state
			]
			_expect(ResourceLoader.exists(icon_path), "Missing status icon: %s" % icon_path)


func _test_inventory_limit() -> void:
	GameState.reset_game()
	GameState.add_item("crowbar")
	GameState.add_item("medkit")
	GameState.add_item("water")
	var added_over_limit: bool = GameState.add_item("bar")
	_expect(GameState.get_inventory_weight() <= GameState.INVENTORY_LIMIT, "Inventory exceeded its limit.")
	_expect(not added_over_limit, "An item was added over the inventory limit.")


func _test_inventory_use() -> void:
	GameState.reset_game()
	GameState.change_stat("fatigue", 1)
	GameState.add_item("water")
	var result: Dictionary = InventoryManager.use_item("water")
	_expect(bool(result.get("success", false)), "Water could not be used.")
	_expect(GameState.fatigue == 0 and not GameState.has_item("water"), "Water effect was not applied.")


func _test_inventory_screen() -> void:
	GameState.reset_game()
	var screen := preload("res://scenes/InventoryScreen.tscn").instantiate() as InventoryScreen
	add_child(screen)
	screen.open_screen()
	var slots: Array[Node] = screen.find_children("*", "PanelContainer", true, false)
	var texture_buttons: Array[Node] = screen.find_children("*", "TextureButton", true, false)
	_expect(slots.size() >= 6, "Inventory screen did not create six slots.")
	_expect(texture_buttons.size() == GameState.inventory.size(), "Inventory item buttons are missing.")
	for node in texture_buttons:
		var texture_button := node as TextureButton
		_expect(texture_button.texture_normal != null, "Inventory item texture was not loaded.")
	screen.free()


func _test_item_popup() -> void:
	var popup := preload("res://scenes/ItemAcquiredPopup.tscn").instantiate() as ItemAcquiredPopup
	add_child(popup)
	popup.enqueue_item("phone")
	popup.enqueue_item("keys_home")
	await get_tree().process_frame
	await get_tree().process_frame
	_expect(popup.current_item_id == "phone", "Item popup did not show the first queued item.")
	_expect(popup.pending_items.size() == 1, "Item popup queue lost the second item.")
	_expect(popup.item_image.texture != null, "Item popup texture was not loaded.")
	_expect(
		is_equal_approx(popup.auto_close_timer.wait_time, ItemAcquiredPopup.AUTO_CLOSE_SECONDS),
		"Item popup auto-close timer is not 20 seconds."
	)
	popup.dismiss()
	await get_tree().create_timer(0.25).timeout
	await get_tree().process_frame
	_expect(popup.current_item_id == "keys_home", "Item popup did not advance to the next item.")
	popup.free()


func _test_save_roundtrip() -> void:
	GameState.reset_game()
	GameState.change_stat("survival", 4)
	GameState.set_flag("station_clue", true)
	GameState.current_scene_id = "scene_4_1"
	_expect(SaveManager.save_to_path(TEST_SAVE_PATH, false), "Temporary save failed.")
	GameState.reset_game()
	_expect(SaveManager.load_from_path(TEST_SAVE_PATH, false), "Temporary load failed.")
	_expect(GameState.survival == 4, "Saved stat was not restored.")
	_expect(bool(GameState.get_flag("station_clue")), "Saved flag was not restored.")
	_expect(GameState.current_scene_id == "scene_4_1", "Saved scene was not restored.")
	if FileAccess.file_exists(TEST_SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SAVE_PATH))


func _test_endings() -> void:
	GameState.reset_game()
	GameState.set_health("critical")
	GameState.change_stat("fatigue", 3)
	_expect(EndingManager.choose_ending("dacha") == "ending_silence", "Silence ending priority failed.")

	GameState.reset_game()
	GameState.add_item("mother_docs")
	GameState.set_flag("hospital_truth", true)
	_expect(EndingManager.choose_ending("dacha") == "ending_message", "Message ending selection failed.")

	GameState.reset_game()
	GameState.set_flag("military_obeyed", true)
	_expect(EndingManager.choose_ending("military") == "ending_military", "Military ending selection failed.")

	GameState.reset_game()
	GameState.change_stat("humanity", -2)
	GameState.change_stat("survival", 6)
	_expect(EndingManager.choose_ending("dacha") == "ending_survivor", "Survivor ending selection failed.")


func _test_human_route() -> void:
	StoryManager.restart_story()
	var route: Array[String] = [
		"stay_seated", "call_exit", "cafeteria", "take_some", "go_mila",
		"save_mila_together", "camp_sleep", "open_door", "old_station",
		"route_highway", "final_dacha"
	]
	for choice_id in route:
		_expect(StoryManager.select_choice(choice_id), "Route choice failed: %s" % choice_id)
	_expect(GameState.current_scene_id == "ending_human", "Human route did not reach ending_human.")


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
