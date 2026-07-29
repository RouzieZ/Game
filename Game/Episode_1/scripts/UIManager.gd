extends Node

const MIX_RATE: int = 22050
const LOOP_SECONDS: int = 6
const UI_TEXT_COLOR: Color = Color("#e2e6ea")
const UI_MUTED_COLOR: Color = Color("#8d98a8")
const UI_HOVER_COLOR: Color = Color(1, 1, 1, 0.15)
const UI_PRESSED_COLOR: Color = Color(1, 1, 1, 0.09)

var music_player: AudioStreamPlayer


func _ready() -> void:
	if DisplayServer.get_name() == "headless":
		return
	music_player = AudioStreamPlayer.new()
	music_player.bus = "Music"
	music_player.stream = _create_ambient_stream()
	add_child(music_player)
	music_player.play()


func shutdown() -> void:
	if music_player == null:
		return
	music_player.stop()
	music_player.stream = null
	music_player.queue_free()
	music_player = null


func style_menu_button(button: Button, content_padding: int = 12) -> void:
	var normal := _create_button_style(Color(0, 0, 0, 0), content_padding)
	var hover := _create_button_style(UI_HOVER_COLOR, content_padding)
	var pressed := _create_button_style(UI_PRESSED_COLOR, content_padding)
	var disabled := _create_button_style(Color(0, 0, 0, 0), content_padding)

	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("focus", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("hover_pressed", pressed)
	button.add_theme_stylebox_override("disabled", disabled)
	button.add_theme_color_override("font_color", UI_TEXT_COLOR)
	button.add_theme_color_override("font_hover_color", UI_TEXT_COLOR)
	button.add_theme_color_override("font_focus_color", UI_TEXT_COLOR)
	button.add_theme_color_override("font_pressed_color", UI_TEXT_COLOR)
	button.add_theme_color_override("font_hover_pressed_color", UI_TEXT_COLOR)
	button.add_theme_color_override("font_disabled_color", UI_MUTED_COLOR)


func create_surface_style(alpha: float = 0.72, padding: int = 0) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.035, 0.045, 0.06, clampf(alpha, 0.0, 1.0))
	style.set_corner_radius_all(6)
	style.content_margin_left = float(padding)
	style.content_margin_top = float(padding)
	style.content_margin_right = float(padding)
	style.content_margin_bottom = float(padding)
	return style


func _exit_tree() -> void:
	shutdown()


func _create_button_style(background: Color, padding: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.set_corner_radius_all(6)
	style.content_margin_left = float(padding)
	style.content_margin_top = 7.0
	style.content_margin_right = float(padding)
	style.content_margin_bottom = 7.0
	return style


func _create_ambient_stream() -> AudioStreamWAV:
	var sample_count: int = MIX_RATE * LOOP_SECONDS
	var audio_data := PackedByteArray()
	audio_data.resize(sample_count * 2)
	for index in sample_count:
		var time: float = float(index) / float(MIX_RATE)
		var envelope: float = 0.72 + 0.28 * sin(TAU * time / float(LOOP_SECONDS))
		var sample: float = (
			sin(TAU * 46.0 * time) * 0.018
			+ sin(TAU * 69.0 * time) * 0.008
		) * envelope
		audio_data.encode_s16(index * 2, clampi(int(sample * 32767.0), -32768, 32767))

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = MIX_RATE
	stream.stereo = false
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = sample_count
	stream.data = audio_data
	return stream
