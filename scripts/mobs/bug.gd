extends Mob

@export var fire_rate: float = 0.5  # seconds between bullets
@export var stop_range: float = 150.0  # distance to stop and fire
@export var bullet_speed: float = 200.0

var _time_since_last_shot: float = 0.0

func _ready() -> void:
	super._ready()

func _physics_process(delta: float) -> void:
	if _dying:
		return

	_update_facing(_player.global_position)

	_time_since_last_shot += delta

	var dist_sq := _distance_to_player_sq()

	# Start firing if in range and not already firing
	if dist_sq <= stop_range * stop_range:
		velocity = Vector2.ZERO
		move_and_slide()
		if _time_since_last_shot >= fire_rate:
			_fire_bullet()
			_time_since_last_shot = 0.0
			_play_animation(&"attack")
		else:
			_play_animation(&"idle")
		return

	var dir := _dir_to_player()
	velocity = dir * speed
	move_and_slide()
	if velocity.length_squared() > 0.0001:
		_play_animation(&"move")
	else:
		_play_animation(&"idle")

func _fire_bullet() -> void:
	var bullet = Pools.spawn("mob_bullet", global_position)
	bullet.look_at(_player.global_position)

	if bullet.has_method("setup"):
		var dir = _dir_to_player()
		bullet.setup(dir, bullet_speed)
