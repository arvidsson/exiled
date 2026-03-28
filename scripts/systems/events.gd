extends Node

signal ammo_changed(cur: int, max: int)

func emit_ammo_changed(cur: int, max: int):
	emit_signal("ammo_changed", cur, max)
