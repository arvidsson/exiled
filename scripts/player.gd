extends CharacterBody2D
class_name Player

@export var max_speed: float
@export var bullet_speed: float = 300.0
@export var roll_speed_mult: float = 1.5
@export var max_stamina: float = 100.0
@export var stamina_regen_per_sec: float = 25.0
@export var roll_stamina_cost: float = 35.0
@export var max_hp: int = 2
@export var xp_per_level: float = 100.0
@export var magazine_size: int = 6
@export var fire_interval_sec: float = 0.2 # fire_speed
@export var reload_duration_sec: float = 1.0 # reload_speed
@export var damage: RangeInt
@export var crit_chance: float = 0.01
@export var crit_multiplier: float = 1.5

const HURT_FLASH_PEAK := Color(5.0, 5.0, 5.0)
const HURT_FLASH_DURATION := 0.12

var cur_dir := Vector2.DOWN
var current_hp: int
var _rolling := false
var _dying := false
var _roll_dir := Vector2.DOWN
var current_stamina: float
var current_xp: float = 0.0
var player_level: int = 1
var _hurt_tween: Tween
var ammo: int
var total_ammo: int
var _reloading := false
var _reload_remaining: float = 0.0
var _fire_cooldown: float = 0.0

@onready var sprite := $AnimatedSprite2D
@onready var gun := $Gun
@onready var muzzle := $Gun/Muzzle

func _ready() -> void:
	current_stamina = max_stamina
	current_hp = max_hp
	ammo = magazine_size
	total_ammo = magazine_size * 2
	call_deferred(&"_sync_xp_bar")
	call_deferred(&"_sync_hp_label")
	call_deferred(&"_sync_ammo_label")

func add_xp(amount: int) -> void:
	current_xp += amount
	while current_xp >= xp_per_level:
		current_xp -= xp_per_level
		player_level += 1
		Events.levelup.emit()
	_sync_xp_bar()

func take_damage(amount: int = 1) -> void:
	# TODO: hack! should check elsewhere, yup cuz now bullets gets destroyed on collision!
	if _rolling or _dying:
		return
	current_hp -= amount
	_play_hurt_flash()
	_sync_hp_label()
	var par := get_parent()
	if par != null:
		var fc: Node = par.get_node_or_null("FollowCamera")
		if fc != null and fc.has_method(&"add_shake"):
			fc.call(&"add_shake", 6.0)
	if current_hp <= 0:
		_die()
		#get_tree().reload_current_scene()

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

func _die() -> void:
	_dying = true
	_rolling = false
	_reloading = false
	velocity = Vector2.ZERO
	gun.hide()  # hide gun during death animation
	_play_animation_once("die", _on_death_anim_finished)

func _on_death_anim_finished() -> void:
	Tools.call_delay(self, 1.2, func() -> void:
		get_tree().reload_current_scene()
	)

func _play_hurt_flash() -> void:
	if _hurt_tween != null:
		_hurt_tween.kill()
	_hurt_tween = create_tween()
	_hurt_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	sprite.modulate = HURT_FLASH_PEAK
	_hurt_tween.tween_property(sprite, "modulate", Color.WHITE, HURT_FLASH_DURATION)

func _process(_delta: float) -> void:
	if _rolling or _dying:
		return
	var target := get_global_mouse_position()
	if (target - global_position).length_squared() > 0.0001:
		gun.look_at(target)
		gun.scale.y = -1.0 if target.x < global_position.x else 1.0
	else:
		gun.scale.y = 1.0

func _physics_process(delta: float) -> void:
	if _dying:
		return
	if current_stamina < max_stamina:
		current_stamina = minf(max_stamina, current_stamina + stamina_regen_per_sec * delta)

	if Input.is_action_just_pressed("roll") and not _rolling and current_stamina >= roll_stamina_cost:
		_start_roll()

	if _rolling:
		velocity = _roll_dir * max_speed * roll_speed_mult
		move_and_slide()
		_sync_stamina_bar()
		_sync_hp_label()
		_sync_ammo_label()
		return

	var dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = dir * max_speed
	move_and_slide()

	if dir.length() > 0:
		cur_dir = dir
		_update_anim("move", dir)
	else:
		_update_anim("idle", cur_dir)

	# Player facing only (matches _update_anim "up" vs down/horizontal).
	var facing_up: bool = abs(cur_dir.x) < abs(cur_dir.y) and cur_dir.y < 0
	gun.z_index = -1 if facing_up else 1

	_fire_cooldown = maxf(0.0, _fire_cooldown - delta)
	if _reloading:
		_reload_remaining -= delta
		if _reload_remaining <= 0.0:
			_reloading = false
			# Transfer bullets from reserve (total_ammo) to the magazine
			var needed: int = magazine_size - ammo
			var to_load: int = min(needed, total_ammo)
			if to_load > 0:
				ammo += to_load
				total_ammo -= to_load
			_fire_cooldown = fire_interval_sec

	if not _reloading:
		if Input.is_action_just_pressed("reload") and ammo < magazine_size:
			_start_reload()
		elif Input.is_action_pressed("shoot") and ammo == 0:
			_start_reload()

	if not _reloading and Input.is_action_pressed("shoot") and ammo > 0 and _fire_cooldown <= 0.0:
		_fire()
		ammo -= 1
		_fire_cooldown = fire_interval_sec

	_sync_stamina_bar()
	_sync_hp_label()
	_sync_ammo_label()

func _start_roll() -> void:
	current_stamina = maxf(0.0, current_stamina - roll_stamina_cost)
	var d := cur_dir
	if d.length_squared() < 0.0001:
		d = Vector2.DOWN
	_roll_dir = d.normalized()
	_rolling = true
	gun.hide()
	_play_roll_anim(_roll_dir)
	sprite.animation_finished.connect(_on_roll_finished, CONNECT_ONE_SHOT)

func _on_roll_finished() -> void:
	_rolling = false
	gun.show()

func _sync_stamina_bar() -> void:
	Events.stamina_changed.emit(current_stamina, max_stamina)

func _sync_xp_bar() -> void:
	Events.xp_changed.emit(current_xp, xp_per_level)

func _sync_hp_label() -> void:
	Events.hp_changed.emit(current_hp, max_hp)

func _sync_ammo_label() -> void:
	Events.ammo_changed.emit(ammo, total_ammo)

func _start_reload() -> void:
	Audio.play_sfx(Data.Sounds.Reload)
	if _reloading or ammo >= magazine_size or total_ammo <= 0:
		return
	_reloading = true
	_reload_remaining = reload_duration_sec

func add_ammo(amount: int) -> void:
	if amount <= 0:
		return
	total_ammo += amount
	_sync_ammo_label()

func _fire() -> void:
	var dmg := damage.get_random()
	var is_crit := randf() < crit_chance
	if is_crit:
		dmg = round(dmg * crit_multiplier)

	Bullet.create(muzzle.global_position, muzzle.global_transform.x, bullet_speed, dmg)
	Audio.play_sfx(Data.Sounds.Shoot)

func _play_roll_anim(dir: Vector2) -> void:
	var anim: String
	if abs(dir.x) < abs(dir.y):
		sprite.flip_h = false
		sprite.offset.x = 0
		anim = "roll_down" if dir.y > 0 else "roll_up"
	else:
		anim = "roll_right"
		sprite.flip_h = dir.x < 0
		sprite.offset.x = -24 if dir.x < 0 else 0
	sprite.play(anim)

func _update_anim(state: String, dir: Vector2) -> void:
	var anim := ""

	if abs(dir.x) < abs(dir.y):
		sprite.flip_h = false
		sprite.offset.x = 0
		if dir.y > 0:
			anim = state + "_down"
		else:
			anim = state + "_up"
	else:
		anim = state + "_right"
		sprite.flip_h = dir.x < 0
		# HACK: offset fix
		sprite.offset.x = -24 if dir.x < 0 else 0

	# Avoid restarting animation every frame
	if sprite.animation != anim:
		sprite.play(anim)
