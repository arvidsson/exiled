extends Node2D


func _ready() -> void:
	# TODO: rethink this?
	Pools.clear()
	Pools.register(Data.get_mob_data("lizard").scene, $Level/MobContainer)
	Pools.register(Data.get_mob_data("bug").scene, $Level/MobContainer)
	Pools.register(Data.get_scene("bullet"), $Level/BulletContainer)
	Pools.register(Data.get_scene("mob_bullet"), $Level/BulletContainer)
	Pools.register(Data.get_scene("xp_pickup"), $Level/XpContainer)
	Audio.play_music(Data.get_music("music"), -20)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_fullscreen"):
		_toggle_fullscreen()

func _toggle_fullscreen() -> void:
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_WINDOWED:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
