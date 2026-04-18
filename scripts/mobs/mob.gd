extends CharacterBody2D
class_name Mob

@export var data: MobData
@export var speed: float = 40.0
@export var attack_range: float = 32.0
@export var attack_cooldown: float = 1.2
@export var xp_reward: int = 10
@export var max_health: int = 10
@export var drop_chance: float = 0.6 # chance to drop anything on death
@export var ammo_chance: float = 0.25 # given a drop, chance it's ammo instead of XP
@export var hurt_flash_color := Color(5, 5, 5)
@export var sep_radius: float = 24.0
@export var sep_weight: float = 120.0
@export var responsiveness: float = 8.0
@export var hurt_flash_duration := 0.12

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var healthbar: ProgressBar = $HealthBar
@onready var damage_label_spawn: Node2D = $DamageLabelSpawn
@onready var player: Player = get_tree().get_first_node_in_group("player") as Player

var health: int
var dying := false
var attacking := false
var hurt_tween: Tween
var skills: Array[MobSkill]

# Knockback handling
var knockback_velocity: Vector2 = Vector2.ZERO
@export var knockback_friction: float = 600.0 # magnitude per second to remove from knockback

func apply_knockback(vec: Vector2) -> void:
	knockback_velocity += vec

func _ready() -> void:
	if data.skills.size() > 0:
		for skill in data.skills:
			skills.append(skill.duplicate())

func disconnect_animation_finished(callback: Callable) -> void:
	if sprite.animation_finished.is_connected(callback):
		sprite.animation_finished.disconnect(callback)

func play_animation(name: StringName) -> void:
	if sprite.animation != name:
		sprite.play(name)

func play_animation_once(anim: StringName, callback: Callable) -> void:
	disconnect_animation_finished(callback)
	sprite.play(anim)
	sprite.animation_finished.connect(callback, CONNECT_ONE_SHOT)

func distance_to_player() -> float:
	return global_position.distance_to(player.global_position)

func distance_to_player_sq() -> float:
	return global_position.distance_squared_to(player.global_position)

func dir_to_player() -> Vector2:
	return global_position.direction_to(player.global_position)

func update_facing(target: Vector2) -> void:
	sprite.flip_h = target.x < global_position.x

func move_towards(target: Vector2, delta: float) -> void:
	var dir := global_position.direction_to(target)
	# Base desired movement velocity towards target
	var desired := dir * speed

	# Allow subclasses to add custom movement (like evasion)
	desired += _get_custom_velocity()

	# Local separation avoidance using a circle query around this mob
	# TODO: consider using an area2d child instead of doing this each frame
	var sep := Vector2.ZERO
	var space_state = get_world_2d().direct_space_state
	var circle = CircleShape2D.new()
	circle.radius = sep_radius
	var params = PhysicsShapeQueryParameters2D.new()
	params.shape = circle
	params.transform = Transform2D(0, global_position)
	params.exclude = [self]
	params.collide_with_bodies = true
	var results = space_state.intersect_shape(params, 32)
	for res in results:
		var body = res.collider
		if body is Node2D:
			var to_neigh = global_position - body.global_position
			var dist = to_neigh.length()
			if dist > 0 and dist < sep_radius:
				# stronger repulsion when closer
				sep += to_neigh.normalized() * ((sep_radius - dist) / sep_radius)

	# Apply separation weight
	if sep != Vector2.ZERO:
		desired += sep * sep_weight

	# Add any active knockback
	desired += knockback_velocity

	# Smooth towards desired velocity and clamp
	velocity = velocity.lerp(desired, clamp(delta * responsiveness, 0.0, 1.0))

	var max_allowed = speed
	if desired.length() > speed:
		# Allow exceeding speed up to 2.5x for special behaviors like evasion
		max_allowed = min(desired.length(), speed * 2.5)

	velocity = velocity.limit_length(max_allowed)

	move_and_slide()

	# Decay knockback over time using provided delta
	knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, knockback_friction * delta)

func stop() -> void:
	velocity = Vector2.ZERO

func _get_custom_velocity() -> Vector2:
	return Vector2.ZERO

func process_skills(dt: float):
	for skill in skills:
		skill.process(dt)

func take_damage(amount: int = 1) -> void:
	if dying:
		return

	health = max(0, health - amount)
	_play_hurt_flash()
	_update_healthbar()
	var damage_label = Data.FX.DamageLabel.instantiate() as Label
	damage_label.text = str(amount)
	damage_label.global_position = damage_label_spawn.global_position
	get_tree().current_scene.call_deferred("add_child", damage_label)

	if health == 0:
		_die()

func _play_hurt_flash() -> void:
	if hurt_tween != null:
		hurt_tween.kill()
	hurt_tween = create_tween()
	hurt_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	sprite.modulate = hurt_flash_color
	hurt_tween.tween_property(sprite, "modulate", Color.WHITE, hurt_flash_duration)

func _update_healthbar() -> void:
	healthbar.value = float(health) / max_health * 100
	healthbar.visible = health < max_health

func _die() -> void:
	healthbar.visible = false
	dying = true
	velocity = Vector2.ZERO
	Audio.play_sfx(Data.Sounds.Hurt)
	collision_layer = 0
	play_animation_once(&"die", _on_die_anim_finished)

func _on_die_anim_finished() -> void:
	# Chance to drop something on death
	if randf() < drop_chance:
		# Small chance that the drop is ammo instead of XP
		var actual_ammo_chance := ammo_chance
		if player and (player.total_ammo == 0 or player.ammo == 0):
			actual_ammo_chance *= 2.5 # Significant boost if low/out of ammo

		if randf() < actual_ammo_chance:
			var ammo_drop = Pools.spawn(Data.Scenes.Ammo, global_position) as Ammo
			# Give ammo proportional to xp_reward (at least 1)
			ammo_drop.setup(max(1, int(xp_reward / 2)))
		else:
			var xp_orb = Pools.spawn(Data.Scenes.XpPickup, global_position) as XPPickup
			xp_orb.setup(xp_reward)
	Pools.despawn(self)

func _reset():
	speed = data.speed
	attack_range = data.attack_range
	attack_cooldown = data.attack_cooldown
	xp_reward = data.xp_reward
	max_health = data.health

func _on_spawn() -> void:
	_reset()
	health = max_health
	healthbar.visible = false
	dying = false
	attacking = false
	velocity = Vector2.ZERO
	collision_layer = Globals.CollisionLayer.MOB
	collision_mask = Globals.CollisionLayer.WORLD
	sprite.flip_h = false
	sprite.play(&"idle")

func _on_despawn() -> void:
	disconnect_animation_finished(_on_die_anim_finished)
