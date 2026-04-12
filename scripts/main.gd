extends Node2D

# NOTE: autoloads ready called before this one
func _ready() -> void:
	# TODO: rethink this?
	print("[Main] ready")
	Pools.clear()
	Pools.register(Data.Mobs.Warrior, $Level/MobContainer)
	Pools.register(Data.Mobs.Lizard, $Level/MobContainer)
	Pools.register(Data.Mobs.Bug, $Level/MobContainer)
	Pools.register(Data.Scenes.Bullet, $Level/BulletContainer)
	Pools.register(Data.Scenes.MobBullet, $Level/BulletContainer)
	Pools.register(Data.Scenes.Slash, $Level/BulletContainer)
	Pools.register(Data.Scenes.XpPickup, $Level/XpContainer) # TODO: should be like ItemsContainer or something
	Pools.register(Data.Scenes.Ammo, $Level/XpContainer)
	Audio.play_music(Data.Music.Default, -20)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_fullscreen"):
		_toggle_fullscreen()

## Toggles between windowed and borderless fullscreen.
func _toggle_fullscreen() -> void:
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_WINDOWED:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
