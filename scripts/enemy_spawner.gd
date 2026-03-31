extends Node

## Seconds from start until x and y reach their end values.
@export var ramp_duration_sec: float = 120.0
## Seconds between each individual spawn within a wave. Decreases over the ramp (y).
@export var spawn_interval_start: float = 2.2
@export var spawn_interval_end: float = 0.35
## Enemies per wave before the next wave starts. Increases over the ramp (x).
@export var enemies_per_wave_start: int = 1
@export var enemies_per_wave_end: int = 6
## Ring sits just outside the visible viewport (world units past the view diagonal).
@export var ring_margin: float = 40.0
## Keep spawn points inside the level rectangle.
@export var clamp_to_level: bool = true

const _MIN_INTERVAL := 0.08

var _elapsed: float = 0.0
var _spawn_accum: float = 0.0
var _left_in_wave: int = 0

func _process(delta: float) -> void:
	var cam := get_viewport().get_camera_2d()
	if cam == null:
		return
	var player := _get_player()
	if player == null:
		return

	_elapsed += delta
	_spawn_accum += delta

	var interval := _spawn_interval()
	while _spawn_accum >= interval:
		_spawn_accum -= interval
		if _left_in_wave <= 0:
			_left_in_wave = _enemies_per_wave()
		_spawn_one_on_ring(player.global_position, cam)
		_left_in_wave -= 1

func _ramp_t() -> float:
	if ramp_duration_sec <= 0.0:
		return 1.0
	return clampf(_elapsed / ramp_duration_sec, 0.0, 1.0)

func _spawn_interval() -> float:
	var t := _ramp_t()
	return maxf(_MIN_INTERVAL, lerpf(spawn_interval_start, spawn_interval_end, t))

func _enemies_per_wave() -> int:
	var t := _ramp_t()
	var a := float(enemies_per_wave_start)
	var b := float(enemies_per_wave_end)
	return int(round(lerpf(a, b, t)))

func _get_player() -> Node2D:
	for n in get_tree().get_nodes_in_group(&"player"):
		if n is Node2D:
			return n as Node2D
	return null

func _ring_radius(cam: Camera2D) -> float:
	var half := get_viewport().get_visible_rect().size / (2.0 * cam.zoom)
	return half.length() + ring_margin

func _spawn_one_on_ring(center: Vector2, cam: Camera2D) -> void:
	var angle := randf() * TAU
	var r := _ring_radius(cam)
	var pos := center + Vector2.from_angle(angle) * r
	if clamp_to_level:
		var lr: Rect2 = $"../Level".level_rect
		pos.x = clampf(pos.x, lr.position.x, lr.end.x)
		pos.y = clampf(pos.y, lr.position.y, lr.end.y)
	var mob_types: Array[String] = ["bug", "lizard", "warrior"]
	var mob_type: String = mob_types[randi() % mob_types.size()]
	Pools.spawn(Data.get_mob_data(mob_type).scene.resource_path.get_file().get_basename(), pos)
