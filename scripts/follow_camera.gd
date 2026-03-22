extends Node2D

@export var target: Node2D
@export var follow_smoothing: float = 8.0
@export var shake_decay: float = 10.0

@onready var _camera: Camera2D = $Camera2D

var _shake_strength: float = 0.0


func _ready() -> void:
	if target:
		global_position = target.global_position
	_camera.make_current()


func _physics_process(delta: float) -> void:
	if target:
		var k := 1.0 - exp(-follow_smoothing * delta)
		global_position = global_position.lerp(target.global_position, k)

	_shake_strength = maxf(_shake_strength - shake_decay * delta, 0.0)
	var shake := Vector2.ZERO
	if _shake_strength > 0.0:
		shake = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * _shake_strength
	_camera.position = shake


func add_shake(intensity: float) -> void:
	_shake_strength = maxf(_shake_strength, intensity)
