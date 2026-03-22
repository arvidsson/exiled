class_name ProgressTimer
extends Node

var duration: float
var startTime: float

func start(time: float):
	duration = time
	startTime = Time.get_ticks_msec() / 1000.0

func fraction_passed() -> float:
	var now = Time.get_ticks_msec() / 1000.0
	return clamp((now - startTime) / duration, 0.0, 1.0)
