extends Node2D


func _ready() -> void:
	Refs.level_container = $Level
	Refs.stamina_bar = $UI/StaminaBar
	Refs.xp_bar = $UI/XPBar
	Refs.hp_label = $UI/HpLabel
	Refs.ammo_label = $UI/AmmoLabel
	Pools.register(Data.get_mob_data("lizard").scene, $Level/MobContainer)
	Pools.register(Data.get_scene("bullet"), $Level/BulletContainer)
	Pools.register(Data.get_scene("xp_pickup"), $Level/XpContainer)
	SoundManager.play_music(Prefabs.music, -20)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_fullscreen"):
		_toggle_fullscreen()

func _toggle_fullscreen() -> void:
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_WINDOWED:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
