extends Node2D


func _ready() -> void:
	Refs.level_container = $Level
	Refs.stamina_bar = $UI/StaminaBar
	Refs.xp_bar = $UI/XPBar
	Refs.bullet_pool = $Pools/BulletPool
