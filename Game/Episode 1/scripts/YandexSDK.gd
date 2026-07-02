extends Node

var initialized: bool = false


func init_sdk() -> bool:
	if not is_available():
		return false

	_eval("window.pzYandexBridge && window.pzYandexBridge.init && window.pzYandexBridge.init();")
	initialized = true
	return true


func game_ready() -> void:
	if not is_available():
		return

	_eval("window.pzYandexBridge && window.pzYandexBridge.gameReady && window.pzYandexBridge.gameReady();")


func gameplay_start() -> void:
	if not is_available():
		return

	_eval("window.pzYandexBridge && window.pzYandexBridge.gameplayStart && window.pzYandexBridge.gameplayStart();")


func gameplay_stop() -> void:
	if not is_available():
		return

	_eval("window.pzYandexBridge && window.pzYandexBridge.gameplayStop && window.pzYandexBridge.gameplayStop();")


func show_fullscreen_ad() -> void:
	if not is_available():
		return

	_eval("window.pzYandexBridge && window.pzYandexBridge.showFullscreenAd && window.pzYandexBridge.showFullscreenAd();")


func show_rewarded_ad(callback: Callable = Callable()) -> void:
	if not is_available():
		if callback.is_valid():
			callback.call(false)
		return

	_eval("window.pzYandexBridge && window.pzYandexBridge.showRewardedAd && window.pzYandexBridge.showRewardedAd();")
	if callback.is_valid():
		callback.call(true)


func save_data(data: Dictionary) -> bool:
	if not is_available():
		return false

	var json_text: String = JSON.stringify(data)
	var escaped_json: String = _escape_for_single_quoted_js(json_text)
	_eval("window.pzYandexBridge && window.pzYandexBridge.saveData && window.pzYandexBridge.saveData(JSON.parse('%s'));" % escaped_json)
	return true


func load_data() -> Dictionary:
	if not is_available():
		return {}

	_eval("window.pzYandexBridge && window.pzYandexBridge.requestData && window.pzYandexBridge.requestData();")
	return {}


func is_available() -> bool:
	return OS.has_feature("web") and Engine.has_singleton("JavaScriptBridge")


func _eval(script: String) -> Variant:
	if not is_available():
		return null

	var bridge: Object = Engine.get_singleton("JavaScriptBridge")
	return bridge.call("eval", script, true)


func _escape_for_single_quoted_js(value: String) -> String:
	return value.replace("\\", "\\\\").replace("'", "\\'").replace("\n", "\\n").replace("\r", "")
