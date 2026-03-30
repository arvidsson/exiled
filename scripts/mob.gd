extends CharacterBody2D
class_name Mob

# TODO: should be set from the data when spawned
@export var speed: float = 40.0
@export var attack_range: float = 32.0
@export var attack_cooldown: float = 1.2
@export var xp_reward: int = 10
@export var max_health: int = 10

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var healthbar: ProgressBar = $HealthBar

const HURT_FLASH_PEAK := Color(5, 5, 5)
const HURT_FLASH_DURATION := 0.12

var _dying := false
var _attacking := false
var _attack_cd_remaining := 0.0
var _hurt_tween: Tween
var _player: Player
var _health: int

func _draw() -> void:
	var hurtbox_radius: float = 16.0  # size of the attack hit area
	# Draw attack range (red ring, not filled)
	#draw_circle(Vector2.ZERO, attack_range, Color(1, 0, 0, 0.5), false)
	# Draw hurtbox only while attacking (yellow ring)
	if _attacking:
		draw_circle(Vector2.ZERO, hurtbox_radius, Color(1, 1, 0, 0.7), false)

func _ready() -> void:
	_player = get_tree().get_first_node_in_group("player") as Player

func _disconnect_animation_finished(callback: Callable) -> void:
	if sprite.animation_finished.is_connected(callback):
		sprite.animation_finished.disconnect(callback)

func _play_animation(name: StringName) -> void:
	if sprite.animation != name:
		sprite.play(name)

func _play_animation_once(anim: StringName, callback: Callable) -> void:
	_disconnect_animation_finished(callback)
	sprite.play(anim)
	sprite.animation_finished.connect(callback, CONNECT_ONE_SHOT)

func _distance_to_player_sq() -> float:
	return global_position.distance_squared_to(_player.global_position)

func _dir_to_player() -> Vector2:
	return global_position.direction_to(_player.global_position)

func _physics_process(delta: float) -> void:
	if _dying:
		return

	_update_facing(_player.global_position)

	if _attack_cd_remaining > 0.0:
		_attack_cd_remaining = maxf(0.0, _attack_cd_remaining - delta)

	if _attacking:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var dist_sq := _distance_to_player_sq()
	var range_sq := attack_range * attack_range
	if dist_sq <= range_sq and _attack_cd_remaining <= 0.0 and not _attacking:
		_start_attack()
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var dir := _dir_to_player()
	velocity = dir * speed
	move_and_slide()

	if velocity.length_squared() > 0.0001:
		_play_animation(&"move")
	else:
		_play_animation(&"idle")

func _update_facing(target: Vector2) -> void:
	sprite.flip_h = target.x < global_position.x

func _start_attack() -> void:
	_attacking = true
	_play_animation_once(&"attack", _on_attack_anim_finished)

func _on_attack_anim_finished() -> void:
	if _dying:
		return
	if _distance_to_player_sq() <= attack_range * attack_range:
		if _player.has_method(&"take_damage"):
			_player.take_damage(1)
	_attacking = false
	_attack_cd_remaining = attack_cooldown
	sprite.play(&"idle")

func take_damage(amount: int = 1) -> void:
	if _dying:
		return

	_health = max(0, _health - amount)
	_play_hurt_flash()
	_update_healthbar()
	if _health == 0:
		_die()

func _play_hurt_flash() -> void:
	if _hurt_tween != null:
		_hurt_tween.kill()
	_hurt_tween = create_tween()
	_hurt_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	sprite.modulate = HURT_FLASH_PEAK
	_hurt_tween.tween_property(sprite, "modulate", Color.WHITE, HURT_FLASH_DURATION)

func _update_healthbar() -> void:
	healthbar.value = float(_health) / max_health * 100
	healthbar.visible = _health < max_health

func _die() -> void:
	_dying = true
	_attacking = false
	velocity = Vector2.ZERO
	Audio.play_sfx(Data.get_sound("hurt"))
	collision_layer = 0
	_disconnect_animation_finished(_on_attack_anim_finished)
	_play_animation_once(&"die", _on_die_anim_finished)

func _on_die_anim_finished() -> void:
	var xp_orb = Pools.spawn("xp_pickup", global_position) as XPPickup
	xp_orb.setup(xp_reward)
	Pools.despawn(self)

func _on_spawn() -> void:
	_health = max_health
	healthbar.visible = false
	_dying = false
	_attacking = false
	_attack_cd_remaining = 0.0
	velocity = Vector2.ZERO
	collision_layer = Globals.CollisionLayer.MOB
	collision_mask = Globals.CollisionLayer.WORLD
	sprite.flip_h = false
	sprite.play(&"idle")

func _on_despawn() -> void:
	_disconnect_animation_finished(_on_attack_anim_finished)
	_disconnect_animation_finished(_on_die_anim_finished)
