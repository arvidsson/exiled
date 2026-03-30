extends Area2D

@export var speed: float = 300.0
@export var lifetime: float = 3.0

var velocity := Vector2.ZERO
var _spent := false
var _lifetime_delay: SceneTreeTimer
var _damage: int = 1

func _ready() -> void:
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

func _on_spawn() -> void:
	_cancel_lifetime_delay()
	_spent = false
	_lifetime_delay = Tools.call_delay(self , lifetime, _on_lifetime_ended)

func _on_despawn() -> void:
	_cancel_lifetime_delay()

func _cancel_lifetime_delay() -> void:
	if _lifetime_delay == null:
		return
	if _lifetime_delay.timeout.is_connected(_on_lifetime_ended):
		_lifetime_delay.timeout.disconnect(_on_lifetime_ended)
	_lifetime_delay = null

func _on_lifetime_ended() -> void:
	_lifetime_delay = null
	if _spent:
		return
	_spent = true
	Pools.despawn(self)

func setup(direction: Vector2, move_speed: float, damage: int = 1) -> void:
	velocity = direction.normalized() * move_speed
	_damage = damage

func _physics_process(delta: float) -> void:
	global_position += velocity * delta

func _on_body_entered(body: Node2D) -> void:
	if _spent:
		return
	if body.has_method(&"take_damage"):
		_spent = true
		# body_entered runs while physics queries flush; reparenting/spawning
		# CollisionObject2D (e.g. XP orb Area2D) must happen after that.
		call_deferred(&"_apply_hit", body)

func _apply_hit(body: Node2D) -> void:
	if is_instance_valid(body) and body.has_method(&"take_damage"):
		body.take_damage(_damage)
	Pools.despawn(self)
