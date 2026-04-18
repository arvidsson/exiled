extends CanvasLayer

# --- Configuration ---
const MAX_LOG_LINES = 10
const LOG_FADE_TIME = 5.0

# --- Internal UI ---
var _static_label: Label
var _log_label: Label
var _log_lines: Array[String] = []
var _static_values: Dictionary = {}

func _ready() -> void:
	# Ensure this stays on top
	layer = 128

	# 1. Setup Top-Left Static Info
	_static_label = Label.new()
	_static_label.set_position(Vector2(10, 10))
	add_child(_static_label)

	# 2. Setup Bottom-Left Log
	_log_label = Label.new()
	_log_label.set_position(Vector2(10, get_viewport().get_visible_rect().size.y - 200))
	# Move log up as it grows
	_log_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	add_child(_log_label)

	# Apply some basic styling via code to make it readable
	var settings = LabelSettings.new()
	settings.font_size = 12
	settings.outline_size = 4
	settings.outline_color = Color.BLACK
	_static_label.label_settings = settings
	_log_label.label_settings = settings

## Updates a persistent value at the top left.
## Usage: Debug.set_info("FPS", Engine.get_frames_per_second())
func set_info(key: String, value: Variant) -> void:
	_static_values[key] = str(value)
	_update_static_text()

## Adds a message to the scrolling log at the bottom left.
## Usage: Debug.log("Player took damage")
func log_msg(message: String) -> void:
	var timestamp = Time.get_time_string_from_system()
	_log_lines.append("[%s] %s" % [timestamp, message])

	if _log_lines.size() > MAX_LOG_LINES:
		_log_lines.remove_at(0)

	_update_log_text()

	# Auto-fade logic: clear log after a few seconds
	get_tree().create_timer(LOG_FADE_TIME).timeout.connect(
		func():
			if not _log_lines.is_empty():
				_log_lines.remove_at(0)
				_update_log_text()
	)

func _update_static_text() -> void:
	var text = ""
	for key in _static_values:
		text += "%s: %s\n" % [key, _static_values[key]]
	_static_label.text = text

func _update_log_text() -> void:
	_log_label.text = "\n".join(_log_lines)
