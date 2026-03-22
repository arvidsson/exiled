extends Area2D

@export var speed: float = 300.0
@export var lifetime: float = 3.0

var velocity := Vector2.ZERO
var _spent := false

func _ready() -> void:
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

func on_spawn() -> void:
	_spent = false
	Tools.call_delay(self , lifetime, Callable(self , "_on_lifetime_ended"))

func _on_lifetime_ended() -> void:
	if _spent:
		return
	_spent = true
	Refs.bullet_pool.despawn(self)

func setup(direction: Vector2, move_speed: float) -> void:
	velocity = direction.normalized() * move_speed

func _physics_process(delta: float) -> void:
	global_position += velocity * delta


func _on_body_entered(body: Node2D) -> void:
	if _spent:
		return
	if body.is_in_group(&"enemy") and body.has_method(&"take_hit"):
		_spent = true
		body.take_hit()
		Refs.bullet_pool.despawn(self)
