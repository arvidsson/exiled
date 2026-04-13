extends Node

func _ready() -> void:
	print("[Events] ready")

signal skill_used(skill: int, cooldown: float)
signal ammo_changed(cur: int, max: int)
signal health_changed(cur: int, max: int)
signal stamina_changed(cur: float, max: float)
signal xp_changed(cur: int, max: int)
signal levelup()
