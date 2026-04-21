class_name Slime
extends Mob

@export var size: int = 2
@export var damage: int = 1

var _attack_timer: float = 0.0

func _on_spawn() -> void:
	size = 2 # default to large
	super._on_spawn()
	apply_size()
	_attack_timer = 0.0

func apply_size() -> void:
	if size == 1:
		scale = Vector2.ONE * 0.2
		max_health = 2
		speed = 60.0
		xp_reward = 2
		damage = 1
	else:
		scale = Vector2.ONE * 0.5
		max_health = 6
		speed = 30.0
		xp_reward = 10
		damage = 2

	health = max_health

func _physics_process(delta: float) -> void:
	if dying or attacking:
		return

	if _attack_timer > 0:
		_attack_timer -= delta

	var dist_sq = distance_to_player_sq()
	if _attack_timer <= 0 and dist_sq <= attack_range * attack_range:
		_start_attack()
		return

	move_towards(player.global_position, delta)
	update_facing(player.global_position)

	if velocity.length_squared() > 0.01:
		play_animation(&"walk")
	else:
		play_animation(&"idle")

func _start_attack() -> void:
	attacking = true
	_attack_timer = attack_cooldown
	play_animation_once(&"attack", _on_attack_anim_finished)

func _on_attack_anim_finished() -> void:
	if dying:
		return

	# Apply damage if player is still in range (with a small buffer)
	if distance_to_player_sq() <= (attack_range + 8.0) ** 2:
		player.take_damage(damage)

	attacking = false

func _on_die_anim_finished() -> void:
	if size > 1:
		var num_small = randi_range(2, 5)
		for i in range(num_small):
			var spawn_pos = global_position + Vector2(randf_range(-12, 12), randf_range(-12, 12))
			var s = Pools.spawn(Data.Mobs.Slime, spawn_pos) as Slime
			if s:
				s.size = size - 1
				s.apply_size()

	super._on_die_anim_finished()
