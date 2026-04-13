# NOTE: respects godot time scaling
class_name CooldownTimer
extends Node

var remain: float = 0.0

func start(duration: float) -> void:
	remain = duration

func tick(delta: float) -> void:
	remain = maxf(0.0, remain - delta)

func is_ready() -> bool:
	return remain <= 0.0
