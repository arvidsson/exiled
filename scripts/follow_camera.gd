extends Node2D

@export var target: Node2D
@export var bounds_source: Node
@export var follow_smoothing: float = 8.0
@export var shake_decay: float = 10.0

@onready var _camera: Camera2D = $Camera2D

var _shake_strength: float = 0.0


func _ready() -> void:
	if target:
		global_position = target.global_position
	_apply_camera_limits()
	_camera.make_current()


func _apply_camera_limits() -> void:
	if bounds_source == null:
		return
	var r: Rect2 = bounds_source.level_rect
	_camera.limit_enabled = true
	_camera.limit_left = int(floor(r.position.x))
	_camera.limit_right = int(ceil(r.end.x))
	_camera.limit_top = int(floor(r.position.y))
	_camera.limit_bottom = int(ceil(r.end.y))


func _physics_process(delta: float) -> void:
	if target:
		var k := 1.0 - exp(-follow_smoothing * delta)
		global_position = global_position.lerp(target.global_position, k)
		_clamp_to_bounds()

	_shake_strength = maxf(_shake_strength - shake_decay * delta, 0.0)
	var shake := Vector2.ZERO
	if _shake_strength > 0.0:
		shake = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * _shake_strength
	_camera.position = shake


func add_shake(intensity: float) -> void:
	_shake_strength = maxf(_shake_strength, intensity)


func _clamp_to_bounds() -> void:
	if bounds_source == null:
		return
	var r: Rect2 = bounds_source.level_rect
	var z := _camera.zoom
	var half := get_viewport().get_visible_rect().size / (2.0 * z)
	var min_x := r.position.x + half.x
	var max_x := r.end.x - half.x
	var min_y := r.position.y + half.y
	var max_y := r.end.y - half.y
	if min_x <= max_x:
		global_position.x = clampf(global_position.x, min_x, max_x)
	else:
		global_position.x = r.get_center().x
	if min_y <= max_y:
		global_position.y = clampf(global_position.y, min_y, max_y)
	else:
		global_position.y = r.get_center().y
