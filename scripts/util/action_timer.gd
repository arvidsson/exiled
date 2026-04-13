class_name ActionTimer
extends Node

var remain: float = 0.0
var active: bool = false
var on_complete: Callable

func start(duration: float, callback: Callable) -> void:
	remain = duration
	active = true
	on_complete = callback

func tick(delta: float) -> void:
	if not active:
		return

	remain -= delta
	if remain <= 0.0:
		active = false
		if on_complete:
			on_complete.call()
