extends Area2D
class_name Bullet

@export var lifetime: float = 3.0

var velocity := Vector2.ZERO
var dead := false
var lifetime_delay: SceneTreeTimer
var damage: int = 1

static func create(position: Vector2, direction: Vector2, speed: float, damage: float) -> Bullet:
	var bullet := Pools.spawn(Data.Scenes.Bullet, position)
	bullet.setup(direction, speed, damage)
	return bullet

static func create_mob(position: Vector2, direction: Vector2, speed: float, damage: float) -> Bullet:
	var bullet := Pools.spawn(Data.Scenes.MobBullet, position)
	bullet.setup(direction, speed, damage)
	return bullet

func setup(direction: Vector2, speed: float, damage: int = 1) -> void:
	velocity = direction.normalized() * speed
	self.damage = damage

func _ready() -> void:
	pass

func _on_body_entered(body: Node2D) -> void:
	if dead:
		return
	if body.has_method(&"take_damage"):
		dead = true
		call_deferred(&"_apply_hit", body)

func _on_spawn() -> void:
	_cancel_lifetime_delay()
	dead = false
	lifetime_delay = Tools.call_delay(self , lifetime, _on_lifetime_ended)

func _on_despawn() -> void:
	_cancel_lifetime_delay()

func _on_lifetime_ended() -> void:
	lifetime_delay = null
	if dead:
		return
	dead = true
	Pools.despawn(self)

func _physics_process(delta: float) -> void:
	global_position += velocity * delta

func _cancel_lifetime_delay() -> void:
	if lifetime_delay == null:
		return
	if lifetime_delay.timeout.is_connected(_on_lifetime_ended):
		lifetime_delay.timeout.disconnect(_on_lifetime_ended)
	lifetime_delay = null

func _apply_hit(body: Node2D) -> void:
	if is_instance_valid(body) and body.has_method(&"take_damage"):
		body.take_damage(damage)
	Pools.despawn(self)
