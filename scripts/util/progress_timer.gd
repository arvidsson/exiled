# NOTE: does NOT respect godot time scaling
class_name ProgressTimer
extends Node

var duration: float
var startTime: float

func start(time: float):
	duration = time
	startTime = Time.get_ticks_msec() / 1000.0

func fraction() -> float:
	var now = Time.get_ticks_msec() / 1000.0
	return clamp((now - startTime) / duration, 0.0, 1.0)

func is_done() -> bool:
	return fraction() >= 1.0
