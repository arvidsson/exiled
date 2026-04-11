extends Node

func _ready() -> void:
	print("[Events] ready")

signal ammo_changed(cur: int, max: int)
signal hp_changed(cur: int, max: int)
signal stamina_changed(cur: float, max: float)
signal xp_changed(cur: int, max: int)
signal levelup()
