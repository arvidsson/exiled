extends Area2D

@export var speed: float = 300.0
@export var lifetime: float = 3.0

var velocity := Vector2.ZERO

func on_spawn() -> void:
	Tools.call_delay(self , lifetime, Callable(self , "_on_lifetime_ended"))

func _on_lifetime_ended() -> void:
	Refs.bullet_pool.despawn(self)

func setup(direction: Vector2, move_speed: float) -> void:
	velocity = direction.normalized() * move_speed

func _physics_process(delta: float) -> void:
	global_position += velocity * delta
