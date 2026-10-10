extends Node
class_name NSTimeManager
signal hour_changed(hour: int)
signal shift_finished

@export var real_shift_minutes: float = 180.0
var minutes: float = 0.0
var speed: float = 1.0
var running = true
var last_hour = 0

func _process(delta: float) -> void:
	if not running:
		return
	advance(delta * 420.0 / (real_shift_minutes * 60.0) * speed)

func advance(amount: float) -> void:
	minutes = minf(420.0, minutes + amount)
	var hour = int(minutes / 60.0)
	if hour != last_hour:
		last_hour = hour
		hour_changed.emit(hour)
	if minutes >= 420.0 and running:
		running = false
		shift_finished.emit()

func clock() -> String:
	return "%02d:%02d" % [int(minutes / 60.0), int(minutes) % 60]
