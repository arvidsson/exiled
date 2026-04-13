extends CharacterBody2D
class_name Player

@export var movement_speed: float = 50.0
@export var bullet_speed: float = 300.0

# burst with knockback, TODO: refactor into a PlayerAction
@export var burst_count: int = 3
@export var burst_interval_sec: float = 0.06
@export var burst_spread_deg: float = 6.0
@export var secondary_bullet_speed: float = 300.0
@export var secondary_knockback: float = 120.0
@export var secondary_cooldown_sec: float = 1.5

# roll, TODO: refactor into a PlayerAction
@export var roll_speed_mult: float = 1.5
@export var roll_stamina_cost: float = 35.0

@export var max_stamina: float = 100.0
@export var stamina_regen: float = 25.0 # per sec

@export var max_health: int = 2
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
var health: int
var rolling := false
var dying := false
var roll_dir := Vector2.DOWN
var stamina: float: set = _set_stamina
var current_xp: float = 0.0
var player_level: int = 1
var hurt_tween: Tween
var ammo: int
var total_ammo: int
var reloading := false
var reload_remaining: float = 0.0
var fire_cooldown: float = 0.0
var secondary_cooldown: float = 0.0

@onready var sprite := $AnimatedSprite2D
@onready var gun := $Gun
@onready var muzzle := $Gun/Muzzle

func _ready() -> void:
	stamina = max_stamina
	health = max_health
	ammo = magazine_size
	total_ammo = magazine_size * 2
	call_deferred(&"_sync_xp_bar")
	call_deferred(&"_sync_hp_label")
	call_deferred(&"_sync_ammo_label")
	call_deferred(&"_sync_stamina_bar")

func _set_stamina(value: float):
	stamina = clamp(value, 0.0, max_stamina)
	_sync_stamina_bar()

func _sync_stamina_bar() -> void:
	Events.stamina_changed.emit(stamina, max_stamina)
func _sync_xp_bar() -> void:
	Events.xp_changed.emit(current_xp, xp_per_level)
func _sync_hp_label() -> void:
	Events.health_changed.emit(health, max_health)
func _sync_ammo_label() -> void:
	Events.ammo_changed.emit(ammo, total_ammo)

func add_xp(amount: int) -> void:
	current_xp += amount
	while current_xp >= xp_per_level:
		current_xp -= xp_per_level
		player_level += 1
		Events.levelup.emit()
	_sync_xp_bar()

func take_damage(amount: int = 1) -> void:
	# TODO: hack! should check elsewhere, yup cuz now bullets gets destroyed on collision!
	if rolling or dying:
		return
	health -= amount
	_play_hurt_flash()
	_sync_hp_label()
	var par := get_parent()
	if par != null:
		var fc: Node = par.get_node_or_null("FollowCamera")
		if fc != null and fc.has_method(&"add_shake"):
			fc.call(&"add_shake", 6.0)
	if health <= 0:
		_die()

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
	dying = true
	rolling = false
	reloading = false
	velocity = Vector2.ZERO
	gun.hide()  # hide gun during death animation
	_play_animation_once("die", _on_death_anim_finished)

func _on_death_anim_finished() -> void:
	Tools.call_delay(self, 1.2, func() -> void:
		get_tree().reload_current_scene()
	)

func _play_hurt_flash() -> void:
	if hurt_tween != null:
		hurt_tween.kill()
	hurt_tween = create_tween()
	hurt_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	sprite.modulate = HURT_FLASH_PEAK
	hurt_tween.tween_property(sprite, "modulate", Color.WHITE, HURT_FLASH_DURATION)

func _process(_delta: float) -> void:
	if rolling or dying:
		return
	var target := get_global_mouse_position()
	if (target - global_position).length_squared() > 0.0001:
		gun.look_at(target)
		gun.scale.y = -1.0 if target.x < global_position.x else 1.0
	else:
		gun.scale.y = 1.0

func _physics_process(delta: float) -> void:
	if dying:
		return
	if stamina < max_stamina:
		stamina = minf(max_stamina, stamina + stamina_regen * delta)

	if Input.is_action_just_pressed("roll") and not rolling and stamina >= roll_stamina_cost:
		_start_roll()

	if rolling:
		velocity = roll_dir * movement_speed * roll_speed_mult
		move_and_slide()
		return

	var dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = dir * movement_speed
	move_and_slide()

	if dir.length() > 0:
		cur_dir = dir
		_update_anim("move", dir)
	else:
		_update_anim("idle", cur_dir)

	# Player facing only (matches _update_anim "up" vs down/horizontal).
	var facing_up: bool = abs(cur_dir.x) < abs(cur_dir.y) and cur_dir.y < 0
	gun.z_index = -1 if facing_up else 1

	fire_cooldown = maxf(0.0, fire_cooldown - delta)
	secondary_cooldown = maxf(0.0, secondary_cooldown - delta)
	if reloading:
		reload_remaining -= delta
		if reload_remaining <= 0.0:
			reloading = false
			# Transfer bullets from reserve (total_ammo) to the magazine
			var needed: int = magazine_size - ammo
			var to_load: int = min(needed, total_ammo)
			if to_load > 0:
				ammo += to_load
				total_ammo -= to_load
			fire_cooldown = fire_interval_sec

	if not reloading:
		if Input.is_action_just_pressed("reload") and ammo < magazine_size:
			_start_reload()
		elif Input.is_action_pressed("shoot") and ammo == 0:
			_start_reload()

	if not reloading and Input.is_action_pressed("shoot") and ammo > 0 and fire_cooldown <= 0.0:
		_fire()
		ammo -= 1
		fire_cooldown = fire_interval_sec

	# Secondary burst attack (bind an input action named "shoot_secondary")
	if Input.is_action_just_pressed("secondary") and secondary_cooldown <= 0.0:
		_secondary_fire()
		secondary_cooldown = secondary_cooldown_sec

func _secondary_fire() -> void:
	# Damage and crit calculation (same as primary)
	Events.skill_used.emit(Globals.Skill.SECONDARY, secondary_cooldown_sec)
	var dmg := damage.get_random()
	dmg = int(dmg / 2.0)
	var is_crit := randf() < crit_chance
	if is_crit:
		dmg = round(dmg * crit_multiplier)

	var base_dir: Vector2 = muzzle.global_transform.x
	var spread_rad := burst_spread_deg * PI / 180.0

	for i in range(burst_count):
		# Schedule each bullet closely after the previous one
		Tools.call_delay(self, i * burst_interval_sec, func() -> void:
			var d := base_dir.rotated(randf_range(-spread_rad, spread_rad))
			Bullet.create(muzzle.global_position, d, secondary_bullet_speed, dmg, secondary_knockback)
			Audio.play_sfx(Data.Sounds.Shoot)
		)


func _start_roll() -> void:
	stamina = maxf(0.0, stamina - roll_stamina_cost)
	var d := cur_dir
	if d.length_squared() < 0.0001:
		d = Vector2.DOWN
	roll_dir = d.normalized()
	rolling = true
	gun.hide()
	_play_roll_anim(roll_dir)
	sprite.animation_finished.connect(_on_roll_finished, CONNECT_ONE_SHOT)

func _on_roll_finished() -> void:
	rolling = false
	gun.show()

func _start_reload() -> void:
	Audio.play_sfx(Data.Sounds.Reload)
	if reloading or ammo >= magazine_size or total_ammo <= 0:
		return
	reloading = true
	reload_remaining = reload_duration_sec

func add_ammo(amount: int) -> void:
	if amount <= 0:
		return
	total_ammo += amount
	_sync_ammo_label()

func _fire() -> void:
	Events.skill_used.emit(Globals.Skill.PRIMARY, fire_interval_sec)
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
