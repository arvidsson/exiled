extends Node

@export var spawn_interval: float = 1.5
@export var viewport_margin: float = 72.0
@export var max_spawn_attempts: int = 24


func _ready() -> void:
	var timer := Timer.new()
	timer.wait_time = spawn_interval
	timer.timeout.connect(_try_spawn_enemy)
	timer.autostart = true
	add_child(timer)


func _try_spawn_enemy() -> void:
	if Refs.enemy_pool == null or Refs.level_container == null:
		return
	var cam := get_viewport().get_camera_2d()
	if cam == null:
		return
	var lr: Rect2 = Refs.level_container.level_rect
	var half := get_viewport().get_visible_rect().size / (2.0 * cam.zoom)
	var center := cam.get_screen_center_position()
	var avoid := Rect2(center - half, half * 2.0).grow(viewport_margin)
	var pos := _pick_spawn_point(lr, avoid)
	if pos.x > -1e9:
		Refs.enemy_pool.spawn(null, pos)


func _pick_spawn_point(lr: Rect2, avoid: Rect2) -> Vector2:
	for i in max_spawn_attempts:
		var p := Vector2(
			randf_range(lr.position.x, lr.end.x),
			randf_range(lr.position.y, lr.end.y)
		)
		if not avoid.has_point(p):
			return p
	var corners := [
		lr.position,
		Vector2(lr.end.x, lr.position.y),
		lr.end,
		Vector2(lr.position.x, lr.end.y)
	]
	var best: Vector2 = corners[0]
	var best_d := -1.0
	for c in corners:
		var d := avoid.get_center().distance_squared_to(c)
		if d > best_d:
			best_d = d
			best = c
	return best
