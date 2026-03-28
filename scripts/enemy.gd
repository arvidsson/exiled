extends CharacterBody2D

@export var speed: float = 40.0
@export var attack_range: float = 32.0
@export var attack_cooldown: float = 1.2
@export var xp_reward: int = 10

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var _dying := false
var _attacking := false
var _attack_cd_remaining := 0.0


func _physics_process(delta: float) -> void:
	if _dying:
		return

	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return

	_update_facing(player.global_position)

	if _attack_cd_remaining > 0.0:
		_attack_cd_remaining = maxf(0.0, _attack_cd_remaining - delta)

	if _attacking:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var dist_sq := global_position.distance_squared_to(player.global_position)
	var range_sq := attack_range * attack_range
	if dist_sq <= range_sq and _attack_cd_remaining <= 0.0 and not _attacking:
		_start_attack()
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var dir := global_position.direction_to(player.global_position)
	velocity = dir * speed
	move_and_slide()

	if velocity.length_squared() > 0.0001:
		if sprite.animation != &"move":
			sprite.play(&"move")
	else:
		if sprite.animation != &"idle":
			sprite.play(&"idle")


func _update_facing(target: Vector2) -> void:
	sprite.flip_h = target.x < global_position.x


func _start_attack() -> void:
	_attacking = true
	sprite.play(&"attack")
	if sprite.animation_finished.is_connected(_on_attack_anim_finished):
		sprite.animation_finished.disconnect(_on_attack_anim_finished)
	sprite.animation_finished.connect(_on_attack_anim_finished, CONNECT_ONE_SHOT)


func _on_attack_anim_finished() -> void:
	if _dying:
		return
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player != null and global_position.distance_squared_to(player.global_position) <= attack_range * attack_range:
		if player.has_method(&"take_damage"):
			player.take_damage(1)
	_attacking = false
	_attack_cd_remaining = attack_cooldown
	if not _dying and sprite.animation != &"die":
		sprite.play(&"idle")


func take_hit() -> void:
	if _dying:
		return
	_dying = true
	_attacking = false
	velocity = Vector2.ZERO
	SoundManager.play_sfx(Data.get_sound("hurt"))
	# Bullets monitor layer 4; clear immediately so dying bodies do not consume shots.
	collision_layer = 0
	var xp_orb = Pools.spawn("xp_pickup", global_position) as XPPickup
	xp_orb.setup(xp_reward)
	if sprite.animation_finished.is_connected(_on_attack_anim_finished):
		sprite.animation_finished.disconnect(_on_attack_anim_finished)
	sprite.play(&"die")
	if sprite.animation_finished.is_connected(_on_die_anim_finished):
		sprite.animation_finished.disconnect(_on_die_anim_finished)
	sprite.animation_finished.connect(_on_die_anim_finished, CONNECT_ONE_SHOT)

func _on_die_anim_finished() -> void:
	Pools.despawn(self)

func _on_spawn() -> void:
	_dying = false
	_attacking = false
	_attack_cd_remaining = 0.0
	velocity = Vector2.ZERO
	collision_layer = 4
	collision_mask = 1
	var spr := $AnimatedSprite2D as AnimatedSprite2D
	spr.flip_h = false
	spr.play(&"idle")
	if spr.animation_finished.is_connected(_on_attack_anim_finished):
		spr.animation_finished.disconnect(_on_attack_anim_finished)
	if spr.animation_finished.is_connected(_on_die_anim_finished):
		spr.animation_finished.disconnect(_on_die_anim_finished)


func on_despawn() -> void:
	velocity = Vector2.ZERO
	var spr := $AnimatedSprite2D as AnimatedSprite2D
	if spr.animation_finished.is_connected(_on_attack_anim_finished):
		spr.animation_finished.disconnect(_on_attack_anim_finished)
	if spr.animation_finished.is_connected(_on_die_anim_finished):
		spr.animation_finished.disconnect(_on_die_anim_finished)
